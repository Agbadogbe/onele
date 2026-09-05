<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfilTest extends TestCase
{
    use RefreshDatabase;

    public function test_un_employe_met_a_jour_sa_fiche(): void
    {
        $user = User::factory()->create(['telephone' => null]);
        Sanctum::actingAs($user);

        $this->putJson('/api/profil', [
            'nom' => 'Sow',
            'prenom' => 'Mariam',
            'email' => 'mariam.sow@onele.test',
            'telephone' => '77 000 11 22',
        ])->assertOk()->assertJsonPath('prenom', 'Mariam');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'email' => 'mariam.sow@onele.test',
            'telephone' => '77 000 11 22',
        ]);
    }

    public function test_la_fiche_ne_permet_pas_de_changer_de_role(): void
    {
        $user = User::factory()->create(['role' => 'employe']);
        Sanctum::actingAs($user);

        $this->putJson('/api/profil', [
            'nom' => $user->nom,
            'prenom' => $user->prenom,
            'email' => $user->email,
            'role' => 'admin',
        ])->assertOk();

        $this->assertSame('employe', $user->fresh()->role);
    }

    public function test_l_email_reste_unique(): void
    {
        $autre = User::factory()->create();
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->putJson('/api/profil', [
            'nom' => $user->nom,
            'prenom' => $user->prenom,
            'email' => $autre->email,
        ])->assertStatus(422)->assertJsonValidationErrors('email');
    }

    public function test_le_mot_de_passe_change_avec_l_ancien(): void
    {
        $user = User::factory()->create(['password' => Hash::make('ancien-mdp')]);
        $jeton = $user->createToken('mobile')->plainTextToken;

        $this->withToken($jeton)->putJson('/api/profil/mot-de-passe', [
            'mot_de_passe_actuel' => 'ancien-mdp',
            'mot_de_passe' => 'nouveau-mdp-2026',
            'mot_de_passe_confirmation' => 'nouveau-mdp-2026',
        ])->assertOk();

        $this->assertTrue(Hash::check('nouveau-mdp-2026', $user->fresh()->password));
    }

    public function test_un_mauvais_mot_de_passe_actuel_est_refuse(): void
    {
        $user = User::factory()->create(['password' => Hash::make('ancien-mdp')]);
        $jeton = $user->createToken('mobile')->plainTextToken;

        $this->withToken($jeton)->putJson('/api/profil/mot-de-passe', [
            'mot_de_passe_actuel' => 'au-hasard',
            'mot_de_passe' => 'nouveau-mdp-2026',
            'mot_de_passe_confirmation' => 'nouveau-mdp-2026',
        ])->assertStatus(422)->assertJsonValidationErrors('mot_de_passe_actuel');

        $this->assertTrue(Hash::check('ancien-mdp', $user->fresh()->password));
    }

    public function test_le_changement_ferme_les_autres_sessions(): void
    {
        $user = User::factory()->create(['password' => Hash::make('ancien-mdp')]);
        $courant = $user->createToken('mobile')->plainTextToken;
        $user->createToken('web');

        $this->assertCount(2, $user->tokens()->get());

        $this->withToken($courant)->putJson('/api/profil/mot-de-passe', [
            'mot_de_passe_actuel' => 'ancien-mdp',
            'mot_de_passe' => 'nouveau-mdp-2026',
            'mot_de_passe_confirmation' => 'nouveau-mdp-2026',
        ])->assertOk();

        // Seule la session qui a demandé le changement survit.
        $restants = $user->tokens()->pluck('name');
        $this->assertSame(['mobile'], $restants->all());
    }

    public function test_les_sessions_se_listent_et_se_revoquent(): void
    {
        $user = User::factory()->create();
        $courant = $user->createToken('mobile')->plainTextToken;
        $autre = $user->createToken('tablette');

        $this->withToken($courant)->getJson('/api/profil/sessions')
            ->assertOk()
            ->assertJsonCount(2);

        $this->withToken($courant)->deleteJson("/api/profil/sessions/{$autre->accessToken->id}")
            ->assertNoContent();

        $this->assertSame(['mobile'], $user->tokens()->pluck('name')->all());
    }

    public function test_la_session_courante_ne_se_revoque_pas_par_cette_route(): void
    {
        $user = User::factory()->create();
        $jeton = $user->createToken('mobile');

        $this->withToken($jeton->plainTextToken)
            ->deleteJson("/api/profil/sessions/{$jeton->accessToken->id}")
            ->assertStatus(422);
    }
}
