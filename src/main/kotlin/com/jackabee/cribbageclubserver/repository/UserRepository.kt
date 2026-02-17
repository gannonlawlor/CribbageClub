package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.UserEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface UserRepository : JpaRepository<UserEntity, String> {
    fun findByUsername(username: String): UserEntity?
    fun existsByUsername(username: String): Boolean
}
