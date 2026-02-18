import type { PlayingCard } from './card'
import type { ScoreBreakdown } from './score-breakdown'

export type GameHistoryEvent =
  | RoundStarted
  | CardsDealt
  | DeckCut
  | CardPlayed
  | GoAnnounced
  | PeggingEnded
  | HandCounted
  | CribCounted
  | GameEnded
  | GameForfeited

export interface RoundStarted {
  type: 'RoundStarted'
  timestamp: string
  roundNumber: number
}

export interface CardsDealt {
  type: 'CardsDealt'
  timestamp: string
  dealtHands: Record<string, PlayingCard[]>
}

export interface DeckCut {
  type: 'DeckCut'
  timestamp: string
  cutCard: PlayingCard
  cuttingPlayerId: string
  dealerScoredNobs: boolean
}

export interface CardPlayed {
  type: 'CardPlayed'
  timestamp: string
  playerId: string
  card: PlayingCard
  newCount: number
  pointsScored: number
  scoringReason?: string
}

export interface GoAnnounced {
  type: 'GoAnnounced'
  timestamp: string
  playerId: string
  pointsScored: number
}

export interface PeggingEnded {
  type: 'PeggingEnded'
  timestamp: string
}

export interface HandCounted {
  type: 'HandCounted'
  timestamp: string
  playerId: string
  hand: PlayingCard[]
  totalPoints: number
  scoreBreakdown: ScoreBreakdown
}

export interface CribCounted {
  type: 'CribCounted'
  timestamp: string
  dealerPlayerId: string
  totalPoints: number
  scoreBreakdown: ScoreBreakdown
  cribCards: PlayingCard[]
}

export interface GameEnded {
  type: 'GameEnded'
  timestamp: string
  winnerPlayerId: string
  finalScore: number
}

export interface GameForfeited {
  type: 'GameForfeited'
  timestamp: string
  forfeitingPlayerId: string
  reason: string
}
