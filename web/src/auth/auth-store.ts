import { create } from 'zustand'
import type { AuthResponse, LoginRequest, RegisterRequest, UpgradeRequest } from '@/models/auth'
import { http } from '@/api/http-client'

const TOKEN_KEY = 'jwt_token'
const USER_ID_KEY = 'user_id'
const USERNAME_KEY = 'username'
const IS_GUEST_KEY = 'is_guest'

interface AuthState {
  token: string | null
  userId: string | null
  username: string | null
  isGuest: boolean
  isLoading: boolean
  error: string | null

  isLoggedIn: boolean

  loadSavedAuth: () => void
  login: (req: LoginRequest) => Promise<void>
  register: (req: RegisterRequest) => Promise<void>
  loginAsGuest: () => Promise<void>
  upgrade: (req: UpgradeRequest) => Promise<void>
  logout: () => void
}

function persistAuth(res: AuthResponse) {
  localStorage.setItem(TOKEN_KEY, res.token)
  localStorage.setItem(USER_ID_KEY, res.userId)
  localStorage.setItem(USERNAME_KEY, res.username)
  localStorage.setItem(IS_GUEST_KEY, String(res.isGuest))
}

function clearAuth() {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(USER_ID_KEY)
  localStorage.removeItem(USERNAME_KEY)
  localStorage.removeItem(IS_GUEST_KEY)
}

export const useAuthStore = create<AuthState>((set, get) => ({
  token: null,
  userId: null,
  username: null,
  isGuest: false,
  isLoading: false,
  error: null,

  get isLoggedIn() {
    return get().token != null
  },

  loadSavedAuth: () => {
    const token = localStorage.getItem(TOKEN_KEY)
    const userId = localStorage.getItem(USER_ID_KEY)
    const username = localStorage.getItem(USERNAME_KEY)
    const isGuest = localStorage.getItem(IS_GUEST_KEY) === 'true'

    if (token && userId) {
      set({ token, userId, username, isGuest })
    }
  },

  login: async (req) => {
    set({ isLoading: true, error: null })
    try {
      const res = await http.post<AuthResponse>('/api/auth/login', req)
      persistAuth(res)
      set({ token: res.token, userId: res.userId, username: res.username, isGuest: res.isGuest, isLoading: false })
    } catch (e) {
      set({ isLoading: false, error: e instanceof Error ? e.message : 'Login failed' })
      throw e
    }
  },

  register: async (req) => {
    set({ isLoading: true, error: null })
    try {
      const res = await http.post<AuthResponse>('/api/auth/register', req)
      persistAuth(res)
      set({ token: res.token, userId: res.userId, username: res.username, isGuest: false, isLoading: false })
    } catch (e) {
      set({ isLoading: false, error: e instanceof Error ? e.message : 'Registration failed' })
      throw e
    }
  },

  loginAsGuest: async () => {
    set({ isLoading: true, error: null })
    try {
      const res = await http.post<AuthResponse>('/api/auth/guest')
      persistAuth(res)
      set({ token: res.token, userId: res.userId, username: res.username, isGuest: true, isLoading: false })
    } catch (e) {
      set({ isLoading: false, error: e instanceof Error ? e.message : 'Guest login failed' })
      throw e
    }
  },

  upgrade: async (req) => {
    set({ isLoading: true, error: null })
    try {
      const res = await http.post<AuthResponse>('/api/auth/upgrade', req)
      persistAuth(res)
      set({ token: res.token, userId: res.userId, username: res.username, isGuest: false, isLoading: false })
    } catch (e) {
      set({ isLoading: false, error: e instanceof Error ? e.message : 'Upgrade failed' })
      throw e
    }
  },

  logout: () => {
    clearAuth()
    set({ token: null, userId: null, username: null, isGuest: false, error: null })
  },
}))
