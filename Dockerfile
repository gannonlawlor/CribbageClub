# Stage 1: Build
FROM amazoncorretto:21-alpine AS build
WORKDIR /app

# Copy Gradle wrapper and build files first for layer caching
COPY gradlew gradlew
COPY gradle/ gradle/
COPY build.gradle.kts settings.gradle.kts ./

# Download dependencies (cached unless build files change)
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon || true

# Copy source and build
COPY src/ src/
RUN ./gradlew bootJar --no-daemon -x test

# Stage 2: Runtime
FROM amazoncorretto:21-alpine
WORKDIR /app

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=build /app/build/libs/*.jar app.jar

RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
