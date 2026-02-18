import type { PlayingCard } from '@/models'
import { CardWidget } from './CardWidget'

interface HandFanProps {
  cards: PlayingCard[]
  selectedIndices: Set<number>
  enabled: boolean
  onCardTap?: (index: number) => void
  cardWidth?: number
  cardHeight?: number
}

export function HandFan({
  cards,
  selectedIndices,
  enabled,
  onCardTap,
  cardWidth = 64,
  cardHeight = 90,
}: HandFanProps) {
  if (cards.length === 0) return <div className="h-4" />

  // Calculate overlap so cards fit within a reasonable width
  const maxWidth = Math.min(440, window.innerWidth - 32)
  const overlap = Math.min(cardWidth * 0.65, (maxWidth - cardWidth) / Math.max(cards.length - 1, 1))
  const stackWidth = cardWidth + (cards.length - 1) * overlap

  return (
    <div className="flex justify-center">
      <div className="relative" style={{ width: stackWidth, height: cardHeight + 12 }}>
        {cards.map((card, i) => (
          <div
            key={`${card.rank}-${card.suit}`}
            className="absolute bottom-0"
            style={{ left: i * overlap, zIndex: i }}
          >
            <CardWidget
              card={card}
              faceUp
              selected={selectedIndices.has(i)}
              enabled={enabled}
              onClick={onCardTap ? () => onCardTap(i) : undefined}
              width={cardWidth}
              height={cardHeight}
            />
          </div>
        ))}
      </div>
    </div>
  )
}

interface OpponentHandProps {
  cardCount: number
}

export function OpponentHand({ cardCount }: OpponentHandProps) {
  if (cardCount <= 0) return <div className="h-3" />

  const cardWidth = 36
  const cardHeight = 50
  const overlap = 14
  const stackWidth = cardWidth + (cardCount - 1) * overlap

  return (
    <div className="flex justify-center">
      <div className="relative" style={{ width: stackWidth, height: cardHeight }}>
        {Array.from({ length: cardCount }, (_, i) => (
          <div
            key={i}
            className="absolute top-0"
            style={{ left: i * overlap, zIndex: i }}
          >
            <CardWidget faceUp={false} width={cardWidth} height={cardHeight} />
          </div>
        ))}
      </div>
    </div>
  )
}
