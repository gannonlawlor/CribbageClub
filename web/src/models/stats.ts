export interface LeaderboardEntry {
  playerId: string
  displayName: string
  gamesPlayed: number
  gamesWon: number
  gamesLost: number
  winRate: number
  averageScore: number
  highestGameScore: number
  currentWinStreak: number
  longestWinStreak: number
  rating: number
}
