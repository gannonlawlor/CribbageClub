import { useState, useEffect, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'
import { CardWidget } from '@/features/game/components/CardWidget'
import { getCachedAnalysis, cacheAnalysis } from '@/services/analysis-cache'
import * as api from '@/api/rest-client'
import type { GameAnalysis, RoundAnalysis, PlayerRoundAnalysis, DiscardOption } from '@/models'
import { cardsEqual } from '@/models/card'

export function AnalysisPage() {
  const { gameId } = useParams<{ gameId: string }>()
  const navigate = useNavigate()
  const userId = useAuthStore((s) => s.userId)

  const [analysis, setAnalysis] = useState<GameAnalysis | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadAnalysis = useCallback(async () => {
    if (!gameId) return
    setIsLoading(true)
    setError(null)

    try {
      // 1. Check local cache
      const cached = getCachedAnalysis(gameId)
      if (cached) {
        setAnalysis(cached)
        setIsLoading(false)
        return
      }

      // 2. Fetch from server
      const serverData = await api.getGameAnalysis(gameId)
      cacheAnalysis(gameId, serverData)
      setAnalysis(serverData)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load analysis')
    } finally {
      setIsLoading(false)
    }
  }, [gameId])

  useEffect(() => {
    loadAnalysis()
  }, [loadAnalysis])

  if (isLoading) {
    return (
      <div className="max-w-lg mx-auto p-8 text-center">
        <div className="text-white/50 py-16 flex flex-col items-center gap-4">
          <div className="w-8 h-8 border-2 border-white/30 border-t-white/80 rounded-full animate-spin" />
          <span>Analyzing discards...</span>
        </div>
      </div>
    )
  }

  if (error || !analysis) {
    return (
      <div className="max-w-lg mx-auto p-8 text-center">
        <div className="text-red-400 text-4xl mb-4">!</div>
        <div className="text-red-400 mb-4">{error ?? 'Analysis unavailable'}</div>
        <button
          onClick={() => navigate('/')}
          className="text-[var(--green-500)] bg-transparent border-none cursor-pointer"
        >
          Back to Home
        </button>
      </div>
    )
  }

  return (
    <div className="max-w-lg mx-auto p-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/')}
            className="text-white/60 bg-transparent border-none cursor-pointer text-lg hover:text-white"
          >
            &larr;
          </button>
          <h1 className="text-lg font-bold text-white">Discard Analysis</h1>
        </div>
        <button
          onClick={() => navigate(`/replay/${gameId}`)}
          className="text-white/50 bg-transparent border-none cursor-pointer text-sm hover:text-white"
        >
          Replay
        </button>
      </div>

      <AnalysisContent analysis={analysis} playerId={userId ?? ''} />
    </div>
  )
}

function AnalysisContent({ analysis, playerId }: { analysis: GameAnalysis; playerId: string }) {
  if (analysis.rounds.length === 0) {
    return (
      <div className="text-white/50 text-center py-8">
        No rounds with analysis data available.
      </div>
    )
  }

  // Summary stats
  const myAnalyses = analysis.rounds
    .flatMap((r) => r.playerAnalyses)
    .filter((a) => a.playerId === playerId)

  const totalEvLost = myAnalyses.reduce((sum, a) => sum + a.evDifference, 0)
  const optimalCount = myAnalyses.filter((a) => a.evDifference < 0.01).length

  return (
    <div className="space-y-4">
      {/* Summary */}
      <div className="bg-white/10 rounded-xl p-4">
        <div className="text-white font-bold text-center mb-2">Summary</div>
        <div className="flex justify-evenly">
          <SummaryChip label="Rounds" value={`${analysis.rounds.length}`} />
          <SummaryChip label="Optimal" value={`${optimalCount}/${myAnalyses.length}`} />
          <SummaryChip
            label="Avg Pts Lost"
            value={totalEvLost.toFixed(1)}
            color={totalEvLost < 2 ? 'text-green-400' : totalEvLost < 5 ? 'text-orange-400' : 'text-red-400'}
          />
        </div>
      </div>

      {/* Round cards */}
      {analysis.rounds.map((round) => (
        <RoundCard key={round.roundNumber} round={round} playerId={playerId} />
      ))}
    </div>
  )
}

function SummaryChip({ label, value, color }: { label: string; value: string; color?: string }) {
  return (
    <div className="flex flex-col items-center">
      <span className={`text-xl font-bold ${color ?? 'text-white'}`}>{value}</span>
      <span className="text-white/50 text-xs">{label}</span>
    </div>
  )
}

function RoundCard({ round, playerId }: { round: RoundAnalysis; playerId: string }) {
  const [expanded, setExpanded] = useState(false)

  const myAnalysis = round.playerAnalyses.find((a) => a.playerId === playerId)
  if (!myAnalysis) return null

  const evDiff = myAnalysis.evDifference
  const evColor = evDiff < 0.5 ? 'text-green-400' : evDiff < 2 ? 'text-orange-400' : 'text-red-400'

  return (
    <div className="bg-white/10 rounded-xl overflow-hidden">
      {/* Header */}
      <div className="p-3 flex items-center">
        <span className="text-white font-bold">Round {round.roundNumber}</span>
        {myAnalysis.isDealer && (
          <span className="ml-2 px-1.5 py-0.5 bg-[var(--green-500)]/20 text-[var(--green-400)] text-xs rounded">
            Dealer
          </span>
        )}
        <div className="flex-1" />
        {round.cutCard && (
          <div className="flex items-center gap-1">
            <span className="text-white/50 text-xs">Cut:</span>
            <CardWidget card={round.cutCard} width={30} height={42} enabled={false} />
          </div>
        )}
      </div>

      {/* Dealt hand */}
      <div className="px-3">
        <div className="text-white/50 text-xs mb-1">Dealt Hand</div>
        <div className="flex gap-1 flex-wrap">
          {myAnalysis.dealtHand.map((card, i) => {
            const isDiscarded = myAnalysis.discarded.some((d) => cardsEqual(d, card))
            return (
              <div key={i} style={{ opacity: isDiscarded ? 0.4 : 1 }}>
                <CardWidget card={card} width={40} height={56} enabled={false} />
              </div>
            )
          })}
        </div>
      </div>

      {/* Discard comparison */}
      <div className="px-3 pt-2 flex gap-2">
        <DiscardComparison label="Your Discard" option={myAnalysis.playerDiscard} isDealer={myAnalysis.isDealer} />
        <DiscardComparison label="Optimal" option={myAnalysis.optimalDiscard} isDealer={myAnalysis.isDealer} isOptimal />
      </div>

      {/* EV difference */}
      <div className="px-3 pt-2 flex items-center gap-1.5 flex-wrap">
        <span className={`${evColor} font-semibold text-sm`}>
          {evDiff < 0.01 ? 'Optimal play!' : `${evDiff.toFixed(2)} avg pts below optimal`}
        </span>
        <div className="flex-1" />
        {myAnalysis.actualHandScore > 0 && (
          <span className="text-white/50 text-xs">Hand: {myAnalysis.actualHandScore} pts</span>
        )}
        {myAnalysis.actualCribScore != null && (
          <span className="text-white/50 text-xs">Crib: {myAnalysis.actualCribScore} pts</span>
        )}
      </div>

      {/* Expand toggle */}
      <button
        onClick={() => setExpanded(!expanded)}
        className="w-full p-3 flex items-center justify-between bg-transparent border-none cursor-pointer"
      >
        <span className="text-white/50 text-xs">
          {expanded ? 'Hide all options' : 'Show all 15 options'}
        </span>
        <span className="text-white/50 text-xs">{expanded ? '\u25B2' : '\u25BC'}</span>
      </button>

      {/* Expanded options */}
      {expanded && (
        <AllOptions myAnalysis={myAnalysis} />
      )}
    </div>
  )
}

function DiscardComparison({
  label,
  option,
  isOptimal = false,
}: {
  label: string
  option: DiscardOption
  isDealer: boolean
  isOptimal?: boolean
}) {
  return (
    <div
      className={`flex-1 p-2 rounded-lg ${
        isOptimal
          ? 'bg-green-500/10 border border-green-500/30'
          : 'bg-white/5'
      }`}
    >
      <div className={`text-xs font-semibold mb-1 ${isOptimal ? 'text-green-400' : 'text-white/70'}`}>
        {label}
      </div>
      <div className="flex gap-1">
        {option.discard.map((card, i) => (
          <CardWidget key={i} card={card} width={32} height={45} enabled={false} />
        ))}
      </div>
      <div className="text-white font-semibold text-sm mt-1">
        {option.expectedCombinedValue.toFixed(2)} avg pts
      </div>
      <div className="text-white/40 text-[10px]">
        hand {option.expectedHandValue.toFixed(1)}  crib {option.expectedCribValue > 0 ? '+' : ''}{option.expectedCribValue.toFixed(1)}
      </div>
    </div>
  )
}

function AllOptions({ myAnalysis }: { myAnalysis: PlayerRoundAnalysis }) {
  const options = [myAnalysis.optimalDiscard, myAnalysis.playerDiscard]
  // Deduplicate
  const unique = options.filter((opt, i, arr) =>
    arr.findIndex((o) =>
      o.discard.length === opt.discard.length &&
      o.discard.every((d, j) => cardsEqual(d, opt.discard[j]))
    ) === i,
  )

  return (
    <div className="px-3 pb-3 space-y-1">
      <div className="border-t border-white/10 mb-2" />
      {unique.map((option, i) => {
        const isPlayerChoice = option.discard.every((d, j) =>
          cardsEqual(d, myAnalysis.playerDiscard.discard[j]),
        )
        const isOptimal = i === 0
        return (
          <OptionRow
            key={i}
            rank={i + 1}
            option={option}
            isPlayerChoice={isPlayerChoice}
            isOptimal={isOptimal}
          />
        )
      })}
    </div>
  )
}

function OptionRow({
  rank,
  option,
  isPlayerChoice,
  isOptimal,
}: {
  rank: number
  option: DiscardOption
  isPlayerChoice: boolean
  isOptimal: boolean
}) {
  return (
    <div className="flex items-center gap-1 py-1">
      <span className={`w-6 text-xs font-semibold ${isOptimal ? 'text-green-400' : 'text-white/50'}`}>
        #{rank}
      </span>
      {option.discard.map((card, i) => (
        <CardWidget key={i} card={card} width={26} height={36} enabled={false} />
      ))}
      <span className="flex-1 text-white text-xs ml-2">
        {option.expectedCombinedValue.toFixed(2)} avg pts
      </span>
      {isPlayerChoice && (
        <span className="px-1.5 py-0.5 bg-blue-500/20 text-blue-400 text-[10px] rounded">You</span>
      )}
      {isOptimal && (
        <span className="px-1.5 py-0.5 bg-green-500/20 text-green-400 text-[10px] rounded ml-1">Best</span>
      )}
    </div>
  )
}
