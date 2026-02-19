import { useNavigate } from 'react-router'
import { motion } from 'motion/react'
import { useAuthStore } from '@/auth/auth-store'

const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5 } },
}

export function LandingPage() {
  const navigate = useNavigate()
  const loginAsGuest = useAuthStore((s) => s.loginAsGuest)

  async function handlePlayNow() {
    await loginAsGuest()
    navigate('/')
  }

  return (
    <div className="-mt-[1px]">
      {/* Hero */}
      <section className="min-h-[calc(100vh-52px)] flex items-center bg-gradient-to-br from-[var(--felt-green-dark)] to-[#0a2e0f]">
        <div className="max-w-5xl mx-auto px-6 py-16 grid lg:grid-cols-2 gap-12 items-center">
          <div>
            <h1 className="text-5xl lg:text-6xl font-extrabold text-[var(--card-white)] leading-tight mb-5">
              The Card Game.<br />
              <span className="text-[var(--gold)]">Elevated.</span>
            </h1>
            <p className="text-lg text-white/70 leading-relaxed mb-8 max-w-md">
              A modern cribbage experience with real-time multiplayer, AI opponents at every skill level, and deep post-game analysis. Play anywhere.
            </p>
            <div className="flex flex-wrap gap-3">
              <button
                onClick={handlePlayNow}
                className="bg-[var(--gold)] text-black font-semibold text-lg px-8 py-3 rounded-lg hover:bg-[var(--gold-light)] active:scale-[0.97] transition-all border-none cursor-pointer"
              >
                Play Now
              </button>
              <button
                onClick={() => navigate('/login')}
                className="border border-white/30 text-white font-semibold text-lg px-8 py-3 rounded-lg hover:bg-white/10 active:scale-[0.97] transition-all bg-transparent cursor-pointer"
              >
                Sign In
              </button>
            </div>
          </div>

          <div className="hidden lg:block">
            <div className="aspect-[3/2] rounded-xl bg-white/5 border border-white/10 flex items-center justify-center">
              <div className="text-center text-white/30">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 80" className="w-32 h-32 mx-auto mb-2 opacity-40">
                  <rect x="10" y="5" width="35" height="50" rx="4" fill="none" stroke="currentColor" strokeWidth="2" transform="rotate(-10 27 30)" />
                  <rect x="30" y="5" width="35" height="50" rx="4" fill="none" stroke="currentColor" strokeWidth="2" />
                  <rect x="50" y="5" width="35" height="50" rx="4" fill="none" stroke="currentColor" strokeWidth="2" transform="rotate(10 67 30)" />
                  <ellipse cx="50" cy="70" rx="40" ry="6" fill="none" stroke="currentColor" strokeWidth="1.5" opacity="0.5" />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="py-20 bg-[var(--felt-green)]">
        <div className="max-w-5xl mx-auto px-6">
          <motion.h2
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="text-3xl lg:text-4xl font-extrabold text-center text-[var(--card-white)] mb-2"
          >
            Why Cribbage Club?
          </motion.h2>
          <motion.p
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="text-center text-white/60 mb-12 max-w-lg mx-auto"
          >
            Everything you need for the perfect cribbage experience.
          </motion.p>

          <div className="grid sm:grid-cols-2 gap-6">
            <FeatureCard
              icon={<RobotIcon />}
              title="Play vs AI"
              description="Three difficulty levels from beginner-friendly to ruthlessly strategic. Perfect your game at your own pace."
            />
            <FeatureCard
              icon={<GlobeIcon />}
              title="Real-Time Multiplayer"
              description="Find opponents instantly with matchmaking, or create a private lobby and invite friends."
            />
            <FeatureCard
              icon={<ChartIcon />}
              title="Stats & Analysis"
              description="Track your rating, win rate, and scoring patterns. Review past hands and learn where points were missed."
            />
            <FeatureCard
              icon={<DevicesIcon />}
              title="Play Anywhere"
              description="Available on iOS, Android, and the web. Your account syncs across every device."
            />
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section className="py-20 bg-[var(--felt-green-dark)]">
        <div className="max-w-4xl mx-auto px-6">
          <motion.h2
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="text-3xl lg:text-4xl font-extrabold text-center text-[var(--card-white)] mb-2"
          >
            Get Started in Minutes
          </motion.h2>
          <motion.p
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="text-center text-white/60 mb-12 max-w-lg mx-auto"
          >
            Three simple steps to your first game.
          </motion.p>

          <div className="grid sm:grid-cols-3 gap-8">
            <Step number={1} title="Sign Up" description="Create a free account in seconds. No credit card required." />
            <Step number={2} title="Find a Game" description="Jump into matchmaking, challenge the AI, or invite a friend to a private lobby." />
            <Step number={3} title="Play & Improve" description="Climb the ladder, track your stats, and sharpen your strategy with every hand." />
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 bg-gradient-to-br from-[var(--felt-green)] to-[var(--felt-green-dark)]">
        <div className="max-w-2xl mx-auto px-6 text-center">
          <motion.h2
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="text-3xl lg:text-4xl font-extrabold text-[var(--card-white)] mb-4"
          >
            Ready to Play?
          </motion.h2>
          <motion.p
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="text-white/60 mb-8 max-w-md mx-auto"
          >
            Jump in as a guest instantly, or create an account to track your progress.
          </motion.p>
          <motion.div
            variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
            className="flex flex-wrap justify-center gap-3"
          >
            <button
              onClick={handlePlayNow}
              className="bg-[var(--gold)] text-black font-semibold text-lg px-8 py-3 rounded-lg hover:bg-[var(--gold-light)] active:scale-[0.97] transition-all border-none cursor-pointer"
            >
              Play Now
            </button>
            <button
              onClick={() => navigate('/login')}
              className="border border-white/30 text-white font-semibold text-lg px-8 py-3 rounded-lg hover:bg-white/10 active:scale-[0.97] transition-all bg-transparent cursor-pointer"
            >
              Create Account
            </button>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-[#071f0b] py-8 text-center">
        <p className="text-white/30 text-sm">&copy; 2026 Cribbage Club. All rights reserved.</p>
      </footer>
    </div>
  )
}

function FeatureCard({ icon, title, description }: { icon: React.ReactNode; title: string; description: string }) {
  return (
    <motion.div
      variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
      className="bg-white/10 rounded-xl p-6 hover:bg-white/15 transition-colors"
    >
      <div className="w-12 h-12 rounded-lg bg-[var(--gold)]/20 text-[var(--gold)] flex items-center justify-center mb-4">
        {icon}
      </div>
      <h3 className="text-lg font-bold text-[var(--card-white)] mb-2">{title}</h3>
      <p className="text-white/60 text-sm leading-relaxed">{description}</p>
    </motion.div>
  )
}

function Step({ number, title, description }: { number: number; title: string; description: string }) {
  return (
    <motion.div
      variants={fadeUp} initial="hidden" whileInView="visible" viewport={{ once: true }}
      className="text-center"
    >
      <div className="w-14 h-14 rounded-full bg-[var(--felt-green)] text-[var(--gold)] text-xl font-bold flex items-center justify-center mx-auto mb-4">
        {number}
      </div>
      <h3 className="text-lg font-bold text-[var(--card-white)] mb-2">{title}</h3>
      <p className="text-white/60 text-sm leading-relaxed">{description}</p>
    </motion.div>
  )
}

function RobotIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-6 h-6">
      <rect x="3" y="11" width="18" height="10" rx="2" />
      <circle cx="12" cy="5" r="2" />
      <path d="M12 7v4" />
      <line x1="8" y1="16" x2="8" y2="16" />
      <line x1="16" y1="16" x2="16" y2="16" />
    </svg>
  )
}

function GlobeIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-6 h-6">
      <circle cx="12" cy="12" r="10" />
      <path d="M2 12h20" />
      <path d="M12 2a15 15 0 0 1 4 10 15 15 0 0 1-4 10 15 15 0 0 1-4-10A15 15 0 0 1 12 2z" />
    </svg>
  )
}

function ChartIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-6 h-6">
      <path d="M18 20V10" />
      <path d="M12 20V4" />
      <path d="M6 20v-6" />
    </svg>
  )
}

function DevicesIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-6 h-6">
      <rect x="2" y="3" width="20" height="14" rx="2" />
      <line x1="8" y1="21" x2="16" y2="21" />
      <line x1="12" y1="17" x2="12" y2="21" />
    </svg>
  )
}
