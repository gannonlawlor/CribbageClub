import { screen, waitFor } from '@testing-library/react'
import { renderWithRouter } from '@/test/render'
import { Layout } from './Layout'
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

describe('Layout', () => {
  it('shows Sign In link when logged out', () => {
    renderWithRouter(<Layout />)
    expect(screen.getByText('Sign In')).toBeInTheDocument()
    expect(screen.queryByText('Friends')).not.toBeInTheDocument()
  })

  it('shows nav links and username when logged in', async () => {
    useAuthStore.setState({
      token: 'test-token',
      userId: 'u1',
      username: 'testuser',
      isGuest: false,
      isLoggedIn: true,
    })
    mockApi.getNotificationCount.mockResolvedValue({ friendRequests: 0, challenges: 0, total: 0 })

    renderWithRouter(<Layout />)
    expect(screen.getByText('Friends')).toBeInTheDocument()
    expect(screen.getByText('testuser')).toBeInTheDocument()
    expect(screen.getByText('Logout')).toBeInTheDocument()
  })

  it('hides Friends link for guest users', () => {
    useAuthStore.setState({
      token: 'test-token',
      userId: 'u1',
      username: 'guest123',
      isGuest: true,
      isLoggedIn: true,
    })

    renderWithRouter(<Layout />)
    expect(screen.queryByText('Friends')).not.toBeInTheDocument()
    expect(screen.getByText('Upgrade')).toBeInTheDocument()
  })

  it('shows notification badge when count > 0', async () => {
    useAuthStore.setState({
      token: 'test-token',
      userId: 'u1',
      username: 'testuser',
      isGuest: false,
      isLoggedIn: true,
    })
    mockApi.getNotificationCount.mockResolvedValue({ friendRequests: 2, challenges: 1, total: 3 })

    renderWithRouter(<Layout />)

    await waitFor(() => {
      expect(screen.getByText('3')).toBeInTheDocument()
    })
  })

  it('does not show badge when count is 0', async () => {
    useAuthStore.setState({
      token: 'test-token',
      userId: 'u1',
      username: 'testuser',
      isGuest: false,
      isLoggedIn: true,
    })
    mockApi.getNotificationCount.mockResolvedValue({ friendRequests: 0, challenges: 0, total: 0 })

    renderWithRouter(<Layout />)

    await waitFor(() => {
      expect(mockApi.getNotificationCount).toHaveBeenCalled()
    })
    expect(screen.queryByText('0')).not.toBeInTheDocument()
  })
})
