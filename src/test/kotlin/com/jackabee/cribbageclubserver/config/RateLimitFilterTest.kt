package com.jackabee.cribbageclubserver.config

import org.junit.jupiter.api.Test
import org.springframework.mock.web.MockFilterChain
import org.springframework.mock.web.MockHttpServletRequest
import org.springframework.mock.web.MockHttpServletResponse
import kotlin.test.assertEquals

class RateLimitFilterTest {

    private fun createFilter(maxRequests: Int = 3, windowSeconds: Long = 60): RateLimitFilter {
        return RateLimitFilter(maxRequests = maxRequests, windowSeconds = windowSeconds)
    }

    @Test
    fun `allows requests within limit`() {
        val filter = createFilter(maxRequests = 5)

        repeat(5) {
            val request = MockHttpServletRequest("POST", "/api/auth/login")
            request.remoteAddr = "127.0.0.1"
            val response = MockHttpServletResponse()
            filter.doFilter(request, response, MockFilterChain())
            assertEquals(200, response.status)
        }
    }

    @Test
    fun `blocks requests exceeding limit`() {
        val filter = createFilter(maxRequests = 3)

        // First 3 should pass
        repeat(3) {
            val request = MockHttpServletRequest("POST", "/api/auth/login")
            request.remoteAddr = "127.0.0.1"
            val response = MockHttpServletResponse()
            filter.doFilter(request, response, MockFilterChain())
            assertEquals(200, response.status, "Request ${it + 1} should pass")
        }

        // 4th should be blocked
        val request = MockHttpServletRequest("POST", "/api/auth/login")
        request.remoteAddr = "127.0.0.1"
        val response = MockHttpServletResponse()
        filter.doFilter(request, response, MockFilterChain())
        assertEquals(429, response.status)
    }

    @Test
    fun `rate limits register endpoint`() {
        val filter = createFilter(maxRequests = 2)

        repeat(2) {
            val request = MockHttpServletRequest("POST", "/api/auth/register")
            request.remoteAddr = "10.0.0.1"
            val response = MockHttpServletResponse()
            filter.doFilter(request, response, MockFilterChain())
            assertEquals(200, response.status)
        }

        val request = MockHttpServletRequest("POST", "/api/auth/register")
        request.remoteAddr = "10.0.0.1"
        val response = MockHttpServletResponse()
        filter.doFilter(request, response, MockFilterChain())
        assertEquals(429, response.status)
    }

    @Test
    fun `does not rate limit non-auth endpoints`() {
        val filter = createFilter(maxRequests = 1)

        repeat(10) {
            val request = MockHttpServletRequest("GET", "/api/games")
            request.remoteAddr = "127.0.0.1"
            val response = MockHttpServletResponse()
            filter.doFilter(request, response, MockFilterChain())
            assertEquals(200, response.status)
        }
    }

    @Test
    fun `tracks different IPs independently`() {
        val filter = createFilter(maxRequests = 2)

        // Exhaust limit for IP 1
        repeat(2) {
            val request = MockHttpServletRequest("POST", "/api/auth/login")
            request.remoteAddr = "10.0.0.1"
            val response = MockHttpServletResponse()
            filter.doFilter(request, response, MockFilterChain())
            assertEquals(200, response.status)
        }

        // IP 2 should still work
        val request = MockHttpServletRequest("POST", "/api/auth/login")
        request.remoteAddr = "10.0.0.2"
        val response = MockHttpServletResponse()
        filter.doFilter(request, response, MockFilterChain())
        assertEquals(200, response.status)
    }

    @Test
    fun `uses X-Forwarded-For header for client IP`() {
        val filter = createFilter(maxRequests = 1)

        val request1 = MockHttpServletRequest("POST", "/api/auth/login")
        request1.remoteAddr = "127.0.0.1"
        request1.addHeader("X-Forwarded-For", "203.0.113.50")
        val response1 = MockHttpServletResponse()
        filter.doFilter(request1, response1, MockFilterChain())
        assertEquals(200, response1.status)

        // Same X-Forwarded-For IP should be blocked
        val request2 = MockHttpServletRequest("POST", "/api/auth/login")
        request2.remoteAddr = "127.0.0.1"
        request2.addHeader("X-Forwarded-For", "203.0.113.50")
        val response2 = MockHttpServletResponse()
        filter.doFilter(request2, response2, MockFilterChain())
        assertEquals(429, response2.status)
    }

    @Test
    fun `returns JSON error body on rate limit`() {
        val filter = createFilter(maxRequests = 0)

        val request = MockHttpServletRequest("POST", "/api/auth/login")
        request.remoteAddr = "127.0.0.1"
        val response = MockHttpServletResponse()
        filter.doFilter(request, response, MockFilterChain())

        assertEquals(429, response.status)
        assertEquals("application/json", response.contentType)
        assert(response.contentAsString.contains("Too many requests"))
    }
}
