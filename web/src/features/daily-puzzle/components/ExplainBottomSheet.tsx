import { useState, useEffect } from 'react'
import { CardWidget } from '@/features/game/components/CardWidget'
import type { PlayingCard } from '@/models'
import { isEngineReady, getEngine } from '@/engine/wasm-engine'
import type { KeepExplanation, CutScore } from '../models/keep-explanation'
import { generateInsights } from '../services/insight-generator'

interface ExplainBottomSheetProps {
  rank: number
  keep: PlayingCard[]
  discard: PlayingCard[]
  hand: PlayingCard[]
  isDealer: boolean
  onClose: () => void
}

export function ExplainBottomSheet({
  rank,
  keep,
  discard,
  hand,
  isDealer,
  onClose,
}: ExplainBottomSheetProps) {
  const [explanation, setExplanation] = useState<KeepExplanation | null>(null)
  const [insights, setInsights] = useState<string[] | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!isEngineReady()) {
      setError('WASM engine not loaded. Explain feature requires the engine.')
      return
    }

    try {
      const engine = getEngine()
      const handJson = JSON.stringify(hand)
      const keepJson = JSON.stringify(keep)
      const resultJson = (engine as unknown as { explain_keep_json: (h: string, k: string, d: boolean) => string })
        .explain_keep_json(handJson, keepJson, isDealer)
      const data = JSON.parse(resultJson) as KeepExplanation
      setExplanation(data)
      setInsights(generateInsights(data, keep, discard))
    } catch {
      setError('Could not compute explanation')
    }
  }, [hand, keep, discard, isDealer])

  return (
    <>
      {/* Backdrop */}
      <div className="fixed inset-0 bg-black/50 z-40" onClick={onClose} />

      {/* Sheet */}
      <div className="fixed bottom-0 left-0 right-0 z-50 bg-[#1B3A1E] rounded-t-2xl p-5 max-w-lg mx-auto">
        {/* Drag handle */}
        <div className="flex justify-center mb-4">
          <div className="w-10 h-1 bg-white/20 rounded-full" />
        </div>

        {/* Header */}
        <div className="flex items-center gap-3 mb-4">
          <span className="text-white text-xl font-bold">Why #{rank}?</span>
          <div className="flex gap-1">
            {keep.map((card, i) => (
              <CardWidget key={i} card={card} width={32} height={45} enabled={false} />
            ))}
          </div>
        </div>

        {/* Content */}
        {error ? (
          <div className="text-white/50 text-sm py-4 text-center">{error}</div>
        ) : !explanation || !insights ? (
          <div className="flex justify-center py-6">
            <div className="w-6 h-6 border-2 border-white/30 border-t-white/80 rounded-full animate-spin" />
          </div>
        ) : (
          <div className="space-y-3">
            {/* Insights */}
            {insights.map((insight, i) => (
              <div key={i} className="flex gap-2 text-white/70 text-sm">
                <span className="text-white/70">&bull;</span>
                <span className="leading-relaxed">{insight}</span>
              </div>
            ))}

            {/* Score summary */}
            <ScoreSummary explanation={explanation} />

            {/* Cut distribution */}
            <CutDistribution cutScores={explanation.cutScores} />
          </div>
        )}
      </div>
    </>
  )
}

function ScoreSummary({ explanation }: { explanation: KeepExplanation }) {
  const netScore = explanation.isDealer
    ? explanation.averageHandScore + explanation.averageCribScore
    : explanation.averageHandScore - explanation.averageCribScore

  return (
    <div className="bg-white/10 rounded-lg p-3 flex justify-evenly">
      <div className="text-center">
        <div className="text-white text-base">{explanation.averageHandScore.toFixed(1)}</div>
        <div className="text-white/40 text-xs">Hand avg</div>
      </div>
      <div className="text-center">
        <div className="text-white text-base">
          {explanation.isDealer ? '+' : '\u2212'}{explanation.averageCribScore.toFixed(1)}
        </div>
        <div className="text-white/40 text-xs">Crib avg</div>
      </div>
      <div className="text-center">
        <div className="text-white text-lg font-bold">{netScore.toFixed(1)}</div>
        <div className="text-white/40 text-xs">Net</div>
      </div>
    </div>
  )
}

function CutDistribution({ cutScores }: { cutScores: CutScore[] }) {
  if (cutScores.length === 0) return null

  const dist = new Map<number, number>()
  for (const cs of cutScores) {
    dist.set(cs.totalScore, (dist.get(cs.totalScore) ?? 0) + 1)
  }

  const scores = Array.from(dist.keys()).sort((a, b) => a - b)
  const minScore = scores[0]
  const maxScore = scores[scores.length - 1]
  const maxCount = Math.max(...dist.values())

  return (
    <div>
      <div className="text-white/50 text-xs mb-1">Score distribution by cut</div>
      <div className="flex items-end gap-px h-14">
        {Array.from({ length: maxScore - minScore + 1 }).map((_, i) => {
          const score = minScore + i
          const count = dist.get(score) ?? 0
          const height = count > 0 ? (count / maxCount) * 100 : 2
          return (
            <div
              key={score}
              className="flex-1 rounded-t-sm"
              style={{
                height: `${height}%`,
                backgroundColor: count > 0 ? barColor(score) : 'rgba(255,255,255,0.05)',
              }}
              title={count > 0 ? `${score} pts: ${count} cuts` : ''}
            />
          )
        })}
      </div>
      <div className="flex justify-between">
        <span className="text-white/40 text-[10px]">{minScore}</span>
        <span className="text-white/40 text-[10px]">{maxScore} pts</span>
      </div>
    </div>
  )
}

function barColor(score: number): string {
  if (score >= 12) return 'rgb(16, 185, 129)' // green-400
  if (score >= 8) return 'rgb(34, 197, 94)' // green-500
  if (score >= 4) return 'rgb(245, 158, 11)' // amber-500
  return 'rgba(255, 255, 255, 0.25)'
}
