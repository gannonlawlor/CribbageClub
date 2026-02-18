import { useState } from 'react'
import { useNavigate } from 'react-router'
import { useAsync } from '@/shared/hooks'
import * as api from '@/api/rest-client'

export function LobbyBrowserPage() {
  const navigate = useNavigate()
  const lobbies = useAsync(() => api.listPublicLobbies())
  const [error, setError] = useState<string | null>(null)

  async function handleJoin(lobbyId: string) {
    setError(null)
    try {
      const result = await api.joinLobby(lobbyId)
      if (result.gameState) {
        navigate(`/game/${result.gameState.gameId}`)
      } else {
        navigate(`/lobby/${result.lobby.id}`)
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to join lobby')
    }
  }

  return (
    <div className="max-w-2xl mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--gold)] mb-6">Open Lobbies</h1>

      {error && (
        <div className="bg-red-500/20 border border-red-500/50 rounded px-3 py-2 mb-4 flex items-center justify-between">
          <span className="text-red-300 text-sm">{error}</span>
          <button onClick={() => setError(null)} className="text-red-300 bg-transparent border-none cursor-pointer text-sm ml-2">x</button>
        </div>
      )}

      {lobbies.isLoading && (
        <div className="text-white/50 text-center py-8">Loading...</div>
      )}

      {lobbies.data && lobbies.data.length === 0 && (
        <div className="text-white/50 text-center py-8">
          No open lobbies. Create one from the home page!
        </div>
      )}

      {lobbies.data && lobbies.data.length > 0 && (
        <div className="space-y-2">
          {lobbies.data.map((lobby) => (
            <div key={lobby.id} className="flex items-center gap-3 bg-white/10 rounded-lg px-4 py-3">
              <div className="flex-1">
                <div className="text-white text-sm">{lobby.name}</div>
                <div className="text-white/50 text-xs">
                  {lobby.players.length}/{lobby.maxPlayers} players
                </div>
              </div>
              <button
                onClick={() => handleJoin(lobby.id)}
                className="bg-[var(--gold)] text-black px-4 py-1.5 rounded font-semibold text-sm hover:bg-[var(--gold-light)] border-none cursor-pointer"
              >
                Join
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
