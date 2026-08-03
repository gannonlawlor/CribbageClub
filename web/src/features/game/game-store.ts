import { create } from 'zustand'
import type { GameState, GameAction, GameResponse, PlayingCard } from '@/models'
import * as api from '@/api/rest-client'
import { subscribe, publish, connectWebSocket } from '@/api/websocket-client'
import { useAuthStore } from '@/auth/auth-store'
import type { GameStateUpdateMessage } from '@/models/game-response'

export interface GameStore {
  gameState: GameState | null
  isLoading: boolean
  error: string | null
  isDiscarding: boolean
  selectedCardIndices: Set<number>

  // Timing
  turnStartedAt: string | null
  turnTimeLimitMs: number
  myTimeBankMs: number
  opponentTimeBankMs: number
  isTimed: boolean

  // Actions
  loadGame: (gameId: string) => Promise<void>
  discardCards: (cards: PlayingCard[]) => Promise<void>
  playCard: (card: PlayingCard) => Promise<void>
  cutDeck: () => Promise<void>
  sayGo: () => Promise<void>
  countHand: () => Promise<void>
  resign: () => Promise<void>
  toggleCardSelection: (index: number) => void
  clearError: () => void
  reset: () => void

  // Internal
  _actionInFlight: boolean
  _unsubscribers: (() => void)[]
}

function getPlayerId(): string {
  return useAuthStore.getState().userId ?? ''
}

function applyResponse(set: (partial: Partial<GameStore>) => void, response: GameResponse) {
  set({
    gameState: response.gameState,
    isLoading: false,
    isDiscarding: false,
    error: null,
    turnStartedAt: response.turnStartedAt ?? null,
    turnTimeLimitMs: response.turnTimeLimitMs,
    myTimeBankMs: response.myTimeBankMs,
    opponentTimeBankMs: response.opponentTimeBankMs,
    isTimed: response.isTimed,
  })
}

export const useGameStore = create<GameStore>((set, get) => ({
  gameState: null,
  isLoading: false,
  error: null,
  isDiscarding: false,
  selectedCardIndices: new Set<number>(),
  turnStartedAt: null,
  turnTimeLimitMs: 30000,
  myTimeBankMs: 120000,
  opponentTimeBankMs: 120000,
  isTimed: false,
  _actionInFlight: false,
  _unsubscribers: [],

  loadGame: async (gameId: string) => {
    set({ isLoading: true, error: null, selectedCardIndices: new Set() })

    try {
      const response = await api.getGameState(gameId)
      applyResponse(set, response)
    } catch (e) {
      set({ isLoading: false, error: e instanceof Error ? e.message : 'Failed to load game' })
      return
    }

    // Skip WebSocket for AI games — no second human player to push updates
    const isAI = get().gameState?.players.some((p) => p.id.startsWith('ai_'))
    if (isAI) return

    // Set up WebSocket subscriptions
    connectWebSocket()

    const unsub1 = subscribe(`/topic/game/${gameId}`, (body) => {
      if (get()._actionInFlight) return
      const msg = body as GameStateUpdateMessage
      const playerId = getPlayerId()
      const gs = msg.gameState
      const isPlayer1 = gs.players.length > 0 && gs.players[0].id === playerId
      set({
        gameState: gs,
        turnStartedAt: msg.turnStartedAt ?? null,
        turnTimeLimitMs: msg.turnTimeLimitMs,
        myTimeBankMs: isPlayer1 ? msg.player1TimeBankMs : msg.player2TimeBankMs,
        opponentTimeBankMs: isPlayer1 ? msg.player2TimeBankMs : msg.player1TimeBankMs,
        isTimed: msg.isTimed,
      })
    })

    const unsub2 = subscribe('/user/queue/game-state', (body) => {
      if (get()._actionInFlight) return
      const msg = body as GameStateUpdateMessage
      if (msg.gameId !== gameId) return
      const playerId = getPlayerId()
      const gs = msg.gameState
      const isPlayer1 = gs.players.length > 0 && gs.players[0].id === playerId
      set({
        gameState: gs,
        turnStartedAt: msg.turnStartedAt ?? null,
        turnTimeLimitMs: msg.turnTimeLimitMs,
        myTimeBankMs: isPlayer1 ? msg.player1TimeBankMs : msg.player2TimeBankMs,
        opponentTimeBankMs: isPlayer1 ? msg.player2TimeBankMs : msg.player1TimeBankMs,
        isTimed: msg.isTimed,
      })
    })

    const unsub3 = subscribe('/user/queue/errors', (body) => {
      const msg = body as { gameId: string; error: string }
      if (msg.gameId === gameId) {
        set({ error: msg.error })
      }
    })

    set({ _unsubscribers: [unsub1, unsub2, unsub3] })

    publish('/app/game/join', { gameId })
  },

  discardCards: async (cards: PlayingCard[]) => {
    const { gameState, isDiscarding } = get()
    if (!gameState || isDiscarding) return
    const playerId = getPlayerId()

    set({ _actionInFlight: true, isDiscarding: true, error: null })
    try {
      let lastResponse: GameResponse | undefined
      for (const card of cards) {
        const action: GameAction = { type: 'DiscardToCrib', playerId, card }
        lastResponse = await api.applyAction(gameState.gameId, action)
      }
      if (lastResponse) {
        applyResponse(set, lastResponse)
        set({ selectedCardIndices: new Set() })
      }
    } catch (e) {
      set({ isDiscarding: false, error: e instanceof Error ? e.message : 'Discard failed' })
    } finally {
      set({ _actionInFlight: false })
    }
  },

  playCard: async (card: PlayingCard) => {
    const { gameState } = get()
    if (!gameState) return
    const playerId = getPlayerId()

    set({ _actionInFlight: true, error: null })
    try {
      const action: GameAction = { type: 'PlayCard', playerId, card }
      const response = await api.applyAction(gameState.gameId, action)
      applyResponse(set, response)
    } catch (e) {
      set({ error: e instanceof Error ? e.message : 'Play card failed' })
    } finally {
      set({ _actionInFlight: false })
    }
  },

  cutDeck: async () => {
    const { gameState } = get()
    if (!gameState) return
    const playerId = getPlayerId()

    set({ _actionInFlight: true, error: null })
    try {
      const action: GameAction = { type: 'CutDeck', playerId }
      const response = await api.applyAction(gameState.gameId, action)
      applyResponse(set, response)
    } catch (e) {
      set({ error: e instanceof Error ? e.message : 'Cut failed' })
    } finally {
      set({ _actionInFlight: false })
    }
  },

  sayGo: async () => {
    const { gameState } = get()
    if (!gameState) return
    const playerId = getPlayerId()

    set({ _actionInFlight: true, error: null })
    try {
      const action: GameAction = { type: 'Go', playerId }
      const response = await api.applyAction(gameState.gameId, action)
      applyResponse(set, response)
    } catch (e) {
      set({ error: e instanceof Error ? e.message : 'Go failed' })
    } finally {
      set({ _actionInFlight: false })
    }
  },

  countHand: async () => {
    const { gameState } = get()
    if (!gameState) return
    const playerId = getPlayerId()

    set({ _actionInFlight: true, error: null })
    try {
      const action: GameAction = { type: 'CountHand', playerId }
      const response = await api.applyAction(gameState.gameId, action)
      applyResponse(set, response)
    } catch (e) {
      set({ error: e instanceof Error ? e.message : 'Count failed' })
    } finally {
      set({ _actionInFlight: false })
    }
  },

  resign: async () => {
    const { gameState } = get()
    if (!gameState) return

    set({ _actionInFlight: true, error: null })
    try {
      const response = await api.resignGame(gameState.gameId)
      applyResponse(set, response)
    } catch (e) {
      set({ error: e instanceof Error ? e.message : 'Resign failed' })
    } finally {
      set({ _actionInFlight: false })
    }
  },

  toggleCardSelection: (index: number) => {
    const next = new Set(get().selectedCardIndices)
    if (next.has(index)) {
      next.delete(index)
    } else {
      if (next.size < 2) {
        next.add(index)
      }
    }
    set({ selectedCardIndices: next })
  },


  clearError: () => set({ error: null }),

  reset: () => {
    const { _unsubscribers, gameState } = get()
    for (const unsub of _unsubscribers) unsub()
    if (gameState) {
      publish('/app/game/leave', { gameId: gameState.gameId })
    }
    set({
      gameState: null,
      isLoading: false,
      error: null,
      isDiscarding: false,
      selectedCardIndices: new Set(),
      _actionInFlight: false,
      _unsubscribers: [],
    })
  },
}))

export function isLocalGame(gameId: string): boolean {
  return gameId.startsWith('local_')
}
