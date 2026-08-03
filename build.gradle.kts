plugins {
    kotlin("jvm") version "1.9.25"
    kotlin("plugin.spring") version "1.9.25"
    id("org.springframework.boot") version "3.4.13"
    id("io.spring.dependency-management") version "1.1.7"
    kotlin("plugin.jpa") version "1.9.25"

}

group = "com.jackabee"
version = "0.0.1-SNAPSHOT"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-websocket")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    implementation("net.java.dev.jna:jna:5.17.0")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.8.15")
    implementation("com.google.auth:google-auth-library-oauth2-http:1.23.0")
    implementation("io.jsonwebtoken:jjwt-api:0.13.0")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.13.0")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.13.0")
    developmentOnly("org.springframework.boot:spring-boot-devtools")
    runtimeOnly("org.postgresql:postgresql")
    testRuntimeOnly("com.h2database:h2")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit5")
    testImplementation("org.springframework.security:spring-security-test")
    testImplementation("org.mockito:mockito-core:5.21.0")
    testImplementation("org.mockito.kotlin:mockito-kotlin:5.4.0")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

kotlin {
    compilerOptions {
        freeCompilerArgs.addAll("-Xjsr305=strict")
    }
}

// ── Rust native library build ───────────────────────────────────────

val cargoReleaseBuild by tasks.registering(Exec::class) {
    description = "Build the Rust cribbage-engine crate in release mode"
    workingDir = file("engine")
    // Use absolute path to cargo since ~/.cargo/bin may not be in Gradle's PATH
    val cargoPath = File(System.getProperty("user.home"), ".cargo/bin/cargo").absolutePath
    // The server only calls the ungated c_api; without this flag the default
    // `frb` feature links the whole flutter_rust_bridge runtime into the
    // server's dylib for nothing.
    commandLine(cargoPath, "build", "--release", "--no-default-features")
}

tasks.named("compileKotlin") {
    dependsOn(cargoReleaseBuild)
}

tasks.withType<Test> {
    // Make the Rust native library available to JNA during tests
    val libDir = file("engine/target/release").absolutePath
    systemProperty("jna.library.path", libDir)
    useJUnitPlatform()
}

tasks.named<org.springframework.boot.gradle.tasks.run.BootRun>("bootRun") {
    val libDir = file("engine/target/release").absolutePath
    systemProperty("jna.library.path", libDir)
}
