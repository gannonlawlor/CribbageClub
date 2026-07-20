import { useState } from 'react'
import { useNavigate } from 'react-router'
import { useAsync } from '@/shared/hooks'
import { useAuthStore } from '@/auth/auth-store'
import * as api from '@/api/rest-client'

export function LobbyBrowserPage() {
  const navigate = useNavigate()
  const lobbies = useAsync(() => api.listPublicLobbies())
  const [error, setError] = useState<string | null>(null)
  const [isBusy, setIsBusy] = useState(false)

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

  async function handleQuickMatch() {
    setError(null)
    setIsBusy(true)
    try {
      const result = await api.quickMatch()
      if (result.gameState) {
        navigate(`/game/${result.gameState.gameId}`)
      } else {
        navigate(`/lobby/${result.lobby.id}`)
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to find match')
      setIsBusy(false)
    }
  }

  async function handleCreate() {
    setError(null)
    setIsBusy(true)
    try {
      const username = useAuthStore.getState().username
      const lobby = await api.createLobby(`${username}'s game`, { isPrivate: false })
      navigate(`/lobby/${lobby.id}`)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create lobby')
      setIsBusy(false)
    }
  }

  return (
    <div className="max-w-3xl mx-auto p-6 lg:p-10">
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <h1 className="text-2xl font-extrabold text-white">Play Online</h1>
        <div className="flex gap-2">
          <button
            onClick={handleQuickMatch}
            disabled={isBusy}
            className="bg-[var(--green-500)] hover:bg-[var(--green-400)] text-[var(--on-green)] px-5 py-2 rounded-md font-bold text-sm shadow-[inset_0_-3px_0_var(--green-600)] border-none cursor-pointer disabled:opacity-50 disabled:shadow-none transition-colors"
          >
            Quick Match
          </button>
          <button
            onClick={handleCreate}
            disabled={isBusy}
            className="bg-[var(--surface)] hover:bg-[var(--surface-hover)] text-white px-5 py-2 rounded-md font-semibold text-sm border border-[var(--border)] cursor-pointer disabled:opacity-50 transition-colors"
          >
            Create Lobby
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-red-500/20 border border-red-500/50 rounded px-3 py-2 mb-4 flex items-center justify-between">
          <span className="text-red-300 text-sm">{error}</span>
          <button onClick={() => setError(null)} className="text-red-300 bg-transparent border-none cursor-pointer text-sm ml-2">x</button>
        </div>
      )}

      <div className="bg-[var(--surface)] rounded-lg border border-[var(--border)] overflow-hidden">
        <div className="grid grid-cols-[1fr_auto_auto] gap-4 px-4 py-2.5 border-b border-[var(--border)] text-white/40 text-xs font-bold uppercase tracking-wider">
          <span>Lobby</span>
          <span className="w-20 text-center">Players</span>
          <span className="w-20" />
        </div>

        {lobbies.isLoading && (
          <div className="text-white/40 text-center py-10 text-sm">Loading lobbies...</div>
        )}

        {lobbies.error && (
          <div className="text-center py-10 px-6">
            <div className="text-white/50 text-sm mb-3">{lobbies.error}</div>
            <button
              onClick={() => navigate('/login')}
              className="bg-[var(--green-500)] hover:bg-[var(--green-400)] text-[var(--on-green)] px-5 py-2 rounded-md font-bold text-sm border-none cursor-pointer transition-colors"
            >
              Create Free Account
            </button>
          </div>
        )}

        {lobbies.data && lobbies.data.length === 0 && (
          <div className="text-center py-10">
            <div className="text-white/50 text-sm mb-1">No open lobbies right now.</div>
            <div className="text-white/30 text-xs">Start a Quick Match or create your own.</div>
          </div>
        )}

        {lobbies.data?.map((lobby) => (
          <div
            key={lobby.id}
            className="grid grid-cols-[1fr_auto_auto] gap-4 items-center px-4 py-3 border-b border-[var(--border)] last:border-b-0 hover:bg-[var(--surface-hover)] transition-colors"
          >
            <div className="min-w-0">
              <div className="text-white text-sm font-medium truncate">{lobby.name}</div>
              <div className="text-white/40 text-xs">
                Hosted by {lobby.players[0]?.name ?? 'unknown'}
              </div>
            </div>
            <span className="w-20 text-center text-white/60 text-sm tabular-nums">
              {lobby.players.length}/{lobby.maxPlayers}
            </span>
            <button
              onClick={() => handleJoin(lobby.id)}
              className="w-20 bg-[var(--green-500)] hover:bg-[var(--green-400)] text-[var(--on-green)] py-1.5 rounded-md font-bold text-sm border-none cursor-pointer transition-colors"
            >
              Join
            </button>
          </div>
        ))}
      </div>

      <button
        onClick={() => navigate('/join')}
        className="mt-4 text-white/40 hover:text-white/70 text-sm bg-transparent border-none cursor-pointer"
      >
        Have an invite code? <span className="text-[var(--accent)] font-semibold">Join by code</span>
      </button>
    </div>
  )
}
