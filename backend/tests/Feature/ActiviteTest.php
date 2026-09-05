<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ActiviteTest extends TestCase
{
    use RefreshDatabase;

    private function deposerConge(User $employe, string $debut, int $jours): array
    {
        return $this->actingAs($employe, 'sanctum')->postJson('/api/demandes', [
            'type' => 'conge',
            'date_debut' => $debut,
            'date_fin' => $debut,
            'type_conge' => 'annuel',
            'nombre_jours' => $jours,
        ])->json();
    }

    public function test_le_tableau_de_bord_expose_les_agregats_de_pilotage(): void
    {
        $admin = User::factory()->admin()->create();
        $employe = User::factory()->create();

        $refusee = $this->deposerConge($employe, '2026-12-01', 3);
        $validee = $this->deposerConge($employe, '2026-12-10', 2);

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/demandes/{$validee['id']}/statut", ['statut' => 'validee']);
        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/demandes/{$refusee['id']}/statut", ['statut' => 'refusee']);

        $reponse = $this->actingAs($admin, 'sanctum')->getJson('/api/dashboard');

        $reponse->assertOk()
            ->assertJsonPath('demandes_total', 2)
            // Une validée sur deux tranchées.
            ->assertJsonPath('taux_validation', 50)
            ->assertJsonCount(12, 'activite_hebdomadaire')
            ->assertJsonStructure([
                'delai_moyen_heures',
                'materiel_alertes',
                'top_demandeurs' => [['id', 'prenom', 'nom', 'total']],
                'activite_hebdomadaire' => [['semaine', 'deposees', 'traitees']],
            ]);

        // La demande vient d'être déposée : la dernière semaine la compte.
        $semaines = $reponse->json('activite_hebdomadaire');
        $this->assertSame(2, $semaines[11]['deposees']);
        $this->assertSame(2, $semaines[11]['traitees']);
    }

    public function test_un_employe_recoit_son_solde_et_sa_prochaine_echeance(): void
    {
        $admin = User::factory()->admin()->create();
        $employe = User::factory()->create();

        $aVenir = $this->deposerConge($employe, now()->addDays(20)->toDateString(), 4);
        $this->deposerConge($employe, now()->addDays(40)->toDateString(), 6);

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/demandes/{$aVenir['id']}/statut", ['statut' => 'validee']);

        $this->actingAs($employe, 'sanctum')->getJson('/api/mon-activite')
            ->assertOk()
            // Seuls les congés validés comptent dans le solde.
            ->assertJsonPath('jours_conges_pris', 4)
            ->assertJsonPath('par_statut.validee', 1)
            ->assertJsonPath('par_statut.en_attente', 1)
            ->assertJsonPath('prochaine_demande.id', $aVenir['id'])
            ->assertJsonCount(6, 'activite_mensuelle');
    }

    public function test_chacun_ne_voit_que_sa_propre_activite(): void
    {
        $employe = User::factory()->create();
        $collegue = User::factory()->create();

        $this->deposerConge($collegue, now()->addDays(10)->toDateString(), 5);

        $this->actingAs($employe, 'sanctum')->getJson('/api/mon-activite')
            ->assertOk()
            ->assertJsonPath('jours_conges_pris', 0)
            ->assertJsonPath('par_statut', [])
            ->assertJsonPath('prochaine_demande', null);
    }

    public function test_le_tableau_de_bord_reste_ferme_aux_employes(): void
    {
        $this->actingAs(User::factory()->create(), 'sanctum')
            ->getJson('/api/dashboard')
            ->assertForbidden();
    }
}
