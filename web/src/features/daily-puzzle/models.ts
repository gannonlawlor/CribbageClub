import type { PlayingCard } from '@/models'

export interface DailyPuzzle {
  date: Date
  index: number
  hand: PlayingCard[]
  isDealer: boolean
  results?: KeepOption[]
}

export interface DailyPuzzleSet {
  date: Date
  puzzles: DailyPuzzle[]
}

export interface KeepOption {
  keep: PlayingCard[]
  discard: PlayingCard[]
  averageHandScore: number
  averageCribScore: number
  netScore: number
  rank: number
}

export function keepOptionToJson(o: KeepOption): Record<string, unknown> {
  return {
    keep: o.keep,
    discard: o.discard,
    averageHandScore: o.averageHandScore,
    averageCribScore: o.averageCribScore,
    netScore: o.netScore,
    rank: o.rank,
  }
}

export function keepOptionFromJson(json: Record<string, unknown>): KeepOption {
  return {
    keep: json.keep as PlayingCard[],
    discard: json.discard as PlayingCard[],
    averageHandScore: json.averageHandScore as number,
    averageCribScore: json.averageCribScore as number,
    netScore: json.netScore as number,
    rank: json.rank as number,
  }
}
