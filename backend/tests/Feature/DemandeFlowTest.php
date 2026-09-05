<?php

namespace Tests\Feature;

use App\Models\Materiel;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DemandeFlowTest extends TestCase
{
    use RefreshDatabase;

    public function test_employe_peut_soumettre_une_demande_de_conge(): void
    {
        $employe = User::factory()->create();

        $response = $this->actingAs($employe, 'sanctum')->postJson('/api/demandes', [
            'type' => 'conge',
            'date_debut' => '2026-09-01',
            'date_fin' => '2026-09-05',
            'type_conge' => 'annuel',
            'nombre_jours' => 5,
        ]);

        $response->assertCreated()->assertJsonPath('statut', 'en_attente');
        $this->assertDatabaseHas('demande_conges', ['nombre_jours' => 5]);
    }

    public function test_admin_peut_valider_une_demande_et_l_employe_est_notifie(): void
    {
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

        $response = $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/demandes/{$demande['id']}/statut", ['statut' => 'validee']);

        $response->assertOk()->assertJsonPath('statut', 'validee');
        $this->assertDatabaseHas('notifications', [
            'utilisateur_id' => $employe->id,
            'demande_id' => $demande['id'],
        ]);
        $this->assertDatabaseHas('historiques', [
            'demande_id' => $demande['id'],
            'action' => 'validee',
        ]);
    }

    public function test_un_employe_ne_peut_pas_valider_une_demande(): void
    {
        $employe = User::factory()->create();
        $autreEmploye = User::factory()->create();

        $demande = $this->actingAs($autreEmploye, 'sanctum')->postJson('/api/demandes', [
            'type' => 'conge',
            'date_debut' => '2026-09-01',
            'date_fin' => '2026-09-02',
            'type_conge' => 'annuel',
            'nombre_jours' => 2,
        ])->json();

        $this->actingAs($employe, 'sanctum')
            ->patchJson("/api/demandes/{$demande['id']}/statut", ['statut' => 'validee'])
            ->assertForbidden();
    }

    public function test_un_employe_ne_voit_pas_les_demandes_des_autres(): void
    {
        $employe = User::factory()->create();
        $autreEmploye = User::factory()->create();

        $this->actingAs($autreEmploye, 'sanctum')->postJson('/api/demandes', [
            'type' => 'conge',
            'date_debut' => '2026-09-01',
            'date_fin' => '2026-09-02',
            'type_conge' => 'annuel',
            'nombre_jours' => 2,
        ]);

        $response = $this->actingAs($employe, 'sanctum')->getJson('/api/demandes');

        $response->assertOk()->assertJsonCount(0);
    }

    public function test_la_validation_d_une_demande_de_materiel_decremente_le_stock(): void
    {
        $admin = User::factory()->admin()->create();
        $employe = User::factory()->create();
        $materiel = Materiel::factory()->create(['quantite_disponible' => 10]);

        $demande = $this->actingAs($employe, 'sanctum')->postJson('/api/demandes', [
            'type' => 'materiel',
            'date_debut' => '2026-09-01',
            'date_fin' => '2026-09-01',
            'materiel_id' => $materiel->id,
            'quantite' => 3,
            'motif' => 'Mission',
        ])->json();

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/demandes/{$demande['id']}/statut", ['statut' => 'validee'])
            ->assertOk();

        $this->assertDatabaseHas('materiels', ['id' => $materiel->id, 'quantite_disponible' => 7]);
    }

    public function test_une_demande_deja_traitee_ne_peut_pas_etre_re_validee(): void
    {
        $admin = User::factory()->admin()->create();
        $employe = User::factory()->create();

        $demande = $this->actingAs($employe, 'sanctum')->postJson('/api/demandes', [
            'type' => 'conge',
            'date_debut' => '2026-09-01',
            'date_fin' => '2026-09-02',
            'type_conge' => 'annuel',
            'nombre_jours' => 2,
        ])->json();

        $this->actingAs($admin, 'sanctum')->patchJson("/api/demandes/{$demande['id']}/statut", ['statut' => 'validee']);

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/demandes/{$demande['id']}/statut", ['statut' => 'refusee'])
            ->assertStatus(409);
    }

    public function test_la_notification_de_verdict_nomme_la_demande_et_sa_date(): void
    {
        $admin = User::factory()->admin()->create();
        $employe = User::factory()->create();

        $demande = $this->actingAs($employe, 'sanctum')->postJson('/api/demandes', [
            'type' => 'conge',
            'date_debut' => '2026-09-01',
            'date_fin' => '2026-09-05',
            'type_conge' => 'annuel',
            'nombre_jours' => 5,
        ])->json('id');

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/demandes/{$demande}/statut", ['statut' => 'validee'])
            ->assertOk();

        // Le message doit se suffire à lui-même : type, période, verdict.
        $this->assertDatabaseHas('notifications', [
            'utilisateur_id' => $employe->id,
            'message' => 'Votre congé du 1 septembre au 5 septembre a été validé.',
        ]);
    }

    public function test_le_verdict_d_une_permission_s_accorde_au_feminin(): void
    {
        $admin = User::factory()->admin()->create();
        $employe = User::factory()->create();

        $demande = $this->actingAs($employe, 'sanctum')->postJson('/api/demandes', [
            'type' => 'permission',
            'date_debut' => '2026-09-01',
            'date_fin' => '2026-09-01',
            'heure_debut' => '08:00',
            'heure_fin' => '11:00',
            'motif' => 'Rendez-vous médical',
        ])->json('id');

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/demandes/{$demande}/statut", ['statut' => 'refusee'])
            ->assertOk();

        $this->assertDatabaseHas('notifications', [
            'utilisateur_id' => $employe->id,
            'message' => 'Votre permission du 1 septembre a été refusée.',
        ]);
    }
}
