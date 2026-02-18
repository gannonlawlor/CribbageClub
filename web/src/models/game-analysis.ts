import type { PlayingCard } from './card'

export interface DiscardOption {
  keep: PlayingCard[]
  discard: PlayingCard[]
  expectedHandValue: number
  expectedCribValue: number
  expectedCombinedValue: number
}

export interface PlayerRoundAnalysis {
  playerId: string
  isDealer: boolean
  dealtHand: PlayingCard[]
  keptHand: PlayingCard[]
  discarded: PlayingCard[]
  actualHandScore: number
  actualCribScore?: number
  optimalDiscard: DiscardOption
  playerDiscard: DiscardOption
  evDifference: number
}

export interface RoundAnalysis {
  roundNumber: number
  cutCard?: PlayingCard
  dealerPlayerId: string
  playerAnalyses: PlayerRoundAnalysis[]
}

export interface GameAnalysis {
  gameId: string
  rounds: RoundAnalysis[]
}
