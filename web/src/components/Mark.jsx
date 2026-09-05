/**
 * Le logotype : un anneau surmonté de son accent — le « Ó » d'Onélé réduit à
 * deux formes. Dessiné plutôt qu'écrit, il est identique au pixel près à celui
 * de l'application mobile, et ne dépend d'aucune fonte.
 */
export default function Mark({ size = 34, className = '' }) {
  return (
    <span
      className={`stamp ${className}`}
      style={{ width: size, height: size, borderRadius: size * 0.3 }}
      aria-hidden="true"
    >
      <svg viewBox="0 0 100 100" width={size * 0.86} height={size * 0.86}>
        <circle cx="50" cy="55" r="21" fill="none" stroke="currentColor" strokeWidth="9.5" />
        <rect
          x="52" y="10" width="22" height="9.5" rx="4.75"
          fill="currentColor"
          transform="rotate(35.5 63 14.75)"
        />
      </svg>
    </span>
  );
}
