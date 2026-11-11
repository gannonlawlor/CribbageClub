import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { CardWidget } from './CardWidget'
import { Rank, Suit } from '@/models/card'

it('names the card and supports keyboard selection', async () => {
  const click = vi.fn()
  render(<CardWidget card={{ rank: Rank.SEVEN, suit: Suit.SPADES }} selected onClick={click} />)
  const card = screen.getByRole('button', { name: 'seven of spades', pressed: true })
  card.focus()
  await userEvent.keyboard('{Enter} ')
  expect(click).toHaveBeenCalledTimes(2)
})
