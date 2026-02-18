import { useEffect } from 'react'
import { useParams, useNavigate } from 'react-router'
import { useGameStore, isLocalGame } from './game-store'
import { useAuthStore } from '@/auth/auth-store'
import { GameStage, GAME_STAGE_DISPLAY } from '@/models/game-state'
import { RANK_DISPLAY, SUIT_SYMBOL, isRedSuit, RANK_PEGGING_VALUE } from '@/models/card'
import type { PlayingCard } from '@/models'

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
        <div className="text-white/50">Loading game...</div>
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

  const playerIndex = gameState.players.findIndex((p) => p.id === userId)
  const player = playerIndex >= 0 ? gameState.players[playerIndex] : gameState.players[0]
  const opponent = gameState.players[playerIndex >= 0 ? 1 - playerIndex : 1]
  const isMyTurn = gameState.currentPlayerId === userId
  const stage = gameState.stage

  function handleCardClick(index: number) {
    if (stage === GameStage.DISCARDING_TO_CRIB && isMyTurn) {
      toggleCardSelection(index)
    } else if (stage === GameStage.PEGGING && isMyTurn) {
      const card = player.hand[index]
      if (card) playCard(card)
    }
  }

  function handleDiscard() {
    const cards = Array.from(selectedCardIndices).map((i) => player.hand[i])
    if (cards.length === 2) {
      discardCards(cards)
    }
  }

  function canPlayCard(card: PlayingCard): boolean {
    return gameState!.peggingCount + RANK_PEGGING_VALUE[card.rank] <= 31
  }

  const hasPlayableCard = stage === GameStage.PEGGING && player.hand.some(canPlayCard)

  return (
    <div className="max-w-2xl mx-auto p-4">
      {/* Error banner */}
      {error && (
        <div className="bg-red-500/20 border border-red-500/50 rounded px-4 py-2 mb-4 flex items-center justify-between">
          <span className="text-red-300 text-sm">{error}</span>
          <button onClick={clearError} className="text-red-300 bg-transparent border-none cursor-pointer">x</button>
        </div>
      )}

      {/* Scoreboard */}
      <div className="flex justify-between items-center mb-4 bg-white/5 rounded-lg px-4 py-3">
        <div className="text-center">
          <div className="text-white/60 text-xs">{player.name} (you)</div>
          <div className="text-white text-2xl font-bold">{player.score}</div>
        </div>
        <div className="text-center">
          <div className="text-[var(--gold)] text-sm font-semibold">
            {GAME_STAGE_DISPLAY[stage]}
          </div>
          {gameState.cutCard && (
            <div className="text-white/50 text-xs mt-1">
              Cut: {renderCardText(gameState.cutCard)}
            </div>
          )}
          {stage === GameStage.PEGGING && (
            <div className="text-white text-lg font-bold mt-1">{gameState.peggingCount}</div>
          )}
        </div>
        <div className="text-center">
          <div className="text-white/60 text-xs">{opponent.name}</div>
          <div className="text-white text-2xl font-bold">{opponent.score}</div>
        </div>
      </div>

      {/* Game over */}
      {stage === GameStage.GAME_OVER && (
        <div className="text-center bg-white/10 rounded-lg p-6 mb-4">
          <div className="text-2xl font-bold mb-2">
            {player.score >= 121 ? (
              <span className="text-[var(--gold)]">You Won!</span>
            ) : (
              <span className="text-red-400">You Lost</span>
            )}
          </div>
          <div className="text-white/60">
            {player.score} - {opponent.score}
          </div>
          <div className="mt-4 flex gap-2 justify-center">
            <button
              onClick={() => navigate(`/analysis/${gameState.gameId}`)}
              className="bg-white/10 text-white px-4 py-2 rounded hover:bg-white/20 border-none cursor-pointer"
            >
              Analysis
            </button>
            <button
              onClick={() => navigate('/')}
              className="bg-[var(--gold)] text-black px-4 py-2 rounded hover:bg-[var(--gold-light)] border-none cursor-pointer font-semibold"
            >
              New Game
            </button>
          </div>
        </div>
      )}

      {/* Player hand */}
      {player.hand.length > 0 && stage !== GameStage.GAME_OVER && (
        <div className="mb-4">
          <div className="text-white/50 text-xs mb-2">Your Hand</div>
          <div className="flex gap-2 justify-center flex-wrap">
            {player.hand.map((card, i) => {
              const isSelected = selectedCardIndices.has(i)
              const isPlayable = stage === GameStage.PEGGING ? canPlayCard(card) : true
              return (
                <button
                  key={`${card.rank}-${card.suit}`}
                  onClick={() => handleCardClick(i)}
                  disabled={!isMyTurn || (stage === GameStage.PEGGING && !isPlayable)}
                  className={`w-16 h-24 rounded-lg border-2 flex flex-col items-center justify-center font-bold cursor-pointer transition-all ${
                    isSelected
                      ? 'border-[var(--gold)] -translate-y-2 bg-[var(--card-white)]'
                      : 'border-white/20 bg-[var(--card-white)]'
                  } ${!isMyTurn || (stage === GameStage.PEGGING && !isPlayable) ? 'opacity-40 cursor-not-allowed' : 'hover:-translate-y-1'}`}
                >
                  <span className={isRedSuit(card.suit) ? 'text-[var(--card-red)]' : 'text-[var(--card-black)]'}>
                    {RANK_DISPLAY[card.rank]}
                  </span>
                  <span className={`text-xl ${isRedSuit(card.suit) ? 'text-[var(--card-red)]' : 'text-[var(--card-black)]'}`}>
                    {SUIT_SYMBOL[card.suit]}
                  </span>
                </button>
              )
            })}
          </div>
        </div>
      )}

      {/* Action buttons */}
      <div className="flex gap-2 justify-center flex-wrap">
        {stage === GameStage.DISCARDING_TO_CRIB && isMyTurn && (
          <button
            onClick={handleDiscard}
            disabled={selectedCardIndices.size !== 2 || isDiscarding}
            className="bg-[var(--gold)] text-black px-6 py-2 rounded font-semibold hover:bg-[var(--gold-light)] disabled:opacity-50 border-none cursor-pointer"
          >
            {isDiscarding ? 'Discarding...' : `Discard (${selectedCardIndices.size}/2)`}
          </button>
        )}

        {stage === GameStage.CUTTING && isMyTurn && (
          <button
            onClick={cutDeck}
            className="bg-[var(--gold)] text-black px-6 py-2 rounded font-semibold hover:bg-[var(--gold-light)] border-none cursor-pointer"
          >
            Cut Deck
          </button>
        )}

        {stage === GameStage.PEGGING && isMyTurn && !hasPlayableCard && (
          <button
            onClick={sayGo}
            className="bg-[var(--gold)] text-black px-6 py-2 rounded font-semibold hover:bg-[var(--gold-light)] border-none cursor-pointer"
          >
            Go
          </button>
        )}

        {stage === GameStage.COUNTING && isMyTurn && (
          <button
            onClick={countHand}
            className="bg-[var(--gold)] text-black px-6 py-2 rounded font-semibold hover:bg-[var(--gold-light)] border-none cursor-pointer"
          >
            Count Hand
          </button>
        )}

        {!isMyTurn && stage !== GameStage.GAME_OVER && stage !== GameStage.DEALING && (
          <div className="text-white/50 text-sm py-2">Waiting for {opponent.name}...</div>
        )}

        {stage !== GameStage.GAME_OVER && (
          <button
            onClick={resign}
            className="text-red-400/60 text-sm bg-transparent border-none cursor-pointer hover:text-red-400 ml-4"
          >
            Resign
          </button>
        )}
      </div>

      {/* Played cards (pegging) */}
      {gameState.playedCards.length > 0 && stage === GameStage.PEGGING && (
        <div className="mt-4">
          <div className="text-white/50 text-xs mb-2">Played Cards</div>
          <div className="flex gap-1 justify-center flex-wrap">
            {gameState.playedCards.map((card, i) => (
              <div
                key={i}
                className="w-10 h-14 rounded border border-white/20 bg-[var(--card-white)] flex flex-col items-center justify-center text-xs"
              >
                <span className={isRedSuit(card.suit) ? 'text-[var(--card-red)]' : 'text-[var(--card-black)]'}>
                  {RANK_DISPLAY[card.rank]}
                </span>
                <span className={isRedSuit(card.suit) ? 'text-[var(--card-red)]' : 'text-[var(--card-black)]'}>
                  {SUIT_SYMBOL[card.suit]}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

function renderCardText(card: PlayingCard): string {
  return `${RANK_DISPLAY[card.rank]}${SUIT_SYMBOL[card.suit]}`
}
