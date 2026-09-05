# Onélé — application mobile

L'application employé : déposer une demande de congé, de permission ou de
matériel, en suivre la validation, et gérer son compte.

La documentation complète (installation, API, temps réel, charte graphique)
vit dans le [README à la racine du dépôt](../README.md).

## Démarrer

```bash
flutter pub get
flutter run
```

L'API doit tourner en parallèle (`php artisan serve` dans `backend/`), ainsi que
le serveur temps réel (`php artisan reverb:start`) pour les alertes en direct.

## Repères

| Dossier | Contenu |
|---|---|
| `lib/screens/` | Un fichier par écran ; `home_shell.dart` porte les quatre onglets. |
| `lib/widgets/` | Les briques partagées : cartes, en-tête sombre, ossatures de chargement. |
| `lib/services/` | Client HTTP, authentification, liaison temps réel (protocole Pusher parlé à la main). |
| `lib/theme/` | Jetons de couleur, typographie et thème Material. |
| `fonts/` | Fraunces et IBM Plex Sans, embarquées : aucun appel réseau pour le rendu. |

## Vérifications

```bash
flutter analyze
flutter test
```
