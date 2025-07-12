# GitHub Copilot Instructions for CribbageClubServer

This is a Kotlin/Spring Boot backend for a Cribbage club server. It manages game rooms, player actions, and the flow of a two-player cribbage game. Please follow these guidelines when contributing:

## Key Guidelines
1. Use idiomatic Kotlin and Spring Boot best practices.
2. Keep controllers thin; place business logic in services or models.
3. All game logic and state transitions should be in the `model/game` package.
4. Game rooms must support creation, joining, and starting games for two players.
5. Write unit or integration tests for new features where possible.
6. Document public APIs and complex logic with KDoc or comments.

## Code Standards

### Required Before Each Commit
- Ensure code compiles and all tests pass (`./gradlew build` and `./gradlew test`)
- Run code formatters (e.g., `ktlint`) and static analysis tools
- Update documentation if public APIs or behaviors change
- Write clear, descriptive commit messages

### Development Flow
- Create a new branch for each feature or bugfix
- Implement code following the guidelines above
- Add or update tests to cover your changes
- Update documentation and comments as needed
- Open a pull request describing your changes and referencing related issues

## Repository Structure
- `.github/`: GitHub workflows and Copilot instructions
- `src/main/kotlin/com/jackabee/cribbageclubserver/model/`: Domain models (game, player, card, etc.)
- `src/main/kotlin/com/jackabee/cribbageclubserver/service/`: Business logic and services
- `src/main/kotlin/com/jackabee/cribbageclubserver/controller/`: REST controllers
- `src/test/`: Unit and integration tests

## Copilot Usage

- Add new features by creating new files in appropriate packages (e.g., `service`, `controller`)
- Modify existing files by only changing the necessary lines and using `// ...existing code...` to indicate unchanged regions
- Keep code concise and avoid duplicating unchanged code
- Use idiomatic Kotlin and follow Spring Boot conventions for REST controllers and services
- Document new classes and methods with brief comments