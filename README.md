# Spring Boot 4 Migration Skill

A comprehensive [Claude Code skill](https://code.claude.com/docs/en/skills) for migrating Spring Boot 3.x applications to Spring Boot 4.x and staying current across 4.x minor versions.

## What This Skill Does

When installed, this skill gives Claude Code deep knowledge of every breaking change in Spring Boot 4.x and guides you through migration step-by-step. It supports:

- **Toolchain version check**: Detects unsupported Java, Kotlin, Maven, and Gradle versions and guides upgrades before migration begins
- **Two migration strategies**: All-at-once (9 sequential phases) or gradual upgrade (Day-1 baseline with 6 independent tracks)
- **Compatibility bridges**: `spring-boot-starter-classic`, `spring-boot-jackson2`, `spring-security-access` for incremental adoption
- **Minor version tracking**: Bridge removal timelines, deprecation promotions, and new features for 4.1, 4.2, and beyond
- **Comprehensive coverage**: Build files, modular starters, Jackson 3, properties, package relocations, Spring Security 7, testing (MockitoBean, Testcontainers 2, JUnit 6), Spring Framework 7, Hibernate 7.1, observability (OpenTelemetry, Micrometer, Actuator), API versioning, HTTP interfaces and clients, AOT/native image, JSpecify nullability, resilience (retry, concurrency limiting)
- **Verification script**: Bridge-aware PASS/FAIL/WARN/BRIDGE checks
- **Enterprise rollout**: Wave-based strategy for organizations with many services

## Installation

### Claude Code CLI

```bash
claude install-skill github:adityamparikh/spring-boot-4-migration-skill
```

### Manual Installation

Copy the contents of this repository to `~/.claude/skills/spring-boot-4-migration/`.

## Usage

In Claude Code, say any of:

- "Migrate this project to Spring Boot 4"
- "Upgrade to Spring Boot 4"
- "Spring Boot 4 migration"
- "Gradual upgrade to Boot 4"
- "Upgrade to Spring Boot 4.1"
- "Update Boot minor version"

The skill will activate automatically and guide you through the migration.

## Repository Structure

```
SKILL.md                              # Main skill definition (phases, workflow, troubleshooting)
references/
  gradual-upgrade-strategy.md         # Dependency graph, bridges, independent tracks, enterprise rollout
  build-and-dependencies.md           # Version requirements, modular starter mapping (70+ starters), build plugin changes
  property-changes.md                 # All property key renames and value changes
  jackson3-migration.md               # Jackson 3 packages, APIs, compatibility mode, OpenRewrite
  api-changes.md                      # Package relocations, removed APIs, renamed classes
  spring-security7.md                 # Security 7 breaking changes, DSL migration, request matchers
  testing-migration.md                # MockitoBean, Testcontainers 2, JUnit 6, RestTestClient
  spring-framework7.md                # JSpecify, path matching, resilience, Hibernate 7.1
  observability-migration.md          # OpenTelemetry, Micrometer, OTLP, Actuator decoupling
  http-clients.md                     # RestClient, WebClient, @HttpExchange, Feign migration
  api-versioning.md                   # Native API versioning strategies, semantic ranges, testing
  resilience-migration.md             # Spring Retry → Framework 7, @Retryable, @ConcurrencyLimit
  aot-native.md                       # AOT processing, BeanRegistrar, RuntimeHints, GraalVM 25
  minor-version-changes.md            # 4.x minor version changes, bridge removals, upgrade checklists
scripts/
  verify_migration.sh                 # Bridge-aware verification (PASS/FAIL/WARN/BRIDGE)
```

## Official Sources

This skill is cross-referenced against:

- [Spring Boot 4.0.0 GA Announcement](https://spring.io/blog/2025/11/20/spring-boot-4-0-0-available-now)
- [Spring Boot 4.0 Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide)
- [Spring Boot 4.0 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Release-Notes)
- [Upgrading Spring Boot](https://docs.spring.io/spring-boot/upgrading.html)
- [Jackson 3 Support in Spring](https://spring.io/blog/2025/10/07/introducing-jackson-3-support-in-spring/)
- [Moderne OpenRewrite Migration Guide](https://www.moderne.ai/blog/spring-boot-4x-migration-guide)
- [Road to GA Blog Series](https://spring.io/blog/2025/09/02/road_to_ga_introduction)
- [Dan Vega — Spring Boot 4 Is Here](https://www.danvega.dev/blog/spring-boot-4-is-here)
- [Dan Vega — sb4 Sample Project](https://github.com/danvega/sb4)

## FAQ

### Do I need to specify sub-agents?

No. This is a single, self-contained skill — no sub-agents or additional agent
configuration is required. The "6 independent tracks" mentioned in the gradual
upgrade strategy are conceptual work areas that teams can tackle in parallel,
not separate agents. Install the skill and Claude Code uses it as one unit.

## License

Apache 2.0
