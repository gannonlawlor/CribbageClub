import { motion } from 'motion/react'
import { RANK_DISPLAY, SUIT_SYMBOL, isRedSuit } from '@/models/card'
import type { PlayingCard } from '@/models'

interface CardWidgetProps {
  card?: PlayingCard
  faceUp?: boolean
  selected?: boolean
  enabled?: boolean
  onClick?: () => void
  width?: number
  height?: number
  className?: string
}

export function CardWidget({
  card,
  faceUp = true,
  selected = false,
  enabled = true,
  onClick,
  width = 60,
  height = 84,
  className = '',
}: CardWidgetProps) {
  const Card = onClick ? motion.button : motion.div
  return (
    <Card
      type={onClick ? "button" : undefined}
      disabled={onClick ? !enabled : undefined}
      aria-label={card && faceUp ? `${card.rank.toLowerCase()} of ${card.suit.toLowerCase()}` : "Face-down card"}
      aria-pressed={onClick ? selected : undefined}
      tabIndex={onClick ? 0 : -1}
      onClick={enabled && onClick ? onClick : undefined}
      animate={{ y: selected ? -8 : 0 }}
      transition={{ duration: 0.15, ease: [0.2, 0, 0, 1] }}
      style={{ width, height, borderRadius: width * 0.08 }}
      className={`relative overflow-hidden select-none p-0 border-0 shrink-0 bg-transparent focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[var(--green-300)] ${
        enabled && onClick ? 'cursor-pointer' : ''
      } ${className}`}
      whileHover={enabled && onClick ? { y: -2, transition: { duration: 0.1 } } : undefined}
    >
      {/* Border / shadow layer */}
      <div
        className="absolute inset-0"
        style={{
          borderRadius: width * 0.08,
          border: selected ? '2px solid var(--green-300)' : '0.5px solid rgba(255,255,255,0.24)',
          boxShadow: '0 1px 3px rgba(0,0,0,0.4)',
        }}
      />

      <span aria-hidden="true" className="absolute inset-0 z-10 pointer-events-none" style={{ borderRadius: width * 0.08, border: selected ? "3px solid var(--green-300)" : "1px solid rgba(0,0,0,.4)" }} />
      {/* Card content */}
      {faceUp && card ? (
        <CardFace card={card} width={width} />
      ) : (
        <CardBack width={width} />
      )}
    </Card>
  )
}

/** Corner index (rank over suit) + one large center pip — no pip grids.
    Rank stays ≥25% of card width so faces read at 40px. */
function CardFace({ card, width }: { card: PlayingCard; width: number }) {
  const color = isRedSuit(card.suit) ? 'var(--card-red)' : 'var(--card-black)'
  const rankText = RANK_DISPLAY[card.rank]
  const suitText = SUIT_SYMBOL[card.suit]
  const rankSize = Math.max(width * 0.25, 11)

  return (
    <div
      className="w-full h-full bg-[var(--card-face)] relative"
      style={{ borderRadius: width * 0.08 }}
    >
      {/* Corner index: rank over suit */}
      <div
        className="absolute flex flex-col items-center leading-none tnum"
        style={{ top: width * 0.06, left: width * 0.08 }}
      >
        <span style={{ color, fontSize: rankSize, fontWeight: 700, lineHeight: 1.05 }}>
          {rankText}
        </span>
        <span style={{ color, fontSize: rankSize * 0.8, lineHeight: 1 }}>
          {suitText}
        </span>
      </div>

      {/* One large center pip */}
      <div className="absolute inset-0 flex items-center justify-center">
        <span style={{ color, fontSize: width * 0.5, lineHeight: 1, transform: 'translate(12%, 12%)' }}>
          {suitText}
        </span>
      </div>
    </div>
  )
}

/** Small card used in the pegging play area. */
export function MiniCard({ card, width = 40, height = 56 }: { card: PlayingCard; width?: number; height?: number }) {
  const color = isRedSuit(card.suit) ? 'var(--card-red)' : 'var(--card-black)'
  const fontSize = Math.round(height * 0.21)
  return (
    <motion.div
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.18, ease: [0.2, 0, 0, 1] }}
      className="rounded border border-white/20 bg-[var(--card-face)] flex flex-col items-center justify-center tnum"
      style={{ width, height, fontSize, boxShadow: '0 1px 3px rgba(0,0,0,0.4)' }}
    >
      <span style={{ color, fontWeight: 700 }}>{RANK_DISPLAY[card.rank]}</span>
      <span style={{ color }}>{SUIT_SYMBOL[card.suit]}</span>
    </motion.div>
  )
}

/** Cool slate, 45° hairline stripes, card-stock border, no logo. */
function CardBack({ width }: { width: number }) {
  const borderWidth = Math.max(Math.round(width * 0.06), 2)
  return (
    <div
      className="w-full h-full"
      style={{
        borderRadius: width * 0.08,
        backgroundColor: 'var(--card-face)',
        padding: borderWidth,
      }}
    >
      <div
        className="w-full h-full"
        style={{
          borderRadius: width * 0.04,
          backgroundColor: 'var(--card-back)',
          backgroundImage:
            'repeating-linear-gradient(45deg, rgba(255,255,255,0.07) 0, rgba(255,255,255,0.07) 1px, transparent 1px, transparent 5px)',
        }}
      />
    </div>
  )
}
