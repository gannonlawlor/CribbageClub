import type { GameAnalysis } from '@/models'

const KEY_PREFIX = 'analysis_'

export function getCachedAnalysis(gameId: string): GameAnalysis | null {
  try {
    const raw = localStorage.getItem(`${KEY_PREFIX}${gameId}`)
    if (!raw) return null
    return JSON.parse(raw) as GameAnalysis
  } catch {
    return null
  }
}

export function cacheAnalysis(gameId: string, analysis: GameAnalysis): void {
  try {
    localStorage.setItem(`${KEY_PREFIX}${gameId}`, JSON.stringify(analysis))
  } catch {
    // Storage full or unavailable — silently ignore
  }
}
