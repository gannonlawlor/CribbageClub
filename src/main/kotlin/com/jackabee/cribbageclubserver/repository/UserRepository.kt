package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.UserEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface UserRepository : JpaRepository<UserEntity, String> {
    fun findByUsername(username: String): UserEntity?
    fun existsByUsername(username: String): Boolean

    @Query("""
        SELECT u FROM UserEntity u
        WHERE LOWER(u.username) LIKE LOWER(CONCAT('%', :query, '%'))
        AND u.isGuest = false AND u.isBot = false AND u.id <> :excludeId
    """)
    fun searchByUsername(@Param("query") query: String, @Param("excludeId") excludeId: String): List<UserEntity>

    fun findByIsBotTrue(): List<UserEntity>
}
