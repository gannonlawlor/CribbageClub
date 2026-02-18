import type { PlayingCard, GameHistoryEvent } from '@/models'
import { RANK_DISPLAY, SUIT_SYMBOL } from '@/models/card'
import type { ScoreBreakdown } from '@/models/score-breakdown'

export interface ReplayPlayer {
  id: string
  name: string
  hand: PlayingCard[]
  score: number
}

export interface ReplaySnapshot {
  eventIndex: number
  event: GameHistoryEvent
  description: string
  scoring: string | null
  player1: ReplayPlayer
  player2: ReplayPlayer
  cutCard: PlayingCard | null
  playedCards: PlayingCard[]
  peggingCount: number
  dealerIndex: number
  roundNumber: number
  stage: string
  /** Cards highlighted in the current event (e.g. the card just played) */
  highlightCards: PlayingCard[]
  /** Hand/crib being shown for counting */
  countingHand: PlayingCard[] | null
  countingBreakdown: ScoreBreakdown | null
  cribCards: PlayingCard[] | null
}

function cardStr(card: PlayingCard): string {
  return `${RANK_DISPLAY[card.rank]}${SUIT_SYMBOL[card.suit]}`
}

function playerName(id: string, p1: ReplayPlayer, p2: ReplayPlayer): string {
  if (id === p1.id) return p1.name
  if (id === p2.id) return p2.name
  return id
}

function removeCard(hand: PlayingCard[], card: PlayingCard): PlayingCard[] {
  const idx = hand.findIndex((c) => c.rank === card.rank && c.suit === card.suit)
  if (idx < 0) return hand
  return [...hand.slice(0, idx), ...hand.slice(idx + 1)]
}

function breakdownStr(b: ScoreBreakdown): string {
  const parts: string[] = []
  if (b.fifteens > 0) parts.push(`Fifteens: ${b.fifteens}`)
  if (b.pairs > 0) parts.push(`Pairs: ${b.pairs}`)
  if (b.runs > 0) parts.push(`Runs: ${b.runs}`)
  if (b.flushes > 0) parts.push(`Flush: ${b.flushes}`)
  if (b.nobs > 0) parts.push(`Nobs: ${b.nobs}`)
  return parts.length > 0 ? parts.join(', ') : 'No points'
}

/**
 * Build an array of ReplaySnapshot from game history events.
 * Each snapshot represents the board state *after* that event has been applied.
 */
export function buildSnapshots(
  history: GameHistoryEvent[],
  p1Id: string,
  p1Name: string,
  p2Id: string,
  p2Name: string,
  initialDealerIndex: number,
): ReplaySnapshot[] {
  const snapshots: ReplaySnapshot[] = []

  let player1: ReplayPlayer = { id: p1Id, name: p1Name, hand: [], score: 0 }
  let player2: ReplayPlayer = { id: p2Id, name: p2Name, hand: [], score: 0 }
  let cutCard: PlayingCard | null = null
  let playedCards: PlayingCard[] = []
  let peggingCount = 0
  let dealerIndex = initialDealerIndex
  let roundNumber = 0
  let stage = 'Starting'

  for (let i = 0; i < history.length; i++) {
    const event = history[i]
    let description = ''
    let scoring: string | null = null
    let highlightCards: PlayingCard[] = []
    let countingHand: PlayingCard[] | null = null
    let countingBreakdown: ScoreBreakdown | null = null
    let cribCards: PlayingCard[] | null = null

    switch (event.type) {
      case 'RoundStarted':
        roundNumber = event.roundNumber
        cutCard = null
        playedCards = []
        peggingCount = 0
        player1 = { ...player1, hand: [] }
        player2 = { ...player2, hand: [] }
        stage = 'Dealing'
        description = `Round ${event.roundNumber}`
        // Alternate dealer each round after the first
        if (roundNumber > 1) {
          dealerIndex = 1 - dealerIndex
        }
        break

      case 'CardsDealt':
        player1 = { ...player1, hand: event.dealtHands[p1Id] ?? [] }
        player2 = { ...player2, hand: event.dealtHands[p2Id] ?? [] }
        stage = 'Discarding'
        description = 'Cards dealt'
        break

      case 'DeckCut':
        cutCard = event.cutCard
        highlightCards = [event.cutCard]
        stage = 'Pegging'
        description = `${playerName(event.cuttingPlayerId, player1, player2)} cut ${cardStr(event.cutCard)}`
        if (event.dealerScoredNobs) {
          const dealerPlayer = dealerIndex === 0 ? player1 : player2
          scoring = `His Nobs! ${dealerPlayer.name} +2`
          if (dealerIndex === 0) {
            player1 = { ...player1, score: player1.score + 2 }
          } else {
            player2 = { ...player2, score: player2.score + 2 }
          }
        }
        break

      case 'CardPlayed': {
        const card = event.card
        highlightCards = [card]
        // Remove from the player's hand
        if (event.playerId === p1Id) {
          player1 = { ...player1, hand: removeCard(player1.hand, card) }
        } else {
          player2 = { ...player2, hand: removeCard(player2.hand, card) }
        }
        playedCards = [...playedCards, card]
        peggingCount = event.newCount
        stage = 'Pegging'
        description = `${playerName(event.playerId, player1, player2)} played ${cardStr(card)} (count: ${event.newCount})`
        if (event.pointsScored > 0) {
          scoring = `+${event.pointsScored}${event.scoringReason ? ` ${event.scoringReason}` : ''}`
          if (event.playerId === p1Id) {
            player1 = { ...player1, score: player1.score + event.pointsScored }
          } else {
            player2 = { ...player2, score: player2.score + event.pointsScored }
          }
        }
        break
      }

      case 'GoAnnounced':
        stage = 'Pegging'
        description = `${playerName(event.playerId, player1, player2)} said Go`
        if (event.pointsScored > 0) {
          scoring = `+${event.pointsScored}`
          if (event.playerId === p1Id) {
            player1 = { ...player1, score: player1.score + event.pointsScored }
          } else {
            player2 = { ...player2, score: player2.score + event.pointsScored }
          }
        }
        break

      case 'PeggingEnded':
        playedCards = []
        peggingCount = 0
        stage = 'Counting'
        description = 'Pegging ended'
        break

      case 'HandCounted':
        countingHand = event.hand
        countingBreakdown = event.scoreBreakdown
        stage = 'Counting'
        description = `${playerName(event.playerId, player1, player2)} hand: +${event.totalPoints}`
        scoring = breakdownStr(event.scoreBreakdown)
        highlightCards = event.hand
        if (event.playerId === p1Id) {
          player1 = { ...player1, score: player1.score + event.totalPoints }
        } else {
          player2 = { ...player2, score: player2.score + event.totalPoints }
        }
        break

      case 'CribCounted':
        cribCards = event.cribCards
        countingHand = event.cribCards
        countingBreakdown = event.scoreBreakdown
        stage = 'Counting'
        description = `${playerName(event.dealerPlayerId, player1, player2)} crib: +${event.totalPoints}`
        scoring = breakdownStr(event.scoreBreakdown)
        highlightCards = event.cribCards
        if (event.dealerPlayerId === p1Id) {
          player1 = { ...player1, score: player1.score + event.totalPoints }
        } else {
          player2 = { ...player2, score: player2.score + event.totalPoints }
        }
        break

      case 'GameEnded':
        stage = 'Game Over'
        description = `${playerName(event.winnerPlayerId, player1, player2)} wins!`
        scoring = `Final score: ${event.finalScore}`
        break

      case 'GameForfeited':
        stage = 'Game Over'
        description = `${playerName(event.forfeitingPlayerId, player1, player2)} forfeited (${event.reason})`
        break
    }

    snapshots.push({
      eventIndex: i,
      event,
      description,
      scoring,
      player1: { ...player1 },
      player2: { ...player2 },
      cutCard,
      playedCards: [...playedCards],
      peggingCount,
      dealerIndex,
      roundNumber,
      stage,
      highlightCards,
      countingHand,
      countingBreakdown,
      cribCards,
    })
  }

  return snapshots
}
