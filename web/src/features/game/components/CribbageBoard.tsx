import { useEffect, useRef } from 'react'

interface CribbageBoardProps {
  playerScore: number
  opponentScore: number
  className?: string
}

const TOTAL_HOLES = 121
const GROUP_SIZE = 5

// Colors matching Flutter theme
const BOARD_BROWN = '#5D4037'
const BOARD_BROWN_LIGHT = '#795548'
const BOARD_HOLE = '#3E2723'
const PEG_GOLD = '#FFD54F'
const PEG_WHITE = '#EEEEEE'

/** Computed dimensions proportional to canvas width */
interface Dims {
  boardWidth: number
  cornerRadius: number
  holeRadius: number
  pegRadius: number
  outerTrackOffset: number
  innerTrackOffset: number
  fontSize: number
}

function computeDims(w: number): Dims {
  const boardWidth = w * 0.058
  return {
    boardWidth,
    cornerRadius: w * 0.029,
    holeRadius: w * 0.003,
    pegRadius: w * 0.006,
    outerTrackOffset: boardWidth * 0.18,
    innerTrackOffset: boardWidth * -0.18,
    fontSize: Math.max(w * 0.014, 6),
  }
}

export function CribbageBoard({ playerScore, opponentScore, className = '' }: CribbageBoardProps) {
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

      // Snap when close
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

  // Initial draw
  useEffect(() => {
    const canvas = canvasRef.current
    if (canvas) draw(canvas, 0, 0)
  }, [])

  return (
    <canvas
      ref={canvasRef}
      className={`pointer-events-none ${className}`}
      style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}
    />
  )
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
  const dims = computeDims(w)

  // Draw board background (three-sided frame)
  drawBoardBackground(ctx, w, h, dims)
  drawBoardBorder(ctx, w, h, dims)

  // Calculate hole positions
  const outerHoles = calculateHolePositions(w, h, dims.outerTrackOffset, dims)
  const innerHoles = calculateHolePositions(w, h, dims.innerTrackOffset, dims)

  // Draw holes
  drawHoles(ctx, outerHoles, dims)
  drawHoles(ctx, innerHoles, dims)

  // Draw milestone labels
  drawMilestones(ctx, outerHoles, innerHoles, dims)

  // Draw pegs
  const playerPos = scoreToPosition(playerScore, outerHoles)
  const opponentPos = scoreToPosition(opponentScore, innerHoles)
  drawPeg(ctx, opponentPos, PEG_WHITE, dims)
  drawPeg(ctx, playerPos, PEG_GOLD, dims)
}

function drawBoardBackground(ctx: CanvasRenderingContext2D, w: number, h: number, dims: Dims) {
  const path = buildFramePath(w, h, dims)
  const grad = ctx.createLinearGradient(0, 0, 0, dims.boardWidth)
  grad.addColorStop(0, BOARD_BROWN_LIGHT)
  grad.addColorStop(1, BOARD_BROWN)
  ctx.fillStyle = grad
  ctx.fill(path)
}

function drawBoardBorder(ctx: CanvasRenderingContext2D, w: number, h: number, dims: Dims) {
  const path = buildFramePath(w, h, dims)
  ctx.strokeStyle = `${BOARD_HOLE}80`
  ctx.lineWidth = 1
  ctx.stroke(path)
}

function buildFramePath(w: number, h: number, dims: Dims): Path2D {
  const bw = dims.boardWidth
  const r = dims.cornerRadius
  const ir = Math.max(r - bw, 0)
  const path = new Path2D()

  // Outer edge
  path.moveTo(0, h)
  path.lineTo(0, r)
  path.arcTo(0, 0, r, 0, r)
  path.lineTo(w - r, 0)
  path.arcTo(w, 0, w, r, r)
  path.lineTo(w, h)

  // Inner edge
  path.lineTo(w - bw, h)
  if (ir > 0) {
    path.lineTo(w - bw, r)
    path.arcTo(w - bw, bw, w - r, bw, ir)
    path.lineTo(r, bw)
    path.arcTo(bw, bw, bw, r, ir)
  } else {
    path.lineTo(w - bw, bw)
    path.lineTo(bw, bw)
  }
  path.lineTo(bw, h)
  path.closePath()

  return path
}

function segmentLengths(w: number, h: number, dims: Dims): number[] {
  const r = dims.cornerRadius
  return [
    h - r,                    // left edge
    (Math.PI / 2) * r,       // top-left arc
    w - 2 * r,               // top edge
    (Math.PI / 2) * r,       // top-right arc
    h - r,                    // right edge
  ]
}

function totalPathLength(w: number, h: number, dims: Dims): number {
  return segmentLengths(w, h, dims).reduce((a, b) => a + b, 0)
}

function pathDistanceToOffset(d: number, w: number, h: number, trackOffset: number, dims: Dims): [number, number] {
  const r = dims.cornerRadius
  const center = dims.boardWidth / 2
  const segs = segmentLengths(w, h, dims)
  let remaining = d

  // Segment 0: Left edge (going up)
  if (remaining <= segs[0]) {
    const t = remaining / segs[0]
    return [center + trackOffset, h - t * (h - r)]
  }
  remaining -= segs[0]

  // Segment 1: Top-left arc
  if (remaining <= segs[1]) {
    const t = remaining / segs[1]
    const angle = Math.PI + t * (Math.PI / 2)
    const cx = r, cy = r
    const nx = Math.cos(angle), ny = Math.sin(angle)
    return [
      cx + r * nx + nx * (center - r) + nx * trackOffset,
      cy + r * ny + ny * (center - r) + ny * trackOffset,
    ]
  }
  remaining -= segs[1]

  // Segment 2: Top edge (going right)
  if (remaining <= segs[2]) {
    const t = remaining / segs[2]
    return [r + t * (w - 2 * r), center + trackOffset]
  }
  remaining -= segs[2]

  // Segment 3: Top-right arc
  if (remaining <= segs[3]) {
    const t = remaining / segs[3]
    const angle = (3 * Math.PI / 2) + t * (Math.PI / 2)
    const cx = w - r, cy = r
    const nx = Math.cos(angle), ny = Math.sin(angle)
    return [
      cx + r * nx + nx * (center - r) + nx * trackOffset,
      cy + r * ny + ny * (center - r) + ny * trackOffset,
    ]
  }
  remaining -= segs[3]

  // Segment 4: Right edge (going down)
  const t = Math.min(remaining / segs[4], 1)
  return [w - center + trackOffset, r + t * (h - r)]
}

function calculateHolePositions(w: number, h: number, trackOffset: number, dims: Dims): [number, number][] {
  const total = totalPathLength(w, h, dims)
  const numGroups = Math.ceil(TOTAL_HOLES / GROUP_SIZE)
  const groupGap = 3.0
  const totalGaps = TOTAL_HOLES - 1 + (numGroups - 1) * (groupGap / 2)
  const spacing = total / totalGaps

  const linear: number[] = []
  let pos = 0
  for (let i = 0; i < TOTAL_HOLES; i++) {
    linear.push(pos)
    pos += spacing
    if ((i + 1) % GROUP_SIZE === 0 && i < TOTAL_HOLES - 1) {
      pos += spacing * (groupGap / 2)
    }
  }

  // Normalize
  const last = linear[linear.length - 1]
  if (last > 0) {
    const scale = total / last
    for (let i = 0; i < linear.length; i++) {
      linear[i] *= scale
    }
  }

  return linear.map((d) => pathDistanceToOffset(d, w, h, trackOffset, dims))
}

function scoreToPosition(score: number, holes: [number, number][]): [number, number] {
  if (score <= 0 || holes.length === 0) return holes[0] ?? [0, 0]
  const clamped = Math.min(Math.max(score, 0), 121)
  const intScore = Math.floor(clamped)
  const fraction = clamped - intScore

  if (intScore >= holes.length) return holes[holes.length - 1]
  if (intScore === 0) return holes[0]

  const a = holes[intScore - 1]
  const b = intScore < holes.length ? holes[intScore] : holes[holes.length - 1]
  return [
    a[0] + (b[0] - a[0]) * fraction,
    a[1] + (b[1] - a[1]) * fraction,
  ]
}

function drawHoles(ctx: CanvasRenderingContext2D, holes: [number, number][], dims: Dims) {
  ctx.fillStyle = BOARD_HOLE
  for (const [x, y] of holes) {
    ctx.beginPath()
    ctx.arc(x, y, dims.holeRadius, 0, Math.PI * 2)
    ctx.fill()
  }
}

function drawMilestones(
  ctx: CanvasRenderingContext2D,
  outerHoles: [number, number][],
  innerHoles: [number, number][],
  dims: Dims,
) {
  const milestones = [31, 61, 91, 121]
  ctx.fillStyle = 'rgba(255,255,255,0.45)'
  ctx.font = `bold ${dims.fontSize}px system-ui`
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'

  for (const m of milestones) {
    if (m - 1 >= outerHoles.length) continue
    const [ox, oy] = outerHoles[m - 1]
    const [ix, iy] = innerHoles[m - 1]
    ctx.fillText(`${m}`, (ox + ix) / 2, (oy + iy) / 2)
  }
}

function drawPeg(ctx: CanvasRenderingContext2D, pos: [number, number], color: string, dims: Dims) {
  const [x, y] = pos
  const pr = dims.pegRadius
  // Glow
  ctx.beginPath()
  ctx.arc(x, y, pr + pr * 0.67, 0, Math.PI * 2)
  ctx.fillStyle = color + '4D'
  ctx.fill()
  // Body
  ctx.beginPath()
  ctx.arc(x, y, pr, 0, Math.PI * 2)
  ctx.fillStyle = color
  ctx.fill()
  // Highlight
  ctx.beginPath()
  ctx.arc(x - pr * 0.23, y - pr * 0.23, pr * 0.4, 0, Math.PI * 2)
  ctx.fillStyle = 'rgba(255,255,255,0.5)'
  ctx.fill()
}
