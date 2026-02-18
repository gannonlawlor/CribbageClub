import { useParams } from 'react-router'

export function GamePage() {
  const { gameId } = useParams<{ gameId: string }>()

  return (
    <div className="max-w-4xl mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--gold)] mb-4">Game</h1>
      <p className="text-white/60">Game ID: {gameId}</p>
      <p className="text-white/40 mt-4">Game board coming soon.</p>
    </div>
  )
}
