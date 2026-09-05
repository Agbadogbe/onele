/**
 * Anneau de répartition — SVG pur, aucune librairie de graphiques.
 * Chaque segment est un arc dessiné avec stroke-dasharray sur un cercle.
 */
export default function Ring({ segments, total, taille = 168, epaisseur = 16 }) {
  const rayon = (taille - epaisseur) / 2;
  const circonference = 2 * Math.PI * rayon;
  const ecart = segments.length > 1 ? 3 : 0; // respiration entre deux arcs

  let parcouru = 0;

  return (
    <div className="ring" style={{ width: taille, height: taille }}>
      <svg width={taille} height={taille} aria-hidden="true">
        <circle
          className="track"
          cx={taille / 2}
          cy={taille / 2}
          r={rayon}
          fill="none"
          strokeWidth={epaisseur}
        />
        {segments.map((s, i) => {
          const part = total > 0 ? s.valeur / total : 0;
          const longueur = Math.max(0, part * circonference - ecart);
          const decalage = -parcouru * circonference;
          parcouru += part;

          return (
            <circle
              key={s.cle}
              className="seg"
              cx={taille / 2}
              cy={taille / 2}
              r={rayon}
              fill="none"
              stroke={s.couleur}
              strokeWidth={epaisseur}
              strokeDasharray={`${longueur} ${circonference - longueur}`}
              strokeDashoffset={decalage}
              // L'arc se trace depuis zéro : les longueurs cibles passent par
              // des variables CSS, seules interpolables par l'animation.
              style={{
                '--arc': `${longueur}px`,
                '--reste': `${circonference - longueur}px`,
                '--tour': `${circonference}px`,
                animationDelay: `${i * 140}ms`,
              }}
            >
              <title>{`${s.label} : ${s.valeur} sur ${total}`}</title>
            </circle>
          );
        })}
      </svg>
      <div className="center">
        <span className="n">{total}</span>
        <span className="l">demandes</span>
      </div>
    </div>
  );
}
