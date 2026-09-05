import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';

/// Clé publique de l'application Reverb — le pendant du `REVERB_APP_KEY` de
/// `backend/.env`. Elle est publique par construction dans le protocole Pusher
/// (le secret, lui, ne quitte jamais le serveur), d'où la valeur par défaut.
/// Surchargeable au lancement :
/// `flutter run --dart-define=REVERB_APP_KEY=...`
const cleReverb = String.fromEnvironment(
  'REVERB_APP_KEY',
  defaultValue: 'onele-dev-key',
);

const portReverb = int.fromEnvironment('REVERB_PORT', defaultValue: 8080);

/// Signature d'un canal privé, déléguée à l'API REST (jeton Sanctum).
typedef SignerCanal = Future<Map<String, dynamic>> Function(
  String socketId,
  String canal,
);

/// Un évènement applicatif reçu du serveur.
class EvenementTempsReel {
  final String nom;
  final Map<String, dynamic> donnees;

  const EvenementTempsReel(this.nom, this.donnees);
}

/// Liaison temps réel avec Reverb.
///
/// Reverb parle le protocole Pusher ; plutôt que d'embarquer un greffon natif
/// (qui exclurait Flutter web), on tient nous-mêmes la poignée de main, qui
/// tient en quelques messages : connexion, signature du canal, abonnement.
class RealtimeClient {
  final SignerCanal signer;
  final String cle;
  final String hote;
  final int port;
  final bool securise;

  RealtimeClient({
    required this.signer,
    this.cle = cleReverb,
    String? hote,
    this.port = portReverb,
    this.securise = false,
  }) : hote = hote ?? hoteServeur;

  final _evenements = StreamController<EvenementTempsReel>.broadcast();
  final _etats = StreamController<bool>.broadcast();

  /// Évènements applicatifs (`notification.recue`, `demande.traitee`…).
  Stream<EvenementTempsReel> get evenements => _evenements.stream;

  /// `true` dès que la poignée de main a abouti, `false` à chaque coupure.
  Stream<bool> get etats => _etats.stream;

  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _ecoute;
  Timer? _reconnexion;
  Timer? _battement;
  String? _socketId;
  int _tentatives = 0;
  bool _arrete = true;
  final _canaux = <String>{};

  bool get connecte => _socketId != null;

  /// Ouvre la liaison et s'abonne aux canaux demandés.
  void demarrer(Iterable<String> canaux) {
    _arrete = false;
    _canaux
      ..clear()
      ..addAll(canaux);
    _connecter();
  }

  /// Ferme la liaison ; aucune reconnexion ne sera tentée ensuite.
  Future<void> arreter() async {
    _arrete = true;
    _reconnexion?.cancel();
    _battement?.cancel();
    _canaux.clear();
    await _fermerSocket();
    if (!_etats.isClosed) _etats.add(false);
  }

  Future<void> liberer() async {
    await arreter();
    await _evenements.close();
    await _etats.close();
  }

  Future<void> _fermerSocket() async {
    _socketId = null;
    await _ecoute?.cancel();
    _ecoute = null;
    await _socket?.sink.close();
    _socket = null;
  }

  void _connecter() {
    if (_arrete) return;
    _reconnexion?.cancel();

    final schema = securise ? 'wss' : 'ws';
    final uri = Uri.parse(
      '$schema://$hote:$port/app/$cle?protocol=7&client=flutter&version=1.0',
    );

    try {
      final socket = WebSocketChannel.connect(uri);
      _socket = socket;

      // Serveur injoignable : l'échec arrive par `ready`. Sans ce garde-fou il
      // remonterait en exception asynchrone non traitée à chaque tentative.
      unawaited(
        socket.ready.catchError((Object erreur) {
          debugPrint('Temps réel : serveur injoignable ($erreur)');
          _replanifier();
        }),
      );

      _ecoute = socket.stream.listen(
        _surMessage,
        onError: (_) => _replanifier(),
        onDone: _replanifier,
        cancelOnError: true,
      );
    } catch (erreur) {
      debugPrint('Temps réel : connexion impossible ($erreur)');
      _replanifier();
    }
  }

  /// Reconnexion à intervalle croissant : 2, 4, 8, 16 puis 20 secondes.
  void _replanifier() {
    if (_arrete || (_reconnexion?.isActive ?? false)) return;

    _battement?.cancel();
    final etaitConnecte = _socketId != null;
    unawaited(_fermerSocket());
    if (etaitConnecte && !_etats.isClosed) _etats.add(false);

    _tentatives++;
    final secondes = math.min(20, 1 << math.min(_tentatives, 4));
    _reconnexion = Timer(Duration(seconds: secondes), _connecter);
  }

  void _surMessage(dynamic brut) {
    final Map<String, dynamic> message;
    try {
      message = jsonDecode(brut as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final nom = message['event'] as String? ?? '';
    final donnees = _charge(message['data']);

    switch (nom) {
      case 'pusher:connection_established':
        _socketId = donnees['socket_id'] as String?;
        _tentatives = 0;
        if (!_etats.isClosed) _etats.add(true);
        _lancerBattement();
        for (final canal in _canaux) {
          unawaited(_souscrire(canal));
        }

      // Le serveur vérifie que la liaison est vivante ; on répond aussitôt.
      case 'pusher:ping':
        _envoyer({'event': 'pusher:pong', 'data': <String, dynamic>{}});

      case 'pusher:error':
        debugPrint('Temps réel : ${donnees['message'] ?? 'erreur serveur'}');

      default:
        // Les messages internes du protocole n'intéressent pas l'application.
        if (nom.startsWith('pusher')) return;
        _evenements.add(EvenementTempsReel(nom, donnees));
    }
  }

  /// Le champ `data` arrive tantôt en objet, tantôt en chaîne JSON.
  Map<String, dynamic> _charge(dynamic valeur) {
    if (valeur is Map) return Map<String, dynamic>.from(valeur);
    if (valeur is String && valeur.isNotEmpty) {
      try {
        final decode = jsonDecode(valeur);
        if (decode is Map) return Map<String, dynamic>.from(decode);
      } catch (_) {
        // Charge illisible : on la traite comme vide.
      }
    }
    return <String, dynamic>{};
  }

  Future<void> _souscrire(String canal) async {
    final socketId = _socketId;
    if (socketId == null) return;

    try {
      final signature = await signer(socketId, canal);
      _envoyer({
        'event': 'pusher:subscribe',
        'data': {'auth': signature['auth'], 'channel': canal},
      });
    } catch (erreur) {
      debugPrint('Temps réel : canal $canal refusé ($erreur)');
    }
  }

  void _lancerBattement() {
    _battement?.cancel();
    _battement = Timer.periodic(const Duration(seconds: 30), (_) {
      _envoyer({'event': 'pusher:ping', 'data': <String, dynamic>{}});
    });
  }

  void _envoyer(Map<String, dynamic> message) {
    try {
      _socket?.sink.add(jsonEncode(message));
    } catch (_) {
      _replanifier();
    }
  }
}
