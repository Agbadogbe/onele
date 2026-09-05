<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\MaterielResource;
use App\Models\Demande;
use App\Models\Historique;
use App\Models\Materiel;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;

class DashboardController extends Controller
{
    /** Sous ce seuil, un stock est signalé comme faible. */
    private const int SEUIL_STOCK_BAS = 3;

    private const int SEMAINES_HISTORIQUE = 12;

    public function index(): JsonResponse
    {
        $traitees = Demande::whereIn('statut', ['validee', 'refusee'])->count();
        $validees = Demande::where('statut', 'validee')->count();

        return response()->json([
            'demandes_en_attente' => Demande::where('statut', 'en_attente')->count(),
            'demandes_total' => Demande::count(),
            'demandes_validees_mois' => Demande::where('statut', 'validee')
                ->whereMonth('updated_at', Carbon::now()->month)
                ->count(),
            'employes_actifs' => User::where('role', 'employe')->where('actif', true)->count(),
            // SUM() revient en chaîne depuis MySQL : on garantit un entier au client.
            'materiel_disponible' => (int) Materiel::sum('quantite_disponible'),
            'demandes_par_type' => Demande::selectRaw('type, count(*) as total')
                ->groupBy('type')
                ->pluck('total', 'type'),

            // Part des demandes tranchées qui ont reçu un avis favorable.
            'taux_validation' => $traitees > 0 ? (int) round($validees / $traitees * 100) : null,
            'delai_moyen_heures' => $this->delaiMoyenDeTraitement(),
            'activite_hebdomadaire' => $this->activiteHebdomadaire(),
            'materiel_alertes' => MaterielResource::collection(
                Materiel::where('quantite_disponible', '<=', self::SEUIL_STOCK_BAS)
                    ->orderBy('quantite_disponible')
                    ->limit(5)
                    ->get()
            ),
            'top_demandeurs' => $this->topDemandeurs(),
        ]);
    }

    /**
     * Heures écoulées, en moyenne, entre le dépôt d'une demande et la décision.
     */
    private function delaiMoyenDeTraitement(): ?float
    {
        $decisions = Historique::query()
            ->whereIn('action', ['validee', 'refusee'])
            ->with('demande:id,created_at')
            ->latest('date_action')
            ->limit(200)
            ->get();

        $heures = $decisions
            ->filter(fn (Historique $h) => $h->demande !== null)
            ->map(fn (Historique $h) => $h->demande->created_at->diffInMinutes($h->date_action) / 60)
            ->filter(fn (float $h) => $h >= 0);

        return $heures->isEmpty() ? null : round($heures->avg(), 1);
    }

    /**
     * Dépôts et décisions des douze dernières semaines.
     *
     * Le regroupement se fait en PHP : les fonctions de semaine diffèrent entre
     * MySQL et le SQLite des tests, et le volume concerné reste minuscule.
     *
     * @return array<int, array{semaine: string, deposees: int, traitees: int}>
     */
    private function activiteHebdomadaire(): array
    {
        $debut = Carbon::now()->startOfWeek()->subWeeks(self::SEMAINES_HISTORIQUE - 1);

        $semaines = [];
        for ($i = 0; $i < self::SEMAINES_HISTORIQUE; $i++) {
            $semaines[] = [
                'semaine' => $debut->copy()->addWeeks($i)->toDateString(),
                'deposees' => 0,
                'traitees' => 0,
            ];
        }

        $ranger = function (Carbon $date, string $cle) use (&$semaines, $debut): void {
            $index = intdiv((int) $debut->diffInDays($date, false), 7);
            if ($index >= 0 && $index < self::SEMAINES_HISTORIQUE) {
                $semaines[$index][$cle]++;
            }
        };

        Demande::where('created_at', '>=', $debut)
            ->pluck('created_at')
            ->each(fn (Carbon $d) => $ranger($d, 'deposees'));

        Historique::whereIn('action', ['validee', 'refusee'])
            ->where('date_action', '>=', $debut)
            ->pluck('date_action')
            ->each(fn (Carbon $d) => $ranger($d, 'traitees'));

        return $semaines;
    }

    /**
     * Les cinq employés qui sollicitent le plus le service.
     *
     * @return array<int, array{id: int, prenom: string, nom: string, total: int}>
     */
    private function topDemandeurs(): array
    {
        return User::query()
            ->withCount('demandes')
            // `having` sur l'alias d'une sous-requête passe sur MySQL mais pas
            // sur SQLite : un EXISTS filtre de la même façon, partout.
            ->whereHas('demandes')
            ->orderByDesc('demandes_count')
            ->limit(5)
            ->get(['id', 'prenom', 'nom'])
            ->map(fn (User $u) => [
                'id' => $u->id,
                'prenom' => $u->prenom,
                'nom' => $u->nom,
                'total' => $u->demandes_count,
            ])
            ->all();
    }
}
