<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\HistoriqueResource;
use App\Models\Historique;
use Illuminate\Http\JsonResponse;

class HistoriqueController extends Controller
{
    public function index(): JsonResponse
    {
        $historiques = Historique::with(['acteur', 'demande'])
            ->latest('date_action')
            ->limit(200)
            ->get();

        return response()->json(HistoriqueResource::collection($historiques));
    }
}
