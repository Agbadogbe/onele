<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['demande_id', 'type_conge', 'nombre_jours', 'piece_jointe'])]
class DemandeConge extends Model
{
    public $incrementing = false;

    protected $primaryKey = 'demande_id';

    public $timestamps = false;

    public function demande(): BelongsTo
    {
        return $this->belongsTo(Demande::class, 'demande_id');
    }
}
