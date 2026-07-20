import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router'
import { usePracticePuzzleStore } from './practice-puzzle-store'
import { CardWidget } from '@/features/game/components/CardWidget'
import { KeepRankTile } from '@/features/daily-puzzle/components/KeepRankTile'
import { ExplainBottomSheet } from '@/features/daily-puzzle/components/ExplainBottomSheet'
import { cardsEqual, cardKey } from '@/models/card'
import type { PlayingCard } from '@/models'
import type { KeepOption } from '@/features/daily-puzzle/models'

export function PuzzlePage() {
  const navigate = useNavigate()
  const {
    puzzle,
    selectedCards,
    phase,
    playerRank,
    results,
    puzzleNumber,
    totalSolved,
    optimalCount,
    isSubmitting,
    loadPuzzle,
    toggleCard,
    submitKeep,
    nextPuzzle,
    reset,
  } = usePracticePuzzleStore()

  const [explainTarget, setExplainTarget] = useState<{
    hand: PlayingCard[]
    keep: PlayingCard[]
    discard: PlayingCard[]
    rank: number
    isDealer: boolean
  } | null>(null)

  useEffect(() => {
    loadPuzzle()
    return () => reset()
  }, [loadPuzzle, reset])

  if (!puzzle) {
    return (
      <div className="max-w-lg mx-auto p-8 text-center">
        <div className="w-8 h-8 border-2 border-white/30 border-t-white/80 rounded-full animate-spin mx-auto" />
      </div>
    )
  }

  const canSubmit = selectedCards.length === 4

  return (
    <div className="max-w-lg mx-auto flex flex-col min-h-[calc(100vh-4rem)]">
      {/* Header */}
      <div className="p-4 flex items-center">
        <button
          onClick={() => navigate('/')}
          className="text-white/60 bg-transparent border-none cursor-pointer text-lg hover:text-white mr-3"
        >
          &larr;
        </button>
        <div className="flex-1">
          <span className="text-white font-bold text-xl">Practice Puzzle</span>
          <div className="text-white/50 text-sm">Puzzle #{puzzleNumber}</div>
        </div>
        {totalSolved > 0 && (
          <div className="bg-white/10 rounded-full px-3 py-1 text-sm text-white/70">
            {optimalCount}/{totalSolved} optimal
          </div>
        )}
      </div>

      {phase === 'playing' ? (
        <PlayingPhase
          puzzle={puzzle}
          selectedCards={selectedCards}
          canSubmit={canSubmit}
          isSubmitting={isSubmitting}
          onToggle={toggleCard}
          onSubmit={submitKeep}
        />
      ) : (
        <RevealedPhase
          puzzle={puzzle}
          playerRank={playerRank}
          results={results}
          selectedCards={selectedCards}
          totalSolved={totalSolved}
          optimalCount={optimalCount}
          onExplain={(option) => setExplainTarget({
            hand: puzzle.hand,
            keep: option.keep,
            discard: option.discard,
            rank: option.rank,
            isDealer: puzzle.isDealer,
          })}
          onNext={nextPuzzle}
          onHome={() => navigate('/')}
        />
      )}

      {/* Explain bottom sheet */}
      {explainTarget && (
        <ExplainBottomSheet
          rank={explainTarget.rank}
          keep={explainTarget.keep}
          discard={explainTarget.discard}
          hand={explainTarget.hand}
          isDealer={explainTarget.isDealer}
          onClose={() => setExplainTarget(null)}
        />
      )}
    </div>
  )
}

function PlayingPhase({
  puzzle,
  selectedCards,
  canSubmit,
  isSubmitting,
  onToggle,
  onSubmit,
}: {
  puzzle: { hand: PlayingCard[]; isDealer: boolean }
  selectedCards: PlayingCard[]
  canSubmit: boolean
  isSubmitting: boolean
  onToggle: (card: PlayingCard) => void
  onSubmit: () => void
}) {
  return (
    <>
      <div className="flex-1" />

      {/* Instruction */}
      <div className="text-white/70 text-center px-6 mb-2">
        You are {puzzle.isDealer ? 'the dealer' : 'not the dealer'}.
        Choose the best 4 cards to keep.
      </div>

      {/* Selection counter */}
      <div className={`text-center text-sm mb-4 ${canSubmit ? 'text-[var(--green-400)]' : 'text-white/40'}`}>
        {selectedCards.length}/4 selected
      </div>

      {/* Card grid: 2 rows of 3 */}
      <div className="px-6 space-y-3 mb-6">
        <div className="flex justify-center gap-2">
          {puzzle.hand.slice(0, 3).map((card) => (
            <PuzzleCard
              key={cardKey(card)}
              card={card}
              selected={selectedCards.some((s) => cardsEqual(s, card))}
              onTap={() => onToggle(card)}
            />
          ))}
        </div>
        <div className="flex justify-center gap-2">
          {puzzle.hand.slice(3, 6).map((card) => (
            <PuzzleCard
              key={cardKey(card)}
              card={card}
              selected={selectedCards.some((s) => cardsEqual(s, card))}
              onTap={() => onToggle(card)}
            />
          ))}
        </div>
      </div>

      <div className="flex-1" />

      {/* Submit button */}
      <div className="p-6">
        <button
          onClick={onSubmit}
          disabled={!canSubmit || isSubmitting}
          className="w-full py-3.5 rounded-lg font-semibold text-lg bg-[var(--gold)] text-black hover:bg-[var(--gold-light)] disabled:opacity-40 disabled:cursor-not-allowed border-none cursor-pointer"
        >
          {isSubmitting ? 'Evaluating...' : 'Submit'}
        </button>
      </div>
    </>
  )
}

function RevealedPhase({
  puzzle,
  playerRank,
  results,
  selectedCards,
  totalSolved,
  optimalCount,
  onExplain,
  onNext,
  onHome,
}: {
  puzzle: { hand: PlayingCard[]; isDealer: boolean }
  playerRank: number | null
  results: KeepOption[]
  selectedCards: PlayingCard[]
  totalSolved: number
  optimalCount: number
  onExplain: (option: KeepOption) => void
  onNext: () => void
  onHome: () => void
}) {
  const isOptimal = playerRank === 1

  return (
    <>
      {/* Result banner */}
      <div className="mx-6 mb-3">
        <div
          className={`w-full p-4 rounded-xl border ${
            isOptimal
              ? 'bg-green-500/15 border-green-500/50'
              : 'bg-white/5 border-white/20'
          }`}
        >
          {isOptimal ? (
            <div className="text-green-400 text-xl font-bold text-center">Optimal!</div>
          ) : (
            <div className="text-white text-lg font-bold text-center">
              Your pick: #{playerRank} of 15
            </div>
          )}
          <div className="text-white/50 text-sm text-center mt-1">
            {optimalCount}/{totalSolved} optimal
          </div>
        </div>
      </div>

      {/* Dealer context */}
      <div className="text-white/50 text-xs text-center mb-2">
        {puzzle.isDealer ? "Dealer (crib is yours)" : "Non-dealer (crib is opponent's)"}
      </div>

      {/* All 15 keeps */}
      <div className="flex-1 overflow-y-auto px-4 pb-2">
        {results.map((option) => (
          <KeepRankTile
            key={option.rank}
            option={option}
            isPlayerPick={option.keep.length === selectedCards.length &&
              option.keep.every((k) => selectedCards.some((s) => cardsEqual(s, k)))}
            isOptimal={option.rank === 1}
            onExplain={() => onExplain(option)}
          />
        ))}
      </div>

      {/* Bottom buttons */}
      <div className="p-4 flex gap-3">
        <button
          onClick={onHome}
          className="flex-1 py-3 rounded-lg border border-white/30 text-white bg-transparent cursor-pointer hover:bg-white/5 font-medium"
        >
          Back to Home
        </button>
        <button
          onClick={onNext}
          className="flex-1 py-3 rounded-lg bg-[var(--gold)] text-black border-none cursor-pointer hover:bg-[var(--gold-light)] font-semibold"
        >
          Next Puzzle
        </button>
      </div>
    </>
  )
}

function PuzzleCard({
  card,
  selected,
  onTap,
}: {
  card: PlayingCard
  selected: boolean
  onTap: () => void
}) {
  return (
    <div className="flex-1 max-w-[100px]" style={{ aspectRatio: '2.5 / 3.5' }}>
      <CardWidget
        card={card}
        selected={selected}
        onClick={onTap}
        width={100}
        height={140}
      />
    </div>
  )
}
