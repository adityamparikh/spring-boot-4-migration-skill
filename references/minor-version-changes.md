# Minor Version Changes (4.x)

This file tracks breaking changes, deprecation removals, new defaults,
and notable features for each Spring Boot 4.x minor version beyond 4.0.

When upgrading to a new minor version, review the relevant section below
AND consult the official release notes for the target version.

## Contents

- [How to Use This File](#how-to-use-this-file)
- [General Minor Version Upgrade Process](#general-minor-version-upgrade-process)
- [Spring Boot 4.1](#spring-boot-41)
- [Spring Boot 4.2](#spring-boot-42)
- [Template for Future Versions](#template-for-future-versions)
- [Official Sources for Minor Version Changes](#official-sources-for-minor-version-changes)

## How to Use This File

1. Find the section for your **target** version.
2. Check "Breaking Changes" — these MUST be addressed before upgrading.
3. Check "Bridge Removals" — if you depend on a bridge being removed,
   complete the migration track first.
4. Check "Deprecations" — these still work but signal what will break
   in the next minor version.
5. Check "New Features" — opt-in improvements you may want to adopt.

## General Minor Version Upgrade Process

```
1. Read this file for the target version
2. Read the official release notes:
   https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-{VERSION}-Release-Notes
3. Update Spring Boot version in build file
4. Fix compilation errors
5. Run full test suite
6. Review deprecation warnings (build output + application logs)
7. Run verify_migration.sh
```

---

## Spring Boot 4.1

**Status**: **Released — GA 2026-06-10.**

**Official release notes**: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.1-Release-Notes

### Breaking Changes (4.0 → 4.1)

| Change | Impact | Action |
|---|---|---|
| **Classes, methods and properties deprecated in 4.0 have been removed.** | Any 4.0 deprecation warning you ignored is now a compile or startup failure. Scoped to deprecated *API* — the compatibility **modules** are separate and survive; see Bridge Status below. | Build on 4.0 with deprecation warnings visible and clear them *before* bumping. This is the single biggest 4.0 → 4.1 risk. |
| **`layertools` jar mode removed** (deprecated in 4.0). | Image builds invoking `java -Djarmode=layertools` break. | Switch to `-Djarmode=tools extract --layers`, or the build plugin's layered-image support. |
| **`-DskipTests` no longer skips AOT processing of tests.** | The Maven plugin now only reacts to `maven.test.skip`. CI relying on `-DskipTests` for speed still pays for AOT test processing. | Use `-Dmaven.test.skip=true` where you intend to skip AOT too. |
| **jOOQ 3.20 requires Java 21+.** | Using jOOQ on Java 17 forces a JDK bump or an explicit jOOQ pin. | Move to Java 21+, or override the jOOQ version. |
| **Apache Derby support deprecated.** | The Derby project was retired upstream, so Boot's integration is deprecated (not yet removed). | Plan a move off Derby — H2 for tests, or a real engine via Testcontainers. |

### Bridge Status

| Bridge | Status in 4.1 | Removal target |
|---|---|---|
| `spring-boot-jackson2` | Present, deprecated | **4.3.0**, per the Javadoc `forRemoval` metadata — not 4.1 or 4.2 as this file previously speculated. Complete Track B (Jackson 3) before 4.3. |

### Dependency Version Changes

| Dependency | Managed by 4.1 |
|---|---|
| Spring Framework | 7.0.8 |
| Spring Security | 7.1.0 |
| Spring Data BOM | 2026.0.0 |
| Kotlin | 2.3.21 |
| Hibernate Validator | 9.1 |

### New Features

- **gRPC** — first-class support for writing *and testing* gRPC servers and clients (Netty-backed standalone, or Servlet integration over HTTP/2).
- **Lazy JDBC connections** — `spring.datasource.connection-fetch` (`eager` | `lazy`). `lazy` wraps the pooled `DataSource` in `LazyConnectionDataSourceProxy`, so a physical connection is taken only when a statement actually runs — useful for `@Transactional` paths that may never touch the DB.
- **SSRF mitigation** — `InetAddressFilter` for blocking outgoing requests by address.
- **Jackson factory config** — `spring.jackson.read.*` / `spring.jackson.write.*`.
- **Cookie handling** — `withCookieHandling` and `spring.http.clients.cookie-handling`.
- **Config import encoding** — `spring.config.import=classpath:import.properties[encoding=utf-8]`.
- **`@RedisListener`** endpoint auto-configuration.
- **Log4j rotation** — size, time, size-and-time, and cron strategies.
- **SSL bundles** for embedded LDAP (`spring.ldap.embedded.ssl.bundle`) and RabbitMQ Streams (`spring.rabbitmq.stream.ssl.enabled`, `.ssl.bundle`).
- **Mongo batch schema** — `spring.batch.data.mongo.schema.initialize`.

### Upgrade Checklist for 4.0 → 4.1

- [ ] On 4.0, surface and clear **all** deprecation warnings — 4.1 removed them
- [ ] Replace `-Djarmode=layertools` with `-Djarmode=tools extract --layers`
- [ ] Replace `-DskipTests` with `-Dmaven.test.skip=true` where AOT should also be skipped
- [ ] If using jOOQ, confirm Java 21+ or pin the jOOQ version
- [ ] If using Derby, plan the move off it
- [ ] Bump to 4.1.x, then run the full build and test suite
- [ ] Review new deprecation warnings — these become 4.2 removals
- [ ] Run `verify_migration.sh`

---

## Spring Boot 4.2

**Status**: Not yet released.

**Official release notes**: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.2-Release-Notes
(will be available when released)

### Anticipated Changes

#### Bridge Removals (Likely)

| Bridge | Status | Expected in 4.2 |
|--------|--------|-----------------|
| `spring-boot-jackson2` | Still present (deprecated) | **Not 4.2** — Javadoc `forRemoval` targets **4.3.0** |

#### Upgrade Checklist

- [ ] Review 4.2 release notes
- [ ] Verify all bridges still in use are supported
- [ ] Update version and run full build
- [ ] Review deprecation warnings for 4.3/5.0 signals

---

## Template for Future Versions

When a new Spring Boot 4.x minor version is released, add a section
following this template:

```markdown
## Spring Boot 4.N

**Release date**: YYYY-MM-DD
**Official release notes**: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.N-Release-Notes

### Breaking Changes

List any changes that will cause compilation errors or runtime failures.

### Bridge Removals

| Bridge | Status |
|--------|--------|
| ... | Removed / Still available |

### Deprecations

List newly deprecated APIs, properties, or starters.

### New Features

Notable new features and auto-configurations.

### Dependency Version Changes

| Dependency | Old Version | New Version |
|-----------|-------------|-------------|
| ... | ... | ... |

### Upgrade Checklist for 4.(N-1) → 4.N

- [ ] Review official release notes
- [ ] Address breaking changes
- [ ] Complete migration for any removed bridges
- [ ] Update version and run full build
- [ ] Review deprecation warnings
- [ ] Run verify_migration.sh
```

---

## Official Sources for Minor Version Changes

Always cross-reference with:
- Release Notes: https://github.com/spring-projects/spring-boot/wiki
- Upgrading Guide: https://docs.spring.io/spring-boot/upgrading.html
- Spring Blog: https://spring.io/blog (announcements per release)
- Spring Boot Milestones: https://github.com/spring-projects/spring-boot/milestones
