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

// The layout renders both the desktop sidebar and the mobile top bar
// (visibility is CSS-only), so shared labels appear twice in jsdom.
describe('Layout', () => {
  it('shows Log In link when logged out', () => {
    renderWithRouter(<Layout />)
    expect(screen.getAllByText('Log In').length).toBeGreaterThan(0)
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
    expect(screen.getAllByText('Friends').length).toBeGreaterThan(0)
    expect(screen.getByText('testuser')).toBeInTheDocument()
    expect(screen.getAllByText('Log Out').length).toBeGreaterThan(0)
  })

  it('hides Friends link and offers Sign Up for guest users', () => {
    useAuthStore.setState({
      token: 'test-token',
      userId: 'u1',
      username: 'guest123',
      isGuest: true,
      isLoggedIn: true,
    })

    renderWithRouter(<Layout />)
    expect(screen.queryByText('Friends')).not.toBeInTheDocument()
    expect(screen.getAllByText('Sign Up').length).toBeGreaterThan(0)
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
      expect(screen.getAllByText('3').length).toBeGreaterThan(0)
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
