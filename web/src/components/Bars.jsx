import { useState } from 'react';

/** Arrondit le plafond de l'axe à une graduation lisible (2, 5, 10, 20…). */
function plafond(valeur) {
  if (valeur <= 4) return 4;
  const pas = valeur <= 10 ? 2 : valeur <= 30 ? 5 : 10;
  return Math.ceil(valeur / pas) * pas;
}

function jourMois(iso) {
  const d = new Date(iso);
  return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}`;
}

const SERIES = [
  { cle: 'deposees', label: 'Déposées', classe: 'dep' },
  { cle: 'traitees', label: 'Traitées', classe: 'tr' },
];

/**
 * Rythme hebdomadaire — colonnes groupées en HTML/CSS.
 *
 * Deux séries comptées dans la même unité, donc un seul axe. Les colonnes sont
 * fines, l'espace entre deux barres est du fond (pas un contour), et seule la
 * semaine la plus chargée porte une étiquette : au-delà, les chiffres se
 * neutralisent les uns les autres.
 */
export default function Bars({ semaines }) {
  const [survol, setSurvol] = useState(null);

  const maxi = Math.max(1, ...semaines.flatMap((s) => [s.deposees, s.traitees]));
  const haut = plafond(maxi);
  const graduations = [haut, haut / 2, 0];
  const sommet = semaines.reduce(
    (best, s, i) => (s.deposees > semaines[best].deposees ? i : best),
    0,
  );

  return (
    <div className="chart">
      <ul className="chart-legend">
        {SERIES.map((s) => (
          <li key={s.cle}>
            <span className={`key ${s.classe}`} />
            {s.label}
          </li>
        ))}
      </ul>

      <div className="chart-body">
        <div className="chart-axis" aria-hidden="true">
          {graduations.map((g) => (
            <span key={g}>{g}</span>
          ))}
        </div>

        <div className="chart-plot">
          {graduations.map((g) => (
            <i className="chart-rule" key={g} style={{ bottom: `${(g / haut) * 100}%` }} aria-hidden="true" />
          ))}

          {semaines.map((s, i) => (
            <div
              className={`wk ${survol === i ? 'on' : ''}`}
              key={s.semaine}
              onMouseEnter={() => setSurvol(i)}
              onMouseLeave={() => setSurvol(null)}
            >
              <div className="cols">
                {SERIES.map((serie) => (
                  <span
                    className={`col ${serie.classe}`}
                    key={serie.cle}
                    data-vide={s[serie.cle] === 0 ? 'oui' : 'non'}
                    style={{
                      height: `${(s[serie.cle] / haut) * 100}%`,
                      animationDelay: `${i * 45}ms`,
                    }}
                  />
                ))}
              </div>

              {/* Une seule étiquette directe : la semaine la plus chargée. */}
              {i === sommet && s.deposees > 0 && (
                <span className="pointe" style={{ bottom: `${(s.deposees / haut) * 100}%` }}>
                  {s.deposees}
                </span>
              )}

              {survol === i && (
                <div className="chart-tip" role="tooltip">
                  <strong>Semaine du {jourMois(s.semaine)}</strong>
                  <span><i className="key dep" />{s.deposees} déposée{s.deposees > 1 ? 's' : ''}</span>
                  <span><i className="key tr" />{s.traitees} traitée{s.traitees > 1 ? 's' : ''}</span>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      <div className="chart-x" aria-hidden="true">
        {semaines.map((s, i) => (
          <span key={s.semaine}>{i % 2 === 0 ? jourMois(s.semaine) : ''}</span>
        ))}
      </div>

      {/* Vue tabulaire : la relève exigée quand une teinte passe sous 3:1. */}
      <table className="sr-only">
        <caption>Demandes déposées et traitées par semaine</caption>
        <thead>
          <tr><th>Semaine</th><th>Déposées</th><th>Traitées</th></tr>
        </thead>
        <tbody>
          {semaines.map((s) => (
            <tr key={s.semaine}>
              <td>{jourMois(s.semaine)}</td>
              <td>{s.deposees}</td>
              <td>{s.traitees}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
