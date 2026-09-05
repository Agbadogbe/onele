<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DemandeResource extends JsonResource
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
            'type' => $this->type,
            'date_debut' => $this->date_debut?->toDateString(),
            'date_fin' => $this->date_fin?->toDateString(),
            'statut' => $this->statut,
            'commentaire' => $this->commentaire,
            'utilisateur' => new UserResource($this->whenLoaded('utilisateur')),
            'validateur' => new UserResource($this->whenLoaded('validateur')),
            'detail' => match ($this->type) {
                'conge' => $this->whenLoaded('conge', fn () => [
                    'type_conge' => $this->conge->type_conge,
                    'nombre_jours' => $this->conge->nombre_jours,
                    'piece_jointe' => $this->conge->piece_jointe,
                ]),
                'permission' => $this->whenLoaded('permission', fn () => [
                    'heure_debut' => $this->permission->heure_debut,
                    'heure_fin' => $this->permission->heure_fin,
                    'motif' => $this->permission->motif,
                ]),
                'materiel' => $this->whenLoaded('materiel', fn () => [
                    'materiel' => new MaterielResource($this->materiel->materiel),
                    'quantite' => $this->materiel->quantite,
                    'motif' => $this->materiel->motif,
                ]),
                default => null,
            },
            'created_at' => $this->created_at,
            'historiques' => HistoriqueResource::collection($this->whenLoaded('historiques')),
        ];
    }
}
