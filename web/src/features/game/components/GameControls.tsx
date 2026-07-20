import { useState } from 'react'
import { GameStage } from '@/models/game-state'

interface GameControlsProps {
  stage: GameStage
  isMyTurn: boolean
  selectedCardCount: number
  isDiscarding: boolean
  onDiscard?: () => void
  onCut?: () => void
  onCount?: () => void
  onResign?: () => void
}

export function GameControls({
  stage,
  isMyTurn,
  selectedCardCount,
  isDiscarding,
  onDiscard,
  onCut,
  onCount,
  onResign,
}: GameControlsProps) {
  if (!isMyTurn && stage !== GameStage.GAME_OVER) {
    return null
  }

  return (
    <div className="flex flex-col items-center gap-1 py-1">
      <div className="flex gap-2 justify-center items-center">
        {stage === GameStage.DISCARDING_TO_CRIB && (
          <ActionButton
            label={isDiscarding ? 'Discarding...' : `Discard (${selectedCardCount}/2)`}
            onClick={onDiscard}
            disabled={selectedCardCount !== 2 || isDiscarding}
          />
        )}

        {stage === GameStage.CUTTING && (
          <ActionButton label="Cut Deck" onClick={onCut} />
        )}

        {stage === GameStage.COUNTING && (
          <ActionButton label="Count Hand" onClick={onCount} />
        )}
      </div>

      {stage !== GameStage.GAME_OVER && onResign && (
        <ResignControl onResign={onResign} />
      )}
    </div>
  )
}

/** Two-step resign: state the consequence, then let the player decide. */
export function ResignControl({ onResign }: { onResign: () => void }) {
  const [confirming, setConfirming] = useState(false)

  if (!confirming) {
    return (
      <button
        onClick={() => setConfirming(true)}
        className="text-[var(--text-3)] text-xs bg-transparent border-none cursor-pointer hover:text-[var(--loss)] mt-1"
      >
        Resign
      </button>
    )
  }

  return (
    <div className="flex items-center gap-2 mt-1">
      <span className="text-[var(--text-2)] text-xs">Resign this game? It counts as a loss.</span>
      <button
        onClick={() => { setConfirming(false); onResign() }}
        className="text-[var(--loss)] text-xs font-semibold bg-transparent border border-[var(--border-strong)] rounded px-2 py-0.5 cursor-pointer hover:bg-[var(--surface-3)]"
      >
        Resign
      </button>
      <button
        onClick={() => setConfirming(false)}
        className="text-[var(--text-1)] text-xs font-semibold bg-transparent border-none cursor-pointer hover:text-[var(--text-2)]"
      >
        Keep playing
      </button>
    </div>
  )
}

function ActionButton({
  label,
  onClick,
  disabled = false,
}: {
  label: string
  onClick?: () => void
  disabled?: boolean
}) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className="h-11 bg-[var(--green-500)] text-[var(--on-green)] px-6 rounded-lg font-bold hover:bg-[var(--green-400)] active:translate-y-[2px] active:shadow-[inset_0_-1px_0_var(--green-600)] shadow-[inset_0_-4px_0_var(--green-600)] disabled:opacity-40 disabled:shadow-none disabled:cursor-not-allowed border-none cursor-pointer text-sm transition-colors duration-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--green-300)]"
    >
      {label}
    </button>
  )
}
