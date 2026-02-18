import { AnimatePresence, motion } from 'motion/react'
import { GameStage } from '@/models/game-state'

interface StageIndicatorProps {
  stage: GameStage
  isMyTurn: boolean
  isDealer: boolean
  selectedCardCount: number
}

function getMessage(stage: GameStage, isMyTurn: boolean, isDealer: boolean, selectedCardCount: number): string {
  switch (stage) {
    case GameStage.DEALING:
      return 'Dealing cards...'
    case GameStage.DISCARDING_TO_CRIB: {
      const cribOwner = isDealer ? 'your' : "opponent's"
      return isMyTurn
        ? `Discard 2 to ${cribOwner} crib (${selectedCardCount}/2 selected)`
        : `Discard to ${cribOwner} crib`
    }
    case GameStage.CUTTING:
      return isMyTurn ? 'Tap to cut the deck' : 'Cutting the deck'
    case GameStage.PEGGING:
      return isMyTurn ? "Play a card or tap Go if you can't play" : 'Pegging'
    case GameStage.COUNTING:
      return isMyTurn ? 'Count your cards!' : 'Counting'
    case GameStage.GAME_OVER:
      return 'Game Over!'
  }
}

export function StageIndicator({ stage, isMyTurn, isDealer, selectedCardCount }: StageIndicatorProps) {
  const message = getMessage(stage, isMyTurn, isDealer, selectedCardCount)

  return (
    <div
      className={`px-3.5 py-1.5 rounded-2xl text-center text-sm transition-all duration-300 ${
        isMyTurn
          ? 'bg-[var(--gold)]/20 border border-[var(--gold)]/50 text-[var(--gold)] font-bold'
          : 'bg-black/25 text-white/70'
      }`}
    >
      <AnimatePresence mode="wait">
        <motion.span
          key={`${stage}-${isMyTurn}`}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -4 }}
          transition={{ duration: 0.2 }}
        >
          {message}
        </motion.span>
      </AnimatePresence>
    </div>
  )
}
