import { useMemo, useEffect, useRef } from 'react'
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
  const dialog = useRef<HTMLDialogElement>(null)
  useEffect(() => {
    const previous = document.activeElement as HTMLElement | null
    dialog.current?.showModal()
    return () => { previous?.focus() }
  }, [])
  const { explanation, insights, error } = useMemo(() => {
    try {
      if (!isEngineReady()) throw new Error('Engine unavailable')
      const data = JSON.parse(getEngine().explain_keep_json(JSON.stringify(hand), JSON.stringify(keep), isDealer)) as KeepExplanation
      return { explanation: data, insights: generateInsights(data, keep, discard), error: null }
    } catch {
      return { explanation: null, insights: null, error: 'Analysis is unavailable. Close this panel and try again shortly.' }
    }
  }, [hand, keep, discard, isDealer])

  return (
    <>
      {/* Sheet */}
      <dialog ref={dialog} onCancel={onClose} aria-label="Keep explanation" className="fixed inset-x-0 bottom-0 top-auto z-50 bg-[var(--surface-1)] text-white rounded-t-2xl p-5 w-full max-w-lg max-h-[85dvh] overflow-y-auto backdrop:bg-black/60">
        <button autoFocus onClick={onClose} className="float-right min-h-11 px-3 text-white">Close</button>
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
      </dialog>
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
