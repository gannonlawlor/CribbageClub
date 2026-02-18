export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? ''
export const WS_URL = `${API_BASE_URL}/ws`

export const CONNECT_TIMEOUT_MS = 10_000
export const RECEIVE_TIMEOUT_MS = 30_000
