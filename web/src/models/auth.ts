export interface AuthResponse {
  token: string
  userId: string
  username: string
  displayName?: string
  isGuest: boolean
}

export interface LoginRequest {
  username: string
  password: string
}

export interface RegisterRequest {
  username: string
  password: string
  displayName?: string
}

export interface UpgradeRequest {
  username: string
  password: string
  displayName?: string
}
