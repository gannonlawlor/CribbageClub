import { useNavigate } from 'react-router'
import { motion } from 'motion/react'
import { useAuthStore } from '@/auth/auth-store'
import { useAsync } from '@/shared/hooks'
import * as api from '@/api/rest-client'

const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5 } },
}

export function LandingPage() {
  const navigate = useNavigate()
  const loginAsGuest = useAuthStore((s) => s.loginAsGuest)
  const leaderboard = useAsync(() => api.getLeaderboard().catch(() => []))

  async function handlePlayNow() {
    await loginAsGuest()
    navigate('/')
  }

  return (
    <div>
      {/* ── Hero ── */}
      <section className="min-h-[calc(100vh-52px)] lg:min-h-screen flex items-center bg-[var(--bg)]">
        <div className="max-w-6xl mx-auto px-6 py-16 grid lg:grid-cols-2 gap-14 items-center w-full">
          <div className="hidden lg:block">
            <GameSnapshot />
          </div>

          <div>
            <h1 className="text-4xl lg:text-5xl font-extrabold text-white leading-tight mb-4">
              Play Cribbage Online<br />on the Rated Ladder
            </h1>
            <p className="text-lg text-white/60 leading-relaxed mb-8 max-w-md">
              Real opponents, Glicko-2 ratings, and engine-backed analysis of
              every discard. Built for players who keep score.
            </p>
            <div className="flex flex-col gap-3 max-w-sm">
              <BigCta
                onClick={handlePlayNow}
                title="Play Online"
                subtitle="Rated matchmaking against real players"
                variant="accent"
                icon={<BoltIcon />}
              />
              <BigCta
                onClick={handlePlayNow}
                title="Play Computer"
                subtitle="Three engine difficulties, instant start"
                variant="surface"
                icon={<CpuIcon />}
              />
              <button
                onClick={() => navigate('/login')}
                className="text-white/50 hover:text-white text-sm bg-transparent border-none cursor-pointer py-1"
              >
                Already have an account? <span className="text-[var(--accent)] font-semibold">Log In</span>
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* ── Ratings / ladder ── */}
      <section className="py-20 bg-[var(--bg-deep)]">
        <div className="max-w-5xl mx-auto px-6 grid lg:grid-cols-2 gap-12 items-center">
          <div>
            <motion.h2
              variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
              className="text-3xl font-extrabold text-white mb-3"
            >
              Earn a Rating That Means Something
            </motion.h2>
            <motion.p
              variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
              className="text-white/60 leading-relaxed mb-6 max-w-md"
            >
              Every rated game moves your Glicko-2 rating. Track win streaks,
              head-to-head records, and your place on the global leaderboard.
            </motion.p>
            <motion.button
              variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
              onClick={() => navigate('/leaderboard')}
              className="bg-[var(--surface)] hover:bg-[var(--surface-hover)] text-white font-semibold px-6 py-2.5 rounded-md border border-[var(--border)] cursor-pointer transition-colors"
            >
              View Leaderboard
            </motion.button>
          </div>

          <motion.div
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="bg-[var(--surface)] rounded-lg border border-[var(--border)] overflow-hidden"
          >
            <div className="px-4 py-3 border-b border-[var(--border)] flex items-center gap-2">
              <span className="text-[var(--gold)]"><TrophySmallIcon /></span>
              <span className="text-white font-bold text-sm">Top Players</span>
            </div>
            {(leaderboard.data ?? []).slice(0, 5).map((entry, i) => (
              <div key={entry.playerId} className="flex items-center gap-3 px-4 py-2.5 border-b border-[var(--border)] last:border-b-0">
                <span className="text-white/40 text-sm w-4 text-right">{i + 1}</span>
                <span className="text-white text-sm font-medium flex-1 truncate">{entry.displayName}</span>
                <span className="text-white/40 text-xs">{entry.gamesWon}W</span>
                <span className="text-[var(--gold)] font-bold text-sm tabular-nums">{entry.rating}</span>
              </div>
            ))}
            {!leaderboard.data?.length && (
              <div className="px-4 py-6 text-white/40 text-sm text-center">
                The ladder is waiting. Be the first to climb it.
              </div>
            )}
          </motion.div>
        </div>
      </section>

      {/* ── Analysis ── */}
      <section className="py-20 bg-[var(--bg)]">
        <div className="max-w-5xl mx-auto px-6 grid lg:grid-cols-2 gap-12 items-center">
          <motion.div
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="order-2 lg:order-1 bg-[var(--surface)] rounded-lg border border-[var(--border)] p-4"
          >
            <div className="text-white/50 text-xs uppercase tracking-wider mb-3">Discard Analysis</div>
            <AnalysisRow label="Best keep" cards="5♥ 5♠ 10♦ J♣" ev="+9.2" best />
            <AnalysisRow label="Your keep" cards="5♥ 5♠ 10♦ Q♦" ev="+8.4" />
            <AnalysisRow label="Alternative" cards="5♠ 10♦ J♣ Q♦" ev="+6.1" />
            <div className="text-white/40 text-xs mt-3">
              All 15 possible keeps evaluated across every cut card.
            </div>
          </motion.div>

          <div className="order-1 lg:order-2">
            <motion.h2
              variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
              className="text-3xl font-extrabold text-white mb-3"
            >
              Review Every Decision
            </motion.h2>
            <motion.p
              variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
              className="text-white/60 leading-relaxed max-w-md"
            >
              After each game, the engine grades your discards against the
              mathematically best line — the same exhaustive analysis on web,
              iOS, and Android. Find the points you left in the crib.
            </motion.p>
          </div>
        </div>
      </section>

      {/* ── Puzzles ── */}
      <section className="py-20 bg-[var(--bg-deep)]">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <motion.h2
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="text-3xl font-extrabold text-white mb-3"
          >
            Train Daily
          </motion.h2>
          <motion.p
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="text-white/60 mb-10 max-w-lg mx-auto"
          >
            Five new discard puzzles every day, plus unlimited practice
            positions. Build streaks and sharpen the judgment that wins close games.
          </motion.p>
          <div className="grid sm:grid-cols-3 gap-4 text-left">
            <MiniFeature title="Daily Challenge" description="Five curated discard decisions each day, scored against the engine." />
            <MiniFeature title="Practice Puzzles" description="Unlimited random positions, analyzed instantly in your browser." />
            <MiniFeature title="Game Replay" description="Step through any finished game card by card." />
          </div>
        </div>
      </section>

      {/* ── Final CTA ── */}
      <section className="py-20 bg-[var(--bg)]">
        <div className="max-w-2xl mx-auto px-6 text-center">
          <motion.h2
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="text-3xl font-extrabold text-white mb-4"
          >
            Your Rating Starts Today
          </motion.h2>
          <motion.p
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="text-white/60 mb-8 max-w-md mx-auto"
          >
            Play instantly as a guest, or create a free account to start
            climbing the ladder. Also on iOS and Android.
          </motion.p>
          <motion.div
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="flex flex-wrap justify-center gap-3"
          >
            <button
              onClick={handlePlayNow}
              className="bg-[var(--accent)] hover:bg-[var(--accent-hover)] text-white font-bold text-lg px-10 py-3 rounded-md active:scale-[0.98] transition-all border-b-4 border-[var(--accent-dark)] cursor-pointer"
            >
              Play Now
            </button>
            <button
              onClick={() => navigate('/login')}
              className="bg-[var(--surface)] hover:bg-[var(--surface-hover)] text-white font-semibold text-lg px-8 py-3 rounded-md transition-colors border border-[var(--border)] cursor-pointer"
            >
              Create Account
            </button>
          </motion.div>
        </div>
      </section>

      {/* ── Footer ── */}
      <footer className="bg-[var(--bg-deep)] border-t border-[var(--border)] py-8 text-center">
        <p className="text-white/30 text-sm">&copy; 2026 Cribbage Club. All rights reserved.</p>
      </footer>
    </div>
  )
}

/* ── Hero mock: a game in progress ── */

function GameSnapshot() {
  return (
    <div className="bg-[var(--bg-deep)] rounded-xl border border-[var(--border)] p-5 shadow-2xl max-w-md">
      <SnapshotPlayerBar name="pegmaster_63" rating={1874} score={96} />
      <div className="flex justify-center gap-2 py-6">
        <MockCard label="5" suit="♥" red />
        <MockCard label="J" suit="♣" />
        <MockCard label="10" suit="♦" red />
        <MockCard label="5" suit="♠" />
      </div>
      <div className="text-center text-white/40 text-xs mb-4 uppercase tracking-wider">
        Pegging &middot; count 25
      </div>
      <SnapshotPlayerBar name="you" rating={1841} score={102} accent />
    </div>
  )
}

function SnapshotPlayerBar({ name, rating, score, accent }: { name: string; rating: number; score: number; accent?: boolean }) {
  return (
    <div className="flex items-center gap-3">
      <div className={`w-9 h-9 rounded-md flex items-center justify-center font-bold text-sm ${accent ? 'bg-[var(--accent)] text-white' : 'bg-[var(--surface)] text-white/60'}`}>
        {name[0].toUpperCase()}
      </div>
      <div className="flex-1">
        <span className="text-white text-sm font-semibold">{name}</span>
        <span className="text-white/40 text-xs ml-2">({rating})</span>
      </div>
      <span className="text-white font-bold text-lg tabular-nums">{score}</span>
    </div>
  )
}

function MockCard({ label, suit, red }: { label: string; suit: string; red?: boolean }) {
  return (
    <div className="w-14 h-20 bg-[var(--card-white)] rounded-md shadow-md flex flex-col items-center justify-center">
      <span className={`text-lg font-bold ${red ? 'text-[var(--card-red)]' : 'text-[var(--card-black)]'}`}>{label}</span>
      <span className={`text-lg leading-none ${red ? 'text-[var(--card-red)]' : 'text-[var(--card-black)]'}`}>{suit}</span>
    </div>
  )
}

/* ── Shared pieces ── */

function BigCta({
  onClick,
  title,
  subtitle,
  variant,
  icon,
}: {
  onClick: () => void
  title: string
  subtitle: string
  variant: 'accent' | 'surface'
  icon: React.ReactNode
}) {
  const styles = variant === 'accent'
    ? 'bg-[var(--accent)] hover:bg-[var(--accent-hover)] border-b-4 border-[var(--accent-dark)]'
    : 'bg-[var(--surface)] hover:bg-[var(--surface-hover)] border border-[var(--border)]'
  return (
    <button
      onClick={onClick}
      className={`${styles} text-left rounded-md px-5 py-3.5 flex items-center gap-4 cursor-pointer active:scale-[0.99] transition-all`}
    >
      <span className="text-white/90">{icon}</span>
      <span>
        <span className="block text-white font-bold text-lg leading-tight">{title}</span>
        <span className={`block text-xs mt-0.5 ${variant === 'accent' ? 'text-white/80' : 'text-white/50'}`}>{subtitle}</span>
      </span>
    </button>
  )
}

function MiniFeature({ title, description }: { title: string; description: string }) {
  return (
    <motion.div
      variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
      className="bg-[var(--surface)] rounded-lg border border-[var(--border)] p-5"
    >
      <h3 className="text-white font-bold mb-1.5">{title}</h3>
      <p className="text-white/50 text-sm leading-relaxed">{description}</p>
    </motion.div>
  )
}

function AnalysisRow({ label, cards, ev, best }: { label: string; cards: string; ev: string; best?: boolean }) {
  return (
    <div className={`flex items-center gap-3 rounded-md px-3 py-2 mb-1.5 ${best ? 'bg-[var(--accent)]/15 border border-[var(--accent)]/40' : 'bg-black/20'}`}>
      <span className={`text-xs w-20 flex-shrink-0 ${best ? 'text-[var(--accent)] font-semibold' : 'text-white/40'}`}>{label}</span>
      <span className="text-white/90 text-sm font-mono flex-1">{cards}</span>
      <span className={`text-sm font-bold tabular-nums ${best ? 'text-[var(--accent)]' : 'text-white/50'}`}>{ev}</span>
    </div>
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

function TrophySmallIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-4 h-4">
      <path d="M8 21h8M12 17v4M7 4h10v6a5 5 0 0 1-10 0z" />
      <path d="M7 6H4v2a3 3 0 0 0 3 3M17 6h3v2a3 3 0 0 1-3 3" />
    </svg>
  )
}
