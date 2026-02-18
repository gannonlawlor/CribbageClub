import { Link } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'

export function HomePage() {
  const { isLoggedIn, username } = useAuthStore()

  if (!isLoggedIn) {
    return (
      <div className="max-w-2xl mx-auto p-8 text-center">
        <h1 className="text-3xl font-bold text-[var(--gold)] mb-4">Cribbage Club</h1>
        <p className="text-white/70 mb-8">Play cribbage online against AI or friends.</p>
        <Link
          to="/login"
          className="inline-block bg-[var(--gold)] text-black px-6 py-3 rounded font-semibold no-underline hover:bg-[var(--gold-light)]"
        >
          Get Started
        </Link>
      </div>
    )
  }

  return (
    <div className="max-w-4xl mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--gold)] mb-6">Welcome, {username}</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <ActionCard title="Play vs AI" description="Start a local game against the computer" to="/game/new-ai" />
        <ActionCard title="Daily Puzzle" description="Test your discard skills" to="/daily-puzzle" />
        <ActionCard title="Game History" description="View your past games" to="/history" />
        <ActionCard title="Leaderboard" description="See the top players" to="/leaderboard" />
      </div>
    </div>
  )
}

function ActionCard({ title, description, to }: { title: string; description: string; to: string }) {
  return (
    <Link
      to={to}
      className="block bg-white/5 border border-white/10 rounded-lg p-6 no-underline hover:bg-white/10 transition-colors"
    >
      <h2 className="text-lg font-semibold text-white mb-1">{title}</h2>
      <p className="text-white/60 text-sm">{description}</p>
    </Link>
  )
}
