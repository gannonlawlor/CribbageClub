import { usePracticePuzzleStore } from './practice-puzzle-store'
import { usePuzzleStore } from '@/features/daily-puzzle/puzzle-store'
import { evaluateAllKeeps } from '@/features/daily-puzzle/puzzle-generator'

vi.mock('@/features/daily-puzzle/puzzle-generator', async (original) => ({
  ...await original<typeof import('@/features/daily-puzzle/puzzle-generator')>(),
  evaluateAllKeeps: vi.fn(),
}))

for (const failure of ['empty', 'throw'] as const) {
  it(`preserves practice and daily attempts when analysis is ${failure}`, async () => {
    vi.mocked(evaluateAllKeeps).mockImplementation(() => {
      if (failure === 'throw') throw new Error('Unavailable')
      return []
    })
    const practice = usePracticePuzzleStore
    practice.getState().reset()
    practice.getState().loadPuzzle()
    for (const card of practice.getState().puzzle!.hand.slice(0, 4)) practice.getState().toggleCard(card)
    practice.getState().submitKeep()
    expect(practice.getState()).toMatchObject({ phase: 'playing', totalSolved: 0, isSubmitting: false })
    expect(practice.getState().selectedCards).toHaveLength(4)
    expect(practice.getState().error).toContain('attempt is safe')

    localStorage.clear()
    const daily = usePuzzleStore
    daily.getState().reset()
    daily.getState().loadPuzzle()
    for (const card of daily.getState().puzzleSet!.puzzles[0].hand.slice(0, 4)) daily.getState().toggleCard(card)
    await daily.getState().submitKeep()
    expect(daily.getState()).toMatchObject({ phase: 'playing', currentPuzzleIndex: 0, isSubmitting: false })
    expect(daily.getState().playerRanks).toEqual([null, null, null, null, null])
    expect(daily.getState().selectedCards).toHaveLength(4)
    expect(localStorage.length).toBe(0)
  })
}
