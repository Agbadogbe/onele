<?php

namespace Database\Seeders;

use App\Models\Demande;
use App\Models\DemandeConge;
use App\Models\DemandeMateriel;
use App\Models\DemandePermission;
use App\Models\Historique;
use App\Models\Materiel;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class DatabaseSeeder extends Seeder
{
    /**
     * Catalogue de matériel cohérent : chaque référence a sa vraie catégorie.
     *
     * @var list<array{string, string, string, int}>
     */
    private const MATERIELS = [
        ['Ordinateur portable', 'Informatique', 'Poste de travail mobile 14 pouces, chargeur inclus.', 12],
        ['Écran 24 pouces', 'Informatique', 'Moniteur externe avec pied réglable en hauteur.', 18],
        ['Station d\'accueil USB-C', 'Informatique', 'Répartiteur pour double écran, ethernet et alimentation.', 7],
        ['Casque audio antibruit', 'Informatique', 'Casque sans fil pour les réunions en espace partagé.', 9],
        ['Vidéoprojecteur', 'Audiovisuel', 'Projecteur de salle de réunion avec télécommande et câble HDMI.', 3],
        ['Micro-cravate sans fil', 'Audiovisuel', 'Ensemble émetteur-récepteur pour les présentations.', 2],
        ['Chaise ergonomique', 'Mobilier', 'Assise réglable avec soutien lombaire.', 6],
        ['Bureau assis-debout', 'Mobilier', 'Plateau à hauteur réglable électriquement.', 0],
        ['Imprimante laser', 'Bureautique', 'Imprimante noir et blanc en réseau, recto-verso automatique.', 4],
        ['Destructeur de documents', 'Bureautique', 'Broyeuse à coupe croisée pour documents confidentiels.', 1],
    ];

    /**
     * Équipe de démonstration.
     *
     * @var list<array{string, string, string, string}>
     */
    private const EMPLOYES = [
        ['Koné', 'Fatou', 'fatou.kone@onele.test', 'rh'],
        ['Ndiaye', 'Moussa', 'moussa.ndiaye@onele.test', 'employe'],
        ['Traoré', 'Aminata', 'aminata.traore@onele.test', 'employe'],
        ['Bamba', 'Ibrahim', 'ibrahim.bamba@onele.test', 'employe'],
        ['Sow', 'Mariam', 'mariam.sow@onele.test', 'employe'],
        ['Camara', 'Seydou', 'seydou.camara@onele.test', 'employe'],
    ];

    public function run(): void
    {
        $admin = User::factory()->admin()->create([
            'nom' => 'Diallo',
            'prenom' => 'Awa',
            'email' => 'admin@onele.test',
            'password' => bcrypt('password'),
            'telephone' => '77 512 40 18',
        ]);

        $employes = collect(self::EMPLOYES)->map(fn (array $ligne) => User::factory()->create([
            'nom' => $ligne[0],
            'prenom' => $ligne[1],
            'email' => $ligne[2],
            'role' => $ligne[3],
            'password' => bcrypt('password'),
            'telephone' => '7'.fake()->numberBetween(0, 8).' '.fake()->numerify('### ## ##'),
        ]));

        $materiels = collect(self::MATERIELS)->map(fn (array $ligne) => Materiel::create([
            'nom' => $ligne[0],
            'categorie' => $ligne[1],
            'description' => $ligne[2],
            'quantite_disponible' => $ligne[3],
        ]));

        $this->seedDemandes($employes, $materiels, $admin);

        $this->command->info('Admin: admin@onele.test / password');
        $this->command->info('Employé: '.$employes->last()->email.' / password');
    }

    /**
     * Chaque employé dépose les trois types de demande, dans les trois statuts,
     * pour que toutes les vues de l'application aient de quoi s'afficher.
     *
     * @param  Collection<int, User>  $employes
     * @param  Collection<int, Materiel>  $materiels
     */
    private function seedDemandes($employes, $materiels, User $admin): void
    {
        $motifsPermission = [
            'Rendez-vous médical',
            'Démarche administrative à la mairie',
            'Rentrée scolaire des enfants',
            'Convocation à la préfecture',
        ];
        $motifsMateriel = [
            'Équipement du nouveau poste',
            'Remplacement du matériel défectueux',
            'Présentation client sur site',
            'Mise en place du télétravail',
        ];
        $refus = [
            'Période déjà couverte par deux absences dans l\'équipe.',
            'Merci de reporter après la clôture trimestrielle.',
            'Stock insuffisant ce mois-ci, demande à renouveler.',
        ];

        foreach ($employes as $index => $employe) {
            // Les cinq premières couvrent les trois types et les trois statuts :
            // toutes les vues ont ainsi de quoi s'afficher pour chaque employé.
            $plans = [
                ['type' => 'conge', 'statut' => 'en_attente', 'ilya' => 2],
                ['type' => 'permission', 'statut' => 'en_attente', 'ilya' => 1],
                ['type' => 'materiel', 'statut' => 'validee', 'ilya' => 9],
                ['type' => 'conge', 'statut' => 'validee', 'ilya' => 16],
                ['type' => 'permission', 'statut' => 'refusee', 'ilya' => 24],
            ];

            // Les suivantes remontent sur douze semaines, une par tranche, pour
            // que les courbes d'activité racontent une histoire plutôt que de
            // s'écraser sur le mois en cours.
            // Un nombre variable par employé : le palmarès du tableau de bord
            // n'aurait aucun sens si tout le monde déposait autant.
            $tranches = [[28, 40], [41, 54], [55, 68], [69, 82]];
            foreach (array_slice($tranches, 0, fake()->numberBetween(1, 4)) as $tranche) {
                $plans[] = [
                    'type' => fake()->randomElement(['conge', 'permission', 'materiel']),
                    // Deux tiers d'avis favorables, comme le taux affiché au tableau de bord.
                    'statut' => fake()->randomElement(['validee', 'validee', 'refusee']),
                    'ilya' => fake()->numberBetween(...$tranche),
                ];
            }

            foreach ($plans as $rang => $plan) {
                $depot = now()->subDays($plan['ilya'])->subHours($index * 3 + $rang);
                $debut = $depot->copy()->addDays(fake()->numberBetween(4, 25));
                $duree = $plan['type'] === 'conge' ? fake()->numberBetween(2, 8) : 0;

                $demande = Demande::create([
                    'type' => $plan['type'],
                    'date_debut' => $debut->toDateString(),
                    'date_fin' => $debut->copy()->addDays($duree)->toDateString(),
                    'statut' => $plan['statut'],
                    'commentaire' => $plan['statut'] === 'refusee' ? fake()->randomElement($refus) : null,
                    'utilisateur_id' => $employe->id,
                    'validateur_id' => $plan['statut'] === 'en_attente' ? null : $admin->id,
                ]);
                $demande->created_at = $depot;
                $demande->updated_at = $depot;
                $demande->save();

                $this->seedDetail($demande, $plan['type'], $duree, $materiels, $motifsPermission, $motifsMateriel);
                $this->seedJournal($demande, $employe, $admin, $depot);
            }
        }
    }

    /**
     * @param  Collection<int, Materiel>  $materiels
     * @param  list<string>  $motifsPermission
     * @param  list<string>  $motifsMateriel
     */
    private function seedDetail(Demande $demande, string $type, int $duree, $materiels, array $motifsPermission, array $motifsMateriel): void
    {
        match ($type) {
            'conge' => DemandeConge::create([
                'demande_id' => $demande->id,
                'type_conge' => fake()->randomElement(['annuel', 'maladie', 'exceptionnel']),
                'nombre_jours' => $duree + 1,
            ]),
            'permission' => DemandePermission::create([
                'demande_id' => $demande->id,
                ...fake()->randomElement([
                    ['heure_debut' => '08:00', 'heure_fin' => '11:00'],
                    ['heure_debut' => '09:30', 'heure_fin' => '12:30'],
                    ['heure_debut' => '14:00', 'heure_fin' => '16:30'],
                ]),
                'motif' => fake()->randomElement($motifsPermission),
            ]),
            'materiel' => DemandeMateriel::create([
                'demande_id' => $demande->id,
                'materiel_id' => $materiels->random()->id,
                'quantite' => fake()->numberBetween(1, 2),
                'motif' => fake()->randomElement($motifsMateriel),
            ]),
        };
    }

    /**
     * Consigne le dépôt puis, le cas échéant, la décision — l'historique et les
     * notifications sont ainsi peuplés comme en usage réel.
     */
    private function seedJournal(Demande $demande, User $employe, User $admin, Carbon $depot): void
    {
        Historique::create([
            'demande_id' => $demande->id,
            'acteur_id' => $employe->id,
            'action' => 'creation',
            'commentaire' => null,
            'date_action' => $depot,
        ]);

        if ($demande->statut === 'en_attente') {
            return;
        }

        $decision = $depot->copy()->addHours(fake()->numberBetween(3, 40));

        Historique::create([
            'demande_id' => $demande->id,
            'acteur_id' => $admin->id,
            'action' => $demande->statut,
            'commentaire' => $demande->commentaire,
            'date_action' => $decision,
        ]);

        $notification = Notification::create([
            'utilisateur_id' => $employe->id,
            'demande_id' => $demande->id,
            'message' => $demande->messageDeVerdict($demande->statut),
            'lue' => fake()->boolean(40),
        ]);
        $notification->created_at = $decision;
        $notification->updated_at = $decision;
        $notification->save();
    }
}
