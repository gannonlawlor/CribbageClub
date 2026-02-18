import { Rank, Suit } from '@/models/card'
import type { PlayingCard } from '@/models'
import type { DiscardOption } from '@/models/game-analysis'
import type { DailyPuzzle, DailyPuzzleSet, KeepOption } from './models'
import { isEngineReady, getEngine } from '@/engine/wasm-engine'

export const PUZZLES_PER_DAY = 5

/**
 * Deterministic PRNG (same algorithm as Dart's Random with seed).
 * Uses a simple mulberry32 for reproducibility.
 */
function mulberry32(seed: number) {
  let s = seed | 0
  return () => {
    s = (s + 0x6d2b79f5) | 0
    let t = Math.imul(s ^ (s >>> 15), 1 | s)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

export function generatePuzzleSet(date: Date): DailyPuzzleSet {
  const baseSeed = date.getFullYear() * 10000 + (date.getMonth() + 1) * 100 + date.getDate()
  const puzzles: DailyPuzzle[] = []
  for (let i = 0; i < PUZZLES_PER_DAY; i++) {
    puzzles.push(generateOne(date, baseSeed * PUZZLES_PER_DAY + i, i))
  }
  return { date, puzzles }
}

function generateOne(date: Date, seed: number, index: number): DailyPuzzle {
  const rng = mulberry32(seed)

  // Build full deck (52 cards)
  const ranks = Object.values(Rank)
  const suits = Object.values(Suit)
  const deck: PlayingCard[] = []
  for (const rank of ranks) {
    for (const suit of suits) {
      deck.push({ rank, suit })
    }
  }

  // Fisher-Yates shuffle
  for (let i = deck.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1))
    const temp = deck[i]
    deck[i] = deck[j]
    deck[j] = temp
  }

  const hand = deck.slice(0, 6)
  const isDealer = rng() < 0.5

  return { date, index, hand, isDealer }
}

/**
 * Evaluate all 15 possible keeps using the WASM engine.
 * Returns ranked options best-to-worst.
 * Falls back to empty array if engine is not ready.
 */
export function evaluateAllKeeps(hand: PlayingCard[], isDealer: boolean): KeepOption[] {
  if (!isEngineReady()) {
    return []
  }

  const engine = getEngine()
  const handJson = JSON.stringify(hand)
  const resultJson = engine.analyze_discards_json(handJson, isDealer)
  const allOptions = JSON.parse(resultJson) as DiscardOption[]

  return allOptions.map((o, i) => ({
    keep: o.keep,
    discard: o.discard,
    averageHandScore: o.expectedHandValue,
    averageCribScore: o.expectedCribValue,
    netScore: o.expectedCombinedValue,
    rank: i + 1,
  }))
}
