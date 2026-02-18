package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.FriendshipEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface FriendshipRepository : JpaRepository<FriendshipEntity, String> {

    @Query("SELECT f FROM FriendshipEntity f WHERE (f.requesterId = :userId OR f.addresseeId = :userId) AND f.status = 'ACCEPTED'")
    fun findAcceptedFriendships(@Param("userId") userId: String): List<FriendshipEntity>

    fun findByAddresseeIdAndStatus(addresseeId: String, status: String): List<FriendshipEntity>

    fun findByRequesterIdAndStatus(requesterId: String, status: String): List<FriendshipEntity>

    @Query("SELECT f FROM FriendshipEntity f WHERE (f.requesterId = :userA AND f.addresseeId = :userB) OR (f.requesterId = :userB AND f.addresseeId = :userA)")
    fun findBetween(@Param("userA") userA: String, @Param("userB") userB: String): FriendshipEntity?
}
