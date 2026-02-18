import { useState } from 'react'
import { Link, useNavigate } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'
import { useAsync } from '@/shared/hooks'
import * as api from '@/api/rest-client'
import type { GameState } from '@/models'
import { GAME_STAGE_DISPLAY } from '@/models/game-state'

export function HomePage() {
  const { isLoggedIn, username, isGuest, userId } = useAuthStore()
  const navigate = useNavigate()

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

  return <AuthenticatedHome username={username} isGuest={isGuest} userId={userId} navigate={navigate} />
}

function AuthenticatedHome({
  username,
  isGuest,
  userId,
  navigate,
}: {
  username: string | null
  isGuest: boolean
  userId: string | null
  navigate: ReturnType<typeof useNavigate>
}) {
  const [isCreating, setIsCreating] = useState(false)
  const [showDifficultyPicker, setShowDifficultyPicker] = useState(false)
  const [showOnlineOptions, setShowOnlineOptions] = useState(false)
  const activeGames = useAsync(() => api.getMyActiveGames())

  async function createAIGame(difficulty: string) {
    setIsCreating(true)
    setShowDifficultyPicker(false)
    try {
      const game = await api.createAIGame({ difficulty })
      navigate(`/game/${game.gameId}`)
    } catch {
      setIsCreating(false)
    }
  }

  async function handleQuickMatch() {
    setIsCreating(true)
    setShowOnlineOptions(false)
    try {
      const result = await api.quickMatch()
      if (result.gameState) {
        navigate(`/game/${result.gameState.gameId}`)
      } else {
        navigate(`/lobby/${result.lobby.id}`)
      }
    } catch {
      setIsCreating(false)
    }
  }

  async function handleCreatePrivate() {
    setIsCreating(true)
    setShowOnlineOptions(false)
    try {
      const lobby = await api.createLobby(`${username}'s game`, { isPrivate: true })
      navigate(`/lobby/${lobby.id}`)
    } catch {
      setIsCreating(false)
    }
  }

  return (
    <div className="max-w-md mx-auto p-8">
      {/* Guest upgrade banner */}
      {isGuest && (
        <div className="border border-[var(--gold)] rounded-lg p-4 mb-6 bg-[var(--gold)]/10">
          <div className="flex items-center gap-3">
            <span className="text-[var(--gold)]">i</span>
            <span className="text-white/70 text-sm flex-1">
              Create an account to save your progress and stats.
            </span>
            <Link to="/upgrade" className="text-[var(--gold)] text-sm font-bold no-underline hover:underline">
              Upgrade
            </Link>
          </div>
        </div>
      )}

      {/* Active games */}
      {activeGames.data && activeGames.data.length > 0 && (
        <div className="mb-6">
          <h2 className="text-white font-bold text-lg mb-2">Continue Game</h2>
          {activeGames.data.map((game) => (
            <ActiveGameTile key={game.gameId} game={game} playerId={userId ?? ''} />
          ))}
        </div>
      )}

      <h1 className="text-2xl font-bold text-[var(--gold)] mb-6 text-center">Welcome, {username}</h1>

      {/* Play vs AI */}
      <div className="relative mb-3">
        <button
          onClick={() => setShowDifficultyPicker(!showDifficultyPicker)}
          disabled={isCreating}
          className="w-full bg-[var(--gold)] text-black font-semibold py-3 rounded hover:bg-[var(--gold-light)] disabled:opacity-50 text-lg"
        >
          Play vs AI
        </button>
        {showDifficultyPicker && (
          <div className="absolute z-10 mt-1 w-full bg-[var(--felt-green)] border border-white/20 rounded-lg shadow-lg overflow-hidden">
            <DifficultyOption label="Easy" desc="Basic heuristics" onClick={() => createAIGame('basic')} />
            <DifficultyOption label="Medium" desc="Optimizes hand scoring" onClick={() => createAIGame('medium')} />
            <DifficultyOption label="Hard" desc="Hand + crib optimization" onClick={() => createAIGame('hard')} />
          </div>
        )}
      </div>

      {/* Play Online */}
      <div className="relative mb-3">
        <button
          onClick={() => setShowOnlineOptions(!showOnlineOptions)}
          disabled={isCreating}
          className="w-full bg-[var(--gold)] text-black font-semibold py-3 rounded hover:bg-[var(--gold-light)] disabled:opacity-50 text-lg"
        >
          Play Online
        </button>
        {showOnlineOptions && (
          <div className="absolute z-10 mt-1 w-full bg-[var(--felt-green)] border border-white/20 rounded-lg shadow-lg overflow-hidden">
            <DifficultyOption label="Quick Game" desc="Find a match instantly" onClick={handleQuickMatch} />
            <DifficultyOption label="Browse Lobbies" desc="Join an open lobby" onClick={() => { setShowOnlineOptions(false); navigate('/lobbies') }} />
            <DifficultyOption label="Create Private" desc="Invite a friend by code" onClick={handleCreatePrivate} />
          </div>
        )}
      </div>

      {/* Daily Challenge */}
      <button
        onClick={() => navigate('/daily-puzzle')}
        className="w-full border border-orange-500 text-white py-3 rounded bg-transparent hover:bg-white/5 text-lg mb-3"
      >
        Daily Challenge
      </button>

      {/* Practice Puzzles */}
      <button
        onClick={() => navigate('/practice-puzzle')}
        className="w-full border border-white/30 text-white py-3 rounded bg-transparent hover:bg-white/5 text-lg mb-6"
      >
        Practice Puzzles
      </button>

      {/* Bottom links */}
      <div className="flex justify-center gap-4 text-sm">
        {!isGuest && (
          <Link to="/friends" className="text-white/70 hover:text-white no-underline">Friends</Link>
        )}
        <Link to="/history" className="text-white/70 hover:text-white no-underline">History</Link>
        <Link to="/leaderboard" className="text-white/70 hover:text-white no-underline">Leaderboard</Link>
      </div>
    </div>
  )
}

function DifficultyOption({ label, desc, onClick }: { label: string; desc: string; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="w-full text-left px-4 py-3 hover:bg-white/10 transition-colors bg-transparent border-none cursor-pointer"
    >
      <div className="text-white font-medium">{label}</div>
      <div className="text-white/50 text-xs">{desc}</div>
    </button>
  )
}

function ActiveGameTile({ game, playerId }: { game: GameState; playerId: string }) {
  const playerIndex = game.players.findIndex((p) => p.id === playerId)
  const player = playerIndex >= 0 ? game.players[playerIndex] : game.players[0]
  const opponent = game.players[playerIndex >= 0 ? 1 - playerIndex : 1]

  return (
    <Link
      to={`/game/${game.gameId}`}
      className="block bg-white/10 rounded-lg px-4 py-3 mb-2 no-underline hover:bg-white/15 transition-colors"
    >
      <div className="flex items-center gap-3">
        <span className="text-[var(--gold)]">&#9654;</span>
        <div className="flex-1">
          <div className="text-white text-sm">vs {opponent.name}</div>
          <div className="text-white/50 text-xs">
            {GAME_STAGE_DISPLAY[game.stage]} — {player.score} to {opponent.score}
          </div>
        </div>
        <span className="text-white/30">&#8250;</span>
      </div>
    </Link>
  )
}
