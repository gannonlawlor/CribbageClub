import { useState } from 'react'
import { CardWidget } from '@/features/game/components/CardWidget'
import { totalScore, maxPossibleScore } from '../puzzle-store'
import { PUZZLES_PER_DAY } from '../puzzle-generator'
import { ExplainBottomSheet } from './ExplainBottomSheet'
import { KeepRankTile } from './KeepRankTile'
import { StreakBadge } from './StreakBadge'
import type { PlayingCard } from '@/models'
import type { DailyPuzzleSet, KeepOption } from '../models'

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

function formatDate(d: Date): string {
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`
}

interface PuzzleSummaryProps {
  puzzleSet: DailyPuzzleSet
  playerScores: (number | null)[]
  playerRanks: (number | null)[]
  allResults: (KeepOption[] | null)[]
  streak: number
  onBackToHome: () => void
}

export function PuzzleSummary({
  puzzleSet,
  playerScores,
  playerRanks,
  allResults,
  streak,
  onBackToHome,
}: PuzzleSummaryProps) {
  const [expandedIndex, setExpandedIndex] = useState<number | null>(null)
  const [explainTarget, setExplainTarget] = useState<{
    hand: PlayingCard[]
    keep: PlayingCard[]
    discard: PlayingCard[]
    rank: number
    isDealer: boolean
  } | null>(null)

  const total = totalScore(playerScores)
  const max = maxPossibleScore(allResults)
  const allOptimal = playerRanks.every((r) => r === 1)
  const dateStr = formatDate(puzzleSet.date)

  function shareResults() {
    let text = `Cribbage Club Daily Challenge - ${dateStr}\n`
    text += `Score: ${total.toFixed(1)} / ${max.toFixed(1)} avg pts\n`
    for (let i = 0; i < PUZZLES_PER_DAY; i++) {
      const rank = playerRanks[i]
      const emoji = rank === 1 ? '\u2B50' : '  '
      text += `${emoji} Puzzle ${i + 1}: #${rank ?? '?'} / 15\n`
    }
    if (allOptimal) text += 'Perfect score!\n'
    if (streak > 0) text += `Streak: ${streak} day${streak > 1 ? 's' : ''}\n`

    navigator.clipboard.writeText(text.trim()).catch(() => {})
  }

  return (
    <div className="max-w-lg mx-auto flex flex-col min-h-[calc(100vh-4rem)]">
      {/* Header */}
      <div className="p-4 flex items-center">
        <button
          onClick={onBackToHome}
          className="text-white/60 bg-transparent border-none cursor-pointer text-lg hover:text-white mr-3"
        >
          &larr;
        </button>
        <div className="flex-1">
          <span className="text-white font-bold text-xl">Daily Challenge</span>
          <div className="text-white/50 text-sm">{dateStr}</div>
        </div>
        {streak > 0 && <StreakBadge streak={streak} />}
      </div>

      {/* Score banner */}
      <div className="mx-6 mb-3">
        <div
          className={`w-full p-4 rounded-xl border ${
            allOptimal
              ? 'bg-green-500/15 border-green-500/50'
              : 'bg-white/5 border-white/20'
          }`}
        >
          {allOptimal && (
            <div className="text-green-400 text-xl font-bold text-center mb-1">Perfect!</div>
          )}
          <div className="flex items-baseline justify-center gap-1">
            <span className="text-white text-3xl font-bold">{total.toFixed(1)}</span>
            {max > 0 && (
              <span className="text-white/50 text-lg">/ {max.toFixed(1)}</span>
            )}
            <span className="text-white/40 text-sm ml-1">avg pts</span>
          </div>
          {allOptimal && streak > 0 && (
            <div className="flex items-center justify-center gap-1 mt-2 text-orange-400">
              <span>&#128293;</span>
              <span>{streak} day streak!</span>
            </div>
          )}
        </div>
      </div>

      {/* Per-puzzle rows */}
      <div className="flex-1 overflow-y-auto px-4 space-y-2">
        {puzzleSet.puzzles.map((puzzle, index) => (
          <PuzzleRow
            key={index}
            puzzleNumber={index + 1}
            isDealer={puzzle.isDealer}
            rank={playerRanks[index]}
            score={playerScores[index]}
            maxScore={allResults[index]?.[0]?.netScore ?? null}
            results={allResults[index]}
            playerRank={playerRanks[index]}
            isExpanded={expandedIndex === index}
            onTap={() => setExpandedIndex(expandedIndex === index ? null : index)}
            onExplain={(option) => setExplainTarget({
              hand: puzzle.hand,
              keep: option.keep,
              discard: option.discard,
              rank: option.rank,
              isDealer: puzzle.isDealer,
            })}
          />
        ))}
      </div>

      {/* Bottom buttons */}
      <div className="p-4 flex gap-3">
        <button
          onClick={shareResults}
          className="flex-1 py-3 rounded-lg border border-white/30 text-white bg-transparent cursor-pointer hover:bg-white/5 font-medium"
        >
          Share
        </button>
        <button
          onClick={onBackToHome}
          className="flex-1 py-3 rounded-lg bg-[var(--gold)] text-black border-none cursor-pointer hover:bg-[var(--gold-light)] font-semibold"
        >
          Back to Home
        </button>
      </div>

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

function PuzzleRow({
  puzzleNumber,
  isDealer,
  rank,
  score,
  maxScore,
  results,
  playerRank,
  isExpanded,
  onTap,
  onExplain,
}: {
  puzzleNumber: number
  isDealer: boolean
  rank: number | null
  score: number | null
  maxScore: number | null
  results: KeepOption[] | null
  playerRank: number | null
  isExpanded: boolean
  onTap: () => void
  onExplain: (option: KeepOption) => void
}) {
  const isOptimal = rank === 1

  return (
    <div>
      {/* Collapsed row */}
      <button
        onClick={onTap}
        className={`w-full flex items-center px-3 py-2.5 border-none cursor-pointer ${
          isOptimal
            ? 'bg-green-500/10 border border-green-500/40'
            : 'bg-white/5'
        } ${isExpanded ? 'rounded-t-lg' : 'rounded-lg'}`}
      >
        <span className="w-6 text-white/70 font-bold text-left">{puzzleNumber}</span>

        {/* Mini kept cards */}
        {results && playerRank != null ? (
          <div className="flex gap-0.5 ml-1">
            {results.find((o) => o.rank === playerRank)?.keep.map((card, i) => (
              <CardWidget key={i} card={card} width={22} height={31} enabled={false} />
            ))}
          </div>
        ) : (
          <div className="w-20" />
        )}

        <div className="flex-1" />

        {/* Score */}
        <div className="text-right mr-2">
          <span className="text-white font-bold text-sm">{score?.toFixed(1) ?? '-'}</span>
          <span className="text-white/50 text-xs"> / {maxScore?.toFixed(1) ?? '-'}</span>
        </div>

        {/* Rank badge */}
        <RankBadge rank={rank} />

        {/* Expand indicator */}
        <span className="text-white/40 text-xs ml-1">{isExpanded ? '\u25B2' : '\u25BC'}</span>
      </button>

      {/* Expanded: all keeps */}
      {isExpanded && results && (
        <div className="bg-black/15 rounded-b-lg px-2 pb-2">
          <div className="text-white/50 text-xs px-3 pt-2 pb-1">
            {isDealer ? "Dealer (crib is yours)" : "Non-dealer (crib is opponent's)"}
          </div>
          {results.map((option) => (
            <KeepRankTile
              key={option.rank}
              option={option}
              isPlayerPick={option.rank === playerRank}
              isOptimal={option.rank === 1}
              onExplain={() => onExplain(option)}
            />
          ))}
        </div>
      )}
    </div>
  )
}

function RankBadge({ rank }: { rank: number | null }) {
  if (rank == null) return <div className="w-7" />

  const isOptimal = rank === 1
  return (
    <div
      className={`w-7 h-7 rounded-full flex items-center justify-center text-[10px] font-bold border ${
        isOptimal
          ? 'bg-green-500/30 border-green-500/60 text-green-400'
          : 'bg-white/10 border-white/20 text-white/70'
      }`}
    >
      #{rank}
    </div>
  )
}
