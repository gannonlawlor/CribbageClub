import { create } from 'zustand'
import type { PlayingCard } from '@/models'
import { Rank, Suit, cardsEqual } from '@/models/card'
import type { KeepOption } from '@/features/daily-puzzle/models'
import { evaluateAllKeeps } from '@/features/daily-puzzle/puzzle-generator'

type Phase = 'playing' | 'revealed'

interface PracticePuzzle {
  hand: PlayingCard[]
  isDealer: boolean
}

interface PracticePuzzleState {
  puzzle: PracticePuzzle | null
  selectedCards: PlayingCard[]
  phase: Phase
  playerRank: number | null
  results: KeepOption[]
  puzzleNumber: number
  totalSolved: number
  optimalCount: number
  error: string | null
  isSubmitting: boolean

  loadPuzzle: () => void
  toggleCard: (card: PlayingCard) => void
  submitKeep: () => void
  nextPuzzle: () => void
  reset: () => void
}

function generateRandomPuzzle(): PracticePuzzle {
  const ranks = Object.values(Rank)
  const suits = Object.values(Suit)
  const deck: PlayingCard[] = []
  for (const rank of ranks) {
    for (const suit of suits) {
      deck.push({ rank, suit })
    }
  }

  // Fisher-Yates shuffle with Math.random()
  for (let i = deck.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    const temp = deck[i]
    deck[i] = deck[j]
    deck[j] = temp
  }

  return {
    hand: deck.slice(0, 6),
    isDealer: Math.random() < 0.5,
  }
}

export const usePracticePuzzleStore = create<PracticePuzzleState>((set, get) => ({
  puzzle: null,
  selectedCards: [],
  phase: 'playing',
  playerRank: null,
  results: [],
  puzzleNumber: 1,
  totalSolved: 0,
  optimalCount: 0,
  error: null,
  isSubmitting: false,

  loadPuzzle() {
    set({
      puzzle: generateRandomPuzzle(),
      selectedCards: [],
      phase: 'playing',
      playerRank: null,
      results: [],
      error: null,
      isSubmitting: false,
    })
  },

  toggleCard(card: PlayingCard) {
    const { phase, selectedCards } = get()
    if (phase !== 'playing') return

    const idx = selectedCards.findIndex((c) => cardsEqual(c, card))
    if (idx >= 0) {
      set({ selectedCards: selectedCards.filter((_, i) => i !== idx) })
    } else if (selectedCards.length < 4) {
      set({ selectedCards: [...selectedCards, card] })
    }
  },

  submitKeep() {
    const { puzzle, selectedCards } = get()
    if (selectedCards.length !== 4 || !puzzle) return

    set({ isSubmitting: true })

    let results: KeepOption[]
    try {
      results = evaluateAllKeeps(puzzle.hand, puzzle.isDealer)
      if (results.length !== 15) throw new Error('Analysis unavailable')
    } catch {
      set({ isSubmitting: false, error: 'Analysis is unavailable. Your attempt is safe. Try Submit again, or reload if this continues.' })
      return
    }

    let playerRank: number | null = null
    for (const option of results) {
      const allMatch = option.keep.length === selectedCards.length &&
        option.keep.every((k) => selectedCards.some((s) => cardsEqual(s, k)))
      if (allMatch) {
        playerRank = option.rank
        break
      }
    }

    const { totalSolved, optimalCount } = get()
    set({
      results,
      playerRank,
      phase: 'revealed',
      error: null,
      isSubmitting: false,
      totalSolved: totalSolved + 1,
      optimalCount: playerRank === 1 ? optimalCount + 1 : optimalCount,
    })
  },

  nextPuzzle() {
    const { puzzleNumber } = get()
    set({ puzzleNumber: puzzleNumber + 1 })
    get().loadPuzzle()
  },

  reset() {
    set({
      puzzle: null,
      selectedCards: [],
      phase: 'playing',
      playerRank: null,
      results: [],
      puzzleNumber: 1,
      totalSolved: 0,
      optimalCount: 0,
      error: null,
      isSubmitting: false,
    })
  },
}))
