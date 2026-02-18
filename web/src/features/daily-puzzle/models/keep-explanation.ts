import type { PlayingCard } from '@/models'

export interface HandPatterns {
  fifteens: number
  pairs: number
  runs: number
  flush: boolean
  total: number
}

export interface CutScore {
  card: PlayingCard
  totalScore: number
}

export interface KeepExplanation {
  guaranteedPoints: HandPatterns
  cutScores: CutScore[]
  averageHandScore: number
  averageCribScore: number
  isDealer: boolean
}
