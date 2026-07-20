import { AnimatePresence, motion } from 'motion/react'
import { GameStage } from '@/models/game-state'

interface StageIndicatorProps {
  stage: GameStage
  isMyTurn: boolean
  isDealer: boolean
  selectedCardCount: number
}

const STAGES: { key: GameStage; label: string }[] = [
  { key: GameStage.DEALING, label: 'Deal' },
  { key: GameStage.DISCARDING_TO_CRIB, label: 'Discard' },
  { key: GameStage.CUTTING, label: 'Cut' },
  { key: GameStage.PEGGING, label: 'Pegging' },
  { key: GameStage.COUNTING, label: 'Count' },
]

function getInstruction(stage: GameStage, isMyTurn: boolean, isDealer: boolean, selectedCardCount: number): string {
  switch (stage) {
    case GameStage.DEALING:
      return 'Dealing'
    case GameStage.DISCARDING_TO_CRIB: {
      const cribOwner = isDealer ? 'your' : "opponent's"
      return isMyTurn
        ? `Your discard — 2 to ${cribOwner} crib (${selectedCardCount}/2)`
        : `Opponent is discarding to ${cribOwner} crib`
    }
    case GameStage.CUTTING:
      return isMyTurn ? 'Your cut' : 'Opponent cuts the starter'
    case GameStage.PEGGING:
      return isMyTurn ? 'Your play' : 'Opponent to play'
    case GameStage.COUNTING:
      return isMyTurn ? 'Count your hand' : 'Counting'
    case GameStage.GAME_OVER:
      return 'Game over'
  }
}

/** Pill strip (Deal · Discard · Cut · Pegging · Count) — the single source
    of turn truth — paired with a one-line instruction. */
export function StageIndicator({ stage, isMyTurn, isDealer, selectedCardCount }: StageIndicatorProps) {
  const instruction = getInstruction(stage, isMyTurn, isDealer, selectedCardCount)
  const activeIndex = STAGES.findIndex((s) => s.key === stage)

  return (
    <div className="flex flex-col items-center gap-1.5">
      <div className="flex items-center gap-1 bg-[var(--surface-0)] border border-[var(--border)] rounded-full p-1">
        {STAGES.map((s, i) => {
          const isActive = s.key === stage
          const isPast = activeIndex >= 0 && i < activeIndex
          return (
            <span
              key={s.key}
              className="px-2.5 py-0.5 rounded-full text-xs font-semibold tracking-[0.04em] transition-colors duration-150"
              style={{
                backgroundColor: isActive ? 'var(--green-500)' : 'transparent',
                color: isActive
                  ? 'var(--on-green)'
                  : isPast
                    ? 'var(--text-3)'
                    : 'var(--text-faint)',
              }}
            >
              {s.label}
            </span>
          )
        })}
      </div>
      <AnimatePresence mode="wait">
        <motion.span
          key={instruction}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -4 }}
          transition={{ duration: 0.16, ease: [0.2, 0, 0, 1] }}
          className={`text-[13px] ${isMyTurn ? 'text-[var(--text-1)] font-semibold' : 'text-[var(--text-3)]'}`}
        >
          {instruction}
        </motion.span>
      </AnimatePresence>
    </div>
  )
}
