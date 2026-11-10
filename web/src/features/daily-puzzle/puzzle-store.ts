import { create } from 'zustand'
import type { PlayingCard } from '@/models'
import { cardsEqual } from '@/models/card'
import type { DailyPuzzleSet, KeepOption } from './models'
import { generatePuzzleSet, evaluateAllKeeps, PUZZLES_PER_DAY } from './puzzle-generator'
import { getProgress, getStreak, savePuzzleResult, finalizeDayResults } from './puzzle-persistence'

type PuzzlePhase = 'playing' | 'revealed' | 'summary'

interface DailyPuzzleState {
  puzzleSet: DailyPuzzleSet | null
  currentPuzzleIndex: number
  selectedCards: PlayingCard[]
  phase: PuzzlePhase
  streak: number
  completedToday: boolean
  playerRanks: (number | null)[]
  playerScores: (number | null)[]
  allResults: (KeepOption[] | null)[]
  error: string | null
  isSubmitting: boolean

  loadPuzzle: () => void
  toggleCard: (card: PlayingCard) => void
  submitKeep: () => Promise<number | null>
  reset: () => void
}

function totalScore(scores: (number | null)[]): number {
  return scores.reduce((sum: number, s) => sum + (s ?? 0), 0)
}

function maxPossibleScore(allResults: (KeepOption[] | null)[]): number {
  let total = 0
  for (const results of allResults) {
    if (results && results.length > 0) {
      total += results[0].netScore
    }
  }
  return total
}

export const usePuzzleStore = create<DailyPuzzleState>((set, get) => ({
  puzzleSet: null,
  currentPuzzleIndex: 0,
  selectedCards: [],
  phase: 'playing',
  streak: 0,
  completedToday: false,
  playerRanks: [null, null, null, null, null],
  playerScores: [null, null, null, null, null],
  allResults: [null, null, null, null, null],
  error: null,
  isSubmitting: false,

  loadPuzzle() {
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const puzzleSet = generatePuzzleSet(today)
    const streak = getStreak()
    const progress = getProgress(today)

    const allComplete = progress.nextIndex >= PUZZLES_PER_DAY

    if (allComplete) {
      set({
        puzzleSet,
        currentPuzzleIndex: PUZZLES_PER_DAY - 1,
        streak,
        completedToday: true,
        phase: 'summary',
        playerRanks: [...progress.ranks],
        playerScores: [...progress.scores],
        allResults: [...progress.allResults],
        selectedCards: [],
      })
    } else {
      set({
        puzzleSet,
        currentPuzzleIndex: progress.nextIndex,
        streak,
        completedToday: false,
        phase: 'playing',
        playerRanks: [...progress.ranks],
        playerScores: [...progress.scores],
        allResults: [...progress.allResults],
        selectedCards: [],
      })
    }
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

  async submitKeep() {
    const state = get()
    const { puzzleSet, currentPuzzleIndex, selectedCards } = state
    if (selectedCards.length !== 4 || !puzzleSet) return null

    const puzzle = puzzleSet.puzzles[currentPuzzleIndex]
    if (!puzzle) return null

    set({ isSubmitting: true })

    let results: KeepOption[]
    try {
      results = evaluateAllKeeps(puzzle.hand, puzzle.isDealer)
      if (results.length !== 15) throw new Error('Analysis unavailable')
    } catch {
      set({ isSubmitting: false, error: 'Analysis is unavailable. Your attempt is safe. Try Submit again, or reload if this continues.' })
      return null
    }

    // Find player's rank and score
    let playerRank: number | null = null
    let playerScore: number | null = null
    for (const option of results) {
      const keepSet = option.keep
      const allMatch = keepSet.length === selectedCards.length &&
        keepSet.every((k) => selectedCards.some((s) => cardsEqual(s, k)))
      if (allMatch) {
        playerRank = option.rank
        playerScore = option.netScore
        break
      }
    }

    // Persist
    savePuzzleResult(puzzle.date, currentPuzzleIndex, playerRank ?? 0, playerScore ?? 0, results)

    const ranks = [...state.playerRanks]
    const scores = [...state.playerScores]
    const allResults = [...state.allResults]
    ranks[currentPuzzleIndex] = playerRank
    scores[currentPuzzleIndex] = playerScore
    allResults[currentPuzzleIndex] = results

    const isLast = currentPuzzleIndex >= PUZZLES_PER_DAY - 1

    if (isLast) {
      finalizeDayResults(puzzle.date)
      const streak = getStreak()
      set({
        phase: 'summary',
        streak,
        completedToday: true,
        playerRanks: ranks,
        playerScores: scores,
        allResults,
        error: null,
        isSubmitting: false,
      })
    } else {
      set({
        currentPuzzleIndex: currentPuzzleIndex + 1,
        selectedCards: [],
        phase: 'playing',
        playerRanks: ranks,
        playerScores: scores,
        allResults,
        error: null,
        isSubmitting: false,
      })
    }

    return playerRank
  },

  reset() {
    set({
      puzzleSet: null,
      currentPuzzleIndex: 0,
      selectedCards: [],
      phase: 'playing',
      streak: 0,
      completedToday: false,
      playerRanks: [null, null, null, null, null],
      playerScores: [null, null, null, null, null],
      allResults: [null, null, null, null, null],
      error: null,
      isSubmitting: false,
    })
  },
}))

// Re-export helpers for UI
export { totalScore, maxPossibleScore }
