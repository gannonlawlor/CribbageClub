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
  const scale = height / 84

  return (
    <motion.div
      onClick={enabled && onClick ? onClick : undefined}
      animate={{ y: selected ? -6 : 0 }}
      transition={{ duration: 0.15, ease: 'easeOut' }}
      style={{ width, height }}
      className={`relative rounded-md overflow-hidden select-none ${
        enabled && onClick ? 'cursor-pointer' : ''
      } ${className}`}
      whileHover={enabled && onClick ? { y: -2, transition: { duration: 0.1, ease: 'easeOut' } } : undefined}
    >
      {/* Border / shadow layer */}
      <div
        className="absolute inset-0 rounded-md"
        style={{
          border: selected ? '2px solid var(--gold)' : '0.5px solid rgba(255,255,255,0.24)',
          boxShadow: selected
            ? '0 0 10px rgba(255,213,79,0.5), 0 0 4px rgba(255,213,79,0.3)'
            : '1px 2px 3px rgba(0,0,0,0.26)',
        }}
      />

      {/* Card content */}
      {faceUp && card ? (
        <CardFace card={card} scale={scale} />
      ) : (
        <CardBack width={width} />
      )}
    </motion.div>
  )
}

function CardFace({ card, scale }: { card: PlayingCard; scale: number }) {
  const color = isRedSuit(card.suit) ? 'var(--card-red)' : 'var(--card-black)'
  const rankText = RANK_DISPLAY[card.rank]
  const suitText = SUIT_SYMBOL[card.suit]

  return (
    <div className="w-full h-full bg-[var(--card-white)] rounded-md p-[2px] relative">
      {/* Top-left: rank + suit */}
      <div className="absolute top-0.5 left-1 flex flex-col items-center leading-none">
        <span style={{ color, fontSize: 16 * scale, fontWeight: 800, lineHeight: 1.1 }}>
          {rankText}
        </span>
        <span style={{ color, fontSize: 12 * scale, lineHeight: 1 }}>
          {suitText}
        </span>
      </div>

      {/* Center: large suit */}
      <div className="absolute inset-0 flex items-center justify-center">
        <span style={{ color, fontSize: 28 * scale }}>{suitText}</span>
      </div>

      {/* Bottom-right: rank + suit (rotated 180) */}
      <div className="absolute bottom-0.5 right-1 flex flex-col items-center leading-none rotate-180">
        <span style={{ color, fontSize: 16 * scale, fontWeight: 800, lineHeight: 1.1 }}>
          {rankText}
        </span>
        <span style={{ color, fontSize: 12 * scale, lineHeight: 1 }}>
          {suitText}
        </span>
      </div>
    </div>
  )
}

function CardBack({ width }: { width: number }) {
  return (
    <div
      className="w-full h-full rounded-md"
      style={{
        background: 'linear-gradient(135deg, #2E7D32, #1B5E20)',
      }}
    >
      <div
        className="flex items-center justify-center w-full h-full"
        style={{
          margin: 0,
        }}
      >
        <div
          className="flex items-center justify-center rounded-sm"
          style={{
            width: `calc(100% - ${width * 0.16}px)`,
            height: `calc(100% - ${width * 0.16}px)`,
            border: '1px solid rgba(255,255,255,0.15)',
          }}
        >
          <span style={{ fontSize: width * 0.4, color: 'rgba(255,255,255,0.2)' }}>
            &#9830;
          </span>
        </div>
      </div>
    </div>
  )
}

/** Mini card for played cards area */
export function MiniCard({ card, width = 40, height = 56 }: { card: PlayingCard; width?: number; height?: number }) {
  const color = isRedSuit(card.suit) ? 'var(--card-red)' : 'var(--card-black)'
  const fontSize = Math.round(height * 0.21)
  return (
    <motion.div
      initial={{ scale: 0.5, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      transition={{ duration: 0.2 }}
      className="rounded border border-white/20 bg-[var(--card-white)] flex flex-col items-center justify-center"
      style={{ width, height, fontSize }}
    >
      <span style={{ color }}>{RANK_DISPLAY[card.rank]}</span>
      <span style={{ color }}>{SUIT_SYMBOL[card.suit]}</span>
    </motion.div>
  )
}
