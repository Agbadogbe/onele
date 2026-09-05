import { useEffect, useRef, useState } from 'react';

/**
 * Fait défiler un nombre de 0 jusqu'à sa valeur, une seule fois par valeur.
 * Rend le chiffre-clé du tableau de bord vivant au chargement.
 */
export default function useCountUp(valeur, duree = 900) {
  const [affiche, setAffiche] = useState(0);
  const frame = useRef(null);

  useEffect(() => {
    // L'API peut renvoyer un nombre sous forme de chaîne (agrégats SQL).
    const cible = Number(valeur);
    if (!Number.isFinite(cible)) return undefined;

    // Respecte le réglage système « animations réduites ».
    const reduit = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
    if (reduit || cible === 0) {
      setAffiche(cible);
      return undefined;
    }

    const depart = performance.now();

    function tick(maintenant) {
      const avancement = Math.min(1, (maintenant - depart) / duree);
      const adouci = 1 - (1 - avancement) ** 3; // easeOutCubic
      setAffiche(Math.round(cible * adouci));
      if (avancement < 1) frame.current = requestAnimationFrame(tick);
    }

    frame.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame.current);
  }, [valeur, duree]);

  return affiche;
}
