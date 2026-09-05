<?php

namespace App\Http\Controllers\Api;

use App\Events\DemandeDeposee;
use App\Events\DemandeTraitee;
use App\Events\NotificationRecue;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreDemandeRequest;
use App\Http\Requests\UpdateDemandeStatutRequest;
use App\Http\Resources\DemandeResource;
use App\Models\Demande;
use App\Models\DemandeConge;
use App\Models\DemandeMateriel;
use App\Models\DemandePermission;
use App\Models\Historique;
use App\Models\Materiel;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

class DemandeController extends Controller
{
    private const array RELATIONS = ['utilisateur', 'validateur', 'conge', 'permission', 'materiel.materiel'];

    /**
     * Display a listing of the resource.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = Demande::query()->with(self::RELATIONS)->latest();

        if (! $user->isAdmin()) {
            $query->where('utilisateur_id', $user->id);
        }

        if ($request->filled('statut')) {
            $query->where('statut', $request->string('statut'));
        }

        if ($request->filled('type')) {
            $query->where('type', $request->string('type'));
        }

        return response()->json(DemandeResource::collection($query->limit(200)->get()));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreDemandeRequest $request): JsonResponse
    {
        $data = $request->validated();
        $user = $request->user();

        [$demande, $notifications] = DB::transaction(function () use ($data, $user) {
            $demande = Demande::create([
                'type' => $data['type'],
                'date_debut' => $data['date_debut'],
                'date_fin' => $data['date_fin'],
                'statut' => 'en_attente',
                'utilisateur_id' => $user->id,
            ]);

            match ($data['type']) {
                'conge' => DemandeConge::create([
                    'demande_id' => $demande->id,
                    'type_conge' => $data['type_conge'],
                    'nombre_jours' => $data['nombre_jours'],
                    'piece_jointe' => $data['piece_jointe'] ?? null,
                ]),
                'permission' => DemandePermission::create([
                    'demande_id' => $demande->id,
                    'heure_debut' => $data['heure_debut'],
                    'heure_fin' => $data['heure_fin'],
                    'motif' => $data['motif'],
                ]),
                'materiel' => DemandeMateriel::create([
                    'demande_id' => $demande->id,
                    'materiel_id' => $data['materiel_id'],
                    'quantite' => $data['quantite'],
                    'motif' => $data['motif'] ?? null,
                ]),
            };

            Historique::create([
                'demande_id' => $demande->id,
                'acteur_id' => $user->id,
                'action' => 'creation',
            ]);

            $libelle = match ($data['type']) {
                'conge' => 'congé',
                'permission' => 'permission',
                'materiel' => 'matériel',
            };

            $notifications = User::query()->where('role', '!=', 'employe')->get()->map(
                fn (User $admin) => Notification::create([
                    'utilisateur_id' => $admin->id,
                    'demande_id' => $demande->id,
                    'message' => "Nouvelle demande de {$libelle} de {$user->prenom} {$user->nom}",
                ])
            );

            return [$demande, $notifications];
        });

        $demande->load(self::RELATIONS);

        // Diffusé une fois la transaction validée : un client ne peut pas ainsi
        // recevoir l'annonce d'une demande que la base n'a pas encore écrite.
        DemandeDeposee::dispatch($demande);
        $notifications->each(fn (Notification $notification) => NotificationRecue::dispatch($notification));

        return response()->json(new DemandeResource($demande), Response::HTTP_CREATED);
    }

    /**
     * Display the specified resource.
     */
    public function show(Request $request, Demande $demande): JsonResponse
    {
        $this->authorizeAccess($request, $demande);

        return response()->json(new DemandeResource($demande->load([...self::RELATIONS, 'historiques.acteur'])));
    }

    /**
     * Update the status of the specified resource (validate/refuse).
     */
    public function updateStatut(UpdateDemandeStatutRequest $request, Demande $demande): JsonResponse
    {
        if ($demande->statut !== 'en_attente') {
            throw new HttpException(409, 'Cette demande a déjà été traitée.');
        }

        $data = $request->validated();
        $validateur = $request->user();

        $notification = DB::transaction(function () use ($demande, $data, $validateur) {
            $demande->update([
                'statut' => $data['statut'],
                'commentaire' => $data['commentaire'] ?? null,
                'validateur_id' => $validateur->id,
            ]);

            if ($demande->type === 'materiel' && $data['statut'] === 'validee') {
                Materiel::whereKey($demande->materiel->materiel_id)
                    ->decrement('quantite_disponible', $demande->materiel->quantite);
            }

            Historique::create([
                'demande_id' => $demande->id,
                'acteur_id' => $validateur->id,
                'action' => $data['statut'],
                'commentaire' => $data['commentaire'] ?? null,
            ]);

            return Notification::create([
                'utilisateur_id' => $demande->utilisateur_id,
                'demande_id' => $demande->id,
                'message' => $demande->messageDeVerdict($data['statut']),
            ]);
        });

        $demande = $demande->fresh(self::RELATIONS);

        // Le verdict part vers le mobile de l'employé et vers les autres écrans RH.
        DemandeTraitee::dispatch($demande);
        NotificationRecue::dispatch($notification);

        return response()->json(new DemandeResource($demande));
    }

    /**
     * Remove the specified resource from storage (cancel while pending).
     */
    public function destroy(Request $request, Demande $demande): JsonResponse
    {
        $this->authorizeAccess($request, $demande);

        if ($demande->statut !== 'en_attente' && ! $request->user()->isAdmin()) {
            throw new HttpException(409, 'Seule une demande en attente peut être annulée.');
        }

        $demande->delete();

        return response()->json(null, Response::HTTP_NO_CONTENT);
    }

    private function authorizeAccess(Request $request, Demande $demande): void
    {
        $user = $request->user();

        if (! $user->isAdmin() && $demande->utilisateur_id !== $user->id) {
            throw new HttpException(403, 'Accès non autorisé à cette demande.');
        }
    }
}
