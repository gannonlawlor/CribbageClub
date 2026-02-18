import { useEffect } from 'react'
import { BrowserRouter, Route, Routes, Navigate } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'
import { Layout } from '@/shared/Layout'
import { HomePage } from '@/features/home/HomePage'
import { LoginPage } from '@/features/auth/LoginPage'
import { UpgradePage } from '@/features/auth/UpgradePage'
import { GamePage } from '@/features/game/GamePage'
import { AnalysisPage } from '@/features/analysis/AnalysisPage'
import { ReplayPage } from '@/features/replay/ReplayPage'
import { DailyPuzzlePage } from '@/features/daily-puzzle/DailyPuzzlePage'
import { HistoryPage } from '@/features/home/HistoryPage'
import { LeaderboardPage } from '@/features/home/LeaderboardPage'
import { FriendsPage } from '@/features/friends/FriendsPage'
import { LobbyBrowserPage } from '@/features/lobby/LobbyBrowserPage'
import { LobbyWaitingPage } from '@/features/lobby/LobbyWaitingPage'
import { JoinByCodePage } from '@/features/lobby/JoinByCodePage'
import { ProfilePage } from '@/features/profile/ProfilePage'
import { PuzzlePage } from '@/features/puzzle/PuzzlePage'

export function App() {
  const loadSavedAuth = useAuthStore((s) => s.loadSavedAuth)

  useEffect(() => {
    loadSavedAuth()
  }, [loadSavedAuth])

  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<HomePage />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/upgrade" element={<UpgradePage />} />
          <Route path="/game/:gameId" element={<GamePage />} />
          <Route path="/analysis/:gameId" element={<AnalysisPage />} />
          <Route path="/replay/:gameId" element={<ReplayPage />} />
          <Route path="/daily-puzzle" element={<DailyPuzzlePage />} />
          <Route path="/history" element={<HistoryPage />} />
          <Route path="/leaderboard" element={<LeaderboardPage />} />
          <Route path="/friends" element={<FriendsPage />} />
          <Route path="/lobbies" element={<LobbyBrowserPage />} />
          <Route path="/join" element={<JoinByCodePage />} />
          <Route path="/lobby/:lobbyId" element={<LobbyWaitingPage />} />
          <Route path="/profile/:userId" element={<ProfilePage />} />
          <Route path="/puzzle" element={<PuzzlePage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
