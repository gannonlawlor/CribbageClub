export interface FriendInfo {
  friendshipId: string
  userId: string
  username: string
  displayName?: string
  isOnline: boolean
  since: string
}

export interface FriendRequestInfo {
  friendshipId: string
  fromUserId: string
  fromUsername: string
  fromDisplayName?: string
  createdAt: string
}

export interface UserSearchResult {
  userId: string
  username: string
  displayName?: string
  relationshipStatus?: string
}

export interface NotificationCount {
  friendRequests: number
  challenges: number
  total: number
}
