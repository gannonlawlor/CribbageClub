export enum Rank {
  ACE = 'ACE',
  TWO = 'TWO',
  THREE = 'THREE',
  FOUR = 'FOUR',
  FIVE = 'FIVE',
  SIX = 'SIX',
  SEVEN = 'SEVEN',
  EIGHT = 'EIGHT',
  NINE = 'NINE',
  TEN = 'TEN',
  JACK = 'JACK',
  QUEEN = 'QUEEN',
  KING = 'KING',
}

export enum Suit {
  CLUBS = 'CLUBS',
  DIAMONDS = 'DIAMONDS',
  HEARTS = 'HEARTS',
  SPADES = 'SPADES',
}

export interface PlayingCard {
  rank: Rank
  suit: Suit
}

export const RANK_PEGGING_VALUE: Record<Rank, number> = {
  [Rank.ACE]: 1,
  [Rank.TWO]: 2,
  [Rank.THREE]: 3,
  [Rank.FOUR]: 4,
  [Rank.FIVE]: 5,
  [Rank.SIX]: 6,
  [Rank.SEVEN]: 7,
  [Rank.EIGHT]: 8,
  [Rank.NINE]: 9,
  [Rank.TEN]: 10,
  [Rank.JACK]: 10,
  [Rank.QUEEN]: 10,
  [Rank.KING]: 10,
}

export const RANK_DISPLAY: Record<Rank, string> = {
  [Rank.ACE]: 'A',
  [Rank.TWO]: '2',
  [Rank.THREE]: '3',
  [Rank.FOUR]: '4',
  [Rank.FIVE]: '5',
  [Rank.SIX]: '6',
  [Rank.SEVEN]: '7',
  [Rank.EIGHT]: '8',
  [Rank.NINE]: '9',
  [Rank.TEN]: '10',
  [Rank.JACK]: 'J',
  [Rank.QUEEN]: 'Q',
  [Rank.KING]: 'K',
}

export const SUIT_SYMBOL: Record<Suit, string> = {
  [Suit.CLUBS]: '\u2663',
  [Suit.DIAMONDS]: '\u2666',
  [Suit.HEARTS]: '\u2665',
  [Suit.SPADES]: '\u2660',
}

export function isRedSuit(suit: Suit): boolean {
  return suit === Suit.HEARTS || suit === Suit.DIAMONDS
}

export function cardKey(card: PlayingCard): string {
  return `${card.rank}_${card.suit}`
}

export function cardsEqual(a: PlayingCard, b: PlayingCard): boolean {
  return a.rank === b.rank && a.suit === b.suit
}
