import 'package:flutter/foundation.dart';

import 'onele_api.dart';
import '../models/user.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final OneleApi api;
  AuthProvider(this.api) {
    _restore();
  }

  AuthStatus status = AuthStatus.checking;
  AppUser? user;
  String? lastError;

  Future<void> _restore() async {
    final token = await api.storedToken;
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      user = await api.me();
      status = AuthStatus.authenticated;
    } catch (_) {
      await api.clearSession();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    lastError = null;
    try {
      user = await api.login(email, password);
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required String password,
  }) async {
    lastError = null;
    try {
      user = await api.register(
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        password: password,
      );
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Après une modification de fiche : l'en-tête, l'avatar et la page profil
  /// se redessinent sans qu'aucun d'eux ait à recharger quoi que ce soit.
  void remplacerUtilisateur(AppUser nouveau) {
    user = nouveau;
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
