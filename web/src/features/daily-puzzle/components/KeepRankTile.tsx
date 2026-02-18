import { CardWidget } from '@/features/game/components/CardWidget'
import type { KeepOption } from '../models'

interface KeepRankTileProps {
  option: KeepOption
  isPlayerPick?: boolean
  isOptimal?: boolean
}

export function KeepRankTile({ option, isPlayerPick = false, isOptimal = false }: KeepRankTileProps) {
  let borderClass = ''
  let bgClass = 'bg-white/5'

  if (isPlayerPick && isOptimal) {
    borderClass = 'border border-[var(--gold)]'
    bgClass = 'bg-[var(--gold)]/15'
  } else if (isPlayerPick) {
    borderClass = 'border border-[var(--gold)]'
    bgClass = 'bg-[var(--gold)]/10'
  } else if (isOptimal) {
    borderClass = 'border border-green-500'
    bgClass = 'bg-green-500/10'
  }

  return (
    <div className={`flex items-center gap-1 px-3 py-2 my-1 rounded-lg ${bgClass} ${borderClass}`}>
      {/* Rank */}
      <span className={`w-8 text-sm font-bold ${isOptimal ? 'text-green-400' : 'text-white/70'}`}>
        #{option.rank}
      </span>

      {/* Mini keep cards */}
      <div className="flex gap-0.5">
        {option.keep.map((card, i) => (
          <CardWidget key={i} card={card} width={32} height={45} enabled={false} />
        ))}
      </div>

      <div className="flex-1" />

      {/* Scores */}
      <div className="text-right">
        <div className="flex items-baseline gap-1 justify-end">
          <span className="text-white font-bold text-sm">{option.netScore.toFixed(1)}</span>
          <span className="text-white/40 text-xs">avg pts</span>
        </div>
        <div className="text-white/50 text-[11px]">
          hand {option.averageHandScore.toFixed(1)}  crib {option.averageCribScore > 0 ? '+' : ''}{option.averageCribScore.toFixed(1)}
        </div>
      </div>

      {/* Player pick indicator */}
      {isPlayerPick && (
        <div className="ml-2 text-[var(--gold)] text-sm" title="Your pick">
          &#9733;
        </div>
      )}
    </div>
  )
}
