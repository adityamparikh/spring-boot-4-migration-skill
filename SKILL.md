---
name: spring-boot-4-migration
description: >
  Guides Spring Boot version migrations: 2.7.x to 3.5.x, 3.5.x to 4.x, and
  minor upgrades within 4.x. Covers Java/Kotlin baseline upgrades, Jakarta
  EE namespace (javax to jakarta), Hibernate 5/6/7, Spring Security 5/6/7,
  modular starters, Jackson 3, Spring Framework 7, observability
  (Micrometer Tracing, OpenTelemetry), property and package relocations,
  JUnit 6, Testcontainers 2, MockitoBean, HTTP clients, resilience,
  AOT/native, API versioning, and OpenRewrite recipe automation. Supports
  all-at-once and gradual strategies with compatibility bridges. Java and
  Kotlin; Maven and Gradle. Trigger on requests like "upgrade/migrate to
  Spring Boot 3 or 4", "Spring Boot 2 to 3", "javax to jakarta", "upgrade
  to 4.1", "OpenRewrite Spring Boot", or any request moving a Spring Boot
  project to a newer major or minor version. Do NOT use for general Spring
  Boot development on a fixed version (new endpoints, services, JPA,
  tests) — use the spring-boot skill for that.
allowed-tools:
  - Bash
  - Glob
  - Grep
  - Read
  - WebFetch
  - WebSearch
  - mcp__claude_ai_Context7__*
  - mcp__plugin_context7_context7__*
---

# Spring Boot 4 Migration Skill

Migrate Spring Boot 2.7.x applications to 3.5.x, then 3.5.x to 4.x,
and stay current across 4.x minor versions, anchored to the official
Spring Boot migration guides and release notes for each leg.

## Scope: 2.7.x → 3.5.x → 4.x and 4.x Minor Versions

This skill covers three scenarios:

1. **Legacy migration (2.7.x → 3.5.x)** — the prelude. Covered in
   `references/spring-boot-2-to-3-migration.md`: Java 8/11 → 17 baseline,
   Jakarta EE namespace migration (`javax.*` → `jakarta.*`), Spring
   Security 5 → 6, Hibernate 5 → 6, observability migration to Micrometer
   Tracing/Observation, OpenRewrite recipe automation for every step.
   Reach Boot 3.5 latest patch here, then chain into the next scenario.
2. **Major migration (3.5.x → 4.0)** — the bulk of this skill. All 9 phases,
   the gradual upgrade strategy, and the bridge system below.
3. **Minor version upgrades (4.0 → 4.1, 4.1 → 4.2, etc.)** — tracked in
   `references/minor-version-changes.md`. Minor versions may deprecate
   APIs, remove compatibility bridges, change defaults, and introduce new
   features. Check that file before bumping to any new 4.x minor version.

If your project is on Boot 2.7.x or earlier, **start with §
"Coming from Spring Boot 2.7?" below**, complete the 2 → 3 leg, then
return here for the 3 → 4 phases.

## Verify APIs Against Current Documentation

Many APIs change across these migrations. When unsure whether an API,
property, or pattern is still valid for the target version, look it up
rather than relying on model knowledge:

- Use Context7 (`mcp__claude_ai_Context7__resolve-library-id` then
  `mcp__claude_ai_Context7__query-docs`) for library docs.
- Use `WebSearch` / `WebFetch` for breaking-change announcements, CVEs,
  and community migration reports.
- Use `gh` for release notes (e.g.,
  `gh api repos/spring-projects/spring-boot/releases/latest`).

## Toolchain Version Check (Do This First)

Before starting any migration, detect the project's Java, Kotlin, Maven,
and Gradle versions. If any are below the minimums for the target Boot
version, upgrade them BEFORE bumping Boot.

Read `references/toolchain-versions.md` for the minimum/recommended
versions table and per-tool upgrade commands.

## Coming from Spring Boot 2.7? Start here.

If your project is on Spring Boot 2.7.x (or earlier), do the 2.7 → 3.5
leg FIRST: `Boot 2.7.x → Boot 3.5.x latest → Boot 4.x`.

Read `references/spring-boot-2-to-3-migration.md`. It covers the
toolchain bump, 2.7.18 pre-flight, OpenRewrite recipes
(`UpgradeSpringBoot_3_5` one-shot or per-minor), Jakarta namespace,
Security 5 → 6, Hibernate 5 → 6, property migration, and observability
migration to Micrometer Tracing.

Return here once `./mvnw verify` / `./gradlew build` passes on Boot 3.5
latest patch and `spring-boot-properties-migrator` is quiet.

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
automate the mechanical changes. Run OpenRewrite FIRST to handle bulk
find-replace operations, then use this skill's phases to address the
remaining manual changes (Security DSL rewrites, behavioral differences,
property semantics, etc.).

**For the 2.7 → 3.5 leg** (run before any 3 → 4 work): see the recipe table in `references/spring-boot-2-to-3-migration.md` § 3 — `UpgradeSpringBoot_3_5` one-shot composes every step, or run per-minor for large codebases.

**For the 3.5 → 4.0 leg**:

| Recipe ID | Coverage |
|---|---|
| `org.openrewrite.java.spring.boot4.UpgradeSpringBoot_4_0` (Community Edition variant available) | Boot 3.5 → 4.0 |
| `org.openrewrite.java.jackson.UpgradeJackson_2_3` | Jackson 2 → 3 package/import migration |
| `org.openrewrite.java.spring.boot3.MigrateMockBeanToMockitoBean` (or the equivalent in `rewrite-spring`) | `@MockBean`/`@SpyBean` → `@MockitoBean`/`@MockitoSpyBean` |

See: [moderne.ai/blog/spring-boot-4x-migration-guide](https://www.moderne.ai/blog/spring-boot-4x-migration-guide). For the 4.0 recipe specifically: [docs.openrewrite.org/recipes/java/spring/boot4/upgradespringboot_4_0-community-edition](https://docs.openrewrite.org/recipes/java/spring/boot4/upgradespringboot_4_0-community-edition).

**Invocation**: `./mvnw org.openrewrite.maven:rewrite-maven-plugin:run -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:RELEASE -Drewrite.activeRecipes=<recipe-id>` (Maven) or `./gradlew rewriteRun -Drewrite.activeRecipes=<recipe-id>` (Gradle).

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
| `references/toolchain-versions.md` | Toolchain check — Java/Kotlin/Maven/Gradle minimums and per-tool upgrade commands |
| `references/spring-boot-2-to-3-migration.md` | Boot 2.7.x → 3.5.x prelude — Java baseline, Jakarta migration, Hibernate 5 → 6, Security 5 → 6, OpenRewrite recipes, per-minor highlights |
| `references/gradual-upgrade-strategy.md` | FIRST (for 3 → 4) — migration dependency graph, bridges, independent tracks, enterprise rollout |
| `references/build-and-dependencies.md` | Phase 1 / Track A — full starter mapping tables, build plugin changes |
| `references/property-changes.md` | Phase 2 / Track C — all property key renames and value changes |
| `references/jackson3-migration.md` | Phase 3 / Track B — Jackson 3 packages, APIs, compatibility mode |
| `references/api-changes.md` | Phase 4 — package relocations, removed APIs, renamed classes |
| `references/observability-migration.md` | Phase 5 — OpenTelemetry starter, OTLP properties, module renames, Actuator decoupling |
| `references/spring-security7.md` | Phase 6 / Track D — Security 7 breaking changes and DSL migration |
| `references/testing-migration.md` | Phase 7 / Track E — 2.7→3 testing leg (JUnit 4→5, javax→jakarta tests), then 3.5→4: MockBean, Testcontainers 2, JUnit 6, RestTestClient |
| `references/spring-framework7.md` | Phase 8 / Track F — Framework 7 changes, JSpecify, path matching |
| `references/http-clients.md` | HTTP clients — RestClient, WebClient, @HttpExchange, Feign migration, RestTestClient |
| `references/api-versioning.md` | API versioning — strategies, semantic ranges, client-side, deprecation, testing |
| `references/resilience-migration.md` | Resilience — Spring Retry → Framework 7, @Retryable, @ConcurrencyLimit, Resilience4j |
| `references/aot-native.md` | AOT/Native — BeanRegistrar, RuntimeHints, Spring Data AOT, GraalVM 25, AOT Cache |
| `references/minor-version-changes.md` | 4.x minor upgrades — changes per minor version, bridge removals, new features |
| `scripts/verify_migration.sh` | Phase 9 — bridge-aware verification with PASS/FAIL/WARN/BRIDGE |

Authoritative external sources for each leg are listed at the bottom of
the corresponding reference file.
