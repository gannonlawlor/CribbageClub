import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { renderWithRouter } from '@/test/render'
import { JoinByCodePage } from './JoinByCodePage'
import * as api from '@/api/rest-client'
import { LobbyStatus } from '@/models/lobby'

vi.mock('@/api/rest-client')

const mockApi = vi.mocked(api)

beforeEach(() => {
  vi.clearAllMocks()
})

describe('JoinByCodePage', () => {
  it('renders input and join button', () => {
    renderWithRouter(<JoinByCodePage />)

    expect(screen.getByText('Join by Code')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Enter invite code')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Join' })).toBeInTheDocument()
  })

  it('uppercases input as user types', async () => {
    const user = userEvent.setup()
    renderWithRouter(<JoinByCodePage />)

    const input = screen.getByPlaceholderText('Enter invite code')
    await user.type(input, 'crib-abc1')

    expect(input).toHaveValue('CRIB-ABC1')
  })

  it('disables Join button when input is empty', () => {
    renderWithRouter(<JoinByCodePage />)

    expect(screen.getByRole('button', { name: 'Join' })).toBeDisabled()
  })

  it('calls joinByCode on submit', async () => {
    mockApi.joinByCode.mockResolvedValue({
      lobby: {
        id: 'lobby1',
        name: 'Test',
        players: [],
        maxPlayers: 2,
        status: LobbyStatus.WAITING,
        createdAt: '2025-01-01',
        isPrivate: true,
      },
    })

    const user = userEvent.setup()
    renderWithRouter(<JoinByCodePage />)

    await user.type(screen.getByPlaceholderText('Enter invite code'), 'CRIB-XY99')
    await user.click(screen.getByRole('button', { name: 'Join' }))

    await waitFor(() => {
      expect(mockApi.joinByCode).toHaveBeenCalledWith('CRIB-XY99')
    })
  })

  it('shows error on failure', async () => {
    mockApi.joinByCode.mockRejectedValue(new Error('Lobby not found'))

    const user = userEvent.setup()
    renderWithRouter(<JoinByCodePage />)

    await user.type(screen.getByPlaceholderText('Enter invite code'), 'BADCODE')
    await user.click(screen.getByRole('button', { name: 'Join' }))

    await waitFor(() => {
      expect(screen.getByText('Lobby not found')).toBeInTheDocument()
    })
  })
})
