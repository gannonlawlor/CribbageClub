import { useCallback, useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router'
import { useAuthStore } from '@/auth/auth-store'
import { useAsync } from '@/shared/hooks'
import * as api from '@/api/rest-client'
import type { FriendInfo, FriendRequestInfo } from '@/models/friend'
import type { Lobby } from '@/models/lobby'

type Tab = 'friends' | 'requests' | 'find'

export function FriendsPage() {
  const { isLoggedIn } = useAuthStore()
  const [activeTab, setActiveTab] = useState<Tab>('friends')

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

      {/* Tabs */}
      <div className="flex border-b border-white/20 mb-6">
        {(['friends', 'requests', 'find'] as const).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 text-sm font-medium border-b-2 bg-transparent cursor-pointer transition-colors ${
              activeTab === tab
                ? 'border-[var(--gold)] text-[var(--gold)]'
                : 'border-transparent text-white/50 hover:text-white/80'
            }`}
          >
            {tab === 'friends' ? 'Friends' : tab === 'requests' ? 'Requests' : 'Find'}
          </button>
        ))}
      </div>

      {activeTab === 'friends' && <FriendsTab />}
      {activeTab === 'requests' && <RequestsTab />}
      {activeTab === 'find' && <FindTab />}
    </div>
  )
}

function FriendsTab() {
  const { isLoggedIn } = useAuthStore()
  const navigate = useNavigate()
  const friends = useAsync(() => (isLoggedIn ? api.getFriends() : Promise.resolve([])), [isLoggedIn])
  const [error, setError] = useState<string | null>(null)

  async function handleChallenge(friendUserId: string) {
    setError(null)
    try {
      const lobby = await api.createChallenge(friendUserId)
      navigate(`/lobby/${lobby.id}`)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create challenge')
    }
  }

  async function handleRemove(id: string) {
    setError(null)
    try {
      await api.removeFriend(id)
      friends.refetch()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to remove friend')
    }
  }

  if (friends.isLoading) {
    return <div className="text-white/50 text-center py-4">Loading...</div>
  }

  if (friends.data && friends.data.length === 0) {
    return <div className="text-white/50 text-center py-4">No friends yet. Use the Find tab to add some!</div>
  }

  return (
    <div className="space-y-2">
      {error && (
        <div className="bg-red-500/20 border border-red-500/50 rounded px-3 py-2 flex items-center justify-between">
          <span className="text-red-300 text-sm">{error}</span>
          <button onClick={() => setError(null)} className="text-red-300 bg-transparent border-none cursor-pointer text-sm ml-2">x</button>
        </div>
      )}
      {friends.data?.map((f: FriendInfo) => (
        <div key={f.friendshipId} className="flex items-center gap-3 bg-white/10 rounded-lg px-4 py-3">
          <div className={`w-2.5 h-2.5 rounded-full flex-shrink-0 ${f.isOnline ? 'bg-green-400' : 'bg-white/30'}`} />
          <div
            className="flex-1 cursor-pointer hover:opacity-80"
            onClick={() => navigate(`/profile/${f.userId}`)}
          >
            <div className="text-white text-sm">{f.displayName ?? f.username}</div>
            {f.displayName && (
              <div className="text-white/40 text-xs">@{f.username}</div>
            )}
          </div>
          <button
            onClick={() => handleChallenge(f.userId)}
            className="text-[var(--gold)] text-sm bg-transparent border border-[var(--gold)]/50 rounded px-3 py-1 cursor-pointer hover:bg-[var(--gold)]/10"
          >
            Challenge
          </button>
          <button
            onClick={() => handleRemove(f.friendshipId)}
            className="text-red-400/60 text-xs bg-transparent border-none cursor-pointer hover:text-red-400"
          >
            Remove
          </button>
        </div>
      ))}
    </div>
  )
}

function RequestsTab() {
  const { isLoggedIn } = useAuthStore()
  const navigate = useNavigate()
  const [error, setError] = useState<string | null>(null)
  const requests = useAsync(
    () => (isLoggedIn ? api.getIncomingFriendRequests() : Promise.resolve([])),
    [isLoggedIn],
  )
  const challenges = useAsync(
    () => (isLoggedIn ? api.getIncomingChallenges() : Promise.resolve([])),
    [isLoggedIn],
  )

  async function handleAcceptRequest(id: string) {
    try {
      await api.acceptFriendRequest(id)
      requests.refetch()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to accept request')
    }
  }

  async function handleDeclineRequest(id: string) {
    try {
      await api.declineFriendRequest(id)
      requests.refetch()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to decline request')
    }
  }

  async function handleAcceptChallenge(lobbyId: string) {
    try {
      const result = await api.acceptChallenge(lobbyId)
      if (result.gameState) {
        navigate(`/game/${result.gameState.gameId}`)
      } else {
        navigate(`/lobby/${result.lobby.id}`)
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to accept challenge')
    }
  }

  async function handleDeclineChallenge(lobbyId: string) {
    try {
      await api.declineChallenge(lobbyId)
      challenges.refetch()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to decline challenge')
    }
  }

  const hasRequests = requests.data && requests.data.length > 0
  const hasChallenges = challenges.data && challenges.data.length > 0
  const isEmpty = !hasRequests && !hasChallenges && !requests.isLoading && !challenges.isLoading

  return (
    <div className="space-y-6">
      {error && (
        <div className="bg-red-500/20 border border-red-500/50 rounded px-3 py-2 flex items-center justify-between">
          <span className="text-red-300 text-sm">{error}</span>
          <button onClick={() => setError(null)} className="text-red-300 bg-transparent border-none cursor-pointer text-sm ml-2">x</button>
        </div>
      )}

      {/* Friend requests */}
      {hasRequests && (
        <div>
          <h2 className="text-white font-semibold mb-2 text-sm">Friend Requests</h2>
          <div className="space-y-2">
            {requests.data!.map((req: FriendRequestInfo) => (
              <div key={req.friendshipId} className="flex items-center gap-3 bg-white/10 rounded-lg px-4 py-3">
                <div className="flex-1">
                  <div className="text-white text-sm">{req.fromDisplayName ?? req.fromUsername}</div>
                  {req.fromDisplayName && (
                    <div className="text-white/40 text-xs">@{req.fromUsername}</div>
                  )}
                </div>
                <button
                  onClick={() => handleAcceptRequest(req.friendshipId)}
                  className="text-green-400 text-sm bg-transparent border-none cursor-pointer hover:underline"
                >
                  Accept
                </button>
                <button
                  onClick={() => handleDeclineRequest(req.friendshipId)}
                  className="text-red-400 text-sm bg-transparent border-none cursor-pointer hover:underline"
                >
                  Decline
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Incoming challenges */}
      {hasChallenges && (
        <div>
          <h2 className="text-white font-semibold mb-2 text-sm">Challenges</h2>
          <div className="space-y-2">
            {challenges.data!.map((lobby: Lobby) => (
              <div key={lobby.id} className="flex items-center gap-3 bg-white/10 rounded-lg px-4 py-3">
                <div className="flex-1">
                  <div className="text-white text-sm">
                    {lobby.players[0]?.name ?? 'Someone'} wants to play!
                  </div>
                </div>
                <button
                  onClick={() => handleAcceptChallenge(lobby.id)}
                  className="text-green-400 text-sm bg-transparent border-none cursor-pointer hover:underline"
                >
                  Accept
                </button>
                <button
                  onClick={() => handleDeclineChallenge(lobby.id)}
                  className="text-red-400 text-sm bg-transparent border-none cursor-pointer hover:underline"
                >
                  Decline
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {(requests.isLoading || challenges.isLoading) && (
        <div className="text-white/50 text-center py-4">Loading...</div>
      )}

      {isEmpty && (
        <div className="text-white/50 text-center py-4">No pending requests or challenges.</div>
      )}
    </div>
  )
}

function FindTab() {
  const navigate = useNavigate()
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<Awaited<ReturnType<typeof api.searchUsers>> | null>(null)
  const [isSearching, setIsSearching] = useState(false)
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const doSearch = useCallback(async (query: string) => {
    if (!query.trim()) {
      setSearchResults(null)
      return
    }
    setIsSearching(true)
    try {
      const results = await api.searchUsers(query.trim())
      setSearchResults(results)
    } finally {
      setIsSearching(false)
    }
  }, [])

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current)
    if (!searchQuery.trim()) {
      setSearchResults(null)
      return
    }
    debounceRef.current = setTimeout(() => doSearch(searchQuery), 400)
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current)
    }
  }, [searchQuery, doSearch])

  async function handleSendRequest(username: string) {
    await api.sendFriendRequest(username)
    // Re-search to update relationship status
    doSearch(searchQuery)
  }

  const statusBadge: Record<string, { label: string; color: string }> = {
    FRIENDS: { label: 'Friends', color: 'text-green-400' },
    REQUEST_SENT: { label: 'Request Sent', color: 'text-yellow-400' },
    PENDING: { label: 'Pending', color: 'text-blue-400' },
  }

  return (
    <div>
      <input
        type="text"
        placeholder="Search by username..."
        value={searchQuery}
        onChange={(e) => setSearchQuery(e.target.value)}
        className="w-full bg-white/10 border border-white/20 rounded px-3 py-2 text-white placeholder-white/40 outline-none focus:border-[var(--gold)] mb-4"
      />

      {isSearching && <div className="text-white/50 text-center py-4 text-sm">Searching...</div>}

      {searchResults && !isSearching && (
        <div className="space-y-2">
          {searchResults.length === 0 ? (
            <div className="text-white/50 text-sm text-center py-4">No users found.</div>
          ) : (
            searchResults.map((u) => {
              const badge = u.relationshipStatus ? statusBadge[u.relationshipStatus] : null
              return (
                <div key={u.userId} className="flex items-center gap-3 bg-white/10 rounded-lg px-4 py-3">
                  <div
                    className="flex-1 cursor-pointer hover:opacity-80"
                    onClick={() => navigate(`/profile/${u.userId}`)}
                  >
                    <div className="text-white text-sm">{u.displayName ?? u.username}</div>
                    {u.displayName && (
                      <div className="text-white/40 text-xs">@{u.username}</div>
                    )}
                  </div>
                  {badge && (
                    <span className={`text-xs ${badge.color}`}>{badge.label}</span>
                  )}
                  {!u.relationshipStatus && (
                    <button
                      onClick={() => handleSendRequest(u.username)}
                      className="text-[var(--gold)] text-sm bg-transparent border border-[var(--gold)]/50 rounded px-3 py-1 cursor-pointer hover:bg-[var(--gold)]/10"
                    >
                      Add Friend
                    </button>
                  )}
                </div>
              )
            })
          )}
        </div>
      )}
    </div>
  )
}
