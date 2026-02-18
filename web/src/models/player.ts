import type { PlayingCard } from './card'

export interface Player {
  id: string
  name: string
  hand: PlayingCard[]
  score: number
}
