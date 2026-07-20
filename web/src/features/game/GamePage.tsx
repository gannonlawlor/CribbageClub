import { useEffect, useMemo, useState, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router'
import { useGameStore, isLocalGame } from './game-store'
import { useAuthStore } from '@/auth/auth-store'
import * as api from '@/api/rest-client'
import { GameStage } from '@/models/game-state'
import { RANK_PEGGING_VALUE } from '@/models/card'
import type { PlayingCard } from '@/models'
import { CribbageBoard } from './components/CribbageBoard'
import { CribbageBoardStandard } from './components/CribbageBoardStandard'
import { HandFan, OpponentHand } from './components/HandFan'
import { PlayArea } from './components/PlayArea'
import { StageIndicator } from './components/StageIndicator'
import { GameControls } from './components/GameControls'
import { CutCard } from './components/CutCard'
import { ScorePopupOverlay } from './components/ScorePopup'
import { HistoryLog } from './components/HistoryLog'

/** Fetch Glicko ratings for the players in the game. AI opponents and
    unknown ids simply resolve to no rating. */
function usePlayerRatings(players: { id: string }[]): Record<string, number> {
  const [ratings, setRatings] = useState<Record<string, number>>({})
  const ids = players.map((p) => p.id).join(',')

  useEffect(() => {
    let cancelled = false
    for (const id of ids.split(',')) {
      if (!id) continue
      api.getProfile(id)
        .then((profile) => {
          if (!cancelled) setRatings((r) => ({ ...r, [id]: profile.rating }))
        })
        .catch(() => {})
    }
    return () => { cancelled = true }
  }, [ids])

  return ratings
}

function useIsDesktop(): boolean {
  const query = '(min-width: 1024px)'
  const [matches, setMatches] = useState(() =>
    typeof window !== 'undefined' ? window.matchMedia(query).matches : false,
  )

  useEffect(() => {
    const mql = window.matchMedia(query)
    const handler = (e: MediaQueryListEvent) => setMatches(e.matches)
    mql.addEventListener('change', handler)
    return () => mql.removeEventListener('change', handler)
  }, [])

  return matches
}

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
  const isDesktop = useIsDesktop()
  const ratings = usePlayerRatings(gameState.players)
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

  const canPlayCard = useCallback(
    (card: PlayingCard): boolean => {
      return gameState.peggingCount + RANK_PEGGING_VALUE[card.rank] <= 31
    },
    [gameState.peggingCount],
  )

  const hasPlayableCard = stage === GameStage.PEGGING && player.hand.some(canPlayCard)

  // Auto-go when player can't play during pegging
  // Include gameState in deps so the effect re-fires after each state update
  // (e.g. when hand is empty and the derived booleans don't change between rounds)
  useEffect(() => {
    if (stage === GameStage.PEGGING && isMyTurn && !hasPlayableCard) {
      const timer = setTimeout(() => onGo(), 500)
      return () => clearTimeout(timer)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stage, isMyTurn, hasPlayableCard, onGo, gameState])

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

  if (isDesktop) {
    return (
      <DesktopGameBoard
        gameState={gameState}
        ratings={ratings}
        player={player}
        opponent={opponent}
        isMyTurn={isMyTurn}
        isDealer={isDealer}
        stage={stage}
        error={error}
        isDiscarding={isDiscarding}
        selectedCardIndices={selectedCardIndices}
        playerNames={playerNames}
        userId={userId}
        onCardTap={handleCardTap}
        onDiscard={handleDiscard}
        onCut={onCut}
        onCount={onCount}
        onResign={onResign}
        onClearError={onClearError}
        onNavigate={onNavigate}
      />
    )
  }

  return (
    <MobileGameBoard
      gameState={gameState}
      ratings={ratings}
      player={player}
      opponent={opponent}
      isMyTurn={isMyTurn}
      isDealer={isDealer}
      stage={stage}
      error={error}
      isDiscarding={isDiscarding}
      selectedCardIndices={selectedCardIndices}
      playerNames={playerNames}
      userId={userId}
      onCardTap={handleCardTap}
      onDiscard={handleDiscard}
      onCut={onCut}
      onCount={onCount}
      onResign={onResign}
      onClearError={onClearError}
      onNavigate={onNavigate}
    />
  )
}

interface InnerBoardProps {
  gameState: import('@/models').GameState
  ratings: Record<string, number>
  player: import('@/models').Player
  opponent: import('@/models').Player
  isMyTurn: boolean
  isDealer: boolean
  stage: GameStage
  error: string | null
  isDiscarding: boolean
  selectedCardIndices: Set<number>
  playerNames: Record<string, string>
  userId: string
  onCardTap: (index: number) => void
  onDiscard: () => void
  onCut: () => void
  onCount: () => void
  onResign: () => void
  onClearError: () => void
  onNavigate: (path: string) => void
}

/* ───────────────────── Desktop layout ───────────────────── */

function DesktopGameBoard({
  gameState,
  ratings,
  player,
  opponent,
  isMyTurn,
  isDealer,
  stage,
  error,
  isDiscarding,
  selectedCardIndices,
  playerNames,
  userId,
  onCardTap,
  onDiscard,
  onCut,
  onCount,
  onResign,
  onClearError,
  onNavigate,
}: InnerBoardProps) {
  return (
    <div className="max-w-6xl mx-auto px-6 py-4 relative">
      {/* Error banner */}
      {error && (
        <div className="bg-red-500/20 border border-red-500/50 rounded-lg px-4 py-2 mb-4 flex items-center justify-between">
          <span className="text-red-300 text-sm">{error}</span>
          <button onClick={onClearError} className="text-red-300 bg-transparent border-none cursor-pointer text-sm ml-4">x</button>
        </div>
      )}

      <div className="flex gap-8">
        {/* Main game column */}
        <div className="flex-1 min-w-0 flex flex-col gap-6 relative">
          {/* Opponent bar */}
          <PlayerBar
            name={opponent.name}
            rating={ratings[opponent.id]}
            score={opponent.score}
            isDealer={!isDealer}
            isTurn={gameState.currentPlayerId === opponent.id && stage !== GameStage.GAME_OVER}
          />

          {/* Opponent hand */}
          <div className="flex justify-center">
            <OpponentHand cardCount={opponent.hand.length} cardWidth={52} cardHeight={73} />
          </div>

          {/* Stage indicator */}
          <StageIndicator
            stage={stage}
            isMyTurn={isMyTurn}
            isDealer={isDealer}
            selectedCardCount={selectedCardIndices.size}
          />

          {/* Center area: cut card + play area */}
          <div className="flex items-center justify-center gap-8 min-h-[140px] py-2">
            <CutCard cutCard={gameState.cutCard} width={88} height={123} />

            {stage === GameStage.PEGGING && (
              <PlayArea
                playedCards={gameState.playedCards}
                peggingCount={gameState.peggingCount}
                miniCardWidth={64}
                miniCardHeight={90}
              />
            )}
          </div>

          {/* Waiting indicator */}
          {!isMyTurn && stage !== GameStage.GAME_OVER && stage !== GameStage.DEALING && (
            <div className="text-white/40 text-sm text-center animate-pulse">
              Waiting for {opponent.name}...
            </div>
          )}

          {/* Game over */}
          {stage === GameStage.GAME_OVER && (
            <div className="text-center bg-[var(--surface)] border border-[var(--border)] rounded-xl p-6 mx-auto max-w-md">
              <div className="text-2xl font-extrabold mb-2">
                {player.score >= 121 ? (
                  <span className="text-[var(--accent)]">You Won</span>
                ) : (
                  <span className="text-red-400">You Lost</span>
                )}
              </div>
              <div className="text-white/60 mb-4 tabular-nums">
                {player.score} &ndash; {opponent.score}
              </div>
              <div className="flex gap-3 justify-center">
                <button
                  onClick={() => onNavigate(`/analysis/${gameState.gameId}`)}
                  className="bg-black/25 text-white px-5 py-2 rounded-md hover:bg-black/40 border border-[var(--border)] cursor-pointer font-semibold"
                >
                  Game Review
                </button>
                <button
                  onClick={() => onNavigate('/')}
                  className="bg-[var(--accent)] text-white px-5 py-2 rounded-md hover:bg-[var(--accent-hover)] border-b-2 border-[var(--accent-dark)] cursor-pointer font-bold"
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
            onDiscard={onDiscard}
            onCut={onCut}
            onCount={onCount}
          />

          {/* Player hand */}
          {player.hand.length > 0 && stage !== GameStage.GAME_OVER && (
            <div>
              <HandFan
                cards={player.hand}
                selectedIndices={selectedCardIndices}
                enabled={isMyTurn}
                onCardTap={onCardTap}
                cardWidth={100}
                cardHeight={140}
                maxWidth={700}
              />
            </div>
          )}

          {/* Player bar */}
          <PlayerBar
            name={player.name}
            rating={ratings[player.id]}
            score={player.score}
            isDealer={isDealer}
            isTurn={isMyTurn && stage !== GameStage.GAME_OVER}
            isSelf
          />

          {/* Score popups */}
          <ScorePopupOverlay history={gameState.history} playerId={userId} />
        </div>

        {/* Right sidebar: cribbage board + history */}
        <div className="w-80 flex-shrink-0">
          <div className="sticky top-4 flex flex-col gap-4 h-[calc(100vh-5rem)]">
            {/* Cribbage board */}
            <div className="bg-[var(--surface)] border border-[var(--border)] rounded-lg overflow-hidden">
              <div className="h-48">
                <CribbageBoardStandard
                  playerScore={player.score}
                  opponentScore={opponent.score}
                />
              </div>
              <div className="flex justify-between text-xs px-3 py-2 border-t border-[var(--border)]">
                <div className="flex items-center gap-1.5">
                  <span className="inline-block w-2.5 h-2.5 rounded-full" style={{ backgroundColor: '#FFD54F' }} />
                  <span className="text-white/50">You: {player.score}</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="inline-block w-2.5 h-2.5 rounded-full" style={{ backgroundColor: '#EEEEEE' }} />
                  <span className="text-white/50">{opponent.name}: {opponent.score}</span>
                </div>
              </div>
            </div>

            {/* Resign + History log */}
            <div className="flex-1 min-h-0 flex flex-col">
              {stage !== GameStage.GAME_OVER && onResign && (
                <div className="flex justify-end mb-1">
                  <button
                    onClick={onResign}
                    className="text-red-400/40 text-xs bg-transparent border-none cursor-pointer hover:text-red-400"
                  >
                    Resign
                  </button>
                </div>
              )}
              <div className="flex-1 min-h-0">
                <HistoryLog events={gameState.history} playerNames={playerNames} variant="sidebar" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

/** Chess.com-style player bar: avatar, name, rating, progress to 121, score. */
function PlayerBar({
  name,
  rating,
  score,
  isDealer,
  isTurn,
  isSelf = false,
  compact = false,
}: {
  name: string
  rating?: number
  score: number
  isDealer: boolean
  isTurn: boolean
  isSelf?: boolean
  compact?: boolean
}) {
  const pct = Math.min((score / 121) * 100, 100)
  return (
    <div
      className={`flex items-center bg-[var(--surface)] rounded-md border transition-colors ${
        isTurn ? 'border-[var(--accent)]/70' : 'border-[var(--border)]'
      } ${compact ? 'gap-2 px-2 py-1.5' : 'gap-3 px-4 py-2.5'}`}
    >
      <div
        className={`rounded-md flex items-center justify-center font-bold ${
          isSelf ? 'bg-[var(--accent)] text-white' : 'bg-black/30 text-white/60'
        } ${compact ? 'w-7 h-7 text-xs' : 'w-9 h-9 text-sm'}`}
      >
        {name[0]?.toUpperCase() ?? '?'}
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className={`text-white font-semibold truncate ${compact ? 'text-xs' : 'text-sm'}`}>
            {isSelf ? 'You' : name}
          </span>
          {rating != null && (
            <span className="text-white/40 text-xs tabular-nums">({Math.round(rating)})</span>
          )}
          {isDealer && (
            <span className="text-[9px] font-bold uppercase tracking-wider bg-black/30 text-white/50 rounded px-1.5 py-0.5">
              Dealer
            </span>
          )}
          {isTurn && <span className="w-1.5 h-1.5 rounded-full bg-[var(--accent)] animate-pulse" />}
        </div>
        <div className={`h-1 bg-black/30 rounded-full overflow-hidden ${compact ? 'w-20 mt-1' : 'w-28 mt-1.5'}`}>
          <div
            className={`h-full rounded-full ${isSelf ? 'bg-[var(--accent)]' : 'bg-white/40'}`}
            style={{ width: `${pct}%` }}
          />
        </div>
      </div>
      <span className={`text-white font-extrabold tabular-nums ${compact ? 'text-lg' : 'text-2xl'}`}>
        {score}
      </span>
    </div>
  )
}

/* ───────────────────── Mobile layout ───────────────────── */

function MobileGameBoard({
  gameState,
  ratings,
  player,
  opponent,
  isMyTurn,
  isDealer,
  stage,
  error,
  isDiscarding,
  selectedCardIndices,
  playerNames,
  userId,
  onCardTap,
  onDiscard,
  onCut,
  onCount,
  onResign,
  onClearError,
  onNavigate,
}: InnerBoardProps) {
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
        <div className="flex flex-col gap-2" style={{ paddingTop: 28, paddingLeft: 28, paddingRight: 28 }}>
          {/* Opponent bar */}
          <PlayerBar
            name={opponent.name}
            rating={ratings[opponent.id]}
            score={opponent.score}
            isDealer={!isDealer}
            isTurn={gameState.currentPlayerId === opponent.id && stage !== GameStage.GAME_OVER}
            compact
          />

          {/* Opponent hand (face-down) */}
          <OpponentHand cardCount={opponent.hand.length} cardWidth={36} cardHeight={50} />

          {/* Stage indicator */}
          <StageIndicator
            stage={stage}
            isMyTurn={isMyTurn}
            isDealer={isDealer}
            selectedCardCount={selectedCardIndices.size}
          />

          {/* Center area: cut card + play area */}
          <div className="flex items-start justify-center gap-4 min-h-[80px]">
            <CutCard cutCard={gameState.cutCard} width={48} height={67} />

            {stage === GameStage.PEGGING && (
              <PlayArea
                playedCards={gameState.playedCards}
                peggingCount={gameState.peggingCount}
                miniCardWidth={40}
                miniCardHeight={56}
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
            <div className="text-center bg-[var(--surface)] border border-[var(--border)] rounded-lg p-4">
              <div className="text-xl font-extrabold mb-1">
                {player.score >= 121 ? (
                  <span className="text-[var(--accent)]">You Won</span>
                ) : (
                  <span className="text-red-400">You Lost</span>
                )}
              </div>
              <div className="text-white/60 text-sm mb-3 tabular-nums">
                {player.score} - {opponent.score}
              </div>
              <div className="flex gap-2 justify-center">
                <button
                  onClick={() => onNavigate(`/analysis/${gameState.gameId}`)}
                  className="bg-black/25 text-white px-4 py-1.5 rounded-md hover:bg-black/40 border border-[var(--border)] cursor-pointer text-sm font-semibold"
                >
                  Game Review
                </button>
                <button
                  onClick={() => onNavigate('/')}
                  className="bg-[var(--accent)] text-white px-4 py-1.5 rounded-md hover:bg-[var(--accent-hover)] border-b-2 border-[var(--accent-dark)] cursor-pointer font-bold text-sm"
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
            onDiscard={onDiscard}
            onCut={onCut}
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
                onCardTap={onCardTap}
                cardWidth={64}
                cardHeight={90}
              />
            </div>
          )}

          {/* Player bar */}
          <PlayerBar
            name={player.name}
            rating={ratings[player.id]}
            score={player.score}
            isDealer={isDealer}
            isTurn={isMyTurn && stage !== GameStage.GAME_OVER}
            isSelf
            compact
          />
        </div>

        {/* Score popups */}
        <ScorePopupOverlay history={gameState.history} playerId={userId} />
      </div>

      {/* History log — inline below board */}
      <div className="mt-2">
        <HistoryLog events={gameState.history} playerNames={playerNames} />
      </div>
    </div>
  )
}
