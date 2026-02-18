export function StreakBadge({ streak }: { streak: number }) {
  if (streak <= 0) return null

  return (
    <div className="flex items-center gap-1 px-2 py-1 bg-orange-500/20 rounded-full">
      <span className="text-orange-400 text-sm">&#128293;</span>
      <span className="text-orange-400 text-sm font-bold">{streak}</span>
    </div>
  )
}
