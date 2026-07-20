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
      {/* ── Hero: one centered column, the proof is the ladder ── */}
      <section className="min-h-[calc(100vh-52px)] lg:min-h-screen flex items-center bg-[var(--surface-1)]">
        <div className="max-w-[720px] mx-auto px-6 py-16 w-full text-center">
          <h1 className="text-[40px] leading-[44px] lg:text-5xl font-bold text-[var(--text-1)] mb-4">
            Play Cribbage Online<br />on the Rated Ladder
          </h1>
          <p className="text-lg text-[var(--text-2)] leading-relaxed mb-8 max-w-md mx-auto">
            Real opponents, Glicko-2 ratings, and engine-backed analysis of
            every discard.
          </p>
          <div className="flex flex-col gap-3 max-w-sm mx-auto">
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
              className="text-[var(--text-3)] hover:text-[var(--text-1)] text-sm bg-transparent border-none cursor-pointer py-1"
            >
              Already have an account? <span className="text-[var(--green-500)] font-semibold">Log In</span>
            </button>
          </div>
          <p className="text-[var(--text-3)] text-xs uppercase tracking-[0.06em] mt-8 tnum">
            Free &middot; Rated ladder &middot; iOS, Android &amp; web
          </p>
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
              className="bg-[var(--green-500)] hover:bg-[var(--green-400)] text-[var(--on-green)] font-bold text-lg px-10 py-3 rounded-lg active:translate-y-[2px] transition-all duration-100 shadow-[inset_0_-4px_0_var(--green-600)] border-none cursor-pointer"
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
  const isAccent = variant === 'accent'
  const styles = isAccent
    ? 'bg-[var(--green-500)] hover:bg-[var(--green-400)] shadow-[inset_0_-4px_0_var(--green-600)]'
    : 'bg-[var(--surface-2)] hover:bg-[var(--surface-3)] border border-[var(--border-strong)]'
  return (
    <button
      onClick={onClick}
      className={`${styles} text-left rounded-lg px-5 py-3.5 flex items-center gap-4 cursor-pointer active:translate-y-[2px] transition-all duration-100 border-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--green-300)]`}
    >
      <span style={{ color: isAccent ? 'var(--on-green)' : 'var(--text-2)' }}>{icon}</span>
      <span>
        <span className={`block font-bold text-lg leading-tight ${isAccent ? 'text-[var(--on-green)]' : 'text-[var(--text-1)]'}`}>{title}</span>
        <span className={`block text-xs mt-0.5 ${isAccent ? 'text-[var(--on-green)]/80' : 'text-[var(--text-3)]'}`}>{subtitle}</span>
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
