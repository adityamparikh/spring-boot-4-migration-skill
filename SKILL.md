---
name: spring-boot-4-migration
description: >
  Migrate Spring Boot 3.x applications to Spring Boot 4.x and stay current
  across 4.x minor versions (4.0, 4.1, 4.2, etc.). Use when upgrading any
  Spring Boot project from 3.x to 4.0, OR from one 4.x minor version to
  another (e.g., 4.0 to 4.1). Covers build file changes (Maven/Gradle),
  modular starter migration, Jackson 3 adoption, Spring Security 7,
  Spring Framework 7, Hibernate 7.1, JUnit 6, Testcontainers 2,
  observability (OpenTelemetry, Micrometer, Actuator, distributed tracing),
  property key/value changes, package relocations, deprecated API removal,
  testing infrastructure updates, and bridge removal timelines tied to
  minor versions. Supports both all-at-once migration AND gradual
  incremental upgrade using compatibility bridges. Covers Java and Kotlin
  projects using Maven or Gradle (Groovy/Kotlin DSL).
  Trigger on: "upgrade to Spring Boot 4", "migrate to Boot 4",
  "Spring Boot 4 migration", "upgrade spring boot", "gradual upgrade",
  "upgrade to 4.1", "Spring Boot 4.1", "update Boot minor version",
  or any request involving moving a Spring Boot 3.x project to 4.x
  or upgrading between 4.x minor versions.
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

## Prerequisites

### For 3.x → 4.0 migration:
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
Execute all 8 phases sequentially in one effort. Best for greenfield
projects, small codebases, or single-team ownership.

## Automated Migration with OpenRewrite

Before doing manual migration, consider using OpenRewrite recipes to
automate the mechanical changes. The Moderne platform and OpenRewrite
project provide recipes for:

- Jackson 2 → 3 package/import migration: `org.openrewrite.java.jackson.UpgradeJackson_2_3`
- Spring Boot 4.x upgrade: `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5` (prepare step), then Boot 4 recipes as they become available
- `@MockBean` → `@MockitoBean` annotation replacement

Run OpenRewrite FIRST to handle bulk find-replace operations, then use
this skill's phases to address the remaining manual changes (Security DSL
rewrites, behavioral differences, property semantics, etc.).

See: https://www.moderne.ai/blog/spring-boot-4x-migration-guide

## Migration Workflow (All-at-Once)

Execute these phases IN ORDER. Each phase must compile and pass tests
before proceeding to the next.

### Phase 1: Build File Migration

Read `references/build-and-dependencies.md` for complete starter mappings
and build plugin changes.

1. Update Spring Boot version to `4.0.x` (latest patch)
2. Update Spring Framework to `7.x` (managed by Boot BOM)
3. Update the build plugin:
   - Maven: `spring-boot-maven-plugin` to 4.0.x
   - Gradle: `org.springframework.boot` plugin to 4.0.x
4. Replace deprecated starters with new names:
   - `spring-boot-starter-web` → `spring-boot-starter-webmvc`
   - `spring-boot-starter-oauth2-authorization-server` → `spring-boot-starter-security-oauth2-authorization-server`
   - `spring-boot-starter-oauth2-client` → `spring-boot-starter-security-oauth2-client`
   - `spring-boot-starter-oauth2-resource-server` → `spring-boot-starter-security-oauth2-resource-server`
   - `spring-boot-starter-web-services` → `spring-boot-starter-webservices`
   - `spring-boot-starter-aop` → `spring-boot-starter-aspectj`
5. Add modular test starters: For every `spring-boot-starter-X` in main
   scope, add `spring-boot-starter-X-test` to test scope if test code
   uses that technology's test support.
   Critical: `@WithMockUser`/`@WithUserDetails` now require
   `spring-boot-starter-security-test`.
6. Remove any direct dependency on `spring-boot-autoconfigure` — it is no
   longer a public dependency. Use technology-specific starters instead.
7. Remove Undertow — it is no longer supported. Switch to Tomcat or Jetty.
8. Remove `loaderImplementation = CLASSIC` from build config if present.
9. If using Flyway directly, add `spring-boot-starter-flyway`.
10. If project cannot immediately adopt modular starters, use classic
    starters as a stopgap:
    - `spring-boot-starter` → `spring-boot-starter-classic`
    - `spring-boot-starter-test` → `spring-boot-starter-test-classic`

**Compile check**: Run `mvn compile` or `gradle compileJava` — fix any
dependency resolution errors before continuing.

### Phase 2: Property Migration

Read `references/property-changes.md` for the complete property mapping.

Scan all `application.properties`, `application.yml`, and profile-specific
variants. Apply these key property changes:

- `spring.jackson.read.*` / `spring.jackson.write.*` → `spring.jackson.json.read.*` / `spring.jackson.json.write.*`
- `spring.data.mongodb.*` → many moved to `spring.mongodb.*` (see reference)
- `spring.session.redis.*` → `spring.session.data.redis.*`
- `spring.session.mongodb.*` → `spring.session.data.mongodb.*`
- `spring.dao.exceptiontranslation.enabled` → `spring.persistence.exceptiontranslation.enabled`
- `management.health.mongo.*` → `management.health.mongodb.*`
- `management.metrics.mongo.*` → `management.metrics.mongodb.*`
- Hibernate naming: `org.springframework.boot.orm.jpa.hibernate.SpringImplicitNamingStrategy` → `org.springframework.boot.hibernate.SpringImplicitNamingStrategy`

Also check `@SpringBootTest(properties = ...)` annotations for stale keys.

### Phase 3: Jackson 3 Migration

Read `references/jackson3-migration.md` for complete details.

Jackson 3 is the default in Boot 4. Key changes:
1. Group IDs: `com.fasterxml.jackson` → `tools.jackson`
   (Exception: `jackson-annotations` stays at `com.fasterxml.jackson.core`)
2. Packages: `com.fasterxml.jackson` → `tools.jackson`
   (Exception: annotations stay at `com.fasterxml.jackson.annotation`)
3. Renamed Boot classes:
   - `JsonObjectSerializer` → `ObjectValueSerializer`
   - `JsonValueDeserializer` → `ObjectValueDeserializer`
   - `Jackson2ObjectMapperBuilderCustomizer` → `JsonMapperBuilderCustomizer`
   - `@JsonComponent` → `@JacksonComponent`
   - `@JsonMixin` → `@JacksonMixin`
4. `ObjectMapper` → `JsonMapper` (Jackson 3 uses `JsonMapper` as primary)
5. If migration is too complex, add `spring-boot-jackson2` as a temporary
   stopgap (deprecated, will be removed later). Configure via
   `spring.jackson2.*` properties. Set `spring.jackson.use-jackson2-defaults=true`
   for backward-compatible defaults.

### Phase 4: Package and API Relocations

Read `references/api-changes.md` for the full list of relocated packages
and removed APIs.

Key changes:
1. `@EntityScan` import: `org.springframework.boot.autoconfigure.domain.EntityScan` → `org.springframework.boot.persistence.autoconfigure.EntityScan`
2. `BootstrapRegistry` moved: `org.springframework.boot` → `org.springframework.boot.bootstrap`
3. `EnvironmentPostProcessor` moved: `org.springframework.boot.env` → `org.springframework.boot` (deprecated form still available)
4. `spring-jcl` module removed — now uses Apache Commons Logging 1.3.0 directly
5. `javax.annotation.*` and `javax.inject.*` no longer supported — use `jakarta.annotation.*` and `jakarta.inject.*`
6. `PropertyMapper`: `alwaysApplyingNotNull()` removed — use `always()` for null-value mapping
7. `HttpMessageConverters` deprecated — use `ClientHttpMessageConvertersCustomizer` and `ServerHttpMessageConvertersCustomizer`
8. Path matching: `suffixPatternMatch`, `trailingSlashMatch`, `favorPathExtension` fully removed
9. Elasticsearch: `RestClient` → `Rest5Client`, `RestClientBuilderCustomizer` → `Rest5ClientBuilderCustomizer`
10. Spring Retry → Spring Framework core resilience (`org.springframework.core.retry`)

### Phase 5: Observability Migration

Read `references/observability-migration.md` for complete details.

Boot 4 restructures observability into modular components:
1. Replace individual Micrometer/OpenTelemetry dependencies with the
   consolidated `spring-boot-starter-opentelemetry` starter (includes
   OTel API, Micrometer tracing bridge, OTLP exporters).
2. Update OTLP properties:
   - `management.otlp.tracing.*` → `management.opentelemetry.tracing.export.*`
   - `management.otlp.metrics.*` → `management.metrics.export.otlp.*`
3. Evaluate whether `spring-boot-starter-actuator` is still needed —
   OpenTelemetry export now works without Actuator.
4. If using Brave/Zipkin, replace dependencies with `spring-boot-starter-zipkin`.
5. If using observation annotations (`@Observed`, `@Timed`, `@Counted`),
   add `spring-boot-starter-aspectj` and enable with
   `management.observations.annotations.enabled=true`.
6. Update any direct references to renamed observability modules:
   - `spring-boot-metrics` → `spring-boot-micrometer-metrics`
   - `spring-boot-observation` → `spring-boot-micrometer-observation`
   - `spring-boot-tracing` → `spring-boot-micrometer-tracing`

### Phase 6: Spring Security 7 Migration

Read `references/spring-security7.md` for complete details.

Key changes:
1. `AuthorizationManager#check` removed → use `AuthorizationManager#authorize`
2. Legacy `AccessDecisionManager`/`AccessDecisionVoter` requires adding
   `spring-security-access` module dependency
3. `AntPathRequestMatcher`/`MvcRequestMatcher` → `PathPatternRequestMatcher`
4. `and()` method in security DSL removed → use lambda DSL
5. Jackson 2 `SecurityJackson2Modules` → Jackson 3 `SecurityJacksonModules`
6. Spring Authorization Server is now part of Spring Security — remove
   explicit version override via `spring-authorization-server.version`;
   use `spring-security.version` instead
7. OpenSAML 4 removed → migrate to OpenSAML 5

### Phase 7: Testing Infrastructure Migration

Read `references/testing-migration.md` for complete details.

1. `@MockBean` → `@MockitoBean` (removed in 4.0, not just deprecated)
   `@SpyBean` → `@MockitoSpyBean` (removed in 4.0, not just deprecated)
   Key difference: `@MockitoBean` does NOT scan for matching beans by type
   across the entire context — it targets a specific bean. Review test
   behavior carefully. Migrate these on Boot 3.5.x before upgrading.
2. HTTP test clients are no longer auto-configured:
   - Add `@AutoConfigureMockMvc` explicitly to `@SpringBootTest` classes using `MockMvc`
   - Add `@AutoConfigureTestRestTemplate` if using `TestRestTemplate`
   - Consider migrating to `RestTestClient` (new in Boot 4)
3. Testcontainers 2.0:
   - Module prefix: `org.testcontainers:postgresql` → `org.testcontainers:testcontainers-postgresql`
   - Package relocations to module-specific packages
   - JUnit 4 support fully removed
4. JUnit 6:
   - Drop-in replacement for JUnit 5 in most cases
   - `SpringRunner` deprecated → use `@ExtendWith(SpringExtension.class)`
   - JUnit Vintage engine deprecated
5. Add test starters: `spring-boot-starter-X-test` for each technology
   used in tests (especially `spring-boot-starter-security-test`,
   `spring-boot-starter-webmvc-test`, `spring-boot-starter-data-jpa-test`)

### Phase 8: Spring Framework 7 Specific Changes

Read `references/spring-framework7.md` for complete details.

1. JSpecify nullability annotations added — may cause Kotlin compile
   errors or IDE warnings. Review nullable/non-nullable types.
2. `spring.lang.Nullable` deprecated → use `org.jspecify.annotations.Nullable`
3. MVC XML config (`<mvc:*>`) deprecated → use Java config
4. `AntPathMatcher` for HTTP request mapping deprecated → use `PathPatternParser`
5. `SpringExtension` now uses test-method scoped `ExtensionContext` —
   may break custom `TestExecutionListener` implementations in `@Nested` tests.
   Fix: annotate top-level class with `@SpringExtensionConfig(useTestClassScope = true)`
6. Spring Retry dependency removed — use Spring Framework core retry:
   `org.springframework.core.retry`
7. Hibernate ORM 7.1 — review entity mappings, especially around
   ID generation strategies and schema validation behavior

### Phase 9: Final Verification

Run the verification script if available, otherwise manually check:

1. `mvn clean verify` or `gradle clean build` — full compile + tests
2. Verify application starts: `mvn spring-boot:run` or `gradle bootRun`
3. Check actuator health: `curl localhost:8080/actuator/health`
4. Verify liveness/readiness probes (now enabled by default)
5. Check structured logging output format
6. Run integration tests against each active Spring profile
7. Verify Docker image builds if using buildpacks or Jib

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
| `references/minor-version-changes.md` | 4.x minor upgrades — changes per minor version, bridge removals, new features |
| `scripts/verify_migration.sh` | Phase 8 — bridge-aware verification with PASS/FAIL/WARN/BRIDGE |

## Official Sources

Cross-reference with these authoritative resources:

- Migration Guide: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide
- Release Notes: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Release-Notes
- Upgrading Docs: https://docs.spring.io/spring-boot/upgrading.html
- Jackson 3 in Spring: https://spring.io/blog/2025/10/07/introducing-jackson-3-support-in-spring/
- OpenRewrite Recipes: https://www.moderne.ai/blog/spring-boot-4x-migration-guide
