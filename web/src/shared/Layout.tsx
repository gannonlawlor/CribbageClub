import { useEffect, useState } from 'react'
import { Link, NavLink, Outlet, useNavigate } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'
import * as api from '@/api/rest-client'

export function Layout() {
  const { isLoggedIn, username, isGuest, userId, logout } = useAuthStore()
  const navigate = useNavigate()
  const [notifCount, setNotifCount] = useState(0)

  useEffect(() => {
    if (!isLoggedIn || isGuest) {
      setNotifCount(0)
      return
    }

    function fetchCount() {
      api.getNotificationCount()
        .then((n) => setNotifCount(n.total))
        .catch(() => {})
    }

    fetchCount()
    const interval = setInterval(fetchCount, 30_000)
    return () => clearInterval(interval)
  }, [isLoggedIn, isGuest])

  function handleLogout() {
    logout()
    navigate('/')
  }

  return (
    <div className="min-h-screen">
      {/* ── Desktop sidebar ── */}
      <aside className="hidden lg:flex fixed inset-y-0 left-0 w-44 flex-col bg-[var(--bg-deep)] border-r border-[var(--border)] z-40">
        <Link to="/" className="flex items-center gap-2 px-4 pt-5 pb-6 no-underline">
          <PegLogo />
          <span className="text-white font-extrabold text-[15px] leading-tight tracking-tight">
            Cribbage<span className="text-[var(--accent)]">Club</span>
          </span>
        </Link>

        <nav className="flex flex-col gap-0.5 px-2 flex-1">
          <SideNavLink to="/" label="Play" icon={<PlayIcon />} end />
          <SideNavLink to="/puzzle" label="Puzzles" icon={<PuzzleIcon />} />
          <SideNavLink to="/daily-puzzle" label="Daily" icon={<CalendarIcon />} />
          <SideNavLink to="/leaderboard" label="Leaderboard" icon={<TrophyIcon />} />
          {isLoggedIn && !isGuest && (
            <SideNavLink to="/friends" label="Friends" icon={<FriendsIcon />} badge={notifCount} />
          )}
          {isLoggedIn && <SideNavLink to="/history" label="Archive" icon={<ArchiveIcon />} />}
        </nav>

        <div className="px-2 pb-4 flex flex-col gap-1">
          {isLoggedIn ? (
            <>
              {isGuest ? (
                <>
                  <div className="px-3 py-1 text-white/40 text-xs truncate">{username} (guest)</div>
                  <Link
                    to="/upgrade"
                    className="mx-1 mb-1 bg-[var(--green-500)] hover:bg-[var(--green-400)] text-[var(--on-green)] text-sm font-bold text-center py-2 rounded-md no-underline transition-colors shadow-[inset_0_-3px_0_var(--green-600)]"
                  >
                    Sign Up
                  </Link>
                </>
              ) : (
                <Link
                  to={`/profile/${userId}`}
                  className="px-3 py-1.5 text-white/70 hover:text-white text-sm font-medium truncate no-underline"
                >
                  {username}
                </Link>
              )}
              <button
                onClick={handleLogout}
                className="text-left px-3 py-1.5 text-white/40 hover:text-white/70 text-xs bg-transparent border-none cursor-pointer"
              >
                Log Out
              </button>
            </>
          ) : (
            <>
              <Link
                to="/login"
                className="mx-1 mb-1 bg-[var(--green-500)] hover:bg-[var(--green-400)] text-[var(--on-green)] text-sm font-bold text-center py-2 rounded-md no-underline transition-colors shadow-[inset_0_-3px_0_var(--green-600)]"
              >
                Sign Up
              </Link>
              <Link
                to="/login"
                className="mx-1 bg-[var(--surface)] hover:bg-[var(--surface-hover)] text-white/90 text-sm font-semibold text-center py-2 rounded-md no-underline transition-colors"
              >
                Log In
              </Link>
            </>
          )}
        </div>
      </aside>

      {/* ── Mobile top bar ── */}
      <nav className="lg:hidden bg-[var(--bg-deep)] border-b border-[var(--border)] px-4 py-3 sticky top-0 z-40">
        <div className="flex items-center justify-between">
          <Link to="/" className="flex items-center gap-2 no-underline">
            <PegLogo />
            <span className="text-white font-extrabold text-sm tracking-tight">
              Cribbage<span className="text-[var(--accent)]">Club</span>
            </span>
          </Link>

          <div className="flex items-center gap-4 text-sm">
            <Link to="/daily-puzzle" className="text-white/70 hover:text-white no-underline">Daily</Link>
            <Link to="/leaderboard" className="text-white/70 hover:text-white no-underline">Ranks</Link>
            {isLoggedIn ? (
              <>
                {!isGuest && (
                  <Link to="/friends" className="text-white/70 hover:text-white no-underline relative">
                    Friends
                    {notifCount > 0 && (
                      <span className="absolute -top-2 -right-4 bg-red-500 text-white text-[10px] font-bold rounded-full min-w-[18px] h-[18px] flex items-center justify-center px-1">
                        {notifCount}
                      </span>
                    )}
                  </Link>
                )}
                {isGuest && (
                  <Link to="/upgrade" className="text-[var(--accent)] font-semibold no-underline">
                    Sign Up
                  </Link>
                )}
                <button
                  onClick={handleLogout}
                  className="text-white/50 hover:text-white bg-transparent border-none cursor-pointer"
                >
                  Log Out
                </button>
              </>
            ) : (
              <Link to="/login" className="text-[var(--accent)] font-semibold no-underline">
                Log In
              </Link>
            )}
          </div>
        </div>
      </nav>

      <main className="lg:pl-44 min-h-screen">
        <Outlet />
      </main>
    </div>
  )
}

function SideNavLink({
  to,
  label,
  icon,
  badge,
  end = false,
}: {
  to: string
  label: string
  icon: React.ReactNode
  badge?: number
  end?: boolean
}) {
  return (
    <NavLink
      to={to}
      end={end}
      className={({ isActive }) =>
        `flex items-center gap-2.5 h-[38px] px-3 rounded-md text-sm font-semibold no-underline transition-colors relative overflow-hidden ${
          isActive
            ? 'bg-[var(--surface-2)] text-[var(--text-1)]'
            : 'text-[var(--text-3)] hover:text-[var(--text-1)] hover:bg-[var(--surface-2)]/60'
        }`
      }
    >
      {({ isActive }) => (
        <>
          {isActive && (
            <span className="absolute left-0 top-0 bottom-0 w-[3px] bg-[var(--green-500)]" />
          )}
          <span
            className="w-5 h-5 flex items-center justify-center"
            style={{ color: isActive ? 'var(--green-500)' : 'var(--text-3)' }}
          >
            {icon}
          </span>
          {label}
          {badge != null && badge > 0 && (
            <span className="ml-auto bg-[var(--loss)] text-[#26221e] text-[10px] font-bold rounded-full min-w-[18px] h-[18px] flex items-center justify-center px-1 tnum">
              {badge}
            </span>
          )}
        </>
      )}
    </NavLink>
  )
}

function PegLogo() {
  return (
    <svg viewBox="0 0 24 24" className="w-6 h-6 flex-shrink-0">
      <rect x="3" y="5" width="18" height="14" rx="3" fill="#6D4C41" />
      <circle cx="8" cy="10" r="1.3" fill="#3E2723" />
      <circle cx="12" cy="10" r="1.3" fill="#3E2723" />
      <circle cx="16" cy="10" r="1.3" fill="#3E2723" />
      <circle cx="8" cy="14" r="1.3" fill="var(--accent)" />
      <circle cx="12" cy="14" r="1.3" fill="#3E2723" />
      <circle cx="16" cy="14" r="1.3" fill="var(--gold)" />
    </svg>
  )
}

function PlayIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className="w-4 h-4">
      <path d="M8 5v14l11-7z" />
    </svg>
  )
}

function PuzzleIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-4 h-4">
      <rect x="4" y="4" width="7" height="7" rx="1" />
      <rect x="13" y="4" width="7" height="7" rx="1" />
      <rect x="4" y="13" width="7" height="7" rx="1" />
      <rect x="13" y="13" width="7" height="7" rx="1" />
    </svg>
  )
}

function CalendarIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-4 h-4">
      <rect x="3" y="4" width="18" height="17" rx="2" />
      <path d="M3 9h18M8 2v4M16 2v4" />
    </svg>
  )
}

function TrophyIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-4 h-4">
      <path d="M8 21h8M12 17v4M7 4h10v6a5 5 0 0 1-10 0z" />
      <path d="M7 6H4v2a3 3 0 0 0 3 3M17 6h3v2a3 3 0 0 1-3 3" />
    </svg>
  )
}

function FriendsIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-4 h-4">
      <circle cx="9" cy="8" r="3.5" />
      <path d="M2.5 20a6.5 6.5 0 0 1 13 0" />
      <path d="M16 5a3.5 3.5 0 0 1 0 7M21.5 20a6.5 6.5 0 0 0-5-6.3" />
    </svg>
  )
}

function ArchiveIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-4 h-4">
      <rect x="3" y="4" width="18" height="5" rx="1" />
      <path d="M5 9v10a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9M10 13h4" />
    </svg>
  )
}
