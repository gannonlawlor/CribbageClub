import { useNavigate } from 'react-router'
import { useAsync } from '@/shared/hooks'
import * as api from '@/api/rest-client'

export function LobbyBrowserPage() {
  const navigate = useNavigate()
  const lobbies = useAsync(() => api.listPublicLobbies())

  async function handleJoin(lobbyId: string) {
    try {
      const result = await api.joinLobby(lobbyId)
      if (result.gameState) {
        navigate(`/game/${result.gameState.gameId}`)
      } else {
        navigate(`/lobby/${result.lobby.id}`)
      }
    } catch {
      // TODO: show error
    }
  }

  return (
    <div className="max-w-2xl mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--gold)] mb-6">Open Lobbies</h1>

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
