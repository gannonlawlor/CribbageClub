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
  const [expanded, setExpanded] = useState<'online' | 'ai' | null>(null)

  const activeGames = useAsync(
    () => isLoggedIn ? api.getMyActiveGames() : Promise.resolve([]),
    [isLoggedIn],
  )

  const myStats = useAsync(
    () => isLoggedIn ? api.getMyStats().catch(() => null) : Promise.resolve(null),
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
    setExpanded(null)
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
    setExpanded(null)
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
    setExpanded(null)
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

  const stats = myStats.data

  return (
    <div className="max-w-5xl mx-auto p-6 lg:p-10">
      {/* Error banner */}
      {createError && (
        <div className="bg-red-500/20 border border-red-500/50 rounded-lg px-4 py-2 mb-6 flex items-center justify-between">
          <span className="text-red-300 text-sm">{createError}</span>
          <button onClick={() => setCreateError(null)} className="text-red-300 bg-transparent border-none cursor-pointer text-sm ml-2">x</button>
        </div>
      )}

      <div className="grid lg:grid-cols-[1fr_320px] gap-8 items-start">
        {/* ── Left: play menu ── */}
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-white mb-6">
            {isLoggedIn ? 'Play Cribbage' : 'Play Cribbage Online'}
          </h1>

          <div className="flex flex-col gap-3 max-w-xl">
            {/* Play Online */}
            <PlayMenuButton
              title="Play Online"
              subtitle="Rated matchmaking against real players"
              icon={<BoltIcon />}
              variant="accent"
              disabled={isCreating}
              expanded={expanded === 'online'}
              onClick={() => setExpanded(expanded === 'online' ? null : 'online')}
            >
              <SubOption label="Quick Match" desc="Find a rated game instantly" onClick={handleQuickMatch} />
              <SubOption label="Browse Lobbies" desc="Join an open lobby" onClick={() => { setExpanded(null); navigate('/lobbies') }} />
              <SubOption label="Play a Friend" desc="Private lobby with invite code" onClick={handleCreatePrivate} />
              <SubOption label="Join by Code" desc="Enter an invite code" onClick={() => { setExpanded(null); navigate('/join') }} />
            </PlayMenuButton>

            {/* Play Computer */}
            <PlayMenuButton
              title="Play Computer"
              subtitle="Engine opponents at three strengths"
              icon={<CpuIcon />}
              variant="surface"
              disabled={isCreating}
              expanded={expanded === 'ai'}
              onClick={() => setExpanded(expanded === 'ai' ? null : 'ai')}
            >
              <SubOption label="Easy" desc="Casual heuristics" onClick={() => createAIGame('basic')} />
              <SubOption label="Medium" desc="Optimizes hand scoring" onClick={() => createAIGame('medium')} />
              <SubOption label="Hard" desc="Full hand + crib optimization" onClick={() => createAIGame('hard')} />
            </PlayMenuButton>

            {/* Puzzles */}
            <PlayMenuButton
              title="Daily Challenge"
              subtitle="Five new discard puzzles every day"
              icon={<TargetIcon />}
              variant="surface"
              disabled={isCreating}
              onClick={() => navigate('/daily-puzzle')}
            />
            <PlayMenuButton
              title="Practice Puzzles"
              subtitle="Unlimited positions, instant analysis"
              icon={<PuzzlePieceIcon />}
              variant="surface"
              disabled={isCreating}
              onClick={() => navigate('/puzzle')}
            />
          </div>
        </div>

        {/* ── Right: rating, active games ── */}
        <div className="flex flex-col gap-4">
          {/* Rating card */}
          {isLoggedIn && (
            <div className="bg-[var(--surface)] rounded-lg border border-[var(--border)] p-4">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 rounded-md bg-[var(--player-self)] text-[var(--on-green)] font-bold flex items-center justify-center text-lg">
                  {(username ?? '?')[0]?.toUpperCase()}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-white font-semibold text-sm truncate">
                    {username}{isGuest && <span className="text-white/40 font-normal"> (guest)</span>}
                  </div>
                  {stats != null && (
                    <div className="text-white/40 text-xs">
                      {stats.gamesWon}W / {stats.gamesLost}L &middot; {stats.gamesPlayed} games
                    </div>
                  )}
                </div>
                <div className="text-right">
                  <div className="text-[var(--gold)] font-extrabold text-2xl tabular-nums leading-none">
                    {stats?.rating ?? '—'}
                  </div>
                  <div className="text-white/40 text-[10px] uppercase tracking-wider mt-0.5">Rating</div>
                </div>
              </div>
              {isGuest ? (
                <>
                  <p className="text-[var(--text-3)] text-xs mb-2">
                    You're playing unrated. Create an account to keep a rating and your game history.
                  </p>
                  <Link
                    to="/upgrade"
                    className="block bg-[var(--green-500)] hover:bg-[var(--green-400)] text-[var(--on-green)] text-center text-sm font-bold py-2 rounded-md no-underline transition-colors shadow-[inset_0_-3px_0_var(--green-600)]"
                  >
                    Create Account
                  </Link>
                </>
              ) : (
                <div className="flex gap-2 text-xs">
                  <Link to={`/profile/${userId}`} className="flex-1 text-center bg-black/20 hover:bg-black/30 text-white/70 py-1.5 rounded no-underline transition-colors">
                    Profile
                  </Link>
                  <Link to="/history" className="flex-1 text-center bg-black/20 hover:bg-black/30 text-white/70 py-1.5 rounded no-underline transition-colors">
                    Game Archive
                  </Link>
                </div>
              )}
            </div>
          )}

          {!isLoggedIn && (
            <div className="bg-[var(--surface)] rounded-lg border border-[var(--border)] p-4">
              <div className="text-white font-semibold mb-1">New here?</div>
              <p className="text-white/50 text-sm mb-3">
                Create a free account to get a rating and climb the leaderboard.
              </p>
              <Link
                to="/login"
                className="block bg-[var(--green-500)] hover:bg-[var(--green-400)] text-[var(--on-green)] text-center text-sm font-bold py-2 rounded-md no-underline transition-colors shadow-[inset_0_-3px_0_var(--green-600)]"
              >
                Sign Up
              </Link>
            </div>
          )}

          {/* Active games */}
          {activeGames.data && activeGames.data.length > 0 && (
            <div className="bg-[var(--surface)] rounded-lg border border-[var(--border)] overflow-hidden">
              <div className="px-4 py-2.5 border-b border-[var(--border)] text-white/70 text-xs font-bold uppercase tracking-wider">
                Games in Progress
              </div>
              {activeGames.data.map((game) => (
                <ActiveGameTile key={game.gameId} game={game} playerId={userId ?? ''} />
              ))}
            </div>
          )}

          {/* Leaderboard link */}
          <Link
            to="/leaderboard"
            className="flex items-center gap-3 bg-[var(--surface)] hover:bg-[var(--surface-hover)] rounded-lg border border-[var(--border)] px-4 py-3 no-underline transition-colors"
          >
            <span className="text-[var(--gold)]"><TrophySmallIcon /></span>
            <span className="text-white/80 text-sm font-semibold flex-1">Leaderboard</span>
            <span className="text-white/30">&#8250;</span>
          </Link>
        </div>
      </div>
    </div>
  )
}

function PlayMenuButton({
  title,
  subtitle,
  icon,
  variant,
  disabled,
  expanded,
  onClick,
  children,
}: {
  title: string
  subtitle: string
  icon: React.ReactNode
  variant: 'accent' | 'surface'
  disabled?: boolean
  expanded?: boolean
  onClick: () => void
  children?: React.ReactNode
}) {
  const isAccent = variant === 'accent'
  const styles = isAccent
    ? 'bg-[var(--green-500)] hover:bg-[var(--green-400)] shadow-[inset_0_-4px_0_var(--green-600)]'
    : 'bg-[var(--surface-2)] hover:bg-[var(--surface-3)] border border-[var(--border-strong)]'
  return (
    <div>
      <button
        onClick={onClick}
        disabled={disabled}
        className={`${styles} w-full text-left rounded-lg px-5 py-3.5 flex items-center gap-4 cursor-pointer active:translate-y-[2px] transition-all duration-100 disabled:opacity-50 disabled:shadow-none border-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--green-300)]`}
      >
        <span style={{ color: isAccent ? 'var(--on-green)' : 'var(--text-2)' }}>{icon}</span>
        <span className="flex-1">
          <span className={`block font-bold text-lg leading-tight ${isAccent ? 'text-[var(--on-green)]' : 'text-[var(--text-1)]'}`}>{title}</span>
          <span className={`block text-xs mt-0.5 ${isAccent ? 'text-[var(--on-green)]/80' : 'text-[var(--text-3)]'}`}>{subtitle}</span>
        </span>
        {children != null && (
          <span className={`transition-transform ${expanded ? 'rotate-90' : ''} ${isAccent ? 'text-[var(--on-green)]/70' : 'text-[var(--text-3)]'}`}>&#8250;</span>
        )}
      </button>
      {expanded && children != null && (
        <div className="mt-1 bg-[var(--bg-deep)] border border-[var(--border)] rounded-md overflow-hidden">
          {children}
        </div>
      )}
    </div>
  )
}

function SubOption({ label, desc, onClick }: { label: string; desc: string; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="w-full text-left px-5 py-2.5 hover:bg-[var(--surface)] transition-colors bg-transparent border-none cursor-pointer"
    >
      <div className="text-white font-semibold text-sm">{label}</div>
      <div className="text-white/40 text-xs">{desc}</div>
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
      className="flex items-center gap-3 px-4 py-2.5 no-underline hover:bg-[var(--surface-hover)] transition-colors border-b border-[var(--border)] last:border-b-0"
    >
      <span className="text-[var(--accent)] text-xs">&#9654;</span>
      <div className="flex-1 min-w-0">
        <div className="text-white text-sm truncate">vs {opponent.name}</div>
        <div className="text-white/40 text-xs">
          {GAME_STAGE_DISPLAY[game.stage]} &middot; {player.score}&ndash;{opponent.score}
        </div>
      </div>
      <span className="text-white/30">&#8250;</span>
    </Link>
  )
}

function BoltIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className="w-7 h-7">
      <path d="M13 2 4 14h6l-1 8 9-12h-6z" />
    </svg>
  )
}

function CpuIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-7 h-7">
      <rect x="5" y="5" width="14" height="14" rx="2" />
      <rect x="10" y="10" width="4" height="4" />
      <path d="M9 2v3M15 2v3M9 19v3M15 19v3M2 9h3M2 15h3M19 9h3M19 15h3" />
    </svg>
  )
}

function TargetIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-7 h-7">
      <circle cx="12" cy="12" r="9" />
      <circle cx="12" cy="12" r="5" />
      <circle cx="12" cy="12" r="1" fill="currentColor" />
    </svg>
  )
}

function PuzzlePieceIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-7 h-7">
      <rect x="4" y="4" width="7" height="7" rx="1" />
      <rect x="13" y="4" width="7" height="7" rx="1" />
      <rect x="4" y="13" width="7" height="7" rx="1" />
      <rect x="13" y="13" width="7" height="7" rx="1" />
    </svg>
  )
}

function TrophySmallIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-4 h-4">
      <path d="M8 21h8M12 17v4M7 4h10v6a5 5 0 0 1-10 0z" />
      <path d="M7 6H4v2a3 3 0 0 0 3 3M17 6h3v2a3 3 0 0 1-3 3" />
    </svg>
  )
}
