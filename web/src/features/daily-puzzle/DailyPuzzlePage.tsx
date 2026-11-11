import { useEffect } from 'react'
import { useNavigate } from 'react-router'
import { usePuzzleStore, totalScore } from './puzzle-store'
import { PUZZLES_PER_DAY } from './puzzle-generator'
import { CardWidget } from '@/features/game/components/CardWidget'
import { cardsEqual, cardKey, RANK_DISPLAY, SUIT_SYMBOL } from '@/models/card'
import type { PlayingCard } from '@/models'
import { StreakBadge } from './components/StreakBadge'
import { PuzzleSummary } from './components/PuzzleSummary'

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

function formatDate(d: Date): string {
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`
}

export function DailyPuzzlePage() {
  const navigate = useNavigate()
  const {
    puzzleSet,
    currentPuzzleIndex,
    selectedCards,
    phase,
    streak,
    playerRanks,
    playerScores,
    allResults,
    isSubmitting,
    error,
    loadPuzzle,
    toggleCard,
    submitKeep,
    reset,
  } = usePuzzleStore()

  useEffect(() => {
    loadPuzzle()
    return () => reset()
  }, [loadPuzzle, reset])

  if (!puzzleSet) {
    return (
      <div className="max-w-lg mx-auto p-8 text-center">
        <div className="w-8 h-8 border-2 border-white/30 border-t-white/80 rounded-full animate-spin mx-auto" />
      </div>
    )
  }

  if (phase === 'summary' || phase === 'revealed') {
    return (
      <PuzzleSummary
        puzzleSet={puzzleSet}
        playerScores={playerScores}
        playerRanks={playerRanks}
        allResults={allResults}
        streak={streak}
        onBackToHome={() => navigate('/')}
      />
    )
  }

  const puzzle = puzzleSet.puzzles[currentPuzzleIndex]
  if (!puzzle) return null

  const canSubmit = selectedCards.length === 4
  const dateStr = formatDate(puzzle.date)

  return (
    <div className="max-w-lg mx-auto flex flex-col min-h-[calc(100vh-4rem)]">
      {error && <p role="alert" className="m-4 p-3 border border-red-400 rounded-lg text-red-200">{error}</p>}
      {/* Header */}
      <div className="p-4 flex items-center">
        <button
          onClick={() => navigate('/')}
          className="text-white/60 bg-transparent border-none cursor-pointer text-lg hover:text-white mr-3"
        >
          &larr;
        </button>
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <span className="text-white font-bold text-xl">Daily Challenge</span>
            <span className="text-white/50">{currentPuzzleIndex + 1}/{PUZZLES_PER_DAY}</span>
          </div>
          <div className="text-white/50 text-sm">{dateStr}</div>
        </div>
        {streak > 0 && <StreakBadge streak={streak} />}
      </div>

      {/* Progress dots */}
      <div className="flex justify-center gap-1.5 mb-2">
        {Array.from({ length: PUZZLES_PER_DAY }).map((_, i) => (
          <div
            key={i}
            className={`w-2.5 h-2.5 rounded-full ${
              playerRanks[i] == null
                ? 'bg-white/20'
                : playerRanks[i] === 1
                  ? 'bg-green-500'
                  : 'bg-[var(--gold)]'
            } ${i === currentPuzzleIndex ? 'ring-2 ring-white ring-offset-1 ring-offset-transparent' : ''}`}
          />
        ))}
      </div>

      {/* Running total */}
      {currentPuzzleIndex > 0 && (
        <div className="text-white/40 text-xs text-center">
          Running total: {totalScore(playerScores).toFixed(1)} avg pts
        </div>
      )}

      <div className="flex-1" />

      {/* Instruction */}
      <div className="text-white/70 text-center px-6 mb-2">
        {puzzle.isDealer ? "The crib is yours." : "The crib belongs to your opponent."}
        Choose the best 4 cards to keep.
      </div>

      {/* Selection counter */}
      <div aria-live="polite" className={`text-center text-sm mb-4 ${canSubmit ? 'text-[var(--green-400)]' : 'text-white/40'}`}>
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
              onTap={() => toggleCard(card)}
            />
          ))}
        </div>
        <div className="flex justify-center gap-2">
          {puzzle.hand.slice(3, 6).map((card) => (
            <PuzzleCard
              key={cardKey(card)}
              card={card}
              selected={selectedCards.some((s) => cardsEqual(s, card))}
              onTap={() => toggleCard(card)}
            />
          ))}
        </div>
      </div>

      <div className="flex-1" />

      <p aria-live="polite" className="px-6 text-center text-sm text-[var(--text-2)]">Keep: {selectedCards.map(c => RANK_DISPLAY[c.rank] + SUIT_SYMBOL[c.suit]).join(' ') || 'Select four cards'}{selectedCards.length === 4 && <> · To crib: {puzzle.hand.filter(c => !selectedCards.some(s => cardsEqual(s, c))).map(c => RANK_DISPLAY[c.rank] + SUIT_SYMBOL[c.suit]).join(' ')}</>}</p>
      {/* Submit button */}
      <div className="p-6">
        <button
          onClick={submitKeep}
          disabled={!canSubmit || isSubmitting}
          className="w-full py-3.5 rounded-lg font-semibold text-lg bg-[var(--green-500)] text-[var(--on-green)] hover:bg-[var(--green-400)] disabled:opacity-40 disabled:cursor-not-allowed border-none cursor-pointer"
        >
          {isSubmitting ? 'Evaluating...' : 'Submit'}
        </button>
      </div>
    </div>
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
        width={Math.min(100, (window.innerWidth - 64) / 3)}
        height={Math.min(100, (window.innerWidth - 64) / 3) * 1.4}
      />
    </div>
  )
}
