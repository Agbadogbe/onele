<?php

namespace App\Events;

use App\Http\Resources\DemandeResource;
use App\Models\Demande;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Une demande vient d'être validée ou refusée. Le verdict part vers le mobile
 * de l'employé concerné et vers les écrans d'administration ouverts.
 */
class DemandeTraitee implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public function __construct(public Demande $demande) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("utilisateur.{$this->demande->utilisateur_id}"),
            new PrivateChannel('administration'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'demande.traitee';
    }

    /**
     * @return array{demande: array<string, mixed>}
     */
    public function broadcastWith(): array
    {
        return ['demande' => (new DemandeResource($this->demande))->resolve()];
    }
}
