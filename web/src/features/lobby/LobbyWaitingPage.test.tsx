import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { render } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router'
import { LobbyWaitingPage } from './LobbyWaitingPage'
import * as api from '@/api/rest-client'
import { LobbyStatus } from '@/models/lobby'

vi.mock('@/api/rest-client')
vi.mock('@/api/websocket-client', () => ({
  connectWebSocket: vi.fn(),
  subscribe: vi.fn(() => vi.fn()),
}))

const mockApi = vi.mocked(api)

function renderLobbyPage() {
  return render(
    <MemoryRouter initialEntries={['/lobby/lobby1']}>
      <Routes>
        <Route path="/lobby/:lobbyId" element={<LobbyWaitingPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

beforeEach(() => {
  vi.clearAllMocks()
  // Stub clipboard API for jsdom
  Object.defineProperty(navigator, 'clipboard', {
    value: { writeText: vi.fn().mockResolvedValue(undefined) },
    writable: true,
    configurable: true,
  })
})

describe('LobbyWaitingPage', () => {
  it('shows lobby with invite code and copy button', async () => {
    mockApi.getLobby.mockResolvedValue({
      id: 'lobby1',
      name: "Test's game",
      players: [{ id: 'u1', name: 'TestUser', joinedAt: '2025-01-01' }],
      maxPlayers: 2,
      status: LobbyStatus.WAITING,
      createdAt: '2025-01-01',
      isPrivate: true,
      inviteCode: 'CRIB-ABC1',
    })

    renderLobbyPage()

    await waitFor(() => {
      expect(screen.getByText('CRIB-ABC1')).toBeInTheDocument()
    })
    expect(screen.getByText('Copy')).toBeInTheDocument()
    expect(screen.getByText('TestUser')).toBeInTheDocument()
  })

  it('copies invite code to clipboard on Copy click', async () => {
    mockApi.getLobby.mockResolvedValue({
      id: 'lobby1',
      name: "Test's game",
      players: [{ id: 'u1', name: 'TestUser', joinedAt: '2025-01-01' }],
      maxPlayers: 2,
      status: LobbyStatus.WAITING,
      createdAt: '2025-01-01',
      isPrivate: true,
      inviteCode: 'CRIB-XY99',
    })

    const user = userEvent.setup()
    renderLobbyPage()

    await waitFor(() => {
      expect(screen.getByText('Copy')).toBeInTheDocument()
    })

    await user.click(screen.getByText('Copy'))

    // "Copied!" feedback confirms clipboard.writeText was called and resolved
    await waitFor(() => {
      expect(screen.getByText('Copied!')).toBeInTheDocument()
    })
  })

  it('shows waiting message when lobby is not full', async () => {
    mockApi.getLobby.mockResolvedValue({
      id: 'lobby1',
      name: 'Lobby',
      players: [{ id: 'u1', name: 'Host', joinedAt: '2025-01-01' }],
      maxPlayers: 2,
      status: LobbyStatus.WAITING,
      createdAt: '2025-01-01',
      isPrivate: false,
    })

    renderLobbyPage()

    await waitFor(() => {
      expect(screen.getByText('Waiting for opponent...')).toBeInTheDocument()
    })
  })
})
