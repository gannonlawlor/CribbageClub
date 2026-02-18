import { useEffect, useState } from 'react'
import { Link, Outlet, useNavigate } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'
import * as api from '@/api/rest-client'

export function Layout() {
  const { isLoggedIn, username, isGuest, logout } = useAuthStore()
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
                  <Link to="/friends" className="text-white/80 hover:text-white no-underline relative">
                    Friends
                    {notifCount > 0 && (
                      <span className="absolute -top-2 -right-4 bg-red-500 text-white text-[10px] font-bold rounded-full min-w-[18px] h-[18px] flex items-center justify-center px-1">
                        {notifCount}
                      </span>
                    )}
                  </Link>
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
