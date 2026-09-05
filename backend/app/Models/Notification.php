<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['utilisateur_id', 'demande_id', 'message', 'lue'])]
class Notification extends Model
{
    /**
     * `lue` a un défaut en base, mais une instance fraîchement créée ne le
     * connaît pas : sans ce défaut de modèle, une diffusion partirait avec
     * `lue: null` alors que la ligne enregistrée vaut bien `false`.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'lue' => false,
    ];

    protected function casts(): array
    {
        return [
            'lue' => 'boolean',
        ];
    }

    public function utilisateur(): BelongsTo
    {
        return $this->belongsTo(User::class, 'utilisateur_id');
    }

    public function demande(): BelongsTo
    {
        return $this->belongsTo(Demande::class, 'demande_id');
    }
}
