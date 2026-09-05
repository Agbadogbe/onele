import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { useAuth } from './AuthContext';
import { creerEcho } from '../realtime';

const RealtimeContext = createContext(null);

/** Évènements diffusés par le serveur, avec le canal qui les porte. */
const ABONNEMENTS = {
  personnel: ['notification.recue', 'demande.traitee'],
  administration: ['demande.deposee', 'demande.traitee'],
};

/**
 * Tient une connexion WebSocket unique pour la session et redistribue les
 * évènements aux pages. Les pages s'abonnent via `useRealtimeEvent`, ce qui
 * évite de rouvrir un canal à chaque rendu.
 */
export function RealtimeProvider({ children }) {
  const { user } = useAuth();
  const [connecte, setConnecte] = useState(false);
  const auditeurs = useRef(new Map());

  const ecouter = useCallback((evenement, rappel) => {
    const groupe = auditeurs.current.get(evenement) ?? new Set();
    groupe.add(rappel);
    auditeurs.current.set(evenement, groupe);
    return () => groupe.delete(rappel);
  }, []);

  useEffect(() => {
    if (!user) {
      setConnecte(false);
      return undefined;
    }

    const echo = creerEcho();
    if (!echo) return undefined;

    // Une même diffusion peut arriver par deux canaux (un RH qui traite sa
    // propre demande) : les pages traitent les évènements de façon idempotente.
    const relayer = (evenement) => (charge) => {
      auditeurs.current.get(evenement)?.forEach((rappel) => rappel(charge));
    };

    const noms = [`utilisateur.${user.id}`];
    if (user.role !== 'employe') noms.push('administration');

    noms.forEach((nom) => {
      const canal = echo.private(nom);
      const evenements = nom === 'administration' ? ABONNEMENTS.administration : ABONNEMENTS.personnel;
      evenements.forEach((evenement) => canal.listen(`.${evenement}`, relayer(evenement)));
    });

    const connexion = echo.connector.pusher.connection;
    const suivreEtat = () => setConnecte(connexion.state === 'connected');
    connexion.bind('state_change', suivreEtat);
    suivreEtat();

    return () => {
      connexion.unbind('state_change', suivreEtat);
      noms.forEach((nom) => echo.leave(`private-${nom}`));
      echo.disconnect();
      setConnecte(false);
    };
  }, [user]);

  return (
    <RealtimeContext.Provider value={{ connecte, ecouter }}>
      {children}
    </RealtimeContext.Provider>
  );
}

export function useRealtime() {
  return useContext(RealtimeContext) ?? { connecte: false, ecouter: () => () => {} };
}

/**
 * Réagit à un évènement temps réel. Le gestionnaire est lu par référence :
 * il peut fermer sur l'état courant sans provoquer de réabonnement.
 */
export function useRealtimeEvent(evenement, gestionnaire) {
  const { ecouter } = useRealtime();
  const reference = useRef(gestionnaire);

  // Réassigné après chaque rendu : l'abonnement reste stable tout en appelant
  // toujours la dernière version du gestionnaire.
  useEffect(() => {
    reference.current = gestionnaire;
  });

  useEffect(
    () => ecouter(evenement, (charge) => reference.current(charge)),
    [evenement, ecouter],
  );
}
