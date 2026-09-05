# Onélé

Application web et mobile de gestion des demandes de congés, permissions et matériel.

Trois composants, une seule API :

```
┌──────────────┐                          ┌──────────────┐
│    Mobile    │                          │     Web      │
│   (Flutter)  │                          │   (React)    │
│    Employé   │                          │  Admin / RH  │
└──┬────────┬──┘                          └──┬────────┬──┘
   │        │                                │        │
   │        └────── WebSocket ───┐  ┌────────┘        │
   │  REST/JSON                  ▼  ▼       REST/JSON │
   │                      ┌─────────────────┐         │
   │                      │  Reverb  :8080  │         │
   │                      │  canaux privés  │         │
   │                      └────────▲────────┘         │
   │                               │ diffusion        │
   └──────────────▶┌───────────────┴──────┐◀──────────┘
                   │  API Laravel  :8000  │
                   │    (Sanctum auth)    │
                   └──────────┬───────────┘
                              ▼
                     MySQL (onele)
```

Les deux clients gardent une liaison WebSocket ouverte : une décision prise dans
l'espace web arrive sur le téléphone de l'employé en quelques dizaines de
millisecondes, et inversement (voir [Temps réel](#temps-réel)).

## Structure du dépôt

| Dossier    | Rôle                                              | Stack                    |
|------------|----------------------------------------------------|---------------------------|
| `backend/` | API REST, authentification, diffusion, base de données | Laravel 13, PHP 8.5, MySQL, Reverb |
| `web/`     | Interface d'administration (RH / Admin)             | React 19, Vite            |
| `mobile/`  | Application employé (congés, permissions, matériel) | Flutter 3.47, Dart        |

## Comptes de démonstration

Après le seed de la base (`php artisan migrate:fresh --seed`) :

| Rôle    | Email                             | Mot de passe |
|---------|-----------------------------------|--------------|
| Admin   | `admin@onele.test`          | `password`   |
| RH      | `fatou.kone@onele.test`     | `password`   |
| Employé | `moussa.ndiaye@onele.test`  | `password`   |

Le seed crée six comptes (`fatou.kone`, `moussa.ndiaye`, `aminata.traore`, `ibrahim.bamba`, `mariam.sow`, `seydou.camara`, tous en `@onele.test`) et, pour chacun, cinq demandes couvrant les trois types et les trois statuts — de quoi remplir toutes les vues dès le premier lancement.

L'app **web** n'accepte que les comptes `admin` / `rh`. L'app **mobile** est réservée aux comptes `employe`.

---

## 1. Backend (API Laravel)

### Prérequis
- PHP 8.5+, Composer
- MySQL 8+

### Installation

```bash
cd backend
composer install
cp .env.example .env   # puis vérifier DB_* (voir ci-dessous)
php artisan key:generate
```

Dans `.env`, la base attendue :

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=onele
DB_USERNAME=root
DB_PASSWORD=
```

Et, pour le temps réel, les identifiants du serveur WebSocket (déjà présents
dans `.env.example`) :

```
BROADCAST_CONNECTION=reverb
REVERB_APP_ID=100000
REVERB_APP_KEY=onele-dev-key
REVERB_APP_SECRET=onele-dev-secret
REVERB_HOST="localhost"
REVERB_PORT=8080
REVERB_SCHEME=http
```

`php artisan reverb:install` regénère ces valeurs si besoin — il faut alors les
reporter dans `web/.env` (`VITE_REVERB_APP_KEY`) et, pour le mobile, les passer
au lancement : `flutter run --dart-define=REVERB_APP_KEY=…`.

Créer la base puis migrer + peupler avec des données de démo :

```bash
mysql -u root -e "CREATE DATABASE IF NOT EXISTS onele CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
php artisan migrate:fresh --seed
```

### Lancer le serveur

```bash
php artisan serve --port=8000     # l'API REST
php artisan reverb:start          # le serveur WebSocket, dans un autre terminal
```

L'API est alors disponible sur `http://127.0.0.1:8000/api`, et le serveur de
diffusion sur `ws://127.0.0.1:8080`. Sans ce second processus l'application
reste pleinement utilisable, simplement sans mise à jour instantanée : les
interfaces l'annoncent (« Hors ligne » dans le rail du web).

### Tests

```bash
php artisan test
```

30 tests d'intégration couvrent le flux métier central (soumission, validation,
refus, contrôle d'accès, décrément du stock matériel, double-traitement interdit,
rédaction des notifications de verdict), la diffusion temps réel (évènements émis
sur les bons canaux, cloisonnement des canaux privés), les agrégats de pilotage
(taux, délai, activité hebdomadaire, solde de congés, cloisonnement des activités)
et le compte de l'utilisateur (fiche, mot de passe, sessions ouvertes,
notifications soldées d'un coup).

### Points d'entrée principaux

| Endpoint | Méthode | Accès |
|---|---|---|
| `/api/register`, `/api/login` | POST | Public |
| `/api/demandes` | GET, POST | Authentifié |
| `/api/demandes/{id}/statut` | PATCH | Admin / RH |
| `/api/materiels` | GET, POST, PUT, DELETE | Lecture: tous · Écriture: Admin |
| `/api/utilisateurs` | GET, POST, PUT, DELETE | Admin / RH |
| `/api/notifications` | GET | Propriétaire |
| `/api/notifications/lues` | PATCH | Propriétaire (solde toute la pile) |
| `/api/notifications/{id}/lue` | PATCH | Propriétaire |
| `/api/dashboard`, `/api/historiques` | GET | Admin / RH |
| `/api/mon-activite` | GET | Authentifié (son propre résumé) |
| `/api/profil` | PUT | Authentifié (sa propre fiche) |
| `/api/profil/mot-de-passe` | PUT | Authentifié (exige le mot de passe actuel) |
| `/api/profil/sessions` | GET, DELETE | Authentifié (ses appareils connectés) |
| `/api/broadcasting/auth` | POST | Authentifié (signe l'accès à un canal privé) |

---

## 2. Web (interface d'administration)

### Prérequis
- Node.js 20+

### Installation et lancement

```bash
cd web
npm install
npm run dev
```

Application disponible sur `http://localhost:5173`. Copier `web/.env.example` vers
`web/.env` ; ce fichier porte
l'adresse de l'API et celle du serveur WebSocket :

```
VITE_API_BASE=http://127.0.0.1:8000/api
VITE_REVERB_APP_KEY=onele-dev-key
VITE_REVERB_HOST=127.0.0.1
VITE_REVERB_PORT=8080
VITE_REVERB_SCHEME=http
```

`VITE_REVERB_APP_KEY` doit refléter le `REVERB_APP_KEY` de `backend/.env`.

### Build de production

```bash
npm run build
```

---

## 3. Mobile (application employé)

### Les quatre onglets

| Onglet | Ce qu'on y fait |
|--------|-----------------|
| **Demandes** | Carte de synthèse annuelle (jours pris, rythme des six derniers mois, délai de réponse habituel, prochaine échéance), compteurs par statut, filtres, dépôt d'une demande. |
| **Matériel** | Le catalogue de l'inventaire : recherche, filtres par catégorie, état du stock en trois paliers, et dépôt d'une demande avec la référence déjà choisie. |
| **Alertes** | Les notifications reçues, lues ou non. |
| **Profil** | Fiche du compte, modification des informations, changement de mot de passe, appareils connectés, réglage des alertes en direct, déconnexion. |

Écrans secondaires : détail d'une demande (avec son historique), nouvelle
demande, mes informations, mot de passe, appareils connectés.

### Prérequis
- Flutter SDK 3.47+
- Un simulateur iOS, un émulateur Android, ou Chrome (pour un aperçu rapide)

### Installation et lancement

```bash
cd mobile
flutter pub get
flutter run          # choisit automatiquement un appareil connecté
```

La clé Reverb par défaut est celle de `.env.example`; pour une autre
installation :

```bash
flutter run --dart-define=REVERB_APP_KEY=votre-cle
```

L'URL de l'API s'adapte automatiquement à la plateforme (voir `lib/services/api_client.dart`) :
- iOS Simulator / Chrome / macOS → `http://127.0.0.1:8000/api`
- Émulateur Android → `http://10.0.2.2:8000/api` (alias réseau vers l'hôte)
- **Appareil physique** → remplacer par l'IP réseau locale de la machine qui héberge l'API.

### Tests et analyse statique

```bash
flutter analyze
flutter test
```

---

---

## Temps réel

Une décision prise dans l'espace web atteint le téléphone de l'employé sans
qu'il ait à rafraîchir quoi que ce soit — et une demande déposée depuis le
mobile apparaît aussitôt dans la liste des RH.

**Transport.** [Laravel Reverb](https://reverb.laravel.com), le serveur
WebSocket officiel de Laravel, tourne à côté de l'API sur le port 8080. Il parle
le protocole Pusher.

**Évènements diffusés** — tous en `ShouldBroadcastNow`, donc sans file d'attente
ni *worker* à faire tourner :

| Évènement | Canal | Déclencheur |
|---|---|---|
| `demande.deposee` | `private-administration` | Un employé dépose une demande |
| `demande.traitee` | `private-utilisateur.{id}` + `private-administration` | Un RH valide ou refuse |
| `notification.recue` | `private-utilisateur.{id}` | Toute notification écrite en base |

Leur charge utile a exactement la forme des réponses REST (`DemandeResource`,
`NotificationResource`) : les clients réutilisent leur parseur sans code
supplémentaire.

**Autorisation.** Les canaux sont privés. La signature passe par
`POST /api/broadcasting/auth`, placée sous `auth:sanctum` et sous le préfixe
`/api` — les clients à jeton n'ont pas de session web, et le préfixe les fait
bénéficier de la politique CORS déjà en place. Les règles tiennent en deux
lignes dans [`backend/routes/channels.php`](backend/routes/channels.php) : on
n'écoute que son propre canal, et le canal d'administration exige un rôle
`admin` ou `rh`.

**Côté web** ([`web/src/context/RealtimeContext.jsx`](web/src/context/RealtimeContext.jsx)) :
`laravel-echo` + `pusher-js`, une seule connexion pour la session, redistribuée
aux pages par le hook `useRealtimeEvent`. À l'écran : le rail affiche « En
direct », son compteur de demandes en attente bouge, une ligne qui arrive ou
change de statut s'illumine brièvement, et un bandeau annonce chaque dépôt.

**Côté mobile** ([`mobile/lib/services/realtime_client.dart`](mobile/lib/services/realtime_client.dart)) :
le protocole Pusher est parlé directement au-dessus de `web_socket_channel`
(connexion, signature du canal, abonnement, battement de cœur, reconnexion à
intervalle croissant). Ce choix évite un greffon natif, qui aurait exclu Flutter
web. À l'écran : une bannière « À l'instant », la pastille rouge sur l'onglet
Notifications, la carte de la demande qui bascule sur place, et les compteurs de
l'en-tête qui suivent.

Si Reverb n'est pas lancé, les deux applications fonctionnent normalement en
mode requête/réponse ; seules les mises à jour instantanées manquent.

---

## Démo rapide (les trois composants ensemble)

```bash
# Terminal 1 — API
cd backend && php artisan serve --port=8000

# Terminal 2 — Serveur temps réel
cd backend && php artisan reverb:start

# Terminal 3 — Web admin
cd web && npm run dev

# Terminal 4 — Mobile
cd mobile && flutter run -d chrome   # ou -d <id-simulateur/émulateur>
```

Se connecter côté web avec le compte admin, côté mobile avec un compte employé (ou en créer un via "Créer un compte").

**Pour voir le temps réel :** placez les deux fenêtres côte à côte, puis validez
depuis le web une demande appartenant au compte employé connecté sur le mobile.
La bannière et le changement de statut arrivent sur le téléphone sans le
toucher. Dans l'autre sens, déposez une demande depuis le mobile : la ligne
apparaît en tête du tableau des RH.

## Limites connues

- Sur le mobile, une session expirée pendant la consultation d'une demande affiche un message d'erreur générique plutôt qu'une redirection automatique vers l'écran de connexion.
- Pas de tests automatisés pour le web (React) et le mobile au-delà d'un test de rendu — les parcours et l'adaptation aux écrans ont été vérifiés en pilotant les applications réelles dans un navigateur et un simulateur.
- Les notifications temps réel sont **dans l'application** : elles supposent que
  l'app mobile est ouverte. Une notification système reçue téléphone verrouillé
  demanderait de brancher APNs / Firebase Cloud Messaging, ce qui sort du cadre
  du projet ; l'historique reste consultable à la réouverture.
- Reverb tourne ici en clair (`ws://`) sur le réseau local. En production il
  faudrait le placer derrière TLS (`wss://`) et ajuster `REVERB_SCHEME`.
- La réinitialisation de mot de passe par email n'est pas branchée : un compte
  dont on a perdu le mot de passe se remet en marche depuis l'espace
  d'administration. Le changement volontaire, lui, se fait depuis l'onglet
  Profil de l'application mobile.
- Pas de déploiement en production ; le projet est prévu pour un usage local/démo.

## Documentation complémentaire

- **[Guide utilisateur](docs/guide-utilisateur.md)** — parcours détaillé pour les employés (mobile) et pour les RH et administrateurs (web).

## Adaptation aux écrans

Les deux interfaces sont conçues pour tenir du petit téléphone à l'écran large,
en portrait comme en paysage. Vérifié de 320 px à 1920 px de large.

### Web

| Largeur | Navigation | Tableaux |
|---|---|---|
| ≥ 1280 px | rail latéral | grille classique |
| 881 – 1280 px | rail latéral | fiches dès que la colonne se resserre |
| ≤ 880 px | barre haute, onglets défilants | fiches |
| ≤ 560 px | barre compacte (pastille et déconnexion en icônes) | fiches, modales en feuille remontante |

Le passage du tableau à la fiche ne dépend **pas** de la largeur de la fenêtre
mais de celle réellement offerte au tableau, mesurée par une *container query*
sur `.table-wrap`. C'est nécessaire : le rail bascule à un autre seuil, et les
deux valeurs divergeraient. En mode fiche, chaque cellule reprend son en-tête de
colonne comme étiquette, via `data-label`, dans une colonne de largeur fixe pour
que l'œil relie l'étiquette à sa valeur.

Deux réglages système sont respectés : le thème sombre et « animations
réduites ». Sur écran tactile (`pointer: coarse`), les cibles sont élargies.

### Mobile

Une largeur de lecture commune (560 px) est appliquée par
[`margeLaterale()`](mobile/lib/widgets/common.dart) : sur téléphone elle vaut la
marge habituelle, sur tablette elle recentre le contenu au lieu de l'étirer. La
marge se pose sur le `padding` des listes, ce qui garde le geste de défilement
sur toute la largeur.

Sur écran bas de plafond — téléphone en paysage — les compteurs de l'en-tête et
l'accroche de l'écran de connexion s'effacent pour rendre la hauteur au
contenu. L'agrandissement système du texte est honoré jusqu'à 1,4x, au-delà
duquel les cartes déborderaient.

---

## Charte graphique

Les trois interfaces partagent le même système de design (« Aurore ») : les
plans sombres portent le spectacle — dégradés, halos, grands chiffres — pendant
que les zones de contenu restent calmes et lisibles.

| Jeton | Valeur | Usage |
|---|---|---|
| Fond papier | `#ECF1EF` | Fond des pages |
| Plan sombre | `#101E1B` | Rail de navigation, panneau héros, en-têtes mobiles |
| Dégradé signature | `#17506E` → `#2AA8C4` | Actions primaires, tampon de marque, anneau actif |
| Accent lumineux | `#5FCBE0` | Éléments actifs sur fond sombre |
| Vert / Ambre / Rouge | `#1E7A4E` / `#916510` / `#AE3A34` | **Réservés aux statuts** (validée / en attente / refusée) |

### Typographie

Les deux plateformes partagent les deux mêmes familles, ce qui fait que le web
et le mobile se reconnaissent au premier coup d'œil.

| Rôle | Famille | Où |
|------|---------|-----|
| Voix de la marque | **Fraunces** 600/700 | Logotype, titres d'écran, grands chiffres |
| Texte courant | **IBM Plex Sans** 400–700 | Tout le reste |

Sur le web, elles sont chargées depuis Google Fonts ; sur mobile, les fichiers
sont embarqués dans `mobile/fonts/` (déclarés dans `pubspec.yaml`) — l'application
ne dépend donc d'aucun réseau pour s'afficher correctement.

> Fraunces n'embarque pas la flèche « → » : tout glyphe hors de son jeu doit
> rester en Plex, sinon il se rendrait en tofu.

### Logotype

Un anneau surmonté de son accent — le « Ó » d'Onélé réduit à deux formes.
Il est **dessiné** (SVG côté web, `CustomPaint`-libre côté Flutter) et non écrit :
même géométrie au pixel près des deux côtés, et aucune dépendance à une fonte.

### Palette de données

Les trois teintes qui portent les types de demande dans les graphiques ne sont
pas choisies à l'œil : elles sont **calculées puis validées**.

| Type | Couleur | OKLCH |
|---|---|---|
| Congé | `#0FA7BF` | L 0,67 · C 0,12 |
| Permission | `#6B3CC1` | L 0,49 · C 0,20 |
| Matériel | `#9A5F1A` | L 0,54 · C 0,11 |

Elles conservent les teintes d'origine mais avec des pas de luminosité et de
chroma retenus par recherche, puis contrôlés sur les trois fonds réels (carte
blanche, carte sombre, panneau héros) :

| Contrôle | Avant | Après | Seuil |
|---|---|---|---|
| Séparation daltonienne (deutéranopie) | ΔE 7,0 | **ΔE 21,1** | ≥ 8 |
| Lisibilité en vision normale | ΔE 14,0 ❌ | **ΔE 27,8** | ≥ 15 |
| Chroma minimum | 0,078 ❌ | **≥ 0,11** | ≥ 0,10 |

Deux règles en découlent, appliquées partout :

- **Les chiffres portent le sans de l'interface**, jamais Fraunces : une police
  d'affichage sur un grand nombre se lit comme un ornement. Fraunces reste aux
  titres et au texte éditorial.
- **Chaque graphique porte une étiquette directe** (la valeur extrême) et, sur
  le web, une table équivalente hors écran — le contraste d'une teinte passe
  sous 3:1, la valeur doit rester atteignable autrement que par la couleur.

Aucune couleur de marque n'emprunte les teintes de statut : un badge vert veut
toujours dire « validée ». Les définitions vivent dans
[`web/src/index.css`](web/src/index.css) (variables CSS, thème clair **et**
sombre) et [`mobile/lib/theme/app_theme.dart`](mobile/lib/theme/app_theme.dart)
(classe `AppColors`).

Typographie web : **Fraunces** (titres et grands chiffres), **IBM Plex Sans**
(texte), **IBM Plex Mono** (étiquettes et valeurs numériques). Le mobile utilise
la police système de chaque plateforme (SF Pro sur iOS, Roboto sur Android) pour
un rendu natif.

Les animations (aurore qui dérive, chiffres qui défilent, lignes qui entrent en
cascade) respectent toutes le réglage système « animations réduites ».
