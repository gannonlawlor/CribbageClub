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

            {/* Cut score table */}
            <CutScoreTable cutScores={explanation.cutScores} />
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

function CutScoreTable({ cutScores }: { cutScores: CutScore[] }) {
  if (cutScores.length === 0) return null

  const scores = cutScores.map((cs) => cs.totalScore)
  const minScore = Math.min(...scores)
  const maxScore = Math.max(...scores)
  const avgScore = scores.reduce((a, b) => a + b, 0) / scores.length

  const total = cutScores.length
  const zeroCount = scores.filter((s) => s === 0).length
  const low = scores.filter((s) => s >= 1 && s <= 3).length
  const mid = scores.filter((s) => s >= 4 && s <= 7).length
  const good = scores.filter((s) => s >= 8 && s <= 11).length
  const great = scores.filter((s) => s >= 12).length

  return (
    <div>
      <div className="text-white/50 text-xs mb-2">Score by cut card</div>
      <div className="bg-white/10 rounded-lg p-3 flex justify-evenly mb-2">
        <div className="text-center">
          <div className="text-white text-base">{minScore}</div>
          <div className="text-white/40 text-xs">Min</div>
        </div>
        <div className="text-center">
          <div className="text-white text-lg font-bold">{avgScore.toFixed(1)}</div>
          <div className="text-white/40 text-xs">Avg</div>
        </div>
        <div className="text-center">
          <div className="text-white text-base">{maxScore}</div>
          <div className="text-white/40 text-xs">Max</div>
        </div>
      </div>
      <div className="space-y-1">
        {great > 0 && <CutBucket label="12+ pts" count={great} total={total} color="text-green-400" />}
        {good > 0 && <CutBucket label="8-11 pts" count={good} total={total} color="text-green-500" />}
        {mid > 0 && <CutBucket label="4-7 pts" count={mid} total={total} color="text-amber-400" />}
        {low > 0 && <CutBucket label="1-3 pts" count={low} total={total} color="text-white/60" />}
        {zeroCount > 0 && <CutBucket label="0 pts" count={zeroCount} total={total} color="text-white/40" />}
      </div>
    </div>
  )
}

function CutBucket({ label, count, total, color }: { label: string; count: number; total: number; color: string }) {
  const pct = Math.round((count / total) * 100)
  return (
    <div className="flex items-center gap-2 text-sm">
      <span className={`w-16 ${color}`}>{label}</span>
      <div className="flex-1 h-2 bg-white/10 rounded-full overflow-hidden">
        <div className={`h-full rounded-full bg-current ${color}`} style={{ width: `${pct}%` }} />
      </div>
      <span className="text-white/50 text-xs w-14 text-right">{count} cut{count !== 1 ? 's' : ''} ({pct}%)</span>
    </div>
  )
}
