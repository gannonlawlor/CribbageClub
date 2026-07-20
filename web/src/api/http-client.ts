import { API_BASE_URL } from './config'
import { useAuthStore } from '@/auth/auth-store'

class HttpError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message)
    this.name = 'HttpError'
  }
}

/** Pull the human-readable `message` out of a Spring error body; fall back to raw text. */
function extractErrorMessage(text: string): string | null {
  if (!text) return null
  try {
    const parsed = JSON.parse(text) as { message?: string; error?: string }
    return parsed.message ?? parsed.error ?? text
  } catch {
    return text
  }
}

async function request<T>(
  method: string,
  path: string,
  body?: unknown,
): Promise<T> {
  const token = useAuthStore.getState().token

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  }
  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  const res = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers,
    body: body != null ? JSON.stringify(body) : undefined,
  })

  if (res.status === 401) {
    useAuthStore.getState().logout()
    throw new HttpError(401, 'Unauthorized')
  }

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText)
    throw new HttpError(res.status, extractErrorMessage(text) ?? res.statusText)
  }

  if (res.status === 204) return undefined as T

  return res.json() as Promise<T>
}

export const http = {
  get: <T>(path: string) => request<T>('GET', path),
  post: <T>(path: string, body?: unknown) => request<T>('POST', path, body),
  put: <T>(path: string, body?: unknown) => request<T>('PUT', path, body),
  delete: <T>(path: string) => request<T>('DELETE', path),
}
