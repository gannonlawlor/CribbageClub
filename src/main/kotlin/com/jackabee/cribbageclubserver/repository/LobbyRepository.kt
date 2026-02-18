package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.LobbyEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface LobbyRepository : JpaRepository<LobbyEntity, String> {
    fun findByStatus(status: String): List<LobbyEntity>
    fun findByStatusAndIsPrivateFalse(status: String): List<LobbyEntity>
    fun findByInviteCode(inviteCode: String): LobbyEntity?
}
