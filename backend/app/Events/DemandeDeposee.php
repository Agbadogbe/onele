<?php

namespace App\Events;

use App\Http\Resources\DemandeResource;
use App\Models\Demande;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Un employé vient de déposer une demande : l'administration en est prévenue
 * dans la seconde, sans attendre un rafraîchissement de page.
 */
class DemandeDeposee implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public function __construct(public Demande $demande) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        return [new PrivateChannel('administration')];
    }

    public function broadcastAs(): string
    {
        return 'demande.deposee';
    }

    /**
     * Même forme que la réponse REST : les clients réutilisent leur parseur.
     *
     * @return array{demande: array<string, mixed>}
     */
    public function broadcastWith(): array
    {
        return ['demande' => (new DemandeResource($this->demande))->resolve()];
    }
}
