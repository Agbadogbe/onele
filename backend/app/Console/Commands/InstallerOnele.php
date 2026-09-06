<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Throwable;

/**
 * Prépare une installation neuve en une commande, quel que soit le système.
 *
 * Les scripts d'amorçage (Windows comme Unix) se contentent de l'appeler :
 * toute la logique vit ici, donc il n'y a pas deux versions à maintenir —
 * ni deux façons de se tromper de guillemets selon le shell.
 */
class InstallerOnele extends Command
{
    protected $signature = 'onele:installer
                            {--fresh : Repart d\'une base vide et rejoue le jeu de démonstration}';

    protected $description = 'Prépare la base, le fichier .env et les données de démonstration';

    public function handle(): int
    {
        $this->components->info('Installation d’Onélé');

        $this->preparerEnv();
        $this->preparerSqlite();

        if (! $this->migrer()) {
            return self::FAILURE;
        }

        $this->semer();

        $this->newLine();
        $this->components->info('Tout est prêt.');
        $this->line('  Admin   : <options=bold>admin@onele.test</> / password');
        $this->line('  Employé : <options=bold>moussa.ndiaye@onele.test</> / password');

        return self::SUCCESS;
    }

    /**
     * `.env` est ignoré par git : une copie fraîche n'en a donc jamais.
     */
    private function preparerEnv(): void
    {
        $env = base_path('.env');

        if (! File::exists($env)) {
            File::copy(base_path('.env.example'), $env);
            $this->components->task('Création du fichier .env');
        }

        // `APP_KEY` chiffre les sessions et les jetons : elle doit être propre
        // à chaque installation, jamais partagée par le dépôt.
        if (blank(config('app.key'))) {
            Artisan::call('key:generate', ['--force' => true]);
            $this->components->task('Génération de la clé d’application');
        }
    }

    /**
     * SQLite est le moteur par défaut : un fichier suffit, il n'y a aucun
     * service à installer ni à démarrer — c'est ce qui rend l'installation
     * identique sur Windows, macOS et Linux.
     */
    private function preparerSqlite(): void
    {
        if (config('database.default') !== 'sqlite') {
            return;
        }

        $chemin = config('database.connections.sqlite.database');

        if ($chemin === ':memory:' || File::exists($chemin)) {
            return;
        }

        File::ensureDirectoryExists(dirname($chemin));
        File::put($chemin, '');
        $this->components->task('Création de la base SQLite');
    }

    private function migrer(): bool
    {
        try {
            Artisan::call(
                $this->option('fresh') ? 'migrate:fresh' : 'migrate',
                ['--force' => true],
                $this->getOutput(),
            );

            return true;
        } catch (Throwable $erreur) {
            $this->newLine();
            $this->components->error('La base est injoignable : '.$erreur->getMessage());
            $this->line('  Vérifiez les lignes <options=bold>DB_*</> de backend/.env.');

            return false;
        }
    }

    /**
     * Le jeu de démonstration n'est rejoué que si la base est vide : relancer
     * l'installation ne doit pas créer six Moussa Ndiaye.
     */
    private function semer(): void
    {
        if (! $this->option('fresh') && User::query()->exists()) {
            $this->components->twoColumnDetail(
                'Données de démonstration',
                '<fg=yellow;options=bold>DÉJÀ PRÉSENTES</>',
            );
            $this->line('  Pour repartir de zéro : <options=bold>php artisan onele:installer --fresh</>');

            return;
        }

        DB::transaction(fn () => Artisan::call('db:seed', ['--force' => true], $this->getOutput()));
    }
}
