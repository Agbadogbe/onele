<?php

namespace App\Events;

use App\Http\Resources\NotificationResource;
use App\Models\Notification;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Une notification vient d'être écrite pour un utilisateur : elle lui est
 * poussée sur son canal personnel, quel que soit l'appareil où il est connecté.
 */
class NotificationRecue implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public function __construct(public Notification $notification) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        return [new PrivateChannel("utilisateur.{$this->notification->utilisateur_id}")];
    }

    public function broadcastAs(): string
    {
        return 'notification.recue';
    }

    /**
     * @return array{notification: array<string, mixed>}
     */
    public function broadcastWith(): array
    {
        return ['notification' => (new NotificationResource($this->notification))->resolve()];
    }
}
