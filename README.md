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
  comparison-with-copilot-instructions.md  # FAQ comparing this skill with the awesome-copilot-instructions guide
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

### What are the minimum toolchain versions?

Java 17+, Kotlin 2.2+, Maven 3.6.3+, and Gradle 8.14+ (or 9.x). The skill
checks these before migration begins and provides upgrade commands if any are
below the minimum. Java 21 and Maven 3.9.x are recommended.

### My project is on Spring Boot 2.x. Can I use this skill?

Not directly. This skill covers 3.x → 4.x migration. You need to migrate to
Spring Boot 3.5.x first (the latest 3.x release), then use this skill to go
to 4.x.

### Should I use the all-at-once or gradual strategy?

Use **gradual** if you have a large codebase, multiple teams, many services, or
need phased rollouts. The gradual strategy uses compatibility bridges so you can
get running on Boot 4 quickly and complete the full migration in independent
tracks over time. Use **all-at-once** for small projects or single-team
ownership where you can do all 9 phases in one effort.

### Does this work with Kotlin projects?

Yes. The skill covers both Java and Kotlin. Kotlin-specific changes include
upgrading to Kotlin 2.2 baseline, JSpecify nullability integration, and the
new `spring-boot-starter-kotlin-serialization` module.

### Can I use OpenRewrite to automate parts of the migration?

Yes. The skill recommends running OpenRewrite recipes first to handle bulk
mechanical changes (import renames, `@MockBean` → `@MockitoBean`, Jackson
package migration), then using the skill's phases for the remaining manual
work like Security DSL rewrites and behavioral changes.

### Does this skill handle minor version upgrades (e.g., 4.0 → 4.1)?

Yes. The skill includes a minor version upgrade workflow and a reference file
(`references/minor-version-changes.md`) tracking changes per minor version,
including bridge removals, deprecation promotions, and new features.

### How does this skill compare to the GitHub Copilot Spring Boot 4 instructions?

See [references/comparison-with-copilot-instructions.md](references/comparison-with-copilot-instructions.md)
for a detailed FAQ-style comparison. In short: the Copilot guide is a single
~1,500-line file focused on Gradle/Kotlin with granular code snippets for core
breaking changes. This skill is a modular multi-file architecture covering the
full ecosystem (Security 7, Framework 7, observability, native image, resilience),
two migration strategies, verification tooling, and minor version tracking. Both
cover the core breaking changes well; each has gaps the other fills.

### What are compatibility bridges?

Bridges are first-class Spring Boot modules that restore Boot 3.x behavior on
Boot 4.x, giving you time to complete the full migration:
- `spring-boot-starter-classic` — restores monolithic auto-configuration
- `spring-boot-jackson2` — keeps Jackson 2 code working alongside Boot 4
- `spring-security-access` — bridges legacy `AccessDecisionManager`/`Voter`

These are temporary — check `references/minor-version-changes.md` for removal
timelines before upgrading minor versions.

## License

Apache 2.0
