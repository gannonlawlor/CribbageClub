import { useEffect, useState, useCallback, useRef } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import type { GameHistoryEvent } from '@/models'

interface ScorePopup {
  id: number
  points: number
  reason?: string
  source?: string
  isPlayer: boolean
}

interface ScorePopupOverlayProps {
  history: GameHistoryEvent[]
  playerId: string
}

let nextId = 0

export function ScorePopupOverlay({ history, playerId }: ScorePopupOverlayProps) {
  const [popups, setPopups] = useState<ScorePopup[]>([])
  const [lastHistoryLength, setLastHistoryLength] = useState(history.length)
  const playerIdRef = useRef(playerId)
  playerIdRef.current = playerId

  const addPopup = useCallback((points: number, eventPlayerId: string, reason?: string, source?: string) => {
    const id = nextId++
    const isPlayer = eventPlayerId === playerIdRef.current
    setPopups((prev) => [...prev, { id, points, reason, source, isPlayer }])
    setTimeout(() => {
      setPopups((prev) => prev.filter((p) => p.id !== id))
    }, 1800)
  }, [])

  useEffect(() => {
    if (history.length <= lastHistoryLength) {
      setLastHistoryLength(history.length)
      return
    }

    // Process new events
    const newEvents = history.slice(lastHistoryLength)
    setLastHistoryLength(history.length)

    for (const event of newEvents) {
      switch (event.type) {
        case 'CardPlayed':
          if (event.pointsScored > 0) {
            addPopup(event.pointsScored, event.playerId, event.scoringReason, 'pegging')
          }
          break
        case 'GoAnnounced':
          if (event.pointsScored > 0) {
            addPopup(event.pointsScored, event.playerId, 'Go', 'go')
          }
          break
        case 'DeckCut':
          if (event.dealerScoredNobs) {
            addPopup(2, event.cuttingPlayerId, 'His Nobs', 'nobs')
          }
          break
        case 'HandCounted':
          if (event.totalPoints > 0) {
            addPopup(event.totalPoints, event.playerId, undefined, 'hand')
          }
          break
        case 'CribCounted':
          if (event.totalPoints > 0) {
            addPopup(event.totalPoints, event.dealerPlayerId, undefined, 'crib')
          }
          break
      }
    }
  }, [history, lastHistoryLength, addPopup])

  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden">
      <AnimatePresence>
        {popups.map((popup) => (
          <motion.div
            key={popup.id}
            initial={{ opacity: 0, scale: 0.5, y: 0 }}
            animate={{ opacity: 1, scale: 1, y: -20 }}
            exit={{ opacity: 0, y: -40, transition: { duration: 0.5, delay: 1 } }}
            transition={{ duration: 0.3 }}
            className={`absolute flex flex-col items-center ${
              popup.isPlayer
                ? 'right-4 top-2'
                : 'left-4 top-2'
            }`}
          >
            {popup.source === 'hand' && (
              <span className="text-[var(--gold)]/80 text-xs font-semibold">Hand</span>
            )}
            {popup.source === 'crib' && (
              <span className="text-[var(--gold)]/80 text-xs font-semibold">Crib</span>
            )}
            <span
              className={`text-4xl font-bold ${popup.isPlayer ? 'text-[var(--gold)]' : 'text-white'}`}
              style={{ textShadow: '1px 1px 4px rgba(0,0,0,0.5)' }}
            >
              +{popup.points}
            </span>
            {popup.reason && (
              <span
                className="text-white/90 text-xs font-medium"
                style={{ textShadow: '1px 1px 3px rgba(0,0,0,0.5)' }}
              >
                {popup.reason}
              </span>
            )}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  )
}
