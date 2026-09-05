const API_BASE = import.meta.env.VITE_API_BASE ?? 'http://127.0.0.1:8000/api';

const TOKEN_KEY = 'onele_token';

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token) {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

class ApiError extends Error {
  constructor(message, status, errors) {
    super(message);
    this.status = status;
    this.errors = errors;
  }
}

async function request(path, { method = 'GET', body, auth = true } = {}) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (auth) {
    const token = getToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  if (res.status === 204) return null;

  const data = await res.json().catch(() => null);

  if (!res.ok) {
    if (res.status === 401) clearToken();
    const message = data?.message ?? "Une erreur est survenue.";
    throw new ApiError(message, res.status, data?.errors);
  }

  return data;
}

export const api = {
  login: (email, password) => request('/login', { method: 'POST', body: { email, password }, auth: false }),
  logout: () => request('/logout', { method: 'POST' }),
  me: () => request('/me'),

  dashboard: () => request('/dashboard'),

  demandes: (params = {}) => {
    const qs = new URLSearchParams(params).toString();
    return request(`/demandes${qs ? `?${qs}` : ''}`);
  },
  demande: (id) => request(`/demandes/${id}`),
  updateDemandeStatut: (id, payload) => request(`/demandes/${id}/statut`, { method: 'PATCH', body: payload }),

  materiels: () => request('/materiels'),
  createMateriel: (payload) => request('/materiels', { method: 'POST', body: payload }),
  updateMateriel: (id, payload) => request(`/materiels/${id}`, { method: 'PUT', body: payload }),
  deleteMateriel: (id) => request(`/materiels/${id}`, { method: 'DELETE' }),

  utilisateurs: () => request('/utilisateurs'),
  createUtilisateur: (payload) => request('/utilisateurs', { method: 'POST', body: payload }),
  updateUtilisateur: (id, payload) => request(`/utilisateurs/${id}`, { method: 'PUT', body: payload }),
  deactivateUtilisateur: (id) => request(`/utilisateurs/${id}`, { method: 'DELETE' }),

  historiques: () => request('/historiques'),

  /** Signe l'accès à un canal privé Reverb, avec le jeton Sanctum déjà en place. */
  autoriserCanal: (socketId, canal) =>
    request('/broadcasting/auth', {
      method: 'POST',
      body: { socket_id: socketId, channel_name: canal },
    }),
};

export { ApiError };
