import { Rank, RANK_DISPLAY, SUIT_SYMBOL } from '@/models/card'
import type { PlayingCard } from '@/models'
import type { KeepExplanation, HandPatterns } from '../models/keep-explanation'

export function generateInsights(
  explanation: KeepExplanation,
  keep: PlayingCard[],
  discard: PlayingCard[],
): string[] {
  const insights: string[] = []

  addGuaranteedInsights(insights, explanation.guaranteedPoints, keep)
  addCutInsights(insights, explanation, keep)
  addCribInsights(insights, explanation, keep, discard)

  return insights.length > 6 ? insights.slice(0, 6) : insights
}

function addGuaranteedInsights(insights: string[], patterns: HandPatterns, keep: PlayingCard[]) {
  if (patterns.pairs > 0) {
    for (const desc of describePairs(keep)) {
      insights.push(desc)
    }
  }

  if (patterns.fifteens > 0) {
    const count = Math.floor(patterns.fifteens / 2)
    if (count === 1) {
      insights.push('15 for 2 guaranteed')
    } else {
      insights.push(`${count} fifteens (${patterns.fifteens} pts guaranteed)`)
    }
  }

  if (patterns.runs > 0) {
    const runDesc = describeRun(keep, patterns.runs)
    if (runDesc) insights.push(runDesc)
  }

  if (patterns.flush) {
    insights.push('Four-card flush (4 pts guaranteed)')
  }
}

function addCutInsights(insights: string[], explanation: KeepExplanation, keep: PlayingCard[]) {
  const cutScores = explanation.cutScores
  if (cutScores.length === 0) return

  const best = cutScores[0]
  insights.push(
    `Best cut: ${RANK_DISPLAY[best.card.rank]}${SUIT_SYMBOL[best.card.suit]} (${best.totalScore} pts)`,
  )

  const strongCuts = cutScores.filter((c) => c.totalScore >= 8).length
  if (strongCuts > 0) {
    insights.push(`${strongCuts} of 46 cuts score 8+`)
  }

  const jacks = keep.filter((c) => c.rank === Rank.JACK)
  if (jacks.length > 0) {
    const suitCount = cutScores.filter((c) => c.card.suit === jacks[0].suit).length
    if (suitCount > 0) {
      insights.push(
        `Nobs potential \u2014 J${SUIT_SYMBOL[jacks[0].suit]} scores +1 on ${suitCount} cuts`,
      )
    }
  }
}

function addCribInsights(
  insights: string[],
  explanation: KeepExplanation,
  _keep: PlayingCard[],
  discard: PlayingCard[],
) {
  const avgCrib = explanation.averageCribScore
  const { isDealer } = explanation

  if (isDealer) {
    insights.push(`Your crib gains avg ${avgCrib.toFixed(1)} pts`)
  } else {
    insights.push(`Opponent's crib gets avg ${avgCrib.toFixed(1)} pts`)
  }

  const hasFiveInDiscard = discard.some((c) => c.rank === Rank.FIVE)
  if (hasFiveInDiscard && !isDealer) {
    insights.push("5 in opponent's crib risks easy 15s")
  } else if (!hasFiveInDiscard && !isDealer) {
    insights.push("Avoids giving a 5 to opponent's crib")
  }

  if (isDealer && discard.length === 2 && discard[0].rank === discard[1].rank) {
    insights.push('Pair in your crib adds guaranteed points')
  }
}

function describePairs(keep: PlayingCard[]): string[] {
  const rankCounts = new Map<Rank, number>()
  for (const card of keep) {
    rankCounts.set(card.rank, (rankCounts.get(card.rank) ?? 0) + 1)
  }

  const descs: string[] = []
  for (const [rank, count] of rankCounts) {
    if (count === 2) descs.push(`Pair of ${RANK_DISPLAY[rank]}s (2 pts guaranteed)`)
    else if (count === 3) descs.push(`Three ${RANK_DISPLAY[rank]}s (6 pts guaranteed)`)
    else if (count === 4) descs.push(`Four ${RANK_DISPLAY[rank]}s (12 pts guaranteed)`)
  }
  return descs
}

const RANK_ORDER: Record<Rank, number> = {
  [Rank.ACE]: 0,
  [Rank.TWO]: 1,
  [Rank.THREE]: 2,
  [Rank.FOUR]: 3,
  [Rank.FIVE]: 4,
  [Rank.SIX]: 5,
  [Rank.SEVEN]: 6,
  [Rank.EIGHT]: 7,
  [Rank.NINE]: 8,
  [Rank.TEN]: 9,
  [Rank.JACK]: 10,
  [Rank.QUEEN]: 11,
  [Rank.KING]: 12,
}

function describeRun(keep: PlayingCard[], runPoints: number): string | null {
  const sorted = [...keep].sort((a, b) => RANK_ORDER[a.rank] - RANK_ORDER[b.rank])

  let bestRun = [sorted[0]]
  let currentRun = [sorted[0]]

  for (let i = 1; i < sorted.length; i++) {
    const diff = RANK_ORDER[sorted[i].rank] - RANK_ORDER[sorted[i - 1].rank]
    if (diff === 1) {
      currentRun.push(sorted[i])
    } else if (diff === 0) {
      continue
    } else {
      if (currentRun.length > bestRun.length) bestRun = currentRun
      currentRun = [sorted[i]]
    }
  }
  if (currentRun.length > bestRun.length) bestRun = currentRun

  if (bestRun.length >= 3) {
    const rankStr = bestRun.map((c) => RANK_DISPLAY[c.rank]).join('-')
    return `Run of ${rankStr} (${runPoints} pts guaranteed)`
  }
  return null
}
