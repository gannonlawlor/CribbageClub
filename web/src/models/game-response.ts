import type { GameState } from './game-state'

export interface GameResponse {
  gameState: GameState
  turnStartedAt?: string
  turnTimeLimitMs: number
  myTimeBankMs: number
  opponentTimeBankMs: number
  isTimed: boolean
}

export interface GameStateUpdateMessage {
  gameId: string
  gameState: GameState
  turnStartedAt?: string
  turnTimeLimitMs: number
  player1TimeBankMs: number
  player2TimeBankMs: number
  isTimed: boolean
  timestamp?: number
}

export interface GameErrorMessage {
  gameId: string
  error: string
  timestamp?: number
}
