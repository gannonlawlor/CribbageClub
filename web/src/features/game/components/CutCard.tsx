import { motion } from 'motion/react'
import type { PlayingCard } from '@/models'
import { CardWidget } from './CardWidget'

interface CutCardProps {
  cutCard: PlayingCard | null
  width?: number
  height?: number
}

export function CutCard({ cutCard, width = 48, height = 67 }: CutCardProps) {
  if (!cutCard) return null

  return (
    <motion.div
      initial={{ rotateY: 90, opacity: 0 }}
      animate={{ rotateY: 0, opacity: 1 }}
      transition={{ duration: 0.4, ease: 'easeOut' }}
      className="flex flex-col items-center gap-1"
    >
      <span className="text-white/40 text-xs">Cut Card</span>
      <CardWidget card={cutCard} faceUp width={width} height={height} />
    </motion.div>
  )
}
