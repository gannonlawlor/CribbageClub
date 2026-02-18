import type { PlayingCard } from './card'
import type { GameHistoryEvent } from './game-history-event'
import type { Player } from './player'

export enum GameStage {
  DEALING = 'DEALING',
  DISCARDING_TO_CRIB = 'DISCARDING_TO_CRIB',
  CUTTING = 'CUTTING',
  PEGGING = 'PEGGING',
  COUNTING = 'COUNTING',
  GAME_OVER = 'GAME_OVER',
}

export const GAME_STAGE_DISPLAY: Record<GameStage, string> = {
  [GameStage.DEALING]: 'Dealing',
  [GameStage.DISCARDING_TO_CRIB]: 'Discard to Crib',
  [GameStage.CUTTING]: 'Cut the Deck',
  [GameStage.PEGGING]: 'Pegging',
  [GameStage.COUNTING]: 'Counting',
  [GameStage.GAME_OVER]: 'Game Over',
}

export interface GameState {
  gameId: string
  players: Player[]
  crib: PlayingCard[]
  cutCard: PlayingCard | null
  currentPlayerId: string | null
  stage: GameStage
  playedCards: PlayingCard[]
  peggingCount: number
  lastPlayWasGo: boolean
  handsForCounting: Record<string, PlayingCard[]>
  history: GameHistoryEvent[]
  dealerIndex: number
  remainingDeck: PlayingCard[]
}
