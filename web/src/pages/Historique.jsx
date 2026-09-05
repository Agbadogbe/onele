import { useEffect, useState } from 'react';
import { api } from '../api';
import Avatar from '../components/Avatar';
import EmptyState from '../components/EmptyState';
import { IconCheck, IconHistory, IconX, TypeIcon } from '../components/Icons';

const ACTIONS = {
  creation: { texte: 'a déposé la demande', ton: '' },
  validee: { texte: 'a validé la demande', ton: 'ok' },
  refusee: { texte: 'a refusé la demande', ton: 'no' },
};

const TYPE_LABELS = { conge: 'congé', permission: 'permission', materiel: 'matériel' };

/** Regroupe le journal par jour, du plus récent au plus ancien. */
function grouperParJour(entries) {
  const groupes = new Map();
  for (const entry of entries) {
    const date = new Date(entry.date_action);
    const cle = date.toDateString();
    if (!groupes.has(cle)) groupes.set(cle, { date, items: [] });
    groupes.get(cle).items.push(entry);
  }
  return [...groupes.values()];
}

function libelleJour(date) {
  const aujourdhui = new Date();
  const hier = new Date(aujourdhui);
  hier.setDate(hier.getDate() - 1);

  if (date.toDateString() === aujourdhui.toDateString()) return "Aujourd'hui";
  if (date.toDateString() === hier.toDateString()) return 'Hier';
  return date.toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' });
}

export default function Historique() {
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.historiques().then(setEntries).catch(() => {}).finally(() => setLoading(false));
  }, []);

  const jours = grouperParJour(entries);

  return (
    <div className="page">
      <div className="page-head">
        <div>
          <h1>Historique</h1>
          <p className="page-sub">Journal des actions effectuées sur les demandes.</p>
        </div>
        {!loading && entries.length > 0 && (
          <span className="eyebrow">{entries.length} évènement{entries.length > 1 ? 's' : ''}</span>
        )}
      </div>

      <div className="card card-pad">
        {loading ? (
          <div>
            {Array.from({ length: 5 }, (_, i) => (
              <div className="sk-row" key={i} style={{ border: 'none' }}>
                <div className="sk sk-circle" />
                <div className="sk" style={{ flex: 1 }} />
              </div>
            ))}
          </div>
        ) : entries.length === 0 ? (
          <EmptyState
            titre="Journal vide"
            texte="Chaque création, validation ou refus de demande sera consigné ici."
            icon={<IconHistory size={22} />}
          />
        ) : (
          jours.map(({ date, items }) => (
            <section className="day" key={date.toISOString()}>
              <h3 className="day-head">{libelleJour(date)}</h3>
              <ol className="timeline">
                {items.map((h) => {
                  const action = ACTIONS[h.action] ?? { texte: h.action, ton: '' };
                  return (
                    <li key={h.id}>
                      <span className={`node ${action.ton}`}>
                        {h.action === 'validee' ? <IconCheck size={12} />
                          : h.action === 'refusee' ? <IconX size={12} />
                            : <TypeIcon type={h.demande_type} size={12} />}
                      </span>
                      <div className="tl-body">
                        <div className="tl-line">
                          <Avatar prenom={h.acteur?.prenom} nom={h.acteur?.nom} size="sm" />
                          <span>
                            <strong>{h.acteur ? `${h.acteur.prenom} ${h.acteur.nom}` : 'Système'}</strong>
                            {' '}{action.texte}{' '}
                            <span className="mono" style={{ fontSize: '.82em' }}>#{h.demande_id}</span>
                            {' '}({TYPE_LABELS[h.demande_type] ?? h.demande_type})
                          </span>
                          <time className="tl-time">
                            {new Date(h.date_action).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
                          </time>
                        </div>
                        {h.commentaire && <p className="tl-note">« {h.commentaire} »</p>}
                      </div>
                    </li>
                  );
                })}
              </ol>
            </section>
          ))
        )}
      </div>
    </div>
  );
}
