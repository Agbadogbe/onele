<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HistoriqueResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'demande_id' => $this->demande_id,
            'demande_type' => $this->whenLoaded('demande', fn () => $this->demande->type),
            'acteur' => new UserResource($this->whenLoaded('acteur')),
            'action' => $this->action,
            'commentaire' => $this->commentaire,
            'date_action' => $this->date_action,
        ];
    }
}
