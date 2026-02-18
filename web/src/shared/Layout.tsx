import { Link, Outlet, useNavigate } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'

export function Layout() {
  const { isLoggedIn, username, isGuest, logout } = useAuthStore()
  const navigate = useNavigate()

  function handleLogout() {
    logout()
    navigate('/')
  }

  return (
    <div className="min-h-screen flex flex-col">
      <nav className="bg-[var(--felt-green)] border-b border-white/10 px-4 py-3">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <Link to="/" className="text-xl font-bold text-[var(--gold)] no-underline">
            Cribbage Club
          </Link>

          <div className="flex items-center gap-4 text-sm">
            <Link to="/" className="text-white/80 hover:text-white no-underline">Home</Link>
            <Link to="/daily-puzzle" className="text-white/80 hover:text-white no-underline">Daily Puzzle</Link>
            <Link to="/leaderboard" className="text-white/80 hover:text-white no-underline">Leaderboard</Link>

            {isLoggedIn ? (
              <>
                {!isGuest && (
                  <Link to="/friends" className="text-white/80 hover:text-white no-underline">Friends</Link>
                )}
                <span className="text-white/60">
                  {username}{isGuest && ' (guest)'}
                </span>
                {isGuest && (
                  <Link to="/upgrade" className="text-[var(--gold)] hover:text-[var(--gold-light)] no-underline">
                    Upgrade
                  </Link>
                )}
                <button
                  onClick={handleLogout}
                  className="text-white/60 hover:text-white bg-transparent border-none cursor-pointer"
                >
                  Logout
                </button>
              </>
            ) : (
              <Link to="/login" className="text-[var(--gold)] hover:text-[var(--gold-light)] no-underline">
                Sign In
              </Link>
            )}
          </div>
        </div>
      </nav>

      <main className="flex-1">
        <Outlet />
      </main>
    </div>
  )
}
