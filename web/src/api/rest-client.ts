import { http } from './http-client'
import type {
  GameState,
  GameResponse,

  GameAction,
  GameAnalysis,
  Lobby,
  FriendInfo,
  FriendRequestInfo,
  UserSearchResult,
  NotificationCount,
  ProfileResponse,
  LeaderboardEntry,
} from '@/models'

// ── Games ─────────────────────────────────────────────────────────────

export function createAIGame(options?: { playerName?: string; difficulty?: string }) {
  return http.post<GameState>('/api/games/ai', options)
}

export function getGameState(gameId: string) {
  return http.get<GameResponse>(`/api/games/${gameId}`)
}

export function applyAction(gameId: string, action: GameAction) {
  return http.post<GameResponse>(`/api/games/${gameId}/actions`, action)
}

export function resignGame(gameId: string) {
  return http.post<GameResponse>(`/api/games/${gameId}/resign`)
}

export function getMyActiveGames() {
  return http.get<GameState[]>('/api/games/me')
}

export function getMyGameHistory() {
  return http.get<GameState[]>('/api/games/me/history')
}

export function deleteGame(gameId: string) {
  return http.delete<void>(`/api/games/${gameId}`)
}


// ── Analysis ──────────────────────────────────────────────────────────

export function getGameAnalysis(gameId: string) {
  return http.get<GameAnalysis>(`/api/games/${gameId}/analysis`)
}

// ── Leaderboard / Stats ──────────────────────────────────────────────

export function getLeaderboard() {
  return http.get<LeaderboardEntry[]>('/api/stats/leaderboard')
}

export function getMyStats() {
  return http.get<{
    playerId: string
    gamesPlayed: number
    gamesWon: number
    gamesLost: number
    winRate: number
    averageScore: number
    highestGameScore: number
    currentWinStreak: number
    longestWinStreak: number
    rating: number
    ratingDeviation: number
  }>('/api/stats/me')
}

// ── Lobbies ───────────────────────────────────────────────────────────

interface JoinByCodeResult {
  lobby: Lobby
  gameState?: GameState
}

export function createLobby(name: string, options?: { creatorName?: string; isPrivate?: boolean }) {
  return http.post<Lobby>('/api/lobbies', { name, ...options })
}

export function getLobby(lobbyId: string) {
  return http.get<Lobby>(`/api/lobbies/${lobbyId}`)
}

export function joinLobby(lobbyId: string) {
  return http.post<JoinByCodeResult>(`/api/lobbies/${lobbyId}/join`)
}

export function leaveLobby(lobbyId: string) {
  return http.post<void>(`/api/lobbies/${lobbyId}/leave`)
}

export function joinByCode(inviteCode: string, playerName?: string) {
  return http.post<JoinByCodeResult>('/api/lobbies/join-by-code', { inviteCode, playerName })
}

export function quickMatch() {
  return http.post<JoinByCodeResult>('/api/lobbies/quick-match')
}

export function listPublicLobbies() {
  return http.get<Lobby[]>('/api/lobbies/public')
}

// ── Friends ───────────────────────────────────────────────────────────

export function searchUsers(query: string) {
  return http.get<UserSearchResult[]>(`/api/friends/search?query=${encodeURIComponent(query)}`)
}

export function sendFriendRequest(username: string) {
  return http.post<FriendRequestInfo>('/api/friends/requests', { username })
}

export function getIncomingFriendRequests() {
  return http.get<FriendRequestInfo[]>('/api/friends/requests/incoming')
}

export function acceptFriendRequest(id: string) {
  return http.post<FriendInfo>(`/api/friends/requests/${id}/accept`)
}

export function declineFriendRequest(id: string) {
  return http.post<void>(`/api/friends/requests/${id}/decline`)
}

export function getFriends() {
  return http.get<FriendInfo[]>('/api/friends')
}

export function removeFriend(id: string) {
  return http.delete<void>(`/api/friends/${id}`)
}

export function getNotificationCount() {
  return http.get<NotificationCount>('/api/friends/notifications/count')
}

// ── Challenges ────────────────────────────────────────────────────────

export function createChallenge(friendUserId: string) {
  return http.post<Lobby>('/api/challenges', { friendUserId })
}

export function getIncomingChallenges() {
  return http.get<Lobby[]>('/api/challenges/incoming')
}

export function acceptChallenge(lobbyId: string) {
  return http.post<JoinByCodeResult>(`/api/challenges/${lobbyId}/accept`)
}

export function declineChallenge(lobbyId: string) {
  return http.post<void>(`/api/challenges/${lobbyId}/decline`)
}

export function cancelChallenge(lobbyId: string) {
  return http.post<void>(`/api/challenges/${lobbyId}/cancel`)
}

// ── Profiles ──────────────────────────────────────────────────────────

export function getProfile(userId: string) {
  return http.get<ProfileResponse>(`/api/profiles/${userId}`)
}

