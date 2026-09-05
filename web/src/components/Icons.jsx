/**
 * Jeu d'icônes maison — SVG inline, trait de 1.7px, grille 24.
 * Aucune dépendance : le poids reste nul et le trait reste cohérent partout.
 */

function Svg({ size = 18, children, ...rest }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      {...rest}
    >
      {children}
    </svg>
  );
}

export const IconDashboard = (p) => (
  <Svg {...p}><rect x="3" y="3" width="7.5" height="8.5" rx="1.5" /><rect x="13.5" y="3" width="7.5" height="5" rx="1.5" /><rect x="13.5" y="11" width="7.5" height="10" rx="1.5" /><rect x="3" y="14.5" width="7.5" height="6.5" rx="1.5" /></Svg>
);

export const IconInbox = (p) => (
  <Svg {...p}><path d="M3 13h4l1.5 2.5h7L17 13h4" /><path d="M4.6 5.4 3 13v5a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-5l-1.6-7.6A2 2 0 0 0 17.4 4H6.6a2 2 0 0 0-2 1.4Z" /></Svg>
);

export const IconUsers = (p) => (
  <Svg {...p}><path d="M15.5 20.5v-1.8a3.6 3.6 0 0 0-3.6-3.6H6.1a3.6 3.6 0 0 0-3.6 3.6v1.8" /><circle cx="9" cy="7.5" r="3.4" /><path d="M21.5 20.5v-1.8a3.6 3.6 0 0 0-2.7-3.5" /><path d="M16 4.3a3.6 3.6 0 0 1 0 6.9" /></Svg>
);

export const IconBox = (p) => (
  <Svg {...p}><path d="M20.5 7.8 12 3 3.5 7.8v8.4L12 21l8.5-4.8V7.8Z" /><path d="M3.7 7.7 12 12.4l8.3-4.7" /><path d="M12 12.4V21" /></Svg>
);

export const IconHistory = (p) => (
  <Svg {...p}><path d="M3.5 12a8.5 8.5 0 1 0 2.6-6.1" /><path d="M3.5 4.5V9h4.5" /><path d="M12 7.8V12l2.8 1.7" /></Svg>
);

export const IconLogout = (p) => (
  <Svg {...p}><path d="M9.5 20.5H5.8A1.8 1.8 0 0 1 4 18.7V5.3a1.8 1.8 0 0 1 1.8-1.8h3.7" /><path d="M15.5 16.5 20 12l-4.5-4.5" /><path d="M20 12H9.5" /></Svg>
);

export const IconPlus = (p) => (<Svg {...p}><path d="M12 5v14" /><path d="M5 12h14" /></Svg>);
export const IconCheck = (p) => (<Svg {...p}><path d="M4.5 12.5 9.5 17.5 19.5 6.5" /></Svg>);
export const IconX = (p) => (<Svg {...p}><path d="M6 6l12 12" /><path d="M18 6 6 18" /></Svg>);

export const IconAlert = (p) => (
  <Svg {...p}><circle cx="12" cy="12" r="9" /><path d="M12 7.5v5.2" /><path d="M12 16.4h.01" /></Svg>
);

export const IconClock = (p) => (
  <Svg {...p}><circle cx="12" cy="12" r="8.7" /><path d="M12 6.9V12l3.2 1.9" /></Svg>
);

export const IconCalendar = (p) => (
  <Svg {...p}><rect x="3.3" y="5" width="17.4" height="16" rx="2.2" /><path d="M3.3 10h17.4" /><path d="M8.2 3v4" /><path d="M15.8 3v4" /></Svg>
);

export const IconSun = (p) => (
  <Svg {...p}><circle cx="12" cy="12" r="4" /><path d="M12 2.5v2.2" /><path d="M12 19.3v2.2" /><path d="m5.3 5.3 1.6 1.6" /><path d="m17.1 17.1 1.6 1.6" /><path d="M2.5 12h2.2" /><path d="M19.3 12h2.2" /><path d="m5.3 18.7 1.6-1.6" /><path d="m17.1 6.9 1.6-1.6" /></Svg>
);

export const IconPending = (p) => (
  <Svg {...p}><circle cx="12" cy="12" r="8.7" /><path d="M12 8v4.5l3 1.8" /></Svg>
);

export const IconChart = (p) => (
  <Svg {...p}><path d="M4 20V4" /><path d="M4 20h16" /><rect x="7.5" y="12" width="3.4" height="5" rx="1" /><rect x="13.8" y="7.5" width="3.4" height="9.5" rx="1" /></Svg>
);

export const IconBell = (p) => (
  <Svg {...p}><path d="M18 8.6a6 6 0 1 0-12 0c0 6-2.2 7.4-2.2 7.4h16.4S18 14.6 18 8.6Z" /><path d="M13.7 19.5a2 2 0 0 1-3.4 0" /></Svg>
);

export const IconShield = (p) => (
  <Svg {...p}><path d="M12 21.5s7.5-3.6 7.5-9.3V5.8L12 2.9 4.5 5.8v6.4c0 5.7 7.5 9.3 7.5 9.3Z" /><path d="m9 12 2.2 2.2L15.3 10" /></Svg>
);

export const IconInboxEmpty = (p) => (
  <Svg {...p}><path d="M3.5 13h4l1.4 2.4h6.2l1.4-2.4h4" /><rect x="3.5" y="4.5" width="17" height="15" rx="2.4" /></Svg>
);

/** Icône correspondant au type de demande. */
export function TypeIcon({ type, size = 14 }) {
  if (type === 'conge') return <IconSun size={size} />;
  if (type === 'permission') return <IconClock size={size} />;
  if (type === 'materiel') return <IconBox size={size} />;
  return <IconInbox size={size} />;
}
