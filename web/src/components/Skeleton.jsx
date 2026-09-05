/**
 * Lignes fantômes affichées pendant le chargement d'un tableau : la page garde
 * sa structure au lieu de sauter quand les données arrivent.
 */
export default function TableSkeleton({ rows = 5, avatar = true }) {
  return (
    <div>
      {Array.from({ length: rows }, (_, i) => (
        <div className="sk-row" key={i}>
          {avatar && <div className="sk sk-circle" />}
          <div className="sk" style={{ width: '22%' }} />
          <div className="sk" style={{ width: '15%' }} />
          <div className="sk" style={{ flex: 1 }} />
          <div className="sk" style={{ width: 76, height: 20, borderRadius: 999 }} />
        </div>
      ))}
    </div>
  );
}
