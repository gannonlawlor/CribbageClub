export interface CategoryStats {
  gamesPlayed: number
  gamesWon: number
  gamesLost: number
  winRate: number
  averageScore: number
}

export interface ProfileResponse {
  userId: string
  username: string
  displayName?: string
  avatarIndex?: number
  createdAt: string
  relationshipStatus?: string
  rating: number
  ratingDeviation: number
  overallStats: CategoryStats
  aiStats: CategoryStats
  humanStats: CategoryStats
}
