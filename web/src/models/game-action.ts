import type { PlayingCard } from './card'

export type GameAction =
  | DiscardToCrib
  | PlayCard
  | CutDeck
  | GoAction
  | CountHand
  | Forfeit

export interface DiscardToCrib {
  type: 'DiscardToCrib'
  playerId: string
  card: PlayingCard
}

export interface PlayCard {
  type: 'PlayCard'
  playerId: string
  card: PlayingCard
}

export interface CutDeck {
  type: 'CutDeck'
  playerId: string
}

export interface GoAction {
  type: 'Go'
  playerId: string
}

export interface CountHand {
  type: 'CountHand'
  playerId: string
}

export interface Forfeit {
  type: 'Forfeit'
  playerId: string
  reason: string
}
