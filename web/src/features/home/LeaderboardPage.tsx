import { Link } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'
import { useAsync } from '@/shared/hooks'
import * as api from '@/api/rest-client'

export function LeaderboardPage() {
  const { isLoggedIn, userId } = useAuthStore()
  const leaderboard = useAsync(() => api.getLeaderboard(), [isLoggedIn])

  if (!isLoggedIn) {
    return (
      <div className="max-w-4xl mx-auto p-8 text-center">
        <h1 className="text-2xl font-bold text-[var(--text-1)] mb-4">Leaderboard</h1>
        <p className="text-white/50 mb-4">Log in to see the leaderboard.</p>
        <Link
          to="/login"
          className="inline-block bg-[var(--gold)] text-black px-6 py-2 rounded font-semibold no-underline"
        >
          Log In
        </Link>
      </div>
    )
  }

  if (leaderboard.isLoading) {
    return (
      <div className="max-w-4xl mx-auto p-8">
        <h1 className="text-2xl font-bold text-[var(--text-1)] mb-4">Leaderboard</h1>
        <div className="text-white/50 text-center py-8">Loading...</div>
      </div>
    )
  }

  if (leaderboard.error) {
    return (
      <div className="max-w-4xl mx-auto p-8">
        <h1 className="text-2xl font-bold text-[var(--text-1)] mb-4">Leaderboard</h1>
        <div className="text-red-400 text-center py-8">Failed to load: {leaderboard.error}</div>
      </div>
    )
  }

  const entries = leaderboard.data ?? []

  return (
    <div className="max-w-2xl mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--text-1)] mb-6">Leaderboard</h1>

      {entries.length === 0 ? (
        <div className="text-white/50 text-center py-8">No players yet.</div>
      ) : (
        <div className="space-y-2">
          {entries.map((entry, index) => {
            const rank = index + 1
            const isMe = entry.playerId === userId
            return (
              <Link
                key={entry.playerId}
                to={`/profile/${entry.playerId}`}
                className={`flex items-center gap-3 px-4 py-3 rounded-lg no-underline transition-colors ${
                  isMe
                    ? 'bg-[rgba(129,182,76,0.08)] border border-[var(--green-500)]/50'
                    : 'bg-white/10 hover:bg-white/15'
                }`}
              >
                <span
                  className={`w-8 text-center font-bold ${
                    rank <= 3 ? 'text-[var(--gold)]' : 'text-white/50'
                  }`}
                >
                  #{rank}
                </span>
                <div className="flex-1">
                  <div className={`text-sm ${isMe ? 'text-[var(--green-500)] font-bold' : 'text-white'}`}>
                    {entry.displayName}
                  </div>
                  <div className="text-white/50 text-xs">{entry.gamesPlayed} games played</div>
                </div>
                <div className="text-right">
                  <div className="text-white font-bold">{Math.round(entry.rating)}</div>
                  <div className="text-white/50 text-xs">{Math.round(entry.winRate * 100)}% win</div>
                </div>
              </Link>
            )
          })}
        </div>
      )}
    </div>
  )
}
