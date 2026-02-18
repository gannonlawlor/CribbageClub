import { type FormEvent, useState } from 'react'
import { useNavigate } from 'react-router'
import * as api from '@/api/rest-client'

export function JoinByCodePage() {
  const navigate = useNavigate()
  const [code, setCode] = useState('')
  const [isJoining, setIsJoining] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    const trimmed = code.trim()
    if (!trimmed) return

    setIsJoining(true)
    setError(null)
    try {
      const result = await api.joinByCode(trimmed)
      if (result.gameState) {
        navigate(`/game/${result.gameState.gameId}`)
      } else {
        navigate(`/lobby/${result.lobby.id}`)
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to join lobby')
      setIsJoining(false)
    }
  }

  return (
    <div className="max-w-md mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--gold)] mb-6 text-center">Join by Code</h1>

      {error && (
        <div className="bg-red-500/20 border border-red-500/50 rounded-lg px-4 py-2 mb-4">
          <span className="text-red-300 text-sm">{error}</span>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <input
          type="text"
          placeholder="Enter invite code"
          value={code}
          onChange={(e) => setCode(e.target.value.toUpperCase())}
          className="w-full bg-white/10 border border-white/20 rounded px-4 py-3 text-white text-center text-2xl font-mono tracking-widest placeholder-white/40 outline-none focus:border-[var(--gold)]"
          autoFocus
        />
        <button
          type="submit"
          disabled={isJoining || !code.trim()}
          className="w-full bg-[var(--gold)] text-black font-semibold py-3 rounded hover:bg-[var(--gold-light)] disabled:opacity-50 text-lg border-none cursor-pointer"
        >
          {isJoining ? 'Joining...' : 'Join'}
        </button>
      </form>
    </div>
  )
}
