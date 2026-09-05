# Onélé — API

API REST et serveur de diffusion temps réel de l'application Onélé
(gestion des demandes de congés, de permissions et de matériel).

- **Framework** : Laravel 13, PHP 8.3+
- **Base de données** : MySQL 8
- **Authentification** : Laravel Sanctum (jetons personnels)
- **Temps réel** : Laravel Reverb, canaux privés

L'installation, les comptes de démonstration, les points d'entrée de l'API et
le fonctionnement du temps réel sont décrits dans le
[README du dépôt](../README.md).

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --port=8000   # API
php artisan reverb:start        # diffusion temps réel
```

Tests :

```bash
php artisan test
```
