import { useEffect, useRef } from 'react'

interface CribbageBoardStandardProps {
  playerScore: number
  opponentScore: number
}

const GROUP_SIZE = 5
const HOLES_PER_ROW = 30
const NUM_ROWS = 4

// Colors
// Flattened board per design language: warmth in the tint, not the texture
const BOARD_BG = '#38342f'
const BOARD_BG_LIGHT = '#3d3934'
const BOARD_EDGE = 'rgba(255,255,255,0.08)'
const HOLE_COLOR = '#211f1d'
const PEG_SELF = '#81b64c'
const PEG_OPP = '#d9d4cc'
const GOLD_121 = '#e3aa24'
const MILESTONE_COLOR = 'rgba(255,255,255,0.35)'

export function CribbageBoardStandard({ playerScore, opponentScore }: CribbageBoardStandardProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const animRef = useRef({ playerScore: 0, opponentScore: 0 })
  const frameRef = useRef<number>(0)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const targetPlayer = playerScore
    const targetOpponent = opponentScore

    function animate() {
      const speed = 0.08
      const prev = animRef.current
      prev.playerScore += (targetPlayer - prev.playerScore) * speed
      prev.opponentScore += (targetOpponent - prev.opponentScore) * speed

      if (Math.abs(prev.playerScore - targetPlayer) < 0.1) prev.playerScore = targetPlayer
      if (Math.abs(prev.opponentScore - targetOpponent) < 0.1) prev.opponentScore = targetOpponent

      draw(canvas!, prev.playerScore, prev.opponentScore)

      if (prev.playerScore !== targetPlayer || prev.opponentScore !== targetOpponent) {
        frameRef.current = requestAnimationFrame(animate)
      }
    }

    frameRef.current = requestAnimationFrame(animate)
    return () => cancelAnimationFrame(frameRef.current)
  }, [playerScore, opponentScore])

  useEffect(() => {
    const canvas = canvasRef.current
    if (canvas) draw(canvas, 0, 0)
  }, [])

  return (
    <canvas
      ref={canvasRef}
      className="w-full h-full"
      style={{ display: 'block' }}
    />
  )
}

/** Map hole number (1-121) to [row, positionInRow] */
function holeToRowPos(hole: number): [number, number] {
  if (hole <= 0) return [0, -1] // start position
  if (hole > 120) return [NUM_ROWS, 0] // finish hole (121)
  const idx = hole - 1
  const row = Math.floor(idx / HOLES_PER_ROW)
  const posInRow = idx % HOLES_PER_ROW
  return [row, posInRow]
}

function draw(canvas: HTMLCanvasElement, playerScore: number, opponentScore: number) {
  const rect = canvas.getBoundingClientRect()
  const dpr = window.devicePixelRatio || 1
  canvas.width = rect.width * dpr
  canvas.height = rect.height * dpr
  const ctx = canvas.getContext('2d')
  if (!ctx) return
  ctx.scale(dpr, dpr)

  const w = rect.width
  const h = rect.height

  // Board dimensions
  const padX = 20
  const padY = 16
  const boardW = w - padX * 2
  const boardH = h - padY * 2

  // Draw board background
  drawBoard(ctx, padX, padY, boardW, boardH)

  // Track layout
  const trackSep = 6 // vertical distance between player and opponent holes in same row
  const holeR = Math.max(1.5, boardW * 0.004)
  const pegR = holeR * 2.2

  // Calculate row Y positions (4 rows of holes + finish row)
  const rowAreaH = boardH - 24 // leave room for top/bottom inner padding
  const rowSpacing = rowAreaH / NUM_ROWS
  const rowYs: number[] = []
  for (let r = 0; r < NUM_ROWS; r++) {
    rowYs.push(padY + 14 + r * rowSpacing)
  }
  const finishY = padY + 14 + NUM_ROWS * rowSpacing - rowSpacing * 0.3

  // Calculate X positions for holes in a row
  const innerPadX = 14
  const availW = boardW - innerPadX * 2
  const numGroups = HOLES_PER_ROW / GROUP_SIZE // 6
  const groupGap = availW * 0.04
  const groupWidth = (availW - (numGroups - 1) * groupGap) / numGroups
  const holeSpacing = groupWidth / (GROUP_SIZE - 1)

  function holeX(posInRow: number, row: number): number {
    const group = Math.floor(posInRow / GROUP_SIZE)
    const inGroup = posInRow % GROUP_SIZE
    let x = padX + innerPadX + group * (groupWidth + groupGap) + inGroup * holeSpacing
    // Odd rows go right-to-left
    if (row % 2 === 1) {
      x = padX + innerPadX + availW - (group * (groupWidth + groupGap) + inGroup * holeSpacing)
    }
    return x
  }

  // Draw all holes
  for (let hole = 1; hole <= 120; hole++) {
    const [row, pos] = holeToRowPos(hole)
    const x = holeX(pos, row)
    const yBase = rowYs[row]
    // Player track (top) and opponent track (bottom)
    drawHole(ctx, x, yBase - trackSep / 2, holeR)
    drawHole(ctx, x, yBase + trackSep / 2, holeR)
  }

  // Finish hole (121) — the only gold on the field
  const actualFinishX = padX + innerPadX
  drawHole(ctx, actualFinishX, finishY, holeR * 1.3)
  drawHole(ctx, actualFinishX + trackSep * 1.5, finishY, holeR * 1.3)
  ctx.strokeStyle = GOLD_121
  ctx.lineWidth = 1.5
  ctx.beginPath()
  ctx.arc(actualFinishX, finishY, holeR * 2, 0, Math.PI * 2)
  ctx.stroke()
  ctx.beginPath()
  ctx.arc(actualFinishX + trackSep * 1.5, finishY, holeR * 2, 0, Math.PI * 2)
  ctx.stroke()

  // Draw milestone labels
  const milestones = [30, 60, 90, 120]
  ctx.fillStyle = MILESTONE_COLOR
  ctx.font = `bold ${Math.max(8, boardW * 0.028)}px system-ui`
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  for (const m of milestones) {
    const [row, pos] = holeToRowPos(m)
    const x = holeX(pos, row)
    const y = rowYs[row]
    ctx.fillText(`${m}`, x, y + trackSep / 2 + trackSep + 2)
  }
  // 121 label
  ctx.fillText('121', actualFinishX + trackSep * 0.75, finishY + trackSep + 4)

  // Start label
  const startX = padX + innerPadX
  const startY = rowYs[0]
  ctx.fillStyle = MILESTONE_COLOR
  ctx.textAlign = 'left'
  ctx.fillText('S', startX - 8, startY)

  // Draw pegs
  function pegPos(score: number, trackOffset: number): [number, number] {
    if (score <= 0) {
      // Starting position — just before hole 1
      const x = holeX(0, 0)
      return [x - holeSpacing, rowYs[0] + trackOffset]
    }
    if (score >= 121) {
      const yOff = trackOffset > 0 ? trackSep * 1.5 : 0
      return [actualFinishX + yOff, finishY]
    }
    const clamped = Math.min(score, 120)
    const intScore = Math.floor(clamped)
    const frac = clamped - intScore
    const [row, pos] = holeToRowPos(intScore)
    const x1 = holeX(pos, row)
    const y1 = rowYs[row] + trackOffset

    if (frac === 0) return [x1, y1]

    // Interpolate to next hole
    const nextHole = intScore + 1
    if (nextHole > 120) {
      return [x1 + (actualFinishX - x1) * frac, y1 + (finishY - y1) * frac]
    }
    const [nRow, nPos] = holeToRowPos(nextHole)
    const x2 = holeX(nPos, nRow)
    const y2 = rowYs[nRow] + trackOffset
    return [x1 + (x2 - x1) * frac, y1 + (y2 - y1) * frac]
  }

  const playerPos = pegPos(playerScore, -trackSep / 2)
  const opponentPos = pegPos(opponentScore, trackSep / 2)
  drawPeg(ctx, opponentPos, PEG_OPP, pegR)
  drawPeg(ctx, playerPos, PEG_SELF, pegR)
}

function drawBoard(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number) {
  const r = 6
  // Board shadow
  ctx.fillStyle = 'rgba(0,0,0,0.3)'
  roundRect(ctx, x + 2, y + 2, w, h, r)
  ctx.fill()

  // Board body with gradient
  const grad = ctx.createLinearGradient(x, y, x, y + h)
  grad.addColorStop(0, BOARD_BG_LIGHT)
  grad.addColorStop(0.5, BOARD_BG)
  grad.addColorStop(1, BOARD_BG_LIGHT)
  ctx.fillStyle = grad
  roundRect(ctx, x, y, w, h, r)
  ctx.fill()

  // Board border
  ctx.strokeStyle = BOARD_EDGE
  ctx.lineWidth = 1.5
  roundRect(ctx, x, y, w, h, r)
  ctx.stroke()

  // Inner border line
  ctx.strokeStyle = 'rgba(255,255,255,0.08)'
  ctx.lineWidth = 0.5
  roundRect(ctx, x + 3, y + 3, w - 6, h - 6, r - 1)
  ctx.stroke()
}

function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  ctx.beginPath()
  ctx.moveTo(x + r, y)
  ctx.lineTo(x + w - r, y)
  ctx.arcTo(x + w, y, x + w, y + r, r)
  ctx.lineTo(x + w, y + h - r)
  ctx.arcTo(x + w, y + h, x + w - r, y + h, r)
  ctx.lineTo(x + r, y + h)
  ctx.arcTo(x, y + h, x, y + h - r, r)
  ctx.lineTo(x, y + r)
  ctx.arcTo(x, y, x + r, y, r)
  ctx.closePath()
}

function drawHole(ctx: CanvasRenderingContext2D, x: number, y: number, r: number) {
  ctx.beginPath()
  ctx.arc(x, y, r, 0, Math.PI * 2)
  ctx.fillStyle = HOLE_COLOR
  ctx.fill()
  // Subtle inner shadow
  ctx.beginPath()
  ctx.arc(x, y, r * 0.6, 0, Math.PI * 2)
  ctx.fillStyle = 'rgba(0,0,0,0.3)'
  ctx.fill()
}

function drawPeg(ctx: CanvasRenderingContext2D, pos: [number, number], color: string, r: number) {
  const [x, y] = pos
  // Glow
  ctx.beginPath()
  ctx.arc(x, y, r * 1.6, 0, Math.PI * 2)
  ctx.fillStyle = color + '30'
  ctx.fill()
  // Body
  ctx.beginPath()
  ctx.arc(x, y, r, 0, Math.PI * 2)
  ctx.fillStyle = color
  ctx.fill()
  // Highlight
  ctx.beginPath()
  ctx.arc(x - r * 0.2, y - r * 0.2, r * 0.4, 0, Math.PI * 2)
  ctx.fillStyle = 'rgba(255,255,255,0.45)'
  ctx.fill()
}
