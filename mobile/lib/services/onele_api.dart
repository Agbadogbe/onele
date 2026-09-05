import 'api_client.dart';
import '../models/user.dart';
import '../models/demande.dart';
import '../models/materiel.dart';
import '../models/activite.dart';
import '../models/app_notification.dart';
import '../models/session.dart';

class OneleApi {
  final ApiClient _client = ApiClient();

  Future<String?> get storedToken => _client.token;
  Future<void> clearSession() => _client.clearToken();

  Future<AppUser> login(String email, String password) async {
    final data = await _client.post(
      '/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    await _client.setToken(data['token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> register({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required String password,
  }) async {
    final data = await _client.post(
      '/register',
      body: {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'password': password,
      },
      auth: false,
    );
    await _client.setToken(data['token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> me() async {
    final data = await _client.get('/me');
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _client.post('/logout');
    } finally {
      await _client.clearToken();
    }
  }

  Future<List<Demande>> mesDemandes({String? statut}) async {
    final data = await _client.get(
      '/demandes',
      query: statut != null ? {'statut': statut} : null,
    );
    return (data as List)
        .map((e) => Demande.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Demande> demande(int id) async {
    final data = await _client.get('/demandes/$id');
    return Demande.fromJson(data as Map<String, dynamic>);
  }

  Future<void> annulerDemande(int id) => _client.delete('/demandes/$id');

  Future<Demande> creerDemandeConge({
    required DateTime debut,
    required DateTime fin,
    required String typeConge,
    required int nombreJours,
  }) async {
    final data = await _client.post(
      '/demandes',
      body: {
        'type': 'conge',
        'date_debut': _fmt(debut),
        'date_fin': _fmt(fin),
        'type_conge': typeConge,
        'nombre_jours': nombreJours,
      },
    );
    return Demande.fromJson(data as Map<String, dynamic>);
  }

  Future<Demande> creerDemandePermission({
    required DateTime date,
    required String heureDebut,
    required String heureFin,
    required String motif,
  }) async {
    final data = await _client.post(
      '/demandes',
      body: {
        'type': 'permission',
        'date_debut': _fmt(date),
        'date_fin': _fmt(date),
        'heure_debut': heureDebut,
        'heure_fin': heureFin,
        'motif': motif,
      },
    );
    return Demande.fromJson(data as Map<String, dynamic>);
  }

  Future<Demande> creerDemandeMateriel({
    required DateTime date,
    required int materielId,
    required int quantite,
    required String motif,
  }) async {
    final data = await _client.post(
      '/demandes',
      body: {
        'type': 'materiel',
        'date_debut': _fmt(date),
        'date_fin': _fmt(date),
        'materiel_id': materielId,
        'quantite': quantite,
        'motif': motif,
      },
    );
    return Demande.fromJson(data as Map<String, dynamic>);
  }

  /// Résumé d'activité de l'employé connecté (solde, rythme, prochaine échéance).
  Future<MonActivite> monActivite() async {
    final data = await _client.get('/mon-activite');
    return MonActivite.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Materiel>> materiels() async {
    final data = await _client.get('/materiels');
    return (data as List)
        .map((e) => Materiel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppNotification>> notifications() async {
    final data = await _client.get('/notifications');
    return (data as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> marquerNotificationLue(int id) =>
      _client.patch('/notifications/$id/lue');

  /// Solde la pile d'un coup — une requête, pas une par ligne.
  Future<int> marquerToutesLues() async {
    final data = await _client.patch('/notifications/lues');
    return (data as Map<String, dynamic>?)?['marquees'] as int? ?? 0;
  }

  /// Met à jour sa propre fiche. Ni le rôle ni l'activation n'y passent :
  /// le serveur les ignore, ils relèvent de l'administration.
  Future<AppUser> modifierProfil({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
  }) async {
    final data = await _client.put(
      '/profil',
      body: {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
      },
    );
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<void> changerMotDePasse({
    required String actuel,
    required String nouveau,
  }) => _client.put(
    '/profil/mot-de-passe',
    body: {
      'mot_de_passe_actuel': actuel,
      'mot_de_passe': nouveau,
      'mot_de_passe_confirmation': nouveau,
    },
  );

  Future<List<SessionOuverte>> sessions() async {
    final data = await _client.get('/profil/sessions');
    return (data as List)
        .map((e) => SessionOuverte.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> revoquerSession(int id) =>
      _client.delete('/profil/sessions/$id');

  /// Signe l'accès à un canal privé Reverb avec le jeton Sanctum déjà stocké.
  Future<Map<String, dynamic>> autoriserCanal(
    String socketId,
    String canal,
  ) async {
    final data = await _client.post(
      '/broadcasting/auth',
      body: {'socket_id': socketId, 'channel_name': canal},
    );
    return data as Map<String, dynamic>;
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
