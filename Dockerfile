# Stage 1: Build
FROM amazoncorretto:21 AS build
WORKDIR /app

# Install Rust toolchain (needed for the engine crate)
RUN yum install -y gcc && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Copy Gradle wrapper and build files first for layer caching
COPY gradlew gradlew
COPY gradle/ gradle/
COPY build.gradle.kts settings.gradle.kts ./

# Download dependencies (cached unless build files change)
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon || true

# Copy engine source and build Rust library (cached unless engine changes)
COPY engine/ engine/
RUN cargo build --release --manifest-path engine/Cargo.toml

# Copy source and build
COPY src/ src/
RUN ./gradlew bootJar --no-daemon -x test

# Stage 2: Runtime
FROM amazoncorretto:21
WORKDIR /app

# Create non-root user
RUN yum install -y shadow-utils && yum clean all && \
    groupadd -r appgroup && useradd -r -g appgroup appuser

COPY --from=build /app/build/libs/*.jar app.jar
COPY --from=build /app/engine/target/release/libcribbage_engine.so /app/lib/

RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s \
  CMD curl -sf http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-Djna.library.path=/app/lib", "-jar", "app.jar"]
