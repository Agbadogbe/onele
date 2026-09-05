import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/demande.dart';
import 'onele_api.dart';
import 'realtime_client.dart';

/// Point d'entrée unique du temps réel côté application.
///
/// Tient une seule liaison pour toute la session, entretient le compteur de
/// notifications non lues et rediffuse les évènements aux écrans intéressés.
class RealtimeProvider extends ChangeNotifier {
  final OneleApi _api;

  RealtimeProvider(this._api) {
    _relireLeReglage();
  }

  static const _clePreference = 'onele_alertes_live';

  RealtimeClient? _client;
  StreamSubscription<EvenementTempsReel>? _ecouteEvenements;
  StreamSubscription<bool>? _ecouteEtats;
  int? _utilisateurId;
  bool _libere = false;

  /// Vrai tant que la liaison WebSocket est établie.
  bool connecte = false;

  /// Notifications non lues, entretenu sans aller-retour serveur.
  int nonLues = 0;

  /// Réglage utilisateur : quand il est levé, aucune liaison n'est ouverte et
  /// rien n'arrive en cours de route. L'écran Notifications continue, lui, de
  /// tout montrer au rechargement — on coupe l'annonce, pas l'information.
  bool alertesActives = true;

  Future<void> _relireLeReglage() async {
    final prefs = await SharedPreferences.getInstance();
    final voulu = prefs.getBool(_clePreference) ?? true;
    if (voulu == alertesActives) return;
    alertesActives = voulu;
    _prevenir();
    if (!voulu) await _arreter();
  }

  Future<void> definirAlertes(bool actives) async {
    if (actives == alertesActives) return;
    alertesActives = actives;
    _prevenir();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clePreference, actives);

    if (actives) {
      final id = _utilisateurId;
      if (id != null) await _demarrer(id);
    } else {
      await _arreter();
      // Le compteur, lui, reste juste : il vient du serveur, pas de la liaison.
      await rafraichirNonLues();
    }
  }

  final _notifications = StreamController<AppNotification>.broadcast();
  final _demandes = StreamController<Demande>.broadcast();

  Stream<AppNotification> get notificationsRecues => _notifications.stream;
  Stream<Demande> get demandesTraitees => _demandes.stream;

  /// Aligne la liaison sur l'état d'authentification : `null` à la déconnexion.
  void synchroniser(int? utilisateurId) {
    if (utilisateurId == _utilisateurId) return;
    _utilisateurId = utilisateurId;

    // Appelé pendant la construction de l'arbre : on diffère pour ne pas
    // notifier des auditeurs en cours de rendu.
    Future.microtask(
      () => (utilisateurId == null || !alertesActives)
          ? _arreter()
          : _demarrer(utilisateurId),
    );
  }

  Future<void> _demarrer(int utilisateurId) async {
    await _arreter();
    if (_libere) return;

    final client = RealtimeClient(signer: _api.autoriserCanal);
    _client = client;

    _ecouteEvenements = client.evenements.listen(_surEvenement);
    _ecouteEtats = client.etats.listen((ouverte) {
      connecte = ouverte;
      _prevenir();
    });

    client.demarrer(['private-utilisateur.$utilisateurId']);
    await rafraichirNonLues();
  }

  Future<void> _arreter() async {
    await _ecouteEvenements?.cancel();
    await _ecouteEtats?.cancel();
    _ecouteEvenements = null;
    _ecouteEtats = null;
    await _client?.liberer();
    _client = null;

    connecte = false;
    nonLues = 0;
    _prevenir();
  }

  void _surEvenement(EvenementTempsReel evenement) {
    switch (evenement.nom) {
      case 'notification.recue':
        final charge = evenement.donnees['notification'];
        if (charge is! Map) return;
        final notification = AppNotification.fromJson(
          Map<String, dynamic>.from(charge),
        );
        nonLues++;
        _prevenir();
        _notifications.add(notification);

      case 'demande.traitee':
        final charge = evenement.donnees['demande'];
        if (charge is! Map) return;
        _demandes.add(Demande.fromJson(Map<String, dynamic>.from(charge)));
    }
  }

  /// Recale le compteur sur le serveur (ouverture de session, reprise).
  Future<void> rafraichirNonLues() async {
    try {
      final liste = await _api.notifications();
      nonLues = liste.where((n) => !n.lue).length;
      _prevenir();
    } catch (_) {
      // Compteur laissé en l'état : l'écran Notifications fera foi.
    }
  }

  /// Décrémente après lecture d'une notification, sans requête supplémentaire.
  void marquerUneLue() {
    nonLues = math.max(0, nonLues - 1);
    _prevenir();
  }

  /// La pile a été soldée : la pastille de l'onglet tombe sans aller-retour.
  void viderCompteur() {
    nonLues = 0;
    _prevenir();
  }

  void _prevenir() {
    if (!_libere) notifyListeners();
  }

  @override
  void dispose() {
    _libere = true;
    unawaited(_ecouteEvenements?.cancel());
    unawaited(_ecouteEtats?.cancel());
    unawaited(_client?.liberer());
    unawaited(_notifications.close());
    unawaited(_demandes.close());
    super.dispose();
  }
}
