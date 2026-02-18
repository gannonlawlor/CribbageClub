import { useEffect, useMemo } from 'react'
import { useParams, useNavigate } from 'react-router'
import { useGameStore, isLocalGame } from './game-store'
import { useAuthStore } from '@/auth/auth-store'
import { GameStage } from '@/models/game-state'
import { RANK_PEGGING_VALUE } from '@/models/card'
import type { PlayingCard } from '@/models'
import { CribbageBoard } from './components/CribbageBoard'
import { HandFan, OpponentHand } from './components/HandFan'
import { PlayArea } from './components/PlayArea'
import { StageIndicator } from './components/StageIndicator'
import { GameControls } from './components/GameControls'
import { CutCard } from './components/CutCard'
import { ScorePopupOverlay } from './components/ScorePopup'
import { HistoryLog } from './components/HistoryLog'

export function GamePage() {
  const { gameId } = useParams<{ gameId: string }>()
  const navigate = useNavigate()
  const userId = useAuthStore((s) => s.userId)
  const {
    gameState,
    isLoading,
    error,
    isDiscarding,
    selectedCardIndices,
    loadGame,
    discardCards,
    playCard,
    cutDeck,
    sayGo,
    countHand,
    resign,
    toggleCardSelection,
    clearError,
    reset,
  } = useGameStore()

  useEffect(() => {
    if (gameId && !isLocalGame(gameId)) {
      loadGame(gameId)
    }
    return () => reset()
  }, [gameId, loadGame, reset])

  if (isLocalGame(gameId ?? '')) {
    return (
      <div className="max-w-4xl mx-auto p-8 text-center">
        <h1 className="text-2xl font-bold text-[var(--gold)] mb-4">Local Game</h1>
        <p className="text-white/50">Local AI games require the WASM engine (coming soon).</p>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="max-w-4xl mx-auto p-8 text-center">
        <div className="text-white/50 py-16">Loading game...</div>
      </div>
    )
  }

  if (error && !gameState) {
    return (
      <div className="max-w-4xl mx-auto p-8 text-center">
        <div className="text-red-400 mb-4">{error}</div>
        <button onClick={() => navigate('/')} className="text-[var(--gold)] bg-transparent border-none cursor-pointer">
          Back to Home
        </button>
      </div>
    )
  }

  if (!gameState) return null

  return (
    <GameBoard
      gameState={gameState}
      userId={userId ?? ''}
      error={error}
      isDiscarding={isDiscarding}
      selectedCardIndices={selectedCardIndices}
      onCardTap={toggleCardSelection}
      onDiscard={(cards) => discardCards(cards)}
      onPlayCard={(card) => playCard(card)}
      onCut={cutDeck}
      onGo={sayGo}
      onCount={countHand}
      onResign={resign}
      onClearError={clearError}
      onNavigate={navigate}
    />
  )
}

interface GameBoardProps {
  gameState: import('@/models').GameState
  userId: string
  error: string | null
  isDiscarding: boolean
  selectedCardIndices: Set<number>
  onCardTap: (index: number) => void
  onDiscard: (cards: PlayingCard[]) => void
  onPlayCard: (card: PlayingCard) => void
  onCut: () => void
  onGo: () => void
  onCount: () => void
  onResign: () => void
  onClearError: () => void
  onNavigate: (path: string) => void
}

function GameBoard({
  gameState,
  userId,
  error,
  isDiscarding,
  selectedCardIndices,
  onCardTap,
  onDiscard,
  onPlayCard,
  onCut,
  onGo,
  onCount,
  onResign,
  onClearError,
  onNavigate,
}: GameBoardProps) {
  const playerIndex = gameState.players.findIndex((p) => p.id === userId)
  const player = playerIndex >= 0 ? gameState.players[playerIndex] : gameState.players[0]
  const opponent = gameState.players[playerIndex >= 0 ? 1 - playerIndex : 1]
  const isMyTurn = gameState.currentPlayerId === userId
  const isDealer = gameState.dealerIndex === playerIndex
  const stage = gameState.stage

  const playerNames = useMemo(() => {
    const map: Record<string, string> = {}
    for (const p of gameState.players) {
      map[p.id] = p.id === userId ? 'You' : p.name
    }
    return map
  }, [gameState.players, userId])

  function canPlayCard(card: PlayingCard): boolean {
    return gameState.peggingCount + RANK_PEGGING_VALUE[card.rank] <= 31
  }

  const hasPlayableCard = stage === GameStage.PEGGING && player.hand.some(canPlayCard)

  function handleCardTap(index: number) {
    if (stage === GameStage.DISCARDING_TO_CRIB && isMyTurn) {
      onCardTap(index)
    } else if (stage === GameStage.PEGGING && isMyTurn) {
      const card = player.hand[index]
      if (card && canPlayCard(card)) {
        onPlayCard(card)
      }
    }
  }

  function handleDiscard() {
    const cards = Array.from(selectedCardIndices).map((i) => player.hand[i])
    if (cards.length === 2) onDiscard(cards)
  }

  return (
    <div className="max-w-lg mx-auto p-2 relative">
      {/* Error banner */}
      {error && (
        <div className="bg-red-500/20 border border-red-500/50 rounded px-3 py-1.5 mb-2 flex items-center justify-between">
          <span className="text-red-300 text-xs">{error}</span>
          <button onClick={onClearError} className="text-red-300 bg-transparent border-none cursor-pointer text-xs">x</button>
        </div>
      )}

      {/* Game area with cribbage board wrapping three edges */}
      <div className="relative">
        <CribbageBoard
          playerScore={player.score}
          opponentScore={opponent.score}
        />

        {/* Content inside the board frame */}
        <div className="pt-7 pl-7 pr-7 flex flex-col gap-2">
          {/* Opponent info */}
          <div className="flex items-center justify-between px-2">
            <div>
              <span className="text-white/60 text-xs">{opponent.name}</span>
              <span className="text-white font-bold text-lg ml-2">{opponent.score}</span>
            </div>
            {isDealer && <span className="text-white/30 text-xs">You deal</span>}
            {!isDealer && <span className="text-white/30 text-xs">They deal</span>}
          </div>

          {/* Opponent hand (face-down) */}
          <OpponentHand cardCount={opponent.hand.length} />

          {/* Stage indicator */}
          <StageIndicator
            stage={stage}
            isMyTurn={isMyTurn}
            isDealer={isDealer}
            selectedCardCount={selectedCardIndices.size}
          />

          {/* Center area: cut card + play area */}
          <div className="flex items-start justify-center gap-4 min-h-[80px]">
            <CutCard cutCard={gameState.cutCard} />

            {stage === GameStage.PEGGING && (
              <PlayArea
                playedCards={gameState.playedCards}
                peggingCount={gameState.peggingCount}
              />
            )}
          </div>

          {/* Waiting indicator */}
          {!isMyTurn && stage !== GameStage.GAME_OVER && stage !== GameStage.DEALING && (
            <div className="text-white/40 text-xs text-center animate-pulse">
              Waiting for {opponent.name}...
            </div>
          )}

          {/* Game over */}
          {stage === GameStage.GAME_OVER && (
            <div className="text-center bg-white/10 rounded-lg p-4">
              <div className="text-xl font-bold mb-1">
                {player.score >= 121 ? (
                  <span className="text-[var(--gold)]">You Won!</span>
                ) : (
                  <span className="text-red-400">You Lost</span>
                )}
              </div>
              <div className="text-white/60 text-sm mb-3">
                {player.score} - {opponent.score}
              </div>
              <div className="flex gap-2 justify-center">
                <button
                  onClick={() => onNavigate(`/analysis/${gameState.gameId}`)}
                  className="bg-white/10 text-white px-4 py-1.5 rounded hover:bg-white/20 border-none cursor-pointer text-sm"
                >
                  Analysis
                </button>
                <button
                  onClick={() => onNavigate('/')}
                  className="bg-[var(--gold)] text-black px-4 py-1.5 rounded hover:bg-[var(--gold-light)] border-none cursor-pointer font-semibold text-sm"
                >
                  New Game
                </button>
              </div>
            </div>
          )}

          {/* Controls */}
          <GameControls
            stage={stage}
            isMyTurn={isMyTurn}
            selectedCardCount={selectedCardIndices.size}
            isDiscarding={isDiscarding}
            canGo={!hasPlayableCard}
            onDiscard={handleDiscard}
            onCut={onCut}
            onGo={onGo}
            onCount={onCount}
            onResign={onResign}
          />

          {/* Player hand */}
          {player.hand.length > 0 && stage !== GameStage.GAME_OVER && (
            <div>
              <div className="text-white/40 text-xs mb-1 text-center">Your Hand</div>
              <HandFan
                cards={player.hand}
                selectedIndices={selectedCardIndices}
                enabled={isMyTurn}
                onCardTap={handleCardTap}
              />
            </div>
          )}

          {/* Player score */}
          <div className="flex items-center justify-between px-2">
            <div>
              <span className="text-[var(--gold)] text-xs font-medium">{player.name} (you)</span>
              <span className="text-white font-bold text-lg ml-2">{player.score}</span>
            </div>
          </div>
        </div>

        {/* Score popups */}
        <ScorePopupOverlay history={gameState.history} playerId={userId} />
      </div>

      {/* History log */}
      <div className="mt-2">
        <HistoryLog events={gameState.history} playerNames={playerNames} />
      </div>
    </div>
  )
}
