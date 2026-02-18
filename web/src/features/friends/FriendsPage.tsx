import { type FormEvent, useState } from 'react'
import { useAuthStore } from '@/auth/auth-store'
import { useAsync } from '@/shared/hooks'
import * as api from '@/api/rest-client'
import type { FriendInfo, FriendRequestInfo } from '@/models/friend'

export function FriendsPage() {
  const { isLoggedIn } = useAuthStore()
  const friends = useAsync(() => (isLoggedIn ? api.getFriends() : Promise.resolve([])), [isLoggedIn])
  const requests = useAsync(() => (isLoggedIn ? api.getIncomingFriendRequests() : Promise.resolve([])), [isLoggedIn])
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<Awaited<ReturnType<typeof api.searchUsers>> | null>(null)
  const [isSearching, setIsSearching] = useState(false)

  async function handleSearch(e: FormEvent) {
    e.preventDefault()
    if (!searchQuery.trim()) return
    setIsSearching(true)
    try {
      const results = await api.searchUsers(searchQuery.trim())
      setSearchResults(results)
    } finally {
      setIsSearching(false)
    }
  }

  async function handleAccept(id: string) {
    await api.acceptFriendRequest(id)
    requests.refetch()
    friends.refetch()
  }

  async function handleDecline(id: string) {
    await api.declineFriendRequest(id)
    requests.refetch()
  }

  async function handleSendRequest(username: string) {
    await api.sendFriendRequest(username)
    setSearchResults(null)
    setSearchQuery('')
  }

  async function handleRemove(id: string) {
    await api.removeFriend(id)
    friends.refetch()
  }

  if (!isLoggedIn) {
    return (
      <div className="max-w-2xl mx-auto p-8 text-center">
        <h1 className="text-2xl font-bold text-[var(--gold)] mb-4">Friends</h1>
        <p className="text-white/50">Log in to manage friends.</p>
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto p-8">
      <h1 className="text-2xl font-bold text-[var(--gold)] mb-6">Friends</h1>

      {/* Search */}
      <form onSubmit={handleSearch} className="flex gap-2 mb-6">
        <input
          type="text"
          placeholder="Search by username..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="flex-1 bg-white/10 border border-white/20 rounded px-3 py-2 text-white placeholder-white/40 outline-none focus:border-[var(--gold)]"
        />
        <button
          type="submit"
          disabled={isSearching}
          className="bg-[var(--gold)] text-black px-4 py-2 rounded font-semibold hover:bg-[var(--gold-light)] disabled:opacity-50"
        >
          Search
        </button>
      </form>

      {searchResults && (
        <div className="mb-6 space-y-2">
          {searchResults.length === 0 ? (
            <div className="text-white/50 text-sm">No users found.</div>
          ) : (
            searchResults.map((u) => (
              <div key={u.userId} className="flex items-center gap-3 bg-white/10 rounded-lg px-4 py-3">
                <div className="flex-1">
                  <div className="text-white text-sm">{u.username}</div>
                  {u.relationshipStatus && (
                    <div className="text-white/50 text-xs">{u.relationshipStatus}</div>
                  )}
                </div>
                {!u.relationshipStatus && (
                  <button
                    onClick={() => handleSendRequest(u.username)}
                    className="text-[var(--gold)] text-sm bg-transparent border-none cursor-pointer hover:underline"
                  >
                    Add Friend
                  </button>
                )}
              </div>
            ))
          )}
        </div>
      )}

      {/* Incoming requests */}
      {requests.data && requests.data.length > 0 && (
        <div className="mb-6">
          <h2 className="text-white font-semibold mb-2">Friend Requests</h2>
          <div className="space-y-2">
            {requests.data.map((req: FriendRequestInfo) => (
              <div key={req.friendshipId} className="flex items-center gap-3 bg-white/10 rounded-lg px-4 py-3">
                <div className="flex-1 text-white text-sm">{req.fromUsername}</div>
                <button
                  onClick={() => handleAccept(req.friendshipId)}
                  className="text-green-400 text-sm bg-transparent border-none cursor-pointer hover:underline"
                >
                  Accept
                </button>
                <button
                  onClick={() => handleDecline(req.friendshipId)}
                  className="text-red-400 text-sm bg-transparent border-none cursor-pointer hover:underline"
                >
                  Decline
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Friends list */}
      {friends.isLoading && <div className="text-white/50 text-center py-4">Loading...</div>}
      {friends.data && friends.data.length === 0 && (
        <div className="text-white/50 text-center py-4">No friends yet. Search to add some!</div>
      )}
      {friends.data && friends.data.length > 0 && (
        <div className="space-y-2">
          {friends.data.map((f: FriendInfo) => (
            <div key={f.friendshipId} className="flex items-center gap-3 bg-white/10 rounded-lg px-4 py-3">
              <div className={`w-2 h-2 rounded-full ${f.isOnline ? 'bg-green-400' : 'bg-white/30'}`} />
              <div className="flex-1">
                <div className="text-white text-sm">{f.username}</div>
              </div>
              <button
                onClick={() => handleRemove(f.friendshipId)}
                className="text-red-400/60 text-xs bg-transparent border-none cursor-pointer hover:text-red-400"
              >
                Remove
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
