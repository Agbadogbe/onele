<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\HttpException;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notifications = $request->user()
            ->notifications()
            ->latest()
            ->limit(50)
            ->get();

        return response()->json(NotificationResource::collection($notifications));
    }

    public function markAsRead(Request $request, Notification $notification): JsonResponse
    {
        if ($notification->utilisateur_id !== $request->user()->id) {
            throw new HttpException(403, 'Accès non autorisé à cette notification.');
        }

        $notification->update(['lue' => true]);

        return response()->json(new NotificationResource($notification));
    }

    /**
     * Solde la pile d'un coup. Une seule requête plutôt qu'une par ligne :
     * cinquante notifications non lues ne doivent pas coûter cinquante appels.
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        $touchees = $request->user()
            ->notifications()
            ->where('lue', false)
            ->update(['lue' => true]);

        return response()->json(['marquees' => $touchees]);
    }
}
