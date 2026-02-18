import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router'
import { useAsync } from '@/shared/hooks'
import * as api from '@/api/rest-client'
import { subscribe, connectWebSocket } from '@/api/websocket-client'


export function LobbyWaitingPage() {
  const { lobbyId } = useParams<{ lobbyId: string }>()
  const navigate = useNavigate()
  const lobby = useAsync(() => api.getLobby(lobbyId!), [lobbyId])
  const [copied, setCopied] = useState(false)
  const [error, setError] = useState<string | null>(null)

  function handleCopy(code: string) {
    navigator.clipboard.writeText(code).then(() => {
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    })
  }

  // Poll for lobby updates or listen via WebSocket
  useEffect(() => {
    if (!lobbyId) return

    connectWebSocket()
    const unsub = subscribe(`/topic/lobby/${lobbyId}`, (body) => {
      const update = body as { gameId?: string; status?: string }
      if (update.gameId) {
        navigate(`/game/${update.gameId}`)
      }
    })

    // Also poll periodically as fallback
    const interval = setInterval(() => {
      api.getLobby(lobbyId).then((l) => {
        if (l.gameId) {
          navigate(`/game/${l.gameId}`)
        }
      }).catch(() => {})
    }, 3000)

    return () => {
      unsub()
      clearInterval(interval)
    }
  }, [lobbyId, navigate])

  async function handleLeave() {
    if (lobbyId) {
      setError(null)
      try {
        await api.leaveLobby(lobbyId)
        navigate('/')
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed to leave lobby')
      }
    }
  }

  if (lobby.isLoading) {
    return (
      <div className="max-w-md mx-auto p-8 text-center">
        <div className="text-white/50">Loading lobby...</div>
      </div>
    )
  }

  const l = lobby.data

  return (
    <div className="max-w-md mx-auto p-8 text-center">
      <h1 className="text-2xl font-bold text-[var(--gold)] mb-2">
        {l?.name ?? 'Lobby'}
      </h1>

      {error && (
        <div className="bg-red-500/20 border border-red-500/50 rounded px-3 py-2 mb-4 flex items-center justify-between">
          <span className="text-red-300 text-sm">{error}</span>
          <button onClick={() => setError(null)} className="text-red-300 bg-transparent border-none cursor-pointer text-sm ml-2">x</button>
        </div>
      )}

      {l?.inviteCode && (
        <div className="mb-6">
          <div className="text-white/50 text-sm mb-1">Invite Code</div>
          <div className="flex items-center justify-center gap-3">
            <div className="text-white text-3xl font-mono tracking-widest">{l.inviteCode}</div>
            <button
              onClick={() => handleCopy(l.inviteCode!)}
              className="text-white/60 hover:text-white bg-white/10 hover:bg-white/20 border-none rounded px-3 py-1.5 text-sm cursor-pointer transition-colors"
            >
              {copied ? 'Copied!' : 'Copy'}
            </button>
          </div>
        </div>
      )}

      <div className="bg-white/5 rounded-lg p-4 mb-6">
        <div className="text-white/60 text-sm mb-2">
          Players ({l?.players.length ?? 0}/{l?.maxPlayers ?? 2})
        </div>
        {l?.players.map((p) => (
          <div key={p.id} className="text-white py-1">{p.name}</div>
        ))}
        {(l?.players.length ?? 0) < (l?.maxPlayers ?? 2) && (
          <div className="text-white/30 py-1 animate-pulse">Waiting for opponent...</div>
        )}
      </div>

      <button
        onClick={handleLeave}
        className="text-red-400/60 text-sm bg-transparent border-none cursor-pointer hover:text-red-400"
      >
        Leave Lobby
      </button>
    </div>
  )
}
