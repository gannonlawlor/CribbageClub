import { useState } from 'react'
import { Link, useNavigate } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'
import { useAsync } from '@/shared/hooks'
import * as api from '@/api/rest-client'
import type { GameState } from '@/models'
import { GAME_STAGE_DISPLAY } from '@/models/game-state'

export function HomePage() {
  const { isLoggedIn, username, isGuest, userId, loginAsGuest } = useAuthStore()
  const navigate = useNavigate()
  const [isCreating, setIsCreating] = useState(false)
  const [createError, setCreateError] = useState<string | null>(null)
  const [showDifficultyPicker, setShowDifficultyPicker] = useState(false)
  const [showOnlineOptions, setShowOnlineOptions] = useState(false)

  const activeGames = useAsync(
    () => isLoggedIn ? api.getMyActiveGames() : Promise.resolve([]),
    [isLoggedIn],
  )

  /** Ensure we have a session (guest if needed) before server calls */
  async function ensureAuth(): Promise<void> {
    if (!useAuthStore.getState().token) {
      await loginAsGuest()
    }
  }

  async function createAIGame(difficulty: string) {
    setIsCreating(true)
    setCreateError(null)
    setShowDifficultyPicker(false)
    try {
      await ensureAuth()
      const game = await api.createAIGame({ difficulty })
      navigate(`/game/${game.gameId}`)
    } catch (e) {
      setCreateError(e instanceof Error ? e.message : 'Failed to create game')
      setIsCreating(false)
    }
  }

  async function handleQuickMatch() {
    setIsCreating(true)
    setCreateError(null)
    setShowOnlineOptions(false)
    try {
      await ensureAuth()
      const result = await api.quickMatch()
      if (result.gameState) {
        navigate(`/game/${result.gameState.gameId}`)
      } else {
        navigate(`/lobby/${result.lobby.id}`)
      }
    } catch (e) {
      setCreateError(e instanceof Error ? e.message : 'Failed to find match')
      setIsCreating(false)
    }
  }

  async function handleCreatePrivate() {
    setIsCreating(true)
    setCreateError(null)
    setShowOnlineOptions(false)
    try {
      await ensureAuth()
      const currentUsername = useAuthStore.getState().username
      const lobby = await api.createLobby(`${currentUsername}'s game`, { isPrivate: true })
      navigate(`/lobby/${lobby.id}`)
    } catch (e) {
      setCreateError(e instanceof Error ? e.message : 'Failed to create lobby')
      setIsCreating(false)
    }
  }

  return (
    <div className="max-w-md mx-auto p-8">
      {/* Error banner */}
      {createError && (
        <div className="bg-red-500/20 border border-red-500/50 rounded-lg px-4 py-2 mb-4 flex items-center justify-between">
          <span className="text-red-300 text-sm">{createError}</span>
          <button onClick={() => setCreateError(null)} className="text-red-300 bg-transparent border-none cursor-pointer text-sm ml-2">x</button>
        </div>
      )}

      {/* Guest upgrade banner */}
      {isLoggedIn && isGuest && (
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

      <h1 className="text-2xl font-bold text-[var(--gold)] mb-6 text-center">
        {isLoggedIn ? `Welcome, ${username}` : 'Cribbage Club'}
      </h1>

      {!isLoggedIn && (
        <p className="text-white/60 text-center mb-6 -mt-4 text-sm">
          Play cribbage online against AI or friends.
        </p>
      )}

      {/* Play vs AI */}
      <div className="relative mb-3">
        <button
          onClick={() => setShowDifficultyPicker(!showDifficultyPicker)}
          disabled={isCreating}
          className="w-full bg-[var(--gold)] text-black font-semibold py-3 rounded hover:bg-[var(--gold-light)] disabled:opacity-50 text-lg border-none cursor-pointer"
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
          className="w-full bg-[var(--gold)] text-black font-semibold py-3 rounded hover:bg-[var(--gold-light)] disabled:opacity-50 text-lg border-none cursor-pointer"
        >
          Play Online
        </button>
        {showOnlineOptions && (
          <div className="absolute z-10 mt-1 w-full bg-[var(--felt-green)] border border-white/20 rounded-lg shadow-lg overflow-hidden">
            <DifficultyOption label="Quick Game" desc="Find a match instantly" onClick={handleQuickMatch} />
            <DifficultyOption label="Browse Lobbies" desc="Join an open lobby" onClick={() => { setShowOnlineOptions(false); navigate('/lobbies') }} />
            <DifficultyOption label="Create Private" desc="Invite a friend by code" onClick={handleCreatePrivate} />
            <DifficultyOption label="Join by Code" desc="Enter an invite code" onClick={() => { setShowOnlineOptions(false); navigate('/join') }} />
          </div>
        )}
      </div>

      {/* Daily Challenge */}
      <button
        onClick={() => navigate('/daily-puzzle')}
        className="w-full border border-orange-500 text-white py-3 rounded bg-transparent hover:bg-white/5 text-lg mb-3 cursor-pointer"
      >
        Daily Challenge
      </button>

      {/* Practice Puzzles */}
      <button
        onClick={() => navigate('/puzzle')}
        className="w-full border border-white/30 text-white py-3 rounded bg-transparent hover:bg-white/5 text-lg mb-6 cursor-pointer"
      >
        Practice Puzzles
      </button>

      {/* Bottom links */}
      <div className="flex justify-center gap-4 text-sm">
        {isLoggedIn && !isGuest && (
          <Link to="/friends" className="text-white/70 hover:text-white no-underline">Friends</Link>
        )}
        {isLoggedIn && (
          <Link to="/history" className="text-white/70 hover:text-white no-underline">History</Link>
        )}
        <Link to="/leaderboard" className="text-white/70 hover:text-white no-underline">Leaderboard</Link>
        {!isLoggedIn && (
          <Link to="/login" className="text-[var(--gold)] hover:text-[var(--gold-light)] no-underline">
            Sign In
          </Link>
        )}
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
