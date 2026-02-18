import type { PlayingCard } from './card'
import type { DiscardOption } from './game-analysis'

export interface PuzzleResponse {
  id: string
  hand: PlayingCard[]
  isDealer: boolean
  puzzleDate: string
  alreadySolved: boolean
}

export interface PuzzleSolveResponse {
  isOptimal: boolean
  evDifference: number
  yourOption: DiscardOption
  optimalOption: DiscardOption
  allOptions: DiscardOption[]
}
