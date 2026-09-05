<?php

namespace Tests\Feature;

use App\Events\DemandeDeposee;
use App\Events\DemandeTraitee;
use App\Events\NotificationRecue;
use App\Models\User;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class DiffusionTempsReelTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @return array<int, string>
     */
    private function canaux(object $evenement): array
    {
        return array_map(
            fn (PrivateChannel $canal) => (string) $canal,
            $evenement->broadcastOn()
        );
    }

    public function test_une_demande_deposee_est_diffusee_a_l_administration(): void
    {
        Event::fake([DemandeDeposee::class, NotificationRecue::class]);

        $admin = User::factory()->admin()->create();
        $employe = User::factory()->create();

        $this->actingAs($employe, 'sanctum')->postJson('/api/demandes', [
            'type' => 'conge',
            'date_debut' => '2026-09-01',
            'date_fin' => '2026-09-05',
            'type_conge' => 'annuel',
            'nombre_jours' => 5,
        ])->assertCreated();

        Event::assertDispatched(
            DemandeDeposee::class,
            fn (DemandeDeposee $e) => $this->canaux($e) === ['private-administration']
                && $e->broadcastWith()['demande']['statut'] === 'en_attente'
        );

        // L'admin est prévenu sur son canal personnel, pas l'auteur de la demande.
        Event::assertDispatched(
            NotificationRecue::class,
            fn (NotificationRecue $e) => $this->canaux($e) === ["private-utilisateur.{$admin->id}"]
        );
    }

    public function test_un_verdict_est_diffuse_a_l_employe_et_a_l_administration(): void
    {
        Event::fake([DemandeTraitee::class, NotificationRecue::class]);

        $admin = User::factory()->admin()->create();
        $employe = User::factory()->create();

        $demande = $this->actingAs($employe, 'sanctum')->postJson('/api/demandes', [
            'type' => 'permission',
            'date_debut' => '2026-09-01',
            'date_fin' => '2026-09-01',
            'heure_debut' => '10:00',
            'heure_fin' => '12:00',
            'motif' => 'Rendez-vous',
        ])->json();

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/demandes/{$demande['id']}/statut", ['statut' => 'validee'])
            ->assertOk();

        Event::assertDispatched(
            DemandeTraitee::class,
            fn (DemandeTraitee $e) => $this->canaux($e) === [
                "private-utilisateur.{$employe->id}",
                'private-administration',
            ] && $e->broadcastWith()['demande']['statut'] === 'validee'
        );

        // La charge doit être exploitable telle quelle par le mobile : `lue`
        // vaut `false` et non `null` sur une notification fraîchement créée.
        Event::assertDispatched(
            NotificationRecue::class,
            function (NotificationRecue $e) use ($employe) {
                $charge = $e->broadcastWith()['notification'];

                return $this->canaux($e) === ["private-utilisateur.{$employe->id}"]
                    && $charge['lue'] === false
                    // Le message nomme la demande et sa date : il est lisible
                    // seul, dans une bannière comme dans la pile d'alertes.
                    && $charge['message'] === 'Votre permission du 1 septembre a été validée.';
            }
        );
    }

    /**
     * `phpunit.xml` force `BROADCAST_CONNECTION=null`, dont le pilote autorise
     * tout sans consulter `routes/channels.php`. Pour éprouver réellement le
     * cloisonnement, on bascule sur le pilote employé en production, avec des
     * identifiants propres au test.
     */
    private function activerLeVraiBroadcaster(): void
    {
        config([
            'broadcasting.default' => 'reverb',
            'broadcasting.connections.reverb.key' => 'cle-de-test',
            'broadcasting.connections.reverb.secret' => 'secret-de-test',
            'broadcasting.connections.reverb.app_id' => 'app-de-test',
        ]);

        // `Broadcast::channel()` enregistre sur le pilote courant : après avoir
        // changé de pilote, il faut rejouer les déclarations pour que les
        // canaux existent aussi sur celui-ci.
        require base_path('routes/channels.php');
    }

    public function test_un_employe_ne_peut_pas_ecouter_le_canal_de_l_administration(): void
    {
        $this->activerLeVraiBroadcaster();
        $employe = User::factory()->create();

        $this->actingAs($employe, 'sanctum')->postJson('/api/broadcasting/auth', [
            'socket_id' => '1234.5678',
            'channel_name' => 'private-administration',
        ])->assertForbidden();
    }

    public function test_un_employe_ne_peut_pas_ecouter_le_canal_d_un_collegue(): void
    {
        $this->activerLeVraiBroadcaster();
        $employe = User::factory()->create();
        $collegue = User::factory()->create();

        $this->actingAs($employe, 'sanctum')->postJson('/api/broadcasting/auth', [
            'socket_id' => '1234.5678',
            'channel_name' => "private-utilisateur.{$collegue->id}",
        ])->assertForbidden();

        $this->actingAs($employe, 'sanctum')->postJson('/api/broadcasting/auth', [
            'socket_id' => '1234.5678',
            'channel_name' => "private-utilisateur.{$employe->id}",
        ])->assertOk();
    }

    public function test_un_visiteur_anonyme_ne_peut_signer_aucun_canal(): void
    {
        $this->activerLeVraiBroadcaster();

        $this->postJson('/api/broadcasting/auth', [
            'socket_id' => '1234.5678',
            'channel_name' => 'private-administration',
        ])->assertUnauthorized();
    }
}
