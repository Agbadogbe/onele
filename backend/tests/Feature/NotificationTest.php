<?php

namespace Tests\Feature;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_tout_marquer_comme_lu_solde_la_pile(): void
    {
        $user = User::factory()->create();
        Notification::create(['utilisateur_id' => $user->id, 'message' => 'A', 'lue' => false]);
        Notification::create(['utilisateur_id' => $user->id, 'message' => 'B', 'lue' => false]);
        Notification::create(['utilisateur_id' => $user->id, 'message' => 'C', 'lue' => true]);

        Sanctum::actingAs($user);

        $this->patchJson('/api/notifications/lues')
            ->assertOk()
            // Seules les deux non lues sont comptées : la troisième l'était déjà.
            ->assertJsonPath('marquees', 2);

        $this->assertSame(0, $user->notifications()->where('lue', false)->count());
    }

    public function test_tout_marquer_comme_lu_ne_touche_pas_les_autres_comptes(): void
    {
        $moi = User::factory()->create();
        $autre = User::factory()->create();
        Notification::create(['utilisateur_id' => $moi->id, 'message' => 'A', 'lue' => false]);
        $sienne = Notification::create(['utilisateur_id' => $autre->id, 'message' => 'B', 'lue' => false]);

        Sanctum::actingAs($moi);
        $this->patchJson('/api/notifications/lues')->assertOk();

        $this->assertFalse($sienne->fresh()->lue);
    }

    public function test_une_notification_d_autrui_ne_se_marque_pas(): void
    {
        $moi = User::factory()->create();
        $autre = User::factory()->create();
        $sienne = Notification::create(['utilisateur_id' => $autre->id, 'message' => 'B', 'lue' => false]);

        Sanctum::actingAs($moi);
        $this->patchJson("/api/notifications/{$sienne->id}/lue")->assertStatus(403);
    }
}
