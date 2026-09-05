import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import { useRealtimeEvent } from '../context/RealtimeContext';
import useCountUp from '../useCountUp';
import Ring from '../components/Ring';
import Bars from '../components/Bars';
import Avatar from '../components/Avatar';
import EmptyState from '../components/EmptyState';
import {
  IconAlert,
  IconBox,
  IconChart,
  IconCheck,
  IconPending,
  IconUsers,
  IconX,
  TypeIcon,
} from '../components/Icons';

const TYPES = [
  { cle: 'conge', label: 'Congés', couleur: 'var(--t-conge)' },
  { cle: 'permission', label: 'Permissions', couleur: 'var(--t-permission)' },
  { cle: 'materiel', label: 'Matériel', couleur: 'var(--t-materiel)' },
];

const ACTION_LABELS = {
  creation: 'a déposé une demande',
  validee: 'a validé une demande',
  refusee: 'a refusé une demande',
};

/** « il y a 3 h », « hier », « 14 août » — plus lisible qu'un horodatage brut. */
function depuis(iso) {
  const date = new Date(iso);
  const minutes = Math.round((Date.now() - date.getTime()) / 60000);
  if (minutes < 1) return "à l'instant";
  if (minutes < 60) return `il y a ${minutes} min`;
  const heures = Math.round(minutes / 60);
  if (heures < 24) return `il y a ${heures} h`;
  if (heures < 48) return 'hier';
  return date.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long' });
}

/** Un délai se lit en minutes sous l'heure, en jours au-delà de deux. */
function delai(heures) {
  if (heures == null) return { valeur: '—', unite: '' };
  if (heures < 1) return { valeur: String(Math.round(heures * 60)), unite: 'min' };
  if (heures < 48) return { valeur: heures.toFixed(1).replace('.', ','), unite: 'h' };
  return { valeur: (heures / 24).toFixed(1).replace('.', ','), unite: 'j' };
}

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [activite, setActivite] = useState([]);

  const charger = useCallback(() => {
    api.dashboard().then(setStats).catch(() => {});
    api.historiques().then((h) => setActivite(h.slice(0, 6))).catch(() => {});
  }, []);

  useEffect(charger, [charger]);

  // Les chiffres sont des agrégats : on les redemande plutôt que de les rejouer
  // côté client — c'est instantané en local, et le compteur se réanime.
  useRealtimeEvent('demande.deposee', charger);
  useRealtimeEvent('demande.traitee', charger);

  const parType = stats?.demandes_par_type ?? {};
  const total = Object.values(parType).reduce((a, b) => a + b, 0);
  const segments = TYPES
    .filter((t) => parType[t.cle] > 0)
    .map((t) => ({ ...t, valeur: parType[t.cle] }));

  const enAttente = useCountUp(stats?.demandes_en_attente ?? 0);
  const alertes = stats?.materiel_alertes ?? [];
  const palmares = stats?.top_demandeurs ?? [];
  const maxPalmares = Math.max(1, ...palmares.map((p) => p.total));
  const attente = delai(stats?.delai_moyen_heures);

  return (
    <div className="page">
      {/* Panneau héros : le chiffre qui appelle une action, et la répartition */}
      <section className="hero aurora">
        <div>
          <span className="eyebrow">À traiter maintenant</span>
          <div className="big">{stats ? enAttente : '—'}</div>
          <p className="lede">
            {stats?.demandes_en_attente === 0
              ? 'Aucune demande en attente. Tout est à jour.'
              : 'demandes attendent votre décision. Les employés sont notifiés dès que vous tranchez.'}
          </p>
          <div className="acts">
            <Link className="btn lg" to="/demandes">
              <IconPending size={16} />
              Traiter les demandes
            </Link>
            <Link className="btn lg light" to="/historique">
              Voir le journal
            </Link>
          </div>
        </div>

        {total > 0 && (
          <div className="ring-wrap">
            <Ring segments={segments} total={total} />
            <ul className="ring-legend">
              {segments.map((s) => (
                <li key={s.cle}>
                  <span className="swatch" style={{ background: s.couleur }} />
                  {s.label}
                  <span className="v">
                    {s.valeur} · {Math.round((s.valeur / total) * 100)} %
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </section>

      <div className="kpi-grid stagger">
        <Kpi
          label="Taux de validation"
          valeur={stats?.taux_validation}
          unite="%"
          pied={`sur ${stats?.demandes_total ?? 0} demandes`}
          jauge={stats?.taux_validation}
        />
        <Kpi
          label="Délai moyen de réponse"
          valeur={stats ? attente.valeur : null}
          unite={attente.unite}
          pied="entre le dépôt et la décision"
        />
        <Kpi
          label="Employés actifs"
          valeur={stats?.employes_actifs}
          pied="comptes pouvant déposer"
        />
        <Kpi
          label="Matériel disponible"
          valeur={stats?.materiel_disponible}
          pied={alertes.length > 0 ? `${alertes.length} référence${alertes.length > 1 ? 's' : ''} à surveiller` : 'unités en stock'}
        />
      </div>

      <section className="card" style={{ marginBottom: 18 }}>
        <div className="card-head">
          <h3>Rythme des demandes</h3>
          <span className="eyebrow">12 dernières semaines</span>
        </div>
        <div className="card-pad">
          {stats ? (
            <Bars semaines={stats.activite_hebdomadaire} />
          ) : (
            <div className="sk" style={{ height: 200 }} />
          )}
        </div>
      </section>

      <div className="split">
        <section className="card">
          <div className="card-head">
            <h3>Activité récente</h3>
            <Link className="eyebrow" to="/historique" style={{ textDecoration: 'none' }}>
              Tout voir
            </Link>
          </div>
          <div className="card-pad">
            {activite.length === 0 ? (
              <EmptyState titre="Rien à afficher" texte="Le journal des actions est encore vide." />
            ) : (
              <ul className="feed">
                {activite.map((h) => (
                  <li key={h.id}>
                    <span className={`dot ${h.action === 'validee' ? 'ok' : h.action === 'refusee' ? 'no' : ''}`}>
                      {h.action === 'validee' ? <IconCheck size={14} />
                        : h.action === 'refusee' ? <IconX size={14} />
                          : <TypeIcon type={h.demande_type} size={14} />}
                    </span>
                    <span className="txt">
                      <strong>
                        {h.acteur ? `${h.acteur.prenom} ${h.acteur.nom}` : 'Système'}{' '}
                        <span className="muted" style={{ fontWeight: 400 }}>
                          {ACTION_LABELS[h.action] ?? h.action}
                        </span>
                      </strong>
                      <span className="when">
                        {depuis(h.date_action)} · #{h.demande_id}
                      </span>
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </section>

        <div style={{ display: 'grid', gap: 18, alignContent: 'start' }}>
          <section className="card">
            <div className="card-head">
              <h3>Stock à surveiller</h3>
              <Link className="eyebrow" to="/materiel" style={{ textDecoration: 'none' }}>
                Inventaire
              </Link>
            </div>
            <div className="card-pad">
              {alertes.length === 0 ? (
                <EmptyState
                  titre="Stock au vert"
                  texte="Aucune référence sous le seuil d’alerte."
                  icon={<IconBox size={22} />}
                />
              ) : (
                <ul className="alerts">
                  {alertes.map((m) => (
                    <li key={m.id}>
                      <span className={`badge ${m.quantite_disponible === 0 ? 'no' : 'pending'}`}>
                        {m.quantite_disponible === 0 ? <IconAlert size={12} /> : null}
                        {m.quantite_disponible === 0 ? 'Rupture' : `${m.quantite_disponible} restant${m.quantite_disponible > 1 ? 's' : ''}`}
                      </span>
                      <span className="a-nom">{m.nom}</span>
                      <span className="a-cat">{m.categorie}</span>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </section>

          <section className="card">
            <div className="card-head">
              <h3>Qui sollicite le plus</h3>
              <span className="eyebrow">{palmares.length} employés</span>
            </div>
            <div className="card-pad">
              {palmares.length === 0 ? (
                <EmptyState titre="Aucune demande" texte="Le palmarès se remplira avec les dépôts." icon={<IconChart size={22} />} />
              ) : (
                <ul className="rank">
                  {palmares.map((p) => (
                    <li key={p.id}>
                      <Avatar prenom={p.prenom} nom={p.nom} size="sm" />
                      <span style={{ minWidth: '7.5em' }}>{p.prenom} {p.nom.charAt(0)}.</span>
                      <span className="r-bar">
                        <i style={{ width: `${(p.total / maxPalmares) * 100}%` }} />
                      </span>
                      <span className="r-n">{p.total}</span>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </section>
        </div>
      </div>
    </div>
  );
}

/** Tuile d'indicateur : libellé, valeur, note de bas, jauge facultative. */
function Kpi({ label, valeur, unite, pied, jauge }) {
  const nombre = typeof valeur === 'number' ? valeur : null;
  const anime = useCountUp(nombre ?? 0);

  return (
    <div className="kpi">
      <span className="k-label">{label}</span>
      <span className="k-val">
        {valeur == null
          ? <span className="sk" style={{ display: 'inline-block', width: 54, height: 26 }} />
          : <>{nombre === null ? valeur : anime}{unite && <small>{unite}</small>}</>}
      </span>
      <span className="k-foot">{pied}</span>
      {jauge != null && (
        <span className="k-meter"><i style={{ width: `${jauge}%` }} /></span>
      )}
    </div>
  );
}
