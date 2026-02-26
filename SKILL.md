---
name: spring-boot-4-migration
description: >
  Migrate Spring Boot 3.x → 4.x and stay current across 4.x minor
  versions. Covers build/starter changes, Jackson 3, Spring Security 7,
  Spring Framework 7, observability (OpenTelemetry/Micrometer), property
  and package relocations, testing (JUnit 6, Testcontainers 2, MockitoBean),
  HTTP clients, resilience, AOT/native, and API versioning. Supports
  all-at-once and gradual upgrade strategies with compatibility bridges.
  Java and Kotlin; Maven and Gradle.
  Trigger on: "upgrade to Spring Boot 4", "migrate to Boot 4",
  "Spring Boot 4 migration", "upgrade spring boot", "gradual upgrade",
  "upgrade to 4.1", "Spring Boot 4.1", "update Boot minor version",
  or any request involving moving a Spring Boot 3.x project to 4.x
  or upgrading between 4.x minor versions.
allowed-tools: Bash(*), Glob(*), Grep(*), Read(*), WebFetch(*), WebSearch(*), mcp__claude_ai_Context7__*, mcp__plugin_context7_context7__*
---

# Spring Boot 4 Migration Skill

Migrate Spring Boot 3.x applications to 4.x and stay current across
minor versions with zero guesswork.

## Scope: 3.x → 4.0 and 4.x Minor Versions

This skill covers two scenarios:

1. **Major migration (3.x → 4.0)**: The bulk of this skill — all 9 phases,
   the gradual upgrade strategy, and the bridge system.
2. **Minor version upgrades (4.0 → 4.1, 4.1 → 4.2, etc.)**: Tracked in
   `references/minor-version-changes.md`. Minor versions may deprecate
   APIs, remove compatibility bridges, change defaults, and introduce new
   features. Check that file before bumping to any new 4.x minor version.

## Verify Library and Framework Usage

The model's training data has a knowledge cutoff. During migration, **actively verify** that APIs, configurations, and patterns are current for the target Spring Boot version:

1. **Identify versions** — Check `pom.xml` or `build.gradle.kts` to determine the exact versions of Spring Boot, Spring Framework, and all key dependencies (both source and target).
2. **Look up current documentation** — Use Context7 (`mcp__claude_ai_Context7__resolve-library-id` then `mcp__claude_ai_Context7__query-docs`) to retrieve up-to-date documentation for any library or framework where:
   - The version is newer than what the model may have been trained on
   - You are unsure whether an API, configuration property, or pattern is still valid or has been deprecated/replaced
   - The migration involves advanced or less common features of a library
3. **Search the web** — Use `WebSearch` and `WebFetch` to check for:
   - Breaking changes or migration guides for the specific version in use
   - Known security vulnerabilities (CVEs) in the dependency versions
   - Deprecated APIs that have been replaced in newer versions
   - Community-reported migration issues and workarounds
4. **Check GitHub** — Use `gh` CLI to check release notes, changelogs, or issues for dependencies when needed (e.g., `gh api repos/spring-projects/spring-boot/releases/latest`)

**Do not assume** that an API or pattern is correct based solely on model knowledge. When in doubt, look it up. This is especially critical during major version migrations where many APIs change.

## Toolchain Version Check (Do This First)

Before starting any migration, detect the project's current Java, Kotlin,
Maven, and Gradle versions. If any are below the minimum supported versions,
upgrade them BEFORE proceeding with the Spring Boot migration.

**Minimum supported versions for Spring Boot 4.x:**

| Tool | Minimum | Recommended | How to check |
|------|---------|-------------|--------------|
| Java | 17 | 21+ (25 supported) | `java -version` or `javac -version` |
| Kotlin | 2.2 | 2.2.x (latest) | Check `kotlin.version` in build file or `kotlinc -version` |
| Maven | 3.6.3 | 3.9.x+ | `mvn -version` or `./mvnw -version` |
| Gradle | 8.14 | 9.x | `gradle -version` or `./gradlew -version` |

**If older versions are detected:**

- **Java < 17**: Upgrade JDK before anything else. Boot 4 will not compile.
  Install JDK 21 (LTS, recommended) or JDK 17 (minimum). Update `JAVA_HOME`,
  `sourceCompatibility`/`targetCompatibility` (Gradle), or
  `<maven.compiler.source>`/`<maven.compiler.target>` (Maven).
- **Kotlin < 2.2**: Update `kotlin.version` property in your build file to
  2.2.x. Spring Boot 4 requires Kotlin 2.2 baseline for JSpecify null-safety
  support. If upgrading from Kotlin 1.x, review the Kotlin 2.0 migration
  guide first.
- **Maven < 3.6.3**: Upgrade Maven wrapper: `mvn wrapper:wrapper -Dmaven=3.9.9`
  or download a newer distribution. Older Maven versions may fail to resolve
  Boot 4 dependencies or run the Boot Maven plugin.
- **Gradle < 8.14**: Upgrade Gradle wrapper:
  `./gradlew wrapper --gradle-version=9.0` (or `8.14` minimum). Older Gradle
  versions are not supported by the Spring Boot 4 Gradle plugin.

**Action**: Run the version checks above. Resolve any version gaps, then
confirm the project still compiles and tests pass before continuing.

## Prerequisites

### For 3.x → 4.0 migration:
- Toolchain versions meet minimums (see Toolchain Version Check above)
- Source project compiles and tests pass on Spring Boot 3.5.x (latest patch)
- Java 17+ is available (Java 21+ recommended, Java 25 supported)
- All deprecated API calls from Boot 3.x are resolved where possible
- If on Boot 3.4 or earlier, first upgrade to 3.5.x before proceeding

### For 4.x → 4.y minor version upgrade:
- Project is on the latest patch of the current minor version (e.g., 4.0.x latest)
- Review `references/minor-version-changes.md` for the target version
- Check the official release notes for the target version
- Resolve any deprecation warnings from the current version

## Choose Your Migration Strategy

**Strategy 1 — Gradual Upgrade (Recommended for enterprise/large codebases)**
Read `references/gradual-upgrade-strategy.md` FIRST. This models migration
as a dependency graph: a Day-1 baseline using compatibility bridges, then
6 independent tracks (Starters, Jackson 3, Properties, Security, Testing,
Framework 7) completed at your own pace. Key bridges:
- `spring-boot-starter-classic` — restores 3.x monolithic auto-configuration
- `spring-boot-jackson2` — keeps Jackson 2 code working alongside Boot 4
- `spring-security-access` — bridges legacy AccessDecisionManager/Voter
Use this when: multiple teams, many services, phased rollouts, or when
complete Jackson 3 / Security 7 migration will take more than one sprint.

**Strategy 2 — All-at-Once (below)**
Execute all 9 phases sequentially in one effort. Best for greenfield
projects, small codebases, or single-team ownership.

## Automated Migration with OpenRewrite

Before doing manual migration, consider using OpenRewrite recipes to
automate the mechanical changes. The Moderne platform and OpenRewrite
project provide recipes for:

- Jackson 2 → 3 package/import migration: `org.openrewrite.java.jackson.UpgradeJackson_2_3`
- Spring Boot 4.x upgrade: `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5` (prepare step), then `UpgradeSpringBoot_4_0`
- `@MockBean` → `@MockitoBean` annotation replacement

Run OpenRewrite FIRST to handle bulk find-replace operations, then use
this skill's phases to address the remaining manual changes (Security DSL
rewrites, behavioral differences, property semantics, etc.).

See: https://www.moderne.ai/blog/spring-boot-4x-migration-guide

## Migration Workflow (All-at-Once)

Execute these phases IN ORDER. Each phase must compile and pass tests
before proceeding to the next.

### Phase 1: Build File Migration

Update Boot/Framework versions, build plugins, and replace deprecated
starters with modular equivalents. Add modular test starters for each
technology used in tests. Use classic starters as a stopgap if needed.

Read `references/build-and-dependencies.md` for complete starter mappings,
build plugin changes, and step-by-step instructions.

**Compile check**: Run `mvn compile` or `gradle compileJava` — fix any
dependency resolution errors before continuing.

### Phase 2: Property Migration

Scan all `application.properties`, `application.yml`, profile-specific
variants, and `@SpringBootTest(properties = ...)` annotations. Rename
changed property keys (Jackson, MongoDB, session, actuator, Hibernate).

Read `references/property-changes.md` for the complete property mapping.

### Phase 3: Jackson 3 Migration

Jackson 3 is the default in Boot 4. Migrate group IDs, packages, and
renamed Boot classes (`@JsonComponent` → `@JacksonComponent`, etc.).
Use `spring-boot-jackson2` bridge as a temporary stopgap if needed.

Read `references/jackson3-migration.md` for complete details.

### Phase 4: Package and API Relocations

Fix relocated imports (`@EntityScan`, `BootstrapRegistry`, etc.), removed
APIs (`PropertyMapper.alwaysApplyingNotNull`, path matching options), and
deprecated converters. Also migrate HTTP client code if applicable.

Read `references/api-changes.md` for the full list of relocated packages
and removed APIs.
Also read `references/http-clients.md` if your project uses RestClient,
WebClient, @HttpExchange, or Feign.

### Phase 5: Observability Migration

Replace individual Micrometer/OTel dependencies with the consolidated
`spring-boot-starter-opentelemetry` starter, update OTLP properties, and
rename observability modules. Actuator is now optional for OTel export.

Read `references/observability-migration.md` for complete details.

### Phase 6: Spring Security 7 Migration

Migrate to Security 7 DSL (lambda-only, no `and()`), replace removed
`AuthorizationManager#check`, switch to `PathPatternRequestMatcher`, and
update Jackson/SAML integrations. Use `spring-security-access` bridge if
legacy AccessDecisionManager/Voter code cannot migrate immediately.

Read `references/spring-security7.md` for complete details.

### Phase 7: Testing Infrastructure Migration

Replace `@MockBean`/`@SpyBean` with `@MockitoBean`/`@MockitoSpyBean`
(removed, not just deprecated). Add explicit auto-configure annotations
for test HTTP clients. Migrate Testcontainers 2 module names/packages
and adopt JUnit 6. Add modular test starters for each technology.

Read `references/testing-migration.md` for complete details.

### Phase 8: Spring Framework 7 Specific Changes

Address JSpecify nullability (Kotlin impact), deprecated `AntPathMatcher`,
MVC XML config removal, `SpringExtension` scope changes, Hibernate 7.1
entity mapping changes, and Spring Retry → Framework core retry migration.

Read `references/spring-framework7.md` for complete details.
Also read `references/resilience-migration.md` if your project uses
Spring Retry, `@Retryable`, `@ConcurrencyLimit`, or Resilience4j.
Optionally read `references/api-versioning.md` for new API versioning
capabilities introduced in Framework 7.

### Phase 9: Final Verification

Run the verification script if available, otherwise manually check:

1. `mvn clean verify` or `gradle clean build` — full compile + tests
2. Verify application starts: `mvn spring-boot:run` or `gradle bootRun`
3. Check actuator health: `curl localhost:8080/actuator/health`
4. Verify liveness/readiness probes (now enabled by default)
5. Check structured logging output format
6. Run integration tests against each active Spring profile
7. Verify Docker image builds if using buildpacks or Jib

Optionally read `references/aot-native.md` if you plan to adopt AOT
processing, GraalVM native images, or the new AOT cache feature.

## Minor Version Upgrades (4.0 → 4.1, 4.1 → 4.2, etc.)

When upgrading between Spring Boot 4.x minor versions, follow this process:

### 1. Check What Changed

Read `references/minor-version-changes.md` for the target version. Also
consult the official release notes:
- https://github.com/spring-projects/spring-boot/wiki (Release Notes per version)
- https://docs.spring.io/spring-boot/upgrading.html

### 2. Bridge Removal Awareness

Minor versions are where compatibility bridges get removed. Before
upgrading, check whether any bridges you depend on are being dropped:

| Bridge | Introduced | Expected Removal |
|--------|-----------|-----------------|
| `spring-boot-jackson2` | 4.0 | 4.1 or 4.2 |
| `spring-boot-starter-classic` | 4.0 | 5.0 |
| `spring-boot-starter-test-classic` | 4.0 | 5.0 |
| Deprecated starter names | 4.0 | 5.0 |

If you are still using a bridge that is being removed in the target
version, complete the corresponding migration track BEFORE upgrading.

### 3. Upgrade Process

1. Update the Spring Boot version in your build file to the target
   minor version's latest patch release.
2. Run `mvn compile` / `gradle compileJava` — fix any new compilation errors.
3. Run the full test suite — fix any test failures.
4. Review deprecation warnings in both build output and application logs.
   These signal what will break in the NEXT minor version.
5. Run `verify_migration.sh` to confirm migration state.

### 4. New Features

Each minor version introduces new features and auto-configurations.
These are opt-in and don't require action, but you may want to adopt
them. Check the "New and Noteworthy" section of each release's notes.

## Troubleshooting

### Common Compilation Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `ClassNotFoundException: ...autoconfigure...` | Modular starters needed | Add specific `spring-boot-starter-X` |
| `NoSuchMethodError: PropertyMapper.alwaysApplyingNotNull` | API removed | Use `always()` instead |
| `Cannot resolve symbol JsonComponent` | Renamed | Use `@JacksonComponent` |
| `Package com.fasterxml.jackson does not exist` | Jackson 3 packages | Change to `tools.jackson` |
| `Cannot resolve symbol MockBean` | Deprecated/removed | Use `@MockitoBean` |
| `ClassNotFoundException: RestClientBuilderCustomizer` | Elasticsearch change | Use `Rest5ClientBuilderCustomizer` |

### Quick Fixes

- If build won't compile at all after version bump, use `spring-boot-starter-classic` and `spring-boot-starter-test-classic` to get running, then incrementally migrate to modular starters. See `references/gradual-upgrade-strategy.md` for the full Day-1 baseline.
- If Jackson 3 migration is blocking, add `spring-boot-jackson2` temporarily. This is a first-class bridge — see Track B in the gradual strategy.
- If Spring Security changes are extensive, add `spring-security-access` bridge and upgrade to Security 6.5 preparation steps first (they provide opt-out flags for 7.0 breaking changes). See Track D in the gradual strategy.
- For enterprise rollouts across many services, use the Wave 1-4 approach in `references/gradual-upgrade-strategy.md` to minimize blast radius.

## Reference File Index

| File | When to read |
|------|-------------|
| `references/gradual-upgrade-strategy.md` | FIRST — migration dependency graph, bridges, independent tracks, enterprise rollout |
| `references/build-and-dependencies.md` | Phase 1 / Track A — full starter mapping tables, build plugin changes |
| `references/property-changes.md` | Phase 2 / Track C — all property key renames and value changes |
| `references/jackson3-migration.md` | Phase 3 / Track B — Jackson 3 packages, APIs, compatibility mode |
| `references/api-changes.md` | Phase 4 — package relocations, removed APIs, renamed classes |
| `references/observability-migration.md` | Phase 5 — OpenTelemetry starter, OTLP properties, module renames, Actuator decoupling |
| `references/spring-security7.md` | Phase 6 / Track D — Security 7 breaking changes and DSL migration |
| `references/testing-migration.md` | Phase 7 / Track E — MockBean, Testcontainers 2, JUnit 6, RestTestClient |
| `references/spring-framework7.md` | Phase 8 / Track F — Framework 7 changes, JSpecify, path matching |
| `references/http-clients.md` | HTTP clients — RestClient, WebClient, @HttpExchange, Feign migration, RestTestClient |
| `references/api-versioning.md` | API versioning — strategies, semantic ranges, client-side, deprecation, testing |
| `references/resilience-migration.md` | Resilience — Spring Retry → Framework 7, @Retryable, @ConcurrencyLimit, Resilience4j |
| `references/aot-native.md` | AOT/Native — BeanRegistrar, RuntimeHints, Spring Data AOT, GraalVM 25, AOT Cache |
| `references/minor-version-changes.md` | 4.x minor upgrades — changes per minor version, bridge removals, new features |
| `scripts/verify_migration.sh` | Phase 9 — bridge-aware verification with PASS/FAIL/WARN/BRIDGE |

## Official Sources

Cross-reference with these authoritative resources:

- GA Announcement: https://spring.io/blog/2025/11/20/spring-boot-4-0-0-available-now
- Migration Guide: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide
- Release Notes: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Release-Notes
- Upgrading Docs: https://docs.spring.io/spring-boot/upgrading.html
- Jackson 3 in Spring: https://spring.io/blog/2025/10/07/introducing-jackson-3-support-in-spring/
- OpenRewrite Recipes: https://www.moderne.ai/blog/spring-boot-4x-migration-guide
- Road to GA blog series: https://spring.io/blog/2025/09/02/road_to_ga_introduction
- Dan Vega walkthrough: https://www.danvega.dev/blog/spring-boot-4-is-here
- Dan Vega sample project: https://github.com/danvega/sb4
