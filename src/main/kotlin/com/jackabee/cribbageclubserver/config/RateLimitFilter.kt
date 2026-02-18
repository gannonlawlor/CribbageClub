package com.jackabee.cribbageclubserver.config

import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * Simple sliding-window rate limiter for auth endpoints.
 * Tracks request counts per IP within a configurable time window.
 */
@Component
class RateLimitFilter(
    @Value("\${rate-limit.auth.max-requests:10}") private val maxRequests: Int,
    @Value("\${rate-limit.auth.window-seconds:60}") private val windowSeconds: Long
) : OncePerRequestFilter() {

    private val log = LoggerFactory.getLogger(RateLimitFilter::class.java)

    data class WindowCounter(
        val count: AtomicInteger = AtomicInteger(0),
        @Volatile var windowStart: Long = System.currentTimeMillis()
    )

    private val counters = ConcurrentHashMap<String, WindowCounter>()

    override fun shouldNotFilter(request: HttpServletRequest): Boolean {
        val path = request.requestURI
        return !(path == "/api/auth/login" || path == "/api/auth/register")
    }

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        val clientIp = getClientIp(request)
        val now = System.currentTimeMillis()
        val windowMs = windowSeconds * 1000

        val counter = counters.computeIfAbsent(clientIp) { WindowCounter(windowStart = now) }

        // Reset window if expired
        if (now - counter.windowStart >= windowMs) {
            synchronized(counter) {
                if (now - counter.windowStart >= windowMs) {
                    counter.count.set(0)
                    counter.windowStart = now
                }
            }
        }

        if (counter.count.incrementAndGet() > maxRequests) {
            log.warn("Rate limit exceeded for IP {} on {}", clientIp, request.requestURI)
            response.status = HttpStatus.TOO_MANY_REQUESTS.value()
            response.contentType = "application/json"
            response.writer.write("""{"error":"Too many requests. Try again later."}""")
            return
        }

        filterChain.doFilter(request, response)
    }

    private fun getClientIp(request: HttpServletRequest): String {
        return request.getHeader("X-Forwarded-For")?.split(",")?.firstOrNull()?.trim()
            ?: request.remoteAddr
    }
}
