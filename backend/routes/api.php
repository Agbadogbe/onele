<?php

use App\Http\Controllers\Api\ActiviteController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\DemandeController;
use App\Http\Controllers\Api\HistoriqueController;
use App\Http\Controllers\Api\MaterielController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ProfilController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // Le compte vu par son titulaire.
    Route::put('/profil', [ProfilController::class, 'update']);
    Route::put('/profil/mot-de-passe', [ProfilController::class, 'motDePasse']);
    Route::get('/profil/sessions', [ProfilController::class, 'sessions']);
    Route::delete('/profil/sessions/{jeton}', [ProfilController::class, 'revoquerSession']);

    // Employé (mobile)
    Route::get('/demandes', [DemandeController::class, 'index']);
    Route::post('/demandes', [DemandeController::class, 'store']);
    Route::get('/demandes/{demande}', [DemandeController::class, 'show']);
    Route::delete('/demandes/{demande}', [DemandeController::class, 'destroy']);

    Route::get('/mon-activite', [ActiviteController::class, 'index']);

    Route::get('/materiels', [MaterielController::class, 'index']);

    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/lues', [NotificationController::class, 'markAllAsRead']);
    Route::patch('/notifications/{notification}/lue', [NotificationController::class, 'markAsRead']);

    // Administration / RH (web)
    Route::middleware('admin')->group(function () {
        Route::patch('/demandes/{demande}/statut', [DemandeController::class, 'updateStatut']);

        Route::post('/materiels', [MaterielController::class, 'store']);
        Route::get('/materiels/{materiel}', [MaterielController::class, 'show']);
        Route::put('/materiels/{materiel}', [MaterielController::class, 'update']);
        Route::delete('/materiels/{materiel}', [MaterielController::class, 'destroy']);

        Route::apiResource('utilisateurs', UserController::class)->parameters(['utilisateurs' => 'user']);

        Route::get('/dashboard', [DashboardController::class, 'index']);
        Route::get('/historiques', [HistoriqueController::class, 'index']);
    });
});
