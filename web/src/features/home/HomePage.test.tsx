import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { renderWithRouter } from '@/test/render'
import { HomePage } from './HomePage'
import { useAuthStore } from '@/auth/auth-store'
import * as api from '@/api/rest-client'

vi.mock('@/api/rest-client')

const mockApi = vi.mocked(api)

const statsFixture = {
  playerId: 'u1',
  gamesPlayed: 10,
  gamesWon: 6,
  gamesLost: 4,
  winRate: 0.6,
  averageScore: 100,
  highestGameScore: 121,
  currentWinStreak: 2,
  longestWinStreak: 4,
  rating: 1500,
  ratingDeviation: 60,
}

afterEach(() => {
  vi.clearAllMocks()
  useAuthStore.setState({
    token: null,
    userId: null,
    username: null,
    isGuest: false,
    isLoggedIn: false,
    isLoading: false,
    error: null,
  })
})

describe('HomePage', () => {
  it('shows play menu when logged out', () => {
    renderWithRouter(<HomePage />)
    expect(screen.getByText('Play Cribbage Online')).toBeInTheDocument()
    expect(screen.getByText('Play Computer')).toBeInTheDocument()
    expect(screen.getByText('Play Online')).toBeInTheDocument()
  })

  it('shows username and rating when logged in', async () => {
    useAuthStore.setState({
      token: 'test-token',
      userId: 'u1',
      username: 'testuser',
      isGuest: false,
      isLoggedIn: true,
    })
    mockApi.getMyActiveGames.mockResolvedValue([])
    mockApi.getMyStats.mockResolvedValue(statsFixture)

    renderWithRouter(<HomePage />)
    expect(screen.getByText('testuser')).toBeInTheDocument()
    await waitFor(() => {
      expect(screen.getByText('1500')).toBeInTheDocument()
    })
  })

  it('shows Play Online options with Join by Code', async () => {
    const user = userEvent.setup()
    renderWithRouter(<HomePage />)

    await user.click(screen.getByText('Play Online'))

    await waitFor(() => {
      expect(screen.getByText('Quick Match')).toBeInTheDocument()
    })
    expect(screen.getByText('Browse Lobbies')).toBeInTheDocument()
    expect(screen.getByText('Play a Friend')).toBeInTheDocument()
    expect(screen.getByText('Join by Code')).toBeInTheDocument()
    expect(screen.getByText('Enter an invite code')).toBeInTheDocument()
  })

  it('shows AI difficulty picker', async () => {
    const user = userEvent.setup()
    renderWithRouter(<HomePage />)

    await user.click(screen.getByText('Play Computer'))

    await waitFor(() => {
      expect(screen.getByText('Easy')).toBeInTheDocument()
    })
    expect(screen.getByText('Medium')).toBeInTheDocument()
    expect(screen.getByText('Hard')).toBeInTheDocument()
  })
})
