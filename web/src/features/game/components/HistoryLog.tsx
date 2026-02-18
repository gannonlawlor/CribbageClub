import { useRef, useEffect } from 'react'
import type { GameHistoryEvent } from '@/models'
import { RANK_DISPLAY, SUIT_SYMBOL } from '@/models/card'

interface HistoryLogProps {
  events: GameHistoryEvent[]
  playerNames: Record<string, string>
  variant?: 'inline' | 'sidebar'
}

export function HistoryLog({ events, playerNames, variant = 'inline' }: HistoryLogProps) {
  const scrollRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [events.length])

  if (events.length === 0) return null

  const isSidebar = variant === 'sidebar'

  return (
    <div className={isSidebar ? 'flex flex-col h-full' : ''}>
      {isSidebar && (
        <div className="text-white/70 text-sm font-semibold px-3 py-2 border-b border-white/10">
          Game Log
        </div>
      )}
      <div
        ref={scrollRef}
        className={
          isSidebar
            ? 'bg-black/20 rounded-b-lg p-3 flex-1 overflow-y-auto text-sm text-white/60 space-y-0.5'
            : 'bg-black/20 rounded-lg p-3 max-h-32 overflow-y-auto text-xs text-white/60 space-y-0.5'
        }
      >
        {events.map((event, i) => (
          <div key={`${event.type}-${event.timestamp}-${i}`}>{formatEvent(event, playerNames)}</div>
        ))}
      </div>
    </div>
  )
}

function name(playerId: string, playerNames: Record<string, string>): string {
  return playerNames[playerId] ?? playerId
}

function cardStr(card: { rank: string; suit: string }): string {
  return `${RANK_DISPLAY[card.rank as keyof typeof RANK_DISPLAY] ?? card.rank}${SUIT_SYMBOL[card.suit as keyof typeof SUIT_SYMBOL] ?? card.suit}`
}

function formatEvent(event: GameHistoryEvent, playerNames: Record<string, string>): string {
  switch (event.type) {
    case 'RoundStarted':
      return `--- Round ${event.roundNumber} ---`
    case 'CardsDealt':
      return 'Cards dealt.'
    case 'DeckCut':
      return `${name(event.cuttingPlayerId, playerNames)} cut ${cardStr(event.cutCard)}${event.dealerScoredNobs ? ' (His Nobs! +2)' : ''}`
    case 'CardPlayed':
      return `${name(event.playerId, playerNames)} played ${cardStr(event.card)} (count: ${event.newCount})${event.pointsScored > 0 ? ` +${event.pointsScored}${event.scoringReason ? ` ${event.scoringReason}` : ''}` : ''}`
    case 'GoAnnounced':
      return `${name(event.playerId, playerNames)} said Go${event.pointsScored > 0 ? ` +${event.pointsScored}` : ''}`
    case 'PeggingEnded':
      return 'Pegging ended.'
    case 'HandCounted':
      return `${name(event.playerId, playerNames)} hand: +${event.totalPoints}`
    case 'CribCounted':
      return `${name(event.dealerPlayerId, playerNames)} crib: +${event.totalPoints}`
    case 'GameEnded':
      return `Game over! ${name(event.winnerPlayerId, playerNames)} wins with ${event.finalScore} points.`
    case 'GameForfeited':
      return `${name(event.forfeitingPlayerId, playerNames)} forfeited (${event.reason}).`
  }
}
