import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { renderWithRouter } from '@/test/render'
import { FriendsPage } from './FriendsPage'
import { useAuthStore } from '@/auth/auth-store'
import * as api from '@/api/rest-client'
import { LobbyStatus } from '@/models/lobby'

vi.mock('@/api/rest-client')
vi.mock('@/api/websocket-client', () => ({
  connectWebSocket: vi.fn(),
  subscribe: vi.fn(() => vi.fn()),
}))

const mockApi = vi.mocked(api)

function setLoggedIn() {
  useAuthStore.setState({
    token: 'test-token',
    userId: 'user1',
    username: 'testuser',
    isGuest: false,
    // isLoggedIn is a getter on initial state but gets flattened by zustand's
    // Object.assign during setState — must be set explicitly in tests
    isLoggedIn: true,
  })
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

describe('FriendsPage', () => {
  it('shows login message when not logged in', () => {
    renderWithRouter(<FriendsPage />)
    expect(screen.getByText('Log in to manage friends.')).toBeInTheDocument()
  })

  it('renders three tabs when logged in', async () => {
    setLoggedIn()
    mockApi.getFriends.mockResolvedValue([])
    renderWithRouter(<FriendsPage />)

    expect(screen.getByRole('button', { name: 'Friends' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Requests' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Find' })).toBeInTheDocument()
  })

  it('shows friends with display name and online status', async () => {
    setLoggedIn()
    mockApi.getFriends.mockResolvedValue([
      {
        friendshipId: 'f1',
        userId: 'u1',
        username: 'alice',
        displayName: 'Alice W',
        isOnline: true,
        since: '2025-01-01',
      },
    ])
    renderWithRouter(<FriendsPage />)

    await waitFor(() => {
      expect(screen.getByText('Alice W')).toBeInTheDocument()
    })
    expect(screen.getByText('@alice')).toBeInTheDocument()
    expect(screen.getByText('Challenge')).toBeInTheDocument()
  })

  it('shows username when no display name', async () => {
    setLoggedIn()
    mockApi.getFriends.mockResolvedValue([
      {
        friendshipId: 'f1',
        userId: 'u1',
        username: 'bob',
        isOnline: false,
        since: '2025-01-01',
      },
    ])
    renderWithRouter(<FriendsPage />)

    await waitFor(() => {
      expect(screen.getByText('bob')).toBeInTheDocument()
    })
    expect(screen.queryByText('@bob')).not.toBeInTheDocument()
  })

  it('switches to Requests tab and shows friend requests', async () => {
    setLoggedIn()
    mockApi.getFriends.mockResolvedValue([])
    mockApi.getIncomingFriendRequests.mockResolvedValue([
      {
        friendshipId: 'r1',
        fromUserId: 'u2',
        fromUsername: 'charlie',
        createdAt: '2025-01-01',
      },
    ])
    mockApi.getIncomingChallenges.mockResolvedValue([])

    const user = userEvent.setup()
    renderWithRouter(<FriendsPage />)

    await user.click(screen.getByRole('button', { name: 'Requests' }))

    await waitFor(() => {
      expect(screen.getByText('charlie')).toBeInTheDocument()
    })
    expect(screen.getAllByText('Accept')[0]).toBeInTheDocument()
    expect(screen.getAllByText('Decline')[0]).toBeInTheDocument()
  })

  it('switches to Requests tab and shows incoming challenges', async () => {
    setLoggedIn()
    mockApi.getFriends.mockResolvedValue([])
    mockApi.getIncomingFriendRequests.mockResolvedValue([])
    mockApi.getIncomingChallenges.mockResolvedValue([
      {
        id: 'lobby1',
        name: 'Challenge',
        players: [{ id: 'u2', name: 'Dana', joinedAt: '2025-01-01' }],
        maxPlayers: 2,
        status: LobbyStatus.WAITING,
        createdAt: '2025-01-01',
        isPrivate: true,
      },
    ])

    const user = userEvent.setup()
    renderWithRouter(<FriendsPage />)

    await user.click(screen.getByRole('button', { name: 'Requests' }))

    await waitFor(() => {
      expect(screen.getByText('Dana wants to play!')).toBeInTheDocument()
    })
  })

  it('switches to Find tab and searches with debounce', async () => {
    setLoggedIn()
    mockApi.getFriends.mockResolvedValue([])
    mockApi.searchUsers.mockResolvedValue([
      {
        userId: 'u3',
        username: 'eve',
        displayName: 'Eve S',
      },
    ])

    const user = userEvent.setup()
    renderWithRouter(<FriendsPage />)

    await user.click(screen.getByRole('button', { name: 'Find' }))
    await user.type(screen.getByPlaceholderText('Search by username...'), 'eve')

    expect(mockApi.searchUsers).not.toHaveBeenCalled()

    await waitFor(() => {
      expect(mockApi.searchUsers).toHaveBeenCalledWith('eve')
    })

    await waitFor(() => {
      expect(screen.getByText('Eve S')).toBeInTheDocument()
    })
    expect(screen.getByText('@eve')).toBeInTheDocument()
    expect(screen.getByText('Add Friend')).toBeInTheDocument()
  })

  it('shows relationship badges in Find results', async () => {
    setLoggedIn()
    mockApi.getFriends.mockResolvedValue([])
    mockApi.searchUsers.mockResolvedValue([
      { userId: 'u3', username: 'eve', relationshipStatus: 'FRIENDS' },
      { userId: 'u4', username: 'frank', relationshipStatus: 'REQUEST_SENT' },
    ])

    const user = userEvent.setup()
    renderWithRouter(<FriendsPage />)

    await user.click(screen.getByRole('button', { name: 'Find' }))
    await user.type(screen.getByPlaceholderText('Search by username...'), 'e')

    await waitFor(() => {
      // Badge text — not the tab button
      expect(screen.getByText('Request Sent')).toBeInTheDocument()
    })
    // The "Friends" badge should appear as a span within the search results
    const badges = screen.getAllByText('Friends')
    // At least one is the relationship badge (in addition to the tab button)
    expect(badges.length).toBeGreaterThanOrEqual(2)
    expect(screen.queryByText('Add Friend')).not.toBeInTheDocument()
  })

  it('calls createChallenge on Challenge click', async () => {
    setLoggedIn()
    mockApi.getFriends.mockResolvedValue([
      {
        friendshipId: 'f1',
        userId: 'u1',
        username: 'alice',
        isOnline: true,
        since: '2025-01-01',
      },
    ])
    mockApi.createChallenge.mockResolvedValue({
      id: 'lobby123',
      name: 'Challenge',
      players: [],
      maxPlayers: 2,
      status: LobbyStatus.WAITING,
      createdAt: '2025-01-01',
      isPrivate: true,
    })

    const user = userEvent.setup()
    renderWithRouter(<FriendsPage />)

    await waitFor(() => {
      expect(screen.getByText('Challenge')).toBeInTheDocument()
    })

    await user.click(screen.getByText('Challenge'))

    await waitFor(() => {
      expect(mockApi.createChallenge).toHaveBeenCalledWith('u1')
    })
  })
})
