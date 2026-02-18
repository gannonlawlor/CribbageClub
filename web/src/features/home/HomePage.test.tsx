import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { renderWithRouter } from '@/test/render'
import { HomePage } from './HomePage'
import { useAuthStore } from '@/auth/auth-store'
import * as api from '@/api/rest-client'

vi.mock('@/api/rest-client')

const mockApi = vi.mocked(api)

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
  it('shows welcome message when logged out', () => {
    renderWithRouter(<HomePage />)
    expect(screen.getByText('Cribbage Club')).toBeInTheDocument()
    expect(screen.getByText('Play vs AI')).toBeInTheDocument()
    expect(screen.getByText('Play Online')).toBeInTheDocument()
  })

  it('shows welcome with username when logged in', () => {
    useAuthStore.setState({
      token: 'test-token',
      userId: 'u1',
      username: 'testuser',
      isGuest: false,
      isLoggedIn: true,
    })
    mockApi.getMyActiveGames.mockResolvedValue([])

    renderWithRouter(<HomePage />)
    expect(screen.getByText('Welcome, testuser')).toBeInTheDocument()
  })

  it('shows Play Online dropdown with Join by Code option', async () => {
    const user = userEvent.setup()
    renderWithRouter(<HomePage />)

    await user.click(screen.getByText('Play Online'))

    await waitFor(() => {
      expect(screen.getByText('Quick Game')).toBeInTheDocument()
    })
    expect(screen.getByText('Browse Lobbies')).toBeInTheDocument()
    expect(screen.getByText('Create Private')).toBeInTheDocument()
    expect(screen.getByText('Join by Code')).toBeInTheDocument()
    expect(screen.getByText('Enter an invite code')).toBeInTheDocument()
  })

  it('shows AI difficulty picker', async () => {
    const user = userEvent.setup()
    renderWithRouter(<HomePage />)

    await user.click(screen.getByText('Play vs AI'))

    await waitFor(() => {
      expect(screen.getByText('Easy')).toBeInTheDocument()
    })
    expect(screen.getByText('Medium')).toBeInTheDocument()
    expect(screen.getByText('Hard')).toBeInTheDocument()
  })
})
