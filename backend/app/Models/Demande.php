<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable(['type', 'date_debut', 'date_fin', 'statut', 'commentaire', 'utilisateur_id', 'validateur_id'])]
class Demande extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'date_debut' => 'date',
            'date_fin' => 'date',
        ];
    }

    public function utilisateur(): BelongsTo
    {
        return $this->belongsTo(User::class, 'utilisateur_id');
    }

    public function validateur(): BelongsTo
    {
        return $this->belongsTo(User::class, 'validateur_id');
    }

    public function conge(): HasOne
    {
        return $this->hasOne(DemandeConge::class, 'demande_id');
    }

    public function permission(): HasOne
    {
        return $this->hasOne(DemandePermission::class, 'demande_id');
    }

    public function materiel(): HasOne
    {
        return $this->hasOne(DemandeMateriel::class, 'demande_id');
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class, 'demande_id');
    }

    public function historiques(): HasMany
    {
        return $this->hasMany(Historique::class, 'demande_id');
    }

    /**
     * Phrase de notification d'un verdict.
     *
     * Une notification est souvent lue hors de tout contexte : elle doit dire
     * de quelle demande elle parle et pour quelle date, sans quoi une pile de
     * « Votre demande a été validée » n'apprend rien à personne.
     */
    public function messageDeVerdict(string $statut): string
    {
        $verdict = $statut === 'validee' ? 'validé' : 'refusé';

        [$objet, $accord] = match ($this->type) {
            'conge' => ['Votre congé', ''],
            'permission' => ['Votre permission', 'e'],
            default => ['Votre demande de matériel', 'e'],
        };

        // La locale est posée ici plutôt que globalement : `APP_LOCALE` pilote
        // aussi les fichiers de traduction, et l'application n'en a pas en fr.
        $debut = $this->date_debut->locale('fr');
        $fin = $this->date_fin->locale('fr');

        $quand = $debut->isSameDay($fin)
            ? 'du '.$debut->translatedFormat('j F')
            : 'du '.$debut->translatedFormat('j F').' au '.$fin->translatedFormat('j F');

        return "{$objet} {$quand} a été {$verdict}{$accord}.";
    }
}
