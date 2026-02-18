import { useParams } from 'react-router'

export function LobbyWaitingPage() {
  const { lobbyId } = useParams<{ lobbyId: string }>()

  return (
    <div className="max-w-4xl mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--gold)] mb-4">Lobby</h1>
      <p className="text-white/60">Lobby ID: {lobbyId}</p>
      <p className="text-white/40 mt-4">Waiting room coming soon.</p>
    </div>
  )
}
