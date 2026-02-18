import { useParams } from 'react-router'

export function AnalysisPage() {
  const { gameId } = useParams<{ gameId: string }>()

  return (
    <div className="max-w-4xl mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--gold)] mb-4">Analysis</h1>
      <p className="text-white/60">Game ID: {gameId}</p>
      <p className="text-white/40 mt-4">Discard analysis coming soon.</p>
    </div>
  )
}
