import { type FormEvent, useState } from 'react'
import { useNavigate } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'

export function LoginPage() {
  const [isRegister, setIsRegister] = useState(false)
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const { login, register, loginAsGuest, isLoading, error } = useAuthStore()
  const navigate = useNavigate()

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    try {
      if (isRegister) {
        await register({ username, password })
      } else {
        await login({ username, password })
      }
      navigate('/')
    } catch {
      // error is set in store
    }
  }

  async function handleGuest() {
    try {
      await loginAsGuest()
      navigate('/')
    } catch {
      // error is set in store
    }
  }

  return (
    <div className="max-w-md mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--text-1)] mb-6 text-center">
        {isRegister ? 'Create Account' : 'Login'}
      </h1>

      <form onSubmit={handleSubmit} className="space-y-4">
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          className="w-full bg-white/10 border border-white/20 rounded px-4 py-2 text-white placeholder-white/40 outline-none focus:border-[var(--green-300)]"
          required
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full bg-white/10 border border-white/20 rounded px-4 py-2 text-white placeholder-white/40 outline-none focus:border-[var(--green-300)]"
          required
        />

        {error && <p className="text-red-400 text-sm">{error}</p>}

        <button
          type="submit"
          disabled={isLoading}
          className="w-full bg-[var(--gold)] text-black font-semibold py-2 rounded hover:bg-[var(--gold-light)] disabled:opacity-50"
        >
          {isLoading ? 'Loading...' : isRegister ? 'Register' : 'Login'}
        </button>
      </form>

      <div className="mt-4 text-center space-y-2">
        <button
          onClick={() => setIsRegister(!isRegister)}
          className="text-[var(--green-500)] text-sm bg-transparent border-none cursor-pointer hover:underline"
        >
          {isRegister ? 'Already have an account? Login' : "Don't have an account? Register"}
        </button>

        <div className="text-white/40 text-sm">or</div>

        <button
          onClick={handleGuest}
          disabled={isLoading}
          className="text-white/60 text-sm bg-transparent border-none cursor-pointer hover:text-white"
        >
          Play as Guest
        </button>
      </div>
    </div>
  )
}
