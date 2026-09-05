<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DemandeResource;
use App\Models\Demande;
use App\Models\DemandeConge;
use App\Models\Historique;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * Le pendant employé du tableau de bord : ce que l'application mobile affiche
 * en tête d'accueil (solde, rythme, prochaine échéance).
 */
class ActiviteController extends Controller
{
    private const int MOIS_HISTORIQUE = 6;

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $prochaine = Demande::query()
            ->where('utilisateur_id', $user->id)
            ->where('statut', 'validee')
            ->whereDate('date_debut', '>=', Carbon::today())
            ->with(['conge', 'permission', 'materiel.materiel'])
            ->orderBy('date_debut')
            ->first();

        return response()->json([
            'jours_conges_pris' => $this->joursCongesPris($user->id),
            'par_statut' => $this->compter($user->id, 'statut'),
            'par_type' => $this->compter($user->id, 'type'),
            'delai_reponse_moyen_heures' => $this->delaiDeReponse($user->id),
            'activite_mensuelle' => $this->activiteMensuelle($user->id),
            'prochaine_demande' => $prochaine ? new DemandeResource($prochaine) : null,
        ]);
    }

    /** Jours de congé validés sur l'année civile en cours. */
    private function joursCongesPris(int $utilisateurId): int
    {
        return (int) DemandeConge::query()
            ->whereHas('demande', fn ($q) => $q
                ->where('utilisateur_id', $utilisateurId)
                ->where('statut', 'validee')
                ->whereYear('date_debut', Carbon::now()->year))
            ->sum('nombre_jours');
    }

    /**
     * @return array<string, int>
     */
    private function compter(int $utilisateurId, string $colonne): array
    {
        return Demande::query()
            ->where('utilisateur_id', $utilisateurId)
            ->selectRaw("{$colonne}, count(*) as total")
            ->groupBy($colonne)
            ->pluck('total', $colonne)
            ->map(fn ($v) => (int) $v)
            ->all();
    }

    /** Délai moyen, en heures, avant qu'une de ses demandes reçoive une réponse. */
    private function delaiDeReponse(int $utilisateurId): ?float
    {
        $heures = Historique::query()
            ->whereIn('action', ['validee', 'refusee'])
            ->whereHas('demande', fn ($q) => $q->where('utilisateur_id', $utilisateurId))
            ->with('demande:id,created_at')
            ->latest('date_action')
            ->limit(50)
            ->get()
            ->filter(fn (Historique $h) => $h->demande !== null)
            ->map(fn (Historique $h) => $h->demande->created_at->diffInMinutes($h->date_action) / 60)
            ->filter(fn (float $h) => $h >= 0);

        return $heures->isEmpty() ? null : round($heures->avg(), 1);
    }

    /**
     * Nombre de demandes déposées sur chacun des six derniers mois.
     *
     * Regroupé en PHP : les fonctions de date diffèrent entre MySQL et le
     * SQLite des tests, et le volume est négligeable.
     *
     * @return array<int, array{mois: string, total: int}>
     */
    private function activiteMensuelle(int $utilisateurId): array
    {
        $debut = Carbon::now()->startOfMonth()->subMonths(self::MOIS_HISTORIQUE - 1);

        $mois = [];
        for ($i = 0; $i < self::MOIS_HISTORIQUE; $i++) {
            $mois[$debut->copy()->addMonths($i)->format('Y-m')] = 0;
        }

        Demande::query()
            ->where('utilisateur_id', $utilisateurId)
            ->where('created_at', '>=', $debut)
            ->pluck('created_at')
            ->each(function (Carbon $date) use (&$mois): void {
                $cle = $date->format('Y-m');
                if (array_key_exists($cle, $mois)) {
                    $mois[$cle]++;
                }
            });

        return collect($mois)
            ->map(fn (int $total, string $cle) => ['mois' => $cle, 'total' => $total])
            ->values()
            ->all();
    }
}
