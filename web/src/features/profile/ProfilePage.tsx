import { useParams } from 'react-router'

export function ProfilePage() {
  const { userId } = useParams<{ userId: string }>()

  return (
    <div className="max-w-4xl mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--gold)] mb-4">Profile</h1>
      <p className="text-white/60">User ID: {userId}</p>
      <p className="text-white/40 mt-4">Profile page coming soon.</p>
    </div>
  )
}
