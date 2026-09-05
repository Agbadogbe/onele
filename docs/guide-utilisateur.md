# Guide utilisateur

Onélé gère les demandes de congés, de permissions et de matériel dans une
entreprise. Deux applications se partagent le travail :

- l'**application mobile**, pour les employés qui déposent et suivent leurs demandes ;
- l'**espace web**, pour les RH et les administrateurs qui décident.

Un compte n'ouvre qu'une seule des deux. Un employé ne peut pas se connecter à
l'espace web, un compte RH ou administrateur ne peut pas se connecter à
l'application mobile.

---

## Se connecter

À la première ouverture, l'application mobile propose « Créer un compte » : le
compte est créé avec le rôle employé. Les comptes RH et administrateur sont
créés depuis l'espace web, par un administrateur.

Sur une installation de démonstration, les comptes suivants existent après le
peuplement de la base :

| Rôle | Identifiant | Mot de passe |
|---|---|---|
| Administrateur | `admin@onele.test` | `password` |
| RH | `fatou.kone@onele.test` | `password` |
| Employé | `moussa.ndiaye@onele.test` | `password` |

---

## Côté employé (application mobile)

L'application s'organise en quatre onglets.

### Demandes

L'écran d'accueil. En haut, une carte de synthèse annuelle : jours déjà pris,
rythme des six derniers mois, délai de réponse habituel, prochaine échéance.
En dessous, les compteurs par statut puis la liste des demandes, filtrable.

**Déposer une demande** ouvre un formulaire en trois variantes :

- **Congé** : dates de début et de fin, motif. Le nombre de jours est calculé
  automatiquement.
- **Permission** : une date, une plage horaire, un motif. C'est une absence
  courte, dans la journée.
- **Matériel** : la référence choisie dans le catalogue, la quantité, la
  justification.

Une demande déposée part en statut **En attente**. Tant qu'elle n'est pas
traitée, elle peut être retirée depuis son écran de détail. Une fois la
décision prise, elle ne peut plus l'être.

**Suivre une demande** : la toucher ouvre son détail, avec l'historique complet
des changements de statut, qui les a faits et quand.

### Matériel

Le catalogue de l'inventaire. Recherche par nom, filtres par catégorie, et pour
chaque référence l'état du stock en trois paliers (disponible, tendu, épuisé).
Le bouton de demande depuis une fiche ouvre le formulaire avec la référence
déjà renseignée.

### Alertes

Les notifications reçues, lues ou non. Une décision sur une de vos demandes y
arrive immédiatement si l'application est ouverte, et reste consultable
ensuite. Le compteur de l'onglet indique les non lues.

### Profil

La fiche du compte : informations personnelles modifiables, changement de mot
de passe, liste des appareils connectés avec possibilité de révoquer une
session à distance, réglage des alertes en direct, déconnexion.

Un mot de passe oublié se réinitialise auprès d'un administrateur : la
réinitialisation par courriel n'est pas branchée.

---

## Côté RH et administration (espace web)

### Tableau de bord

L'état du service en un écran : demandes en attente, volumes par type et par
statut, activité récente. C'est la page d'atterrissage après connexion.

### Demandes

Le cœur du travail. Le tableau liste toutes les demandes de l'entreprise, avec
filtres par type, par statut et par personne. Chaque ligne s'ouvre sur le
détail : les informations saisies par l'employé, son historique, et les deux
actions **Approuver** et **Refuser**.

La décision est immédiate : l'employé concerné la reçoit sur son téléphone en
quelques dizaines de millisecondes s'il a l'application ouverte, sinon à sa
prochaine ouverture.

Sur écran étroit, le tableau se transforme en fiches, chaque valeur reprenant
son en-tête de colonne comme étiquette.

### Matériel

La gestion de l'inventaire : créer une référence, modifier sa quantité ou sa
catégorie, la retirer. C'est ce catalogue que les employés consultent depuis
l'application mobile.

### Utilisateurs

Réservé aux administrateurs. Création, modification et suppression des comptes,
attribution des rôles, réinitialisation d'un mot de passe perdu.

### Historique

Le journal des décisions : qui a approuvé ou refusé quoi, et quand. Consultable
et filtrable, il sert de trace en cas de contestation.

---

## Le temps réel

Les deux applications gardent une liaison ouverte avec le serveur. Concrètement :

- une demande déposée depuis un téléphone apparaît en tête du tableau des RH
  sans rechargement ;
- une décision prise depuis l'espace web change le statut sur le téléphone de
  l'employé et y déclenche une alerte, sans qu'il touche à rien.

Si le serveur de diffusion n'est pas démarré, tout reste utilisable : les
interfaces l'indiquent (« Hors ligne » dans le rail latéral du web) et les
informations se mettent à jour au rechargement.

Ces alertes sont **dans l'application**. Elles supposent qu'elle soit ouverte.
Une notification reçue téléphone verrouillé demanderait de brancher les
services de notification d'Apple et de Google, ce qui sort du cadre du projet ;
l'historique reste consultable à la réouverture.

---

## En cas de problème

| Situation | Que faire |
|---|---|
| « Identifiants incorrects » alors que le compte existe | Vérifier l'application : les employés passent par le mobile, les RH et administrateurs par le web. |
| Mot de passe perdu | Demander à un administrateur de le réinitialiser depuis l'espace web. |
| Les mises à jour n'arrivent plus en direct | Le serveur de diffusion est probablement arrêté. Les données restent justes après un rechargement. |
| Une demande ne peut plus être retirée | Elle a déjà été traitée. Son historique en indique la date et l'auteur. |
| Session expirée sur mobile pendant la consultation d'une demande | Message d'erreur générique pour l'instant ; se reconnecter depuis l'écran d'accueil. |
