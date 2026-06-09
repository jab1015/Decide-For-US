const API_BASE = 'http://localhost:3000/api'

function getToken() {
  return localStorage.getItem('nearvibe_token')
}

async function request(endpoint, options = {}) {
  const token = getToken()
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  }

  const res = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers,
  })

  const data = await res.json().catch(() => null)

  if (!res.ok) {
    const error = new Error(data?.error || data?.message || `Request failed (${res.status})`)
    error.status = res.status
    error.data = data
    throw error
  }

  return data
}

export const api = {
  // Auth
  register: (body) => request('/auth/register', { method: 'POST', body: JSON.stringify(body) }),
  login: (body) => request('/auth/login', { method: 'POST', body: JSON.stringify(body) }),
  verifyAge: (body) => request('/auth/verify-age', { method: 'POST', body: JSON.stringify(body) }),
  parentalConsent: (body) => request('/auth/parental-consent', { method: 'POST', body: JSON.stringify(body) }),
  getMe: () => request('/auth/me'),

  // Suggestions
  getSuggestions: (body) => request('/suggestions', { method: 'POST', body: JSON.stringify(body) }),

  // Usage
  getUsage: () => request('/usage'),

  // Subscriptions
  subscribe: () => request('/subscribe', { method: 'POST' }),

  // Premium: Date Night
  getDateNight: (body) => request('/date-night', { method: 'POST', body: JSON.stringify(body) }),

  // Premium: Trip Itinerary
  getTripItinerary: (body) => request('/trip-itinerary', { method: 'POST', body: JSON.stringify(body) }),
}

export function setToken(token) {
  if (token) {
    localStorage.setItem('nearvibe_token', token)
  } else {
    localStorage.removeItem('nearvibe_token')
  }
}

export function getAuthToken() {
  return getToken()
}

export default api