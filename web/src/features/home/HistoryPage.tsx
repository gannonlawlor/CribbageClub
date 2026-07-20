import { Link } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'
import { useAsync } from '@/shared/hooks'
import * as api from '@/api/rest-client'
import type { GameState } from '@/models'

export function HistoryPage() {
  const { isLoggedIn, userId } = useAuthStore()
  const history = useAsync(() => (isLoggedIn ? api.getMyGameHistory() : Promise.resolve([])), [isLoggedIn])

  return (
    <div className="max-w-2xl mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--text-1)] mb-6">Game History</h1>

      {!isLoggedIn && (
        <div className="text-center py-8">
          <p className="text-white/50 mb-4">Log in to see your game history.</p>
          <Link
            to="/login"
            className="inline-block bg-[var(--gold)] text-black px-6 py-2 rounded font-semibold no-underline"
          >
            Log In
          </Link>
        </div>
      )}

      {isLoggedIn && history.isLoading && (
        <div className="text-white/50 text-center py-8">Loading...</div>
      )}

      {isLoggedIn && history.error && (
        <div className="text-red-400 text-center py-8">Failed to load: {history.error}</div>
      )}

      {isLoggedIn && history.data && history.data.length === 0 && (
        <div className="text-white/50 text-center py-8">
          No games yet. Play vs AI or online to get started!
        </div>
      )}

      {isLoggedIn && history.data && history.data.length > 0 && (
        <div className="space-y-2">
          {history.data.map((game) => (
            <GameRow key={game.gameId} game={game} playerId={userId ?? ''} />
          ))}
        </div>
      )}
    </div>
  )
}

function GameRow({ game, playerId }: { game: GameState; playerId: string }) {
  const playerIndex = game.players.findIndex((p) => p.id === playerId)
  const player = playerIndex >= 0 ? game.players[playerIndex] : game.players[0]
  const opponent = game.players[playerIndex >= 0 ? 1 - playerIndex : 1]
  const isWinner = player.score > opponent.score

  return (
    <div className="flex items-center gap-3 bg-white/10 rounded-lg px-4 py-3">
      <span className={isWinner ? 'text-[var(--win)]' : 'text-[var(--loss)]'}>
        {isWinner ? '🏆' : '✕'}
      </span>
      <div className="flex-1">
        <div className="text-white text-sm">vs {opponent.name}</div>
        <div className="text-white/50 text-xs">{player.score} - {opponent.score}</div>
      </div>
      <span className={`font-bold text-sm ${isWinner ? 'text-[var(--win)]' : 'text-[var(--loss)]'}`}>
        {isWinner ? 'Won' : 'Lost'}
      </span>
      <Link
        to={`/analysis/${game.gameId}`}
        className="text-white/30 hover:text-white/60 text-xs no-underline"
        title="Analyze"
      >
        Analysis
      </Link>
      <Link
        to={`/replay/${game.gameId}`}
        className="text-white/30 hover:text-white/60 text-xs no-underline"
        title="Replay"
      >
        Replay
      </Link>
    </div>
  )
}
