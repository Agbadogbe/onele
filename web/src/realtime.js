import Echo from 'laravel-echo';
import Pusher from 'pusher-js';
import { api } from './api';

const CLE = import.meta.env.VITE_REVERB_APP_KEY;
const HOTE = import.meta.env.VITE_REVERB_HOST ?? '127.0.0.1';
const PORT = Number(import.meta.env.VITE_REVERB_PORT ?? 8080);
const SECURISE = (import.meta.env.VITE_REVERB_SCHEME ?? 'http') === 'https';

/**
 * Ouvre la connexion temps réel vers Reverb.
 *
 * Renvoie `null` si la clé n'est pas configurée : l'application reste alors
 * pleinement utilisable, simplement sans mise à jour instantanée.
 */
export function creerEcho() {
  if (!CLE) return null;

  return new Echo({
    broadcaster: 'reverb',
    Pusher,
    key: CLE,
    wsHost: HOTE,
    wsPort: PORT,
    wssPort: PORT,
    forceTLS: SECURISE,
    enabledTransports: [SECURISE ? 'wss' : 'ws'],
    // Les canaux privés se signent avec le jeton Sanctum du client REST,
    // pas avec un cookie de session : on réutilise donc notre propre client.
    authorizer: (canal) => ({
      authorize: (socketId, rappel) => {
        api
          .autoriserCanal(socketId, canal.name)
          .then((signature) => rappel(null, signature))
          .catch((erreur) => rappel(erreur, null));
      },
    }),
  });
}
