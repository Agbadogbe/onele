<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['nom', 'categorie', 'description', 'quantite_disponible'])]
class Materiel extends Model
{
    use HasFactory;

    public function demandeMateriels(): HasMany
    {
        return $this->hasMany(DemandeMateriel::class, 'materiel_id');
    }
}
