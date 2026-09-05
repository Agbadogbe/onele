<?php

use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

/**
 * Canal personnel : chacun ne reçoit que ce qui le concerne
 * (ses notifications, le verdict porté sur ses demandes).
 */
Broadcast::channel('utilisateur.{id}', function (User $user, int $id): bool {
    return $user->id === $id;
});

/**
 * Canal partagé par l'administration : toute demande déposée ou traitée y passe,
 * pour que les écrans RH ouverts en parallèle restent alignés.
 */
Broadcast::channel('administration', function (User $user): bool {
    return $user->isAdmin();
});
