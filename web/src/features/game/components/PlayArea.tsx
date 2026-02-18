import { AnimatePresence, motion } from 'motion/react'
import type { PlayingCard } from '@/models'
import { MiniCard } from './CardWidget'

interface PlayAreaProps {
  playedCards: PlayingCard[]
  peggingCount: number
  miniCardWidth?: number
  miniCardHeight?: number
}

export function PlayArea({ playedCards, peggingCount, miniCardWidth, miniCardHeight }: PlayAreaProps) {
  return (
    <div className="flex flex-col items-center gap-2">
      {/* Pegging count badge */}
      <AnimatePresence mode="wait">
        <motion.div
          key={peggingCount}
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          exit={{ scale: 0.8, opacity: 0 }}
          transition={{ duration: 0.2 }}
          className="px-3 py-1 bg-black/40 rounded-full"
        >
          <span className="text-[var(--gold)] font-bold text-base">
            Count: {peggingCount}
          </span>
        </motion.div>
      </AnimatePresence>

      {/* Played cards */}
      <div className="flex gap-1 justify-center flex-wrap min-h-[56px]">
        {playedCards.length === 0 ? (
          <span className="text-white/30 text-xs py-5">No cards played yet</span>
        ) : (
          <AnimatePresence>
            {playedCards.map((card, i) => (
              <motion.div
                key={`${card.rank}-${card.suit}-${i}`}
                initial={{ scale: 0, y: -20 }}
                animate={{ scale: 1, y: 0 }}
                transition={{ duration: 0.25, type: 'spring', stiffness: 300 }}
              >
                <MiniCard card={card} width={miniCardWidth} height={miniCardHeight} />
              </motion.div>
            ))}
          </AnimatePresence>
        )}
      </div>
    </div>
  )
}
