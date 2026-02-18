export enum LobbyStatus {
  WAITING = 'WAITING',
  IN_GAME = 'IN_GAME',
  COMPLETED = 'COMPLETED',
}

export interface LobbyPlayer {
  id: string
  name: string
  joinedAt: string
}

export interface Lobby {
  id: string
  name: string
  players: LobbyPlayer[]
  maxPlayers: number
  status: LobbyStatus
  createdAt: string
  gameId?: string
  isPrivate: boolean
  inviteCode?: string
  challengedUserId?: string
}
