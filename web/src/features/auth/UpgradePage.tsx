import { type FormEvent, useState } from 'react'
import { useNavigate } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'

export function UpgradePage() {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const { upgrade, isLoading, error } = useAuthStore()
  const navigate = useNavigate()

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    try {
      await upgrade({ username, password })
      navigate('/')
    } catch {
      // error is set in store
    }
  }

  return (
    <div className="max-w-md mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--gold)] mb-2 text-center">Upgrade Account</h1>
      <p className="text-white/60 text-sm text-center mb-6">
        Choose a username and password to save your progress.
      </p>

      <form onSubmit={handleSubmit} className="space-y-4">
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          className="w-full bg-white/10 border border-white/20 rounded px-4 py-2 text-white placeholder-white/40 outline-none focus:border-[var(--gold)]"
          required
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full bg-white/10 border border-white/20 rounded px-4 py-2 text-white placeholder-white/40 outline-none focus:border-[var(--gold)]"
          required
        />

        {error && <p className="text-red-400 text-sm">{error}</p>}

        <button
          type="submit"
          disabled={isLoading}
          className="w-full bg-[var(--gold)] text-black font-semibold py-2 rounded hover:bg-[var(--gold-light)] disabled:opacity-50"
        >
          {isLoading ? 'Upgrading...' : 'Upgrade Account'}
        </button>
      </form>
    </div>
  )
}
