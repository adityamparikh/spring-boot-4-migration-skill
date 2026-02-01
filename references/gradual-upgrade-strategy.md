# Gradual Upgrade Strategy

A complete Boot 4 migration has many breaking changes that cannot all be
tackled in a single sprint. This document models migration as a dependency
graph: a mandatory Day-1 baseline using compatibility bridges, followed by
independent tracks that can be completed in any order by different teams on
different timelines.

## Migration Dependency Graph

```
┌──────────────────────────────────────────────────────────────────────┐
│  LEVEL 0 — DAY-1 BASELINE (must do together, in one PR)             │
│                                                                      │
│  ┌────────────────┐  ┌──────────────────┐  ┌─────────────────────┐  │
│  │ Version bump   │  │ Classic starters │  │ Jackson 2 compat    │  │
│  │ to 4.0.x       │→ │ escape hatch     │  │ module (bridge)     │  │
│  └────────────────┘  └──────────────────┘  └─────────────────────┘  │
│  ┌────────────────┐  ┌──────────────────┐  ┌─────────────────────┐  │
│  │ Security access│  │ Remove hard      │  │ Fix property hard   │  │
│  │ bridge module  │  │ removals (Undertow│  │ breaks (see below)  │  │
│  └────────────────┘  │ classic loader)  │  └─────────────────────┘  │
│                       └──────────────────┘                           │
│  RESULT: App compiles and runs on Boot 4 with all bridges in place  │
└────────────────────────────┬─────────────────────────────────────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          ▼                  ▼                  ▼
┌────────────────┐ ┌────────────────┐ ┌────────────────────┐
│ TRACK A        │ │ TRACK B        │ │ TRACK C            │
│ Modular        │ │ Jackson 3      │ │ Properties         │
│ Starters       │ │                │ │                    │
│                │ │ Remove jackson2│ │ Rename deprecated  │
│ Replace classic│ │ bridge, migrate│ │ keys across all    │
│ with specific  │ │ to tools.jackson│ │ profiles           │
│ starters +     │ │ packages       │ │                    │
│ test starters  │ │                │ │ No bridge needed—  │
│                │ │                │ │ old keys log       │
│ No ordering    │ │                │ │ deprecation warns  │
│ constraint     │ │                │ │                    │
└───────┬────────┘ └───────┬────────┘ └────────────────────┘
        │                  │
        │                  │ (Jackson 3 must be done before
        │                  │  Security Jackson migration)
        │                  ▼
        │          ┌────────────────┐ ┌────────────────────┐
        │          │ TRACK D        │ │ TRACK F            │
        │          │ Security 7     │ │ Framework 7        │
        │          │                │ │                    │
        │          │ DSL migration, │ │ JSpecify, path     │
        │          │ request matcher│ │ matching, resilience│
        │          │ authorization  │ │ Hibernate 7.1      │
        │          │ API, Jackson 3 │ │                    │
        │          │ security mods  │ │ No bridge needed—  │
        │          │                │ │ mostly additive    │
        │          │ Bridge: spring-│ │                    │
        │          │ security-access│ │                    │
        │          └────────────────┘ └────────────────────┘
        │
        ▼
┌────────────────────┐
│ TRACK E            │
│ Testing            │
│                    │
│ MockitoBean,       │
│ RestTestClient,    │
│ Testcontainers 2,  │
│ JUnit 6            │
│                    │
│ Partially depends  │
│ on Track A (need   │
│ test starters)     │
│ OR use test-classic│
└────────┬───────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│  LEVEL 2 — FINAL CLEANUP (after all tracks complete)                │
│                                                                      │
│  • Remove spring-boot-starter-classic                               │
│  • Remove spring-boot-starter-test-classic                          │
│  • Remove spring-boot-jackson2                                      │
│  • Remove spring-security-access                                    │
│  • Remove spring.jackson.use-jackson2-defaults=true                 │
│  • Run verify_migration.sh — all checks must pass                   │
│  • Adopt new features (API versioning, BeanRegistrar, HTTP clients) │
└──────────────────────────────────────────────────────────────────────┘
```

## Level 0: Day-1 Baseline (One PR)

The goal is a compiling, test-passing application on Boot 4.0.x with the
minimum possible code changes. All compatibility bridges are in play.

### Build File Changes

```xml
<!-- 1. Version bump -->
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.0.0</version>
</parent>

<!-- 2. Classic starters — restore 3.x monolithic auto-configuration -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-classic</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test-classic</artifactId>
    <scope>test</scope>
</dependency>

<!-- 3. Jackson 2 compatibility — keep existing Jackson 2 code working -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-jackson2</artifactId>
</dependency>

<!-- 4. Security access bridge — keep legacy AccessDecisionManager/Voter -->
<dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-access</artifactId>
</dependency>
```

Gradle Kotlin DSL equivalent:

```kotlin
implementation("org.springframework.boot:spring-boot-starter-classic")
testImplementation("org.springframework.boot:spring-boot-starter-test-classic")
implementation("org.springframework.boot:spring-boot-jackson2")
implementation("org.springframework.security:spring-security-access")
```

### Properties to Add on Day 1

```properties
# Get Jackson 2-compatible defaults (timestamp formats, etc.)
spring.jackson.use-jackson2-defaults=true
```

### Hard Breaks That Cannot Be Bridged

Even with all bridges, these MUST be fixed on Day 1:

| Issue | Why No Bridge Exists | Fix |
|-------|---------------------|-----|
| Undertow | Incompatible with Servlet 6.1 | Switch to Tomcat or Jetty |
| `loaderImplementation = CLASSIC` | Loader removed entirely | Remove from build plugin config |
| Embedded launch scripts | Feature removed | Use `java -jar` |
| Direct `spring-boot-autoconfigure` dependency | No longer a public artifact | Remove (classic starter covers it) |
| `javax.annotation.*` / `javax.inject.*` | Should already be `jakarta.*` from Boot 3 | Fix any stragglers |
| `PropertyMapper.alwaysApplyingNotNull()` | Method removed, no deprecated bridge | Change to `always()` |
| `AuthorizationManager#check()` | Method removed, no deprecated bridge | Change to `#authorize()` |
| `spring-jcl` explicit dependency | Module removed entirely | Remove; Commons Logging 1.3.0 is automatic |

### Day-1 Verification

After applying the baseline, confirm:
1. `mvn clean compile` / `gradle compileJava` — green
2. `mvn test` / `gradle test` — green (some deprecation warnings OK)
3. Application starts and serves requests
4. CI pipeline passes

Deprecation warnings are expected and acceptable. They mark the tracks
you will complete incrementally.

## Track A: Modular Starters

**Depends on**: Level 0 only
**Blocks**: Track E (test starters) — unless using test-classic
**Bridge being removed**: `spring-boot-starter-classic`, `spring-boot-starter-test-classic`
**Effort**: Low to Medium (mostly build file changes)

### What to Do

1. Replace `spring-boot-starter-classic` with technology-specific starters.
   See `references/build-and-dependencies.md` for the complete mapping.

2. For every `spring-boot-starter-X` in main scope, evaluate whether
   test code needs `spring-boot-starter-X-test` in test scope.

3. Rename deprecated starters:
   - `spring-boot-starter-web` → `spring-boot-starter-webmvc`
   - `spring-boot-starter-aop` → `spring-boot-starter-aspectj`
   - `spring-boot-starter-oauth2-*` → `spring-boot-starter-security-oauth2-*`
   - `spring-boot-starter-web-services` → `spring-boot-starter-webservices`

4. Replace raw library dependencies with Boot starters where available.
   Example: raw `com.h2database:h2` → `spring-boot-starter-h2-console`
   (the starter includes both the library AND its auto-configuration module).

### Incremental Approach

You do NOT have to replace `classic` all at once. You can add specific
starters alongside `classic`:

```xml
<!-- Phase 1: classic + explicit starters you've already audited -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-classic</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webmvc</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>

<!-- Phase 2: once all starters are explicit, remove classic -->
```

This is safe because duplicated auto-configuration is deduplicated by
Spring Boot — having both `classic` and a specific starter does not
cause conflicts.

### Verification

- Remove `spring-boot-starter-classic` (and test-classic)
- `mvn clean verify` — no `ClassNotFoundException` for auto-configuration
- Every feature that was auto-configured still works

## Track B: Jackson 3

**Depends on**: Level 0 only
**Blocks**: Track D (Security Jackson modules depend on Jackson 3)
**Bridge being removed**: `spring-boot-jackson2`
**Effort**: Medium to High (depends on custom serializer count)

### What to Do

See `references/jackson3-migration.md` for complete details. Summary:

1. Find/replace package imports: `com.fasterxml.jackson` → `tools.jackson`
   (EXCEPT annotations which stay at `com.fasterxml.jackson.annotation`)
2. Rename Spring Boot Jackson classes:
   - `@JsonComponent` → `@JacksonComponent`
   - `@JsonMixin` → `@JacksonMixin`
   - `JsonObjectSerializer` → `ObjectValueSerializer`
   - `Jackson2ObjectMapperBuilderCustomizer` → `JsonMapperBuilderCustomizer`
3. Migrate custom serializers/deserializers
4. Migrate `ObjectMapper` direct usage to `JsonMapper.builder()` pattern
5. Update explicit Jackson dependencies from `com.fasterxml.*` to `tools.jackson.*`

### Incremental Approach for Jackson

For large codebases with many custom serializers, migrate module-by-module:

1. Keep `spring-boot-jackson2` bridge in place
2. Migrate one module/package of serializers at a time
3. Jackson 2 and Jackson 3 `ObjectMapper`/`JsonMapper` can coexist in the
   same application — Jackson 2 `ObjectMapper` via the bridge, Jackson 3
   `JsonMapper` via Boot's default auto-configuration
4. Once all custom code uses Jackson 3, remove the bridge and
   `spring.jackson.use-jackson2-defaults=true`

### Jersey Exception

Jersey 4.0 does NOT support Jackson 3 yet. If you use Jersey:
- Keep `spring-boot-jackson2` alongside Jersey
- Add explicit Jackson 2 provider dependency for Jersey
- Track Jersey's Jackson 3 support roadmap before removing bridge

### Verification

- Remove `spring-boot-jackson2` dependency
- Remove `spring.jackson.use-jackson2-defaults=true`
- `grep -r "com.fasterxml.jackson.core\|com.fasterxml.jackson.databind\|com.fasterxml.jackson.datatype\|com.fasterxml.jackson.module" src/` — should return zero matches (annotations excluded)
- All JSON serialization/deserialization tests pass
- API responses produce expected JSON format

## Track C: Properties

**Depends on**: Level 0 only
**Blocks**: Nothing
**Bridge**: Deprecated keys still work with warnings (no explicit bridge module)
**Effort**: Low

### What to Do

See `references/property-changes.md` for complete details. Scan ALL of:
- `src/main/resources/application.properties` (and `.yml`)
- Profile-specific variants (`application-dev.properties`, etc.)
- `@SpringBootTest(properties = ...)` annotations
- `@TestPropertySource` annotations
- External config files (Kubernetes ConfigMaps, etc.)
- Environment variable overrides that map to renamed keys

### Incremental Approach

Deprecated keys log warnings but still function. You can rename them
across profiles incrementally — e.g., fix `application.properties` first,
then tackle profile variants one at a time.

Priority order:
1. Fix keys that changed semantically (not just renamed)
2. Fix keys in production profiles
3. Fix keys in test/dev profiles
4. Fix keys in `@SpringBootTest` annotations (easy to miss)

### Verification

- Start application, grep logs for `Deprecated configuration property`
- Zero deprecation warnings from property keys = track complete

## Track D: Security 7

**Depends on**: Level 0, and Track B (Jackson 3) if using Security's Jackson modules
**Blocks**: Nothing
**Bridge being removed**: `spring-security-access`
**Effort**: Medium to High (depends on security config complexity)

### What to Do

See `references/spring-security7.md` for complete details. Summary:

1. Migrate `and()` chaining → lambda DSL (if not done during Boot 3.x)
2. `AntPathRequestMatcher`/`MvcRequestMatcher` → `PathPatternRequestMatcher`
3. `SecurityJackson2Modules` → `SecurityJacksonModules` (requires Track B)
4. `AccessDecisionManager`/`AccessDecisionVoter` → `AuthorizationManager`
5. Authorization Server version management changes
6. OpenSAML 4 → 5 (if using SAML)

### Incremental Approach

1. **Phase 1** — DSL and matchers (no bridge dependency):
   Remove `and()`, switch to lambda DSL, replace request matchers.
   These are mechanical transforms that can be done independently.

2. **Phase 2** — Authorization API (removes `spring-security-access` bridge):
   Migrate `AccessDecisionManager`/`Voter` to `AuthorizationManager`.
   This is the most significant Security refactor.

3. **Phase 3** — Jackson and SAML (depends on Track B):
   Migrate Security Jackson modules to Jackson 3 API.
   Migrate SAML to OpenSAML 5 if applicable.

### Preparation Path

If your codebase has extensive Security configuration, the safest path is:

1. While still on Boot 3.5.x / Security 6.5, apply the Security 7
   preparation steps (Security 6.5 provides opt-out flags for every
   breaking change in 7.0)
2. After Day-1 baseline on Boot 4, the Security migration is minimal

### Verification

- Remove `spring-security-access` dependency
- All `@WithMockUser`/`@WithUserDetails` tests pass
- OAuth2 flows work end-to-end
- No `AccessDecisionManager` or `AccessDecisionVoter` references remain

## Track E: Testing

**Depends on**: Level 0, optionally Track A (for modular test starters)
**Blocks**: Nothing
**Bridge**: `spring-boot-starter-test-classic` covers test auto-configuration
**Effort**: Medium (scales with test count)

### What to Do

See `references/testing-migration.md` for complete details. Summary:

1. `@MockBean` → `@MockitoBean`, `@SpyBean` → `@MockitoSpyBean`
   Critical behavioral difference: `@MockitoBean` does NOT scan by type
2. Add `@AutoConfigureMockMvc` or `@AutoConfigureTestRestTemplate` explicitly
3. Consider adopting `RestTestClient` (new unified testing API)
4. Testcontainers 2.0 module rename: add `testcontainers-` prefix
5. JUnit 6 cleanup (optional, mostly drop-in compatible)
6. Add test starters: `spring-boot-starter-X-test` for each technology

### Incremental Approach

1. **Phase 1** — Keep `test-classic`, just fix `@MockBean` → `@MockitoBean`.
   This is the highest-risk change (behavioral difference) so do it first
   while everything else is stable.

2. **Phase 2** — Add explicit test auto-configuration annotations.
   `@AutoConfigureMockMvc`, `@AutoConfigureTestRestTemplate`, etc.
   Test each test class individually.

3. **Phase 3** — Replace `test-classic` with specific test starters.
   After Track A is complete, add `spring-boot-starter-X-test` for each
   technology used in tests.

4. **Phase 4** — Adopt `RestTestClient` for new tests.
   Existing `MockMvc`/`WebTestClient`/`TestRestTemplate` tests still work;
   only migrate them if you want the unified API.

### Verification

- Remove `spring-boot-starter-test-classic`
- All tests pass (unit, integration, E2E)
- No `@MockBean` or `@SpyBean` annotations remain
- No `ClassNotFoundException` for test auto-configuration

## Track F: Framework 7

**Depends on**: Level 0 only
**Blocks**: Nothing
**Bridge**: None needed — changes are mostly additive or opt-in
**Effort**: Low to Medium

### What to Do

See `references/spring-framework7.md` for complete details. Summary:

1. JSpecify null safety — add `@NullMarked` to packages, use
   `org.jspecify.annotations.Nullable` instead of Spring's deprecated one.
   **This is opt-in for your code** — you can adopt gradually.

2. Path matching: remove reliance on `suffixPatternMatch`,
   `trailingSlashMatch`, `favorPathExtension` (all removed).

3. Spring Retry → Core resilience: migrate `org.springframework.retry` to
   `org.springframework.core.retry` with `@Retryable` and `@ConcurrencyLimit`.

4. MVC XML config → Java config (if applicable).

5. Hibernate ORM 7.1 — review entity ID generation strategy changes.

6. `SpringExtension` test-method scope change — may affect `@Nested` tests.

### Incremental Approach

All Framework 7 changes can be applied independently:
- JSpecify: package by package, team by team
- Path matching: fix affected endpoints one at a time
- Resilience: migrate retry logic module by module
- Hibernate: test entity mapping changes in isolation

### Verification

- No `spring.lang.Nullable` imports remain
- No suffix/trailing-slash path matching configuration
- No `org.springframework.retry` imports (if migrating away)
- Hibernate entity tests pass with 7.1

## Bridge Deprecation Timeline (Estimated)

Understanding when bridges will be removed creates appropriate urgency.

**Note**: The "Expected Removal" column contains estimates based on Spring
team communications and historical patterns, NOT official commitments.
Check the official Spring Boot release notes for confirmed removal dates
before planning migration deadlines.

| Bridge | Available | Expected Deprecation | Expected Removal (estimated) |
|--------|-----------|---------------------|-----------------|
| `spring-boot-starter-classic` | Boot 4.0 | Boot 4.0 (deprecated at launch) | Boot 5.0 |
| `spring-boot-starter-test-classic` | Boot 4.0 | Boot 4.0 (deprecated at launch) | Boot 5.0 |
| `spring-boot-jackson2` | Boot 4.0 | Boot 4.0 (deprecated at launch) | Boot 4.1 or 4.2 |
| `spring-security-access` | Security 7.0 | Security 7.0 (deprecated at launch) | Security 8.0 |
| Deprecated starter names (web, aop) | Boot 4.0 | Boot 4.0 (deprecated at launch) | Boot 5.0 |
| Deprecated property keys | Boot 4.0 | Boot 4.0 | Boot 5.0 |
| `spring.jackson.use-jackson2-defaults` | Boot 4.0 | Boot 4.0 (deprecated at launch) | Follows jackson2 module |

**Key takeaway**: Classic starters and deprecated starter names are safe through
the entire 4.x lifecycle. The Jackson 2 bridge has the shortest expected lifespan
— prioritize Track B accordingly.

## Enterprise Rollout Strategy

For organizations with many services:

### Wave 1 — Pilot (1-2 services)
Apply Level 0 + all tracks to a low-risk service. Document any issues
not covered by this skill. Validate CI/CD pipelines.

### Wave 2 — Day-1 Baseline (all services)
Apply Level 0 only to every service. Every service is now on Boot 4 with
bridges. This unlocks using Boot 4 features in shared libraries.

### Wave 3 — Track Completion (team-by-team)
Each team works through Tracks A-F at their own pace. Shared internal
libraries should complete Track B (Jackson 3) first since they affect
consumers.

### Wave 4 — Bridge Removal
After all services complete all tracks, remove bridges globally.
Run `verify_migration.sh` across the fleet.

## Track Dependency Summary Table

| Track | Depends On | Blocks | Bridge Module | Risk |
|-------|-----------|--------|---------------|------|
| A: Modular Starters | Level 0 | E (test starters) | `starter-classic` | Low |
| B: Jackson 3 | Level 0 | D (Security Jackson) | `spring-boot-jackson2` | Medium-High |
| C: Properties | Level 0 | Nothing | None (deprecated keys still work) | Low |
| D: Security 7 | Level 0, B (partial) | Nothing | `spring-security-access` | Medium-High |
| E: Testing | Level 0, A (optional) | Nothing | `starter-test-classic` | Medium |
| F: Framework 7 | Level 0 | Nothing | None (mostly additive) | Low |
