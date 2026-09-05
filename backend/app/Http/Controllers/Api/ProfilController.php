<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateMotDePasseRequest;
use App\Http\Requests\UpdateProfilRequest;
use App\Http\Resources\UserResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

/**
 * Le compte vu par son titulaire : sa fiche et son mot de passe.
 * L'administration passe, elle, par UserController.
 */
class ProfilController extends Controller
{
    public function update(UpdateProfilRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->update($request->validated());

        return response()->json(new UserResource($user->fresh()));
    }

    public function motDePasse(UpdateMotDePasseRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->update(['password' => Hash::make($request->validated('mot_de_passe'))]);

        // Les autres sessions tombent : un mot de passe changé parce qu'on le
        // croit connu d'un tiers doit fermer la porte que ce tiers tient déjà.
        $courant = $request->user()->currentAccessToken();
        $user->tokens()->where('id', '!=', $courant->id)->delete();

        return response()->json([
            'message' => 'Mot de passe mis à jour.',
            'sessions_fermees' => true,
        ]);
    }

    /**
     * Les sessions ouvertes — un jeton par appareil connecté.
     */
    public function sessions(Request $request): JsonResponse
    {
        $courant = $request->user()->currentAccessToken();

        return response()->json(
            $request->user()->tokens()
                ->orderByDesc('last_used_at')
                ->get()
                ->map(fn ($jeton) => [
                    'id' => $jeton->id,
                    'nom' => $jeton->name,
                    'derniere_utilisation' => $jeton->last_used_at,
                    'creee_le' => $jeton->created_at,
                    'actuelle' => $jeton->id === $courant->id,
                ])
        );
    }

    /**
     * Ferme une session à distance — un appareil perdu se révoque d'ici.
     */
    public function revoquerSession(Request $request, int $jeton): JsonResponse
    {
        if ($jeton === $request->user()->currentAccessToken()->id) {
            return response()->json(
                ['message' => 'Utilisez la déconnexion pour fermer la session courante.'],
                422,
            );
        }

        $request->user()->tokens()->where('id', $jeton)->delete();

        return response()->json(null, 204);
    }
}
