import type { KeepOption } from './models'
import { keepOptionFromJson, keepOptionToJson } from './models'
import { PUZZLES_PER_DAY } from './puzzle-generator'

const KEY_LAST_DATE = 'daily_puzzle_last_date'
const KEY_STREAK = 'daily_puzzle_streak'

function formatDate(date: Date): string {
  const y = date.getFullYear().toString().padStart(4, '0')
  const m = (date.getMonth() + 1).toString().padStart(2, '0')
  const d = date.getDate().toString().padStart(2, '0')
  return `${y}${m}${d}`
}

function parseDate(s: string): Date {
  const year = parseInt(s.substring(0, 4))
  const month = parseInt(s.substring(4, 6)) - 1
  const day = parseInt(s.substring(6, 8))
  return new Date(year, month, day)
}

function ranksKey(dateStr: string) { return `daily_puzzle_ranks_${dateStr}` }
function scoresKey(dateStr: string) { return `daily_puzzle_scores_${dateStr}` }
function resultsKey(dateStr: string) { return `daily_puzzle_results_${dateStr}` }

function loadNullableList<T>(key: string, length: number): (T | null)[] {
  try {
    const raw = localStorage.getItem(key)
    if (!raw) return new Array(length).fill(null)
    const list = JSON.parse(raw) as (T | null)[]
    while (list.length < length) list.push(null)
    return list
  } catch {
    return new Array(length).fill(null)
  }
}

function loadResults(key: string, length: number): (KeepOption[] | null)[] {
  try {
    const raw = localStorage.getItem(key)
    if (!raw) return new Array(length).fill(null)
    const list = JSON.parse(raw) as (Record<string, unknown>[] | null)[]
    const results: (KeepOption[] | null)[] = []
    for (const item of list) {
      if (item == null) {
        results.push(null)
      } else {
        results.push(item.map((o) => keepOptionFromJson(o)))
      }
    }
    while (results.length < length) results.push(null)
    return results
  } catch {
    return new Array(length).fill(null)
  }
}

export interface PuzzleProgress {
  ranks: (number | null)[]
  scores: (number | null)[]
  allResults: (KeepOption[] | null)[]
  nextIndex: number
}

export function getProgress(date: Date): PuzzleProgress {
  const dateStr = formatDate(date)
  const n = PUZZLES_PER_DAY
  const ranks = loadNullableList<number>(ranksKey(dateStr), n)
  const scores = loadNullableList<number>(scoresKey(dateStr), n)
  const allResults = loadResults(resultsKey(dateStr), n)

  let nextIndex = n
  for (let i = 0; i < n; i++) {
    if (ranks[i] == null) {
      nextIndex = i
      break
    }
  }

  return { ranks, scores, allResults, nextIndex }
}

export function getStreak(): number {
  try {
    return parseInt(localStorage.getItem(KEY_STREAK) ?? '0') || 0
  } catch {
    return 0
  }
}

export function savePuzzleResult(
  date: Date,
  index: number,
  rank: number,
  score: number,
  results: KeepOption[],
): void {
  const dateStr = formatDate(date)
  const n = PUZZLES_PER_DAY

  const ranks = loadNullableList<number>(ranksKey(dateStr), n)
  const scores = loadNullableList<number>(scoresKey(dateStr), n)
  const allResults = loadResults(resultsKey(dateStr), n)

  ranks[index] = rank
  scores[index] = score
  allResults[index] = results

  localStorage.setItem(ranksKey(dateStr), JSON.stringify(ranks))
  localStorage.setItem(scoresKey(dateStr), JSON.stringify(scores))
  localStorage.setItem(
    resultsKey(dateStr),
    JSON.stringify(allResults.map((r) => r?.map((o) => keepOptionToJson(o)) ?? null)),
  )
}

export function finalizeDayResults(date: Date): void {
  const dateStr = formatDate(date)
  const n = PUZZLES_PER_DAY
  const ranks = loadNullableList<number>(ranksKey(dateStr), n)

  const allOptimal = ranks.every((r) => r === 1)
  const lastDateStr = localStorage.getItem(KEY_LAST_DATE)
  const currentStreak = parseInt(localStorage.getItem(KEY_STREAK) ?? '0') || 0

  let newStreak: number
  if (allOptimal && lastDateStr) {
    const lastDate = parseDate(lastDateStr)
    const yesterday = new Date(date.getFullYear(), date.getMonth(), date.getDate() - 1)
    if (
      lastDate.getFullYear() === yesterday.getFullYear() &&
      lastDate.getMonth() === yesterday.getMonth() &&
      lastDate.getDate() === yesterday.getDate()
    ) {
      newStreak = currentStreak + 1
    } else {
      newStreak = 1
    }
  } else if (allOptimal) {
    newStreak = 1
  } else {
    newStreak = 0
  }

  localStorage.setItem(KEY_LAST_DATE, dateStr)
  localStorage.setItem(KEY_STREAK, newStreak.toString())
}
