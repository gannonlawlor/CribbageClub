import { GameStage } from '@/models/game-state'

interface GameControlsProps {
  stage: GameStage
  isMyTurn: boolean
  selectedCardCount: number
  isDiscarding: boolean
  canGo: boolean
  onDiscard?: () => void
  onCut?: () => void
  onGo?: () => void
  onCount?: () => void
  onResign?: () => void
}

export function GameControls({
  stage,
  isMyTurn,
  selectedCardCount,
  isDiscarding,
  canGo,
  onDiscard,
  onCut,
  onGo,
  onCount,
  onResign,
}: GameControlsProps) {
  if (!isMyTurn && stage !== GameStage.GAME_OVER) {
    return null
  }

  return (
    <div className="flex gap-2 justify-center items-center flex-wrap py-1">
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

      {stage === GameStage.PEGGING && (
        <ActionButton label="Go" onClick={onGo} disabled={!canGo} />
      )}

      {stage === GameStage.COUNTING && (
        <ActionButton label="Count Hand" onClick={onCount} />
      )}

      {stage !== GameStage.GAME_OVER && onResign && (
        <button
          onClick={onResign}
          className="text-red-400/60 text-xs bg-transparent border-none cursor-pointer hover:text-red-400 ml-2"
        >
          Resign
        </button>
      )}
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
      className="bg-[var(--felt-green)] text-white px-4 py-2 rounded font-medium hover:bg-[var(--felt-green-light)] disabled:opacity-40 disabled:cursor-not-allowed border-none cursor-pointer text-sm"
    >
      {label}
    </button>
  )
}
