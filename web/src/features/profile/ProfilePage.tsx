import { useParams } from 'react-router'
import { useAsync } from '@/shared/hooks'
import * as api from '@/api/rest-client'
import type { CategoryStats } from '@/models/profile'

export function ProfilePage() {
  const { userId } = useParams<{ userId: string }>()
  const profile = useAsync(() => api.getProfile(userId!), [userId])

  if (profile.isLoading) {
    return (
      <div className="max-w-2xl mx-auto p-8">
        <div className="text-white/50 text-center py-8">Loading profile...</div>
      </div>
    )
  }

  if (profile.error || !profile.data) {
    return (
      <div className="max-w-2xl mx-auto p-8">
        <div className="text-red-400 text-center py-8">
          {profile.error ?? 'Profile not found'}
        </div>
      </div>
    )
  }

  const p = profile.data

  return (
    <div className="max-w-2xl mx-auto p-8">
      <div className="text-center mb-8">
        <h1 className="text-2xl font-bold text-[var(--gold)]">
          {p.displayName ?? p.username}
        </h1>
        {p.displayName && (
          <div className="text-white/50 text-sm">@{p.username}</div>
        )}
        <div className="text-white font-bold text-3xl mt-2">{Math.round(p.rating)}</div>
        <div className="text-white/50 text-sm">Rating</div>
      </div>

      <div className="space-y-4">
        <StatsSection title="Overall" stats={p.overallStats} />
        <StatsSection title="vs Humans" stats={p.humanStats} />
        <StatsSection title="vs AI" stats={p.aiStats} />
      </div>
    </div>
  )
}

function StatsSection({ title, stats }: { title: string; stats: CategoryStats }) {
  return (
    <div className="bg-white/5 rounded-lg p-4">
      <h3 className="text-white font-semibold mb-2">{title}</h3>
      <div className="grid grid-cols-3 gap-4 text-center">
        <div>
          <div className="text-white font-bold">{stats.gamesPlayed}</div>
          <div className="text-white/50 text-xs">Played</div>
        </div>
        <div>
          <div className="text-white font-bold">{stats.gamesWon}</div>
          <div className="text-white/50 text-xs">Won</div>
        </div>
        <div>
          <div className="text-white font-bold">
            {stats.gamesPlayed > 0 ? `${Math.round(stats.winRate * 100)}%` : '-'}
          </div>
          <div className="text-white/50 text-xs">Win Rate</div>
        </div>
      </div>
    </div>
  )
}
