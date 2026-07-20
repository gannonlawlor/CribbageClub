import { useState, useEffect, useCallback, useMemo } from 'react'
import { useParams, useNavigate } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'
import * as api from '@/api/rest-client'
import type { GameState } from '@/models'
import { RANK_DISPLAY, SUIT_SYMBOL, isRedSuit } from '@/models/card'
import type { PlayingCard } from '@/models'
import { CribbageBoard } from '@/features/game/components/CribbageBoard'
import { CardWidget } from '@/features/game/components/CardWidget'
import { buildSnapshots, type ReplaySnapshot } from './replay-state'

export function ReplayPage() {
  const { gameId } = useParams<{ gameId: string }>()
  const navigate = useNavigate()
  const userId = useAuthStore((s) => s.userId)

  const [gameState, setGameState] = useState<GameState | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [step, setStep] = useState(0)

  const loadGame = useCallback(async () => {
    if (!gameId) return
    setIsLoading(true)
    setError(null)
    try {
      const response = await api.getGameState(gameId)
      setGameState(response.gameState)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load game')
    } finally {
      setIsLoading(false)
    }
  }, [gameId])

  useEffect(() => {
    loadGame()
  }, [loadGame])

  const snapshots = useMemo(() => {
    if (!gameState || gameState.history.length === 0) return []
    const p1 = gameState.players[0]
    const p2 = gameState.players[1]
    if (!p1 || !p2) return []

    // dealerIndex in gameState is the *final* round's dealer.
    // Work backwards to find the round-1 dealer: dealer alternates each round.
    const totalRounds = gameState.history.filter((e) => e.type === 'RoundStarted').length
    const initialDealer = totalRounds % 2 === 1
      ? gameState.dealerIndex
      : 1 - gameState.dealerIndex

    return buildSnapshots(
      gameState.history,
      p1.id,
      p1.id === userId ? 'You' : p1.name,
      p2.id,
      p2.id === userId ? 'You' : p2.name,
      initialDealer,
    )
  }, [gameState, userId])

  // Determine which player is "you" vs opponent for display ordering
  const playerIndex = gameState?.players.findIndex((p) => p.id === userId) ?? 0
  const viewAsPlayer1 = playerIndex <= 0 // default to player 0 if not found

  const currentSnapshot = snapshots[step] ?? null
  const totalSteps = snapshots.length

  function goTo(s: number) {
    setStep(Math.max(0, Math.min(s, totalSteps - 1)))
  }

  if (isLoading) {
    return (
      <div className="max-w-lg mx-auto p-8 text-center">
        <div className="text-white/50 py-16 flex flex-col items-center gap-4">
          <div className="w-8 h-8 border-2 border-white/30 border-t-white/80 rounded-full animate-spin" />
          <span>Loading game...</span>
        </div>
      </div>
    )
  }

  if (error || !gameState) {
    return (
      <div className="max-w-lg mx-auto p-8 text-center">
        <div className="text-red-400 mb-4">{error ?? 'Game not found'}</div>
        <button onClick={() => navigate('/')} className="text-[var(--green-500)] bg-transparent border-none cursor-pointer">
          Back to Home
        </button>
      </div>
    )
  }

  if (totalSteps === 0) {
    return (
      <div className="max-w-lg mx-auto p-8 text-center">
        <div className="text-white/50">No history events to replay.</div>
      </div>
    )
  }

  return (
    <div className="max-w-lg lg:max-w-3xl mx-auto p-2 lg:p-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <button
          onClick={() => navigate(-1)}
          className="text-white/60 hover:text-white bg-transparent border-none cursor-pointer text-sm"
        >
          &larr; Back
        </button>
        <h1 className="text-lg font-bold text-[var(--text-1)]">Game Replay</h1>
        <button
          onClick={() => navigate(`/analysis/${gameId}`)}
          className="text-white/60 hover:text-white bg-transparent border-none cursor-pointer text-sm"
        >
          Analysis &rarr;
        </button>
      </div>

      {currentSnapshot && (
        <ReplayBoard
          snapshot={currentSnapshot}
          viewAsPlayer1={viewAsPlayer1}
        />
      )}

      {/* Transport controls */}
      <div className="mt-4 space-y-3">
        {/* Event description */}
        {currentSnapshot && (
          <div className="text-center">
            <div className="text-white text-sm font-medium">{currentSnapshot.description}</div>
            {currentSnapshot.scoring && (
              <div className="text-[var(--green-400)] text-sm">{currentSnapshot.scoring}</div>
            )}
          </div>
        )}

        {/* Progress bar */}
        <div className="relative">
          <input
            type="range"
            min={0}
            max={totalSteps - 1}
            value={step}
            onChange={(e) => goTo(Number(e.target.value))}
            className="w-full accent-[var(--gold)] h-1.5 bg-white/10 rounded-full appearance-none cursor-pointer
              [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:h-4
              [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-[var(--gold)]
              [&::-webkit-slider-thumb]:cursor-pointer [&::-webkit-slider-thumb]:shadow-md"
          />
        </div>

        {/* Buttons */}
        <div className="flex items-center justify-center gap-3">
          <button
            onClick={() => goTo(0)}
            disabled={step === 0}
            className="px-3 py-1.5 bg-white/10 text-white rounded hover:bg-white/20 disabled:opacity-30 border-none cursor-pointer text-sm"
          >
            &#x23EE;
          </button>
          <button
            onClick={() => goTo(step - 1)}
            disabled={step === 0}
            className="px-4 py-1.5 bg-white/10 text-white rounded hover:bg-white/20 disabled:opacity-30 border-none cursor-pointer text-sm font-bold"
          >
            &#x25C0;
          </button>
          <span className="text-white/50 text-sm min-w-[80px] text-center">
            {step + 1} / {totalSteps}
          </span>
          <button
            onClick={() => goTo(step + 1)}
            disabled={step === totalSteps - 1}
            className="px-4 py-1.5 bg-white/10 text-white rounded hover:bg-white/20 disabled:opacity-30 border-none cursor-pointer text-sm font-bold"
          >
            &#x25B6;
          </button>
          <button
            onClick={() => goTo(totalSteps - 1)}
            disabled={step === totalSteps - 1}
            className="px-3 py-1.5 bg-white/10 text-white rounded hover:bg-white/20 disabled:opacity-30 border-none cursor-pointer text-sm"
          >
            &#x23ED;
          </button>
        </div>

        {/* Round jump buttons */}
        <RoundJumper snapshots={snapshots} currentStep={step} onJump={goTo} />
      </div>
    </div>
  )
}

/** Buttons to quickly jump to the start of each round */
function RoundJumper({
  snapshots,
  currentStep,
  onJump,
}: {
  snapshots: ReplaySnapshot[]
  currentStep: number
  onJump: (step: number) => void
}) {
  const roundStarts = useMemo(() => {
    const starts: { round: number; step: number }[] = []
    for (let i = 0; i < snapshots.length; i++) {
      if (snapshots[i].event.type === 'RoundStarted') {
        starts.push({ round: snapshots[i].roundNumber, step: i })
      }
    }
    return starts
  }, [snapshots])

  if (roundStarts.length <= 1) return null

  const currentRound = snapshots[currentStep]?.roundNumber ?? 0

  return (
    <div className="flex items-center justify-center gap-1.5 flex-wrap">
      <span className="text-white/40 text-xs mr-1">Round:</span>
      {roundStarts.map(({ round, step }) => (
        <button
          key={round}
          onClick={() => onJump(step)}
          className={`px-2.5 py-1 rounded text-xs border-none cursor-pointer ${
            round === currentRound
              ? 'bg-[var(--gold)] text-black font-bold'
              : 'bg-white/10 text-white/60 hover:bg-white/20'
          }`}
        >
          {round}
        </button>
      ))}
    </div>
  )
}

/** The visual board showing a replay snapshot */
function ReplayBoard({
  snapshot,
  viewAsPlayer1,
}: {
  snapshot: ReplaySnapshot
  viewAsPlayer1: boolean
}) {
  const you = viewAsPlayer1 ? snapshot.player1 : snapshot.player2
  const them = viewAsPlayer1 ? snapshot.player2 : snapshot.player1
  const isDealer = viewAsPlayer1
    ? snapshot.dealerIndex === 0
    : snapshot.dealerIndex === 1

  return (
    <div className="relative">
      <CribbageBoard
        playerScore={you.score}
        opponentScore={them.score}
      />

      <div className="pt-7 pl-7 pr-7 flex flex-col gap-2">
        {/* Opponent info */}
        <div className="flex items-center justify-between px-2">
          <div>
            <span className="text-white/60 text-xs">{them.name}</span>
            <span className="text-white font-bold text-lg ml-2">{them.score}</span>
          </div>
          <div className="flex items-center gap-2">
            {isDealer && <span className="text-white/30 text-xs">You deal</span>}
            {!isDealer && <span className="text-white/30 text-xs">They deal</span>}
            <span className="text-white/20 text-xs">R{snapshot.roundNumber}</span>
          </div>
        </div>

        {/* Opponent hand — face up in replay */}
        <ReplayHand
          cards={them.hand}
          highlightCards={snapshot.highlightCards}
          label={null}
        />

        {/* Stage badge */}
        <div className="text-center">
          <span className="text-white/40 text-xs px-2 py-0.5 bg-white/5 rounded-full">
            {snapshot.stage}
          </span>
        </div>

        {/* Center area: cut card + played cards or counting hand */}
        <div className="flex items-start justify-center gap-4 min-h-[70px]">
          {snapshot.cutCard && (
            <div className="flex flex-col items-center gap-1">
              <span className="text-white/40 text-xs">Cut</span>
              <CardWidget card={snapshot.cutCard} faceUp width={48} height={67} />
            </div>
          )}

          {/* Show played cards during pegging */}
          {snapshot.playedCards.length > 0 && snapshot.stage === 'Pegging' && (
            <div className="flex flex-col items-center gap-1">
              <span className="text-white/40 text-xs">Count: {snapshot.peggingCount}</span>
              <div className="flex gap-1 flex-wrap justify-center">
                {snapshot.playedCards.map((card, i) => (
                  <MiniReplayCard key={`${card.rank}-${card.suit}-${i}`} card={card} />
                ))}
              </div>
            </div>
          )}

          {/* Show counting hand / crib */}
          {snapshot.countingHand && (
            <div className="flex flex-col items-center gap-1">
              <span className="text-white/40 text-xs">
                {snapshot.cribCards ? 'Crib' : 'Hand'}
              </span>
              <div className="flex gap-1 flex-wrap justify-center">
                {snapshot.countingHand.map((card, i) => (
                  <MiniReplayCard key={`${card.rank}-${card.suit}-${i}`} card={card} />
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Your hand — face up in replay */}
        <ReplayHand
          cards={you.hand}
          highlightCards={snapshot.highlightCards}
          label="Your Hand"
        />

        {/* Your info */}
        <div className="flex items-center justify-between px-2">
          <div>
            <span className="text-[var(--green-400)] text-xs font-medium">{you.name}</span>
            <span className="text-white font-bold text-lg ml-2">{you.score}</span>
          </div>
        </div>
      </div>
    </div>
  )
}

/** Show a fan of cards in replay mode (all face up, no interaction) */
function ReplayHand({
  cards,
  highlightCards,
  label,
}: {
  cards: PlayingCard[]
  highlightCards: PlayingCard[]
  label: string | null
}) {
  if (cards.length === 0) return <div className="h-3" />

  const cardWidth = 48
  const cardHeight = 67
  const overlap = Math.min(cardWidth * 0.65, (Math.min(400, window.innerWidth - 32) - cardWidth) / Math.max(cards.length - 1, 1))
  const stackWidth = cardWidth + (cards.length - 1) * overlap

  const isHighlighted = (card: PlayingCard) =>
    highlightCards.some((h) => h.rank === card.rank && h.suit === card.suit)

  return (
    <div>
      {label && <div className="text-white/40 text-xs mb-1 text-center">{label}</div>}
      <div className="flex justify-center">
        <div className="relative" style={{ width: stackWidth, height: cardHeight + 4 }}>
          {cards.map((card, i) => (
            <div
              key={`${card.rank}-${card.suit}-${i}`}
              className="absolute bottom-0"
              style={{
                left: i * overlap,
                zIndex: i,
                opacity: isHighlighted(card) ? 1 : 0.7,
              }}
            >
              <CardWidget
                card={card}
                faceUp
                width={cardWidth}
                height={cardHeight}
              />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

/** Small card for play area display */
function MiniReplayCard({ card }: { card: PlayingCard }) {
  const color = isRedSuit(card.suit) ? 'var(--card-red)' : 'var(--card-black)'
  return (
    <div className="w-9 h-12 rounded border border-white/20 bg-[var(--card-white)] flex flex-col items-center justify-center text-xs">
      <span style={{ color }}>{RANK_DISPLAY[card.rank]}</span>
      <span style={{ color }}>{SUIT_SYMBOL[card.suit]}</span>
    </div>
  )
}
