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
    }, 1240) // 140ms in + 1100ms hold; exit animation runs after removal
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
        {popups.map((popup) => {
          const label =
            popup.source === 'hand' ? 'hand'
            : popup.source === 'crib' ? 'crib'
            : popup.reason?.toLowerCase()
          return (
            <motion.div
              key={popup.id}
              initial={{ opacity: 0, y: 0 }}
              animate={{ opacity: 1, y: -6, transition: { duration: 0.14, ease: [0.2, 0, 0, 1] } }}
              exit={{ opacity: 0, y: -12, transition: { duration: 0.2, ease: [0.4, 0, 1, 1] } }}
              className={`absolute flex items-center gap-1.5 rounded-full ${
                popup.isPlayer ? 'right-4 top-2' : 'left-4 top-2'
              }`}
              style={{
                padding: '7px 14px',
                backgroundColor: popup.isPlayer ? 'var(--player-self)' : 'var(--player-opp)',
                color: popup.isPlayer ? 'var(--on-green)' : '#26221e',
                boxShadow: '0 1px 3px rgba(0,0,0,0.4)',
              }}
            >
              <span className="text-sm font-bold tnum">+{popup.points}</span>
              {label && (
                <span className="text-sm font-medium opacity-75">{label}</span>
              )}
            </motion.div>
          )
        })}
      </AnimatePresence>
    </div>
  )
}
