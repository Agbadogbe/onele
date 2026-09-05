import { IconInboxEmpty } from './Icons';

export default function EmptyState({ titre, texte, icon, action }) {
  return (
    <div className="empty">
      <div className="ico">{icon ?? <IconInboxEmpty size={22} />}</div>
      <strong>{titre}</strong>
      {texte && <p>{texte}</p>}
      {action && <div style={{ marginTop: 14 }}>{action}</div>}
    </div>
  );
}
