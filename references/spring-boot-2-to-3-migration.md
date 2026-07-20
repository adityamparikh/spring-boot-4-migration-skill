# Spring Boot 2.7.x → 3.5.x Migration Reference

Prelude to the 3.x → 4.x phases in `SKILL.md`. Reach **Boot 3.5.x latest** here, then chain into the 3.5 → 4.0 phases.

The 2 → 3 leap is well-documented and the LLM has broad knowledge of it (Jakarta namespace, Security 5 → 6 DSL, Hibernate 5 → 6). This reference focuses on **what to run, in what order, and the non-obvious gotchas** rather than restating well-known mechanics. Authoritative links at the bottom.

---

## 1. Toolchain

Java 17+ (21 recommended), Maven 3.6.3+, Gradle 8.5+, Kotlin 1.9.20+ for the 2 → 3 leg. See `references/toolchain-versions.md` for the Boot 4 destination minimums.

**Run the Boot 2.7 build on Java 17 BEFORE bumping Boot** — surfaces JDK incompatibilities (removed APIs, `sun.misc`, etc.) separately from Spring churn.

---

## 2. Pre-flight on Boot 2.7

- Upgrade to **Boot 2.7.18** (final 2.7 patch) first.
- Resolve every deprecation warning — each becomes a hard error on 3.0.
- Add `spring-boot-properties-migrator` as a `runtime` dependency for the duration of the migration so renamed/removed properties surface at startup. Remove it once stable on 3.5.

---

## 3. Automate with OpenRewrite

Run OpenRewrite FIRST. It handles the bulk of mechanical changes (`javax.*` → `jakarta.*`, property renames, deprecated annotation rewrites, version bumps). Hand-fix what it cannot.

### One-shot

```bash
# Maven
./mvnw org.openrewrite.maven:rewrite-maven-plugin:run \
  -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:RELEASE \
  -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5

# Gradle
./gradlew rewriteRun \
  -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5
```

`UpgradeSpringBoot_3_5` composes `_3_0` → `_3_1` → `_3_2` → `_3_3` → `_3_4` → `_3_5` internally and bumps Spring Security to 6.5 and Spring Cloud to 2025.0.x.

### Step-by-step (recommended for large codebases)

Run each minor in its own commit so failures are debuggable:

| Step | Recipe ID |
|---|---|
| 2.7 → 3.0 (incl. Jakarta) | `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0` |
| 3.0 → 3.1 | `…UpgradeSpringBoot_3_1` |
| 3.1 → 3.2 | `…UpgradeSpringBoot_3_2` |
| 3.2 → 3.3 | `…UpgradeSpringBoot_3_3` |
| 3.3 → 3.4 | `…UpgradeSpringBoot_3_4` (Community Edition variant) |
| 3.4 → 3.5 | `…UpgradeSpringBoot_3_5` (Community Edition variant) |

Property-only recipes (for config-only fixes): `SpringBootProperties_3_0` through `SpringBootProperties_3_5`. Standalone Jakarta migration outside the Boot bump: `org.openrewrite.java.migrate.jakarta.JakartaEE10` (artifact `org.openrewrite.recipe:rewrite-migrate-java`).

Catalog: [docs.openrewrite.org/recipes/java/spring/boot3](https://docs.openrewrite.org/recipes/java/spring/boot3).

**After OpenRewrite runs, review the diff.** Recipes do not catch behavioral changes (Security DSL semantics, Hibernate dirty-checking, observability conventions) and cannot rewrite logic that depends on internal Spring APIs.

---

## 4. Jakarta EE namespace migration

`javax.servlet`, `javax.persistence`, `javax.validation`, `javax.annotation.PostConstruct/PreDestroy`, `javax.inject`, `javax.websocket`, `javax.ws.rs` → `jakarta.*`. Handled by `UpgradeSpringBoot_3_0` or the standalone `JakartaEE10` recipe.

Manual cleanup spots OpenRewrite often misses:
- Reflection-based `Class.forName("javax.persistence.Entity")` lookups
- String literals used as JNDI lookup keys
- Generated code (Avro, protobuf, etc. — regenerate against jakarta-flavored generators)
- Third-party libraries still on `javax.*` only — check for a `jakarta` release, add the Apache Tomcat `jakartaee-migration` shim, or upgrade the dependency

---

## 5. Per-minor highlights (3.0 → 3.5)

| Boot | Framework | Notable |
|---|---|---|
| 3.0 | 6.0 | Jakarta, Security 6, Micrometer Tracing/Observation, removed trailing-slash matching, `spring.factories` registration removed |
| 3.1 | 6.0 | `@HttpExchange` GA, Docker Compose dev support, virtual threads experimental |
| 3.2 | 6.1 | Virtual threads GA (`spring.threads.virtual.enabled`), `RestClient`, `JdbcClient`, CRaC, `@Scheduled` observation |
| 3.3 | 6.1 | CDS support, structured logging foundations |
| 3.4 | 6.2 | `@MockitoBean` / `@MockitoSpyBean` introduced (deprecate `@MockBean` / `@SpyBean`) |
| 3.5 | 6.2 | Final 3.x line. `MockMvcTester`. Launchpad for 4.0. |

Per-minor release notes live under [github.com/spring-projects/spring-boot/wiki](https://github.com/spring-projects/spring-boot/wiki) (e.g., `Spring-Boot-3.4-Release-Notes`). Read the release notes between every two minors you skip — breaking-change wording matters.

---

## 6. Spring Security 5 → 6

Standard migration: `WebSecurityConfigurerAdapter` removed → return `SecurityFilterChain @Bean`; `antMatchers/mvcMatchers` → `requestMatchers`; `authorizeRequests` → `authorizeHttpRequests` (applies on every dispatch type, not just `REQUEST`); lambda DSL required. Migration guide: [docs.spring.io/spring-security/reference/migration/index.html](https://docs.spring.io/spring-security/reference/migration/index.html).

Less-obvious: `AccessDecisionVoter`/`AccessDecisionManager` replaced by `AuthorizationManager` — if you have custom voters, you need to port them (or use the `spring-security-access` bridge later on the 3 → 4 leg; see `gradual-upgrade-strategy.md`).

---

## 7. Hibernate 5 → 6

Group ID becomes **`org.hibernate.orm`** (not `org.hibernate`). Migration guide: [github.com/hibernate/hibernate-orm/blob/6.0/migration-guide.adoc](https://github.com/hibernate/hibernate-orm/blob/6.0/migration-guide.adoc).

Most-likely-to-bite:
- **ID generation**: `spring.jpa.hibernate.use-new-id-generator-mappings` is **removed** in Boot 3.0 (always behaves as `true`). Audit `@GeneratedValue(strategy = AUTO)` — prefer explicit `SEQUENCE` (does not block JDBC batching) or explicit `IDENTITY`.
- **Naming strategy**: implicit defaults shifted some collection-table names. Either pin the legacy strategy (`spring.jpa.hibernate.naming.implicit-strategy=org.springframework.boot.orm.jpa.hibernate.SpringImplicitNamingStrategy`) or migrate your Flyway/Liquibase schema.
- **HQL parser** rewritten — some legacy idioms (positional params with mixed casing, certain `IN` subqueries) now error.
- **`@MappedSuperclass`** stricter on abstract entity inheritance.
- **Bytecode enhancement plugin** moved to `org.hibernate.orm:hibernate-enhance-maven-plugin` / `org.hibernate.orm.tooling.gradle`.

For deep JPA review use the **`hibernate-jpa-validator`** skill.

---

## 8. Property renames you will hit

| Boot 2.7 | Boot 3.x |
|---|---|
| `spring.redis.*` | `spring.data.redis.*` |
| `spring.data.cassandra.*` | `spring.cassandra.*` |
| `server.max-http-header-size` | `server.max-http-request-header-size` |
| `management.metrics.export.<product>.*` | `management.<product>.metrics.export.*` |
| `spring.mvc.pathmatch.matching-strategy` | removed default; opt-in to `ant_path_matcher` (deprecated) only if needed |
| `spring.jpa.hibernate.use-new-id-generator-mappings` | removed |

Also: Boot 3 dropped image banner support — only `banner.txt` remains.

`SpringBootProperties_3_5` applies the rename catalog across `application.yml`, `application.properties`, and profile variants.

---

## 9. Observability migration

Boot 3.0 unified tracing onto **Micrometer Observation API** + **Micrometer Tracing**.

| Boot 2.7 | Boot 3.x |
|---|---|
| `spring-cloud-starter-sleuth` | `io.micrometer:micrometer-tracing-bridge-otel` (or `-bridge-brave`) |
| `WebMvcMetricsFilter` | `ServerHttpObservationFilter` |
| `MetricsRestTemplateCustomizer` | `RestTemplateBuilder.observationRegistry(...)` |
| `WebMvcTagsProvider` etc. | Custom `ObservationConvention` extending `DefaultServerRequestObservationConvention` |

If exporting to OpenTelemetry, prefer the OTel bridge — it aligns with Boot 4's consolidated `spring-boot-starter-opentelemetry` story.

---

## 10. Less-obvious pitfalls

- **Trailing slash matching** flips to `false`. `GET /users/` no longer matches `@GetMapping("/users")`. Either redirect or opt-in via `configurePathMatch(c -> c.setUseTrailingSlashMatch(true))` (deprecated; targeted for removal in Framework 7).
- **`spring.factories` auto-config registration** is removed. Move entries to `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`.
- **`@ConstructorBinding`** at the type level is no longer needed; keep it only on individual constructors when there is more than one. The `removeconstructorbindingannotation` recipe handles it.
- **`@EnableBatchProcessing`** is discouraged on Boot 3 — Spring Batch auto-configures. Multi-job apps need refactoring; see the 3.0 release notes.
- **MySQL driver coordinates**: `mysql:mysql-connector-java` → `com.mysql:mysql-connector-j`.
- **Apache HttpClient 4.x** usage relocated to `httpclient5`. `RestTemplate` configurations using `HttpComponentsClientHttpRequestFactory` need imports from `org.apache.hc.client5.http.impl.classic`.
- **Elasticsearch** high-level REST client removed. Replace `RestHighLevelClient` beans with `co.elastic.clients.elasticsearch.ElasticsearchClient`.
- **R2DBC BOM** is no longer transitively imported. Pin `r2dbc-pool` and your driver (`r2dbc-postgresql` etc.) explicitly.

---

## 11. Verification before the 3 → 4 leg

Ready to start `SKILL.md` Phases 1–9 when:

1. `./mvnw verify` / `./gradlew build` passes on **Boot 3.5 latest patch**.
2. `spring-boot-properties-migrator` prints **zero warnings** at startup. Then **remove the dependency**.
3. All build deprecation warnings addressed or explicitly accepted.
4. Application starts; `/actuator/health` returns OK.
5. Integration tests pass against each active profile.
6. Distributed tracing produces spans in your backend — observability is the most-often-skipped leg.

---

## Official sources

- Spring Boot 3.0 Migration Guide: [github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide)
- Spring Boot upgrading docs: [docs.spring.io/spring-boot/upgrading.html](https://docs.spring.io/spring-boot/upgrading.html)
- OpenRewrite Spring 2 → 3 guide: [docs.openrewrite.org/running-recipes/popular-recipe-guides/migrate-to-spring-3](https://docs.openrewrite.org/running-recipes/popular-recipe-guides/migrate-to-spring-3)
- OpenRewrite Boot 3.x recipes: [docs.openrewrite.org/recipes/java/spring/boot3](https://docs.openrewrite.org/recipes/java/spring/boot3)
- Spring Security migration index: [docs.spring.io/spring-security/reference/migration/index.html](https://docs.spring.io/spring-security/reference/migration/index.html)
- Hibernate ORM 6.0 migration guide: [github.com/hibernate/hibernate-orm/blob/6.0/migration-guide.adoc](https://github.com/hibernate/hibernate-orm/blob/6.0/migration-guide.adoc)
- Release notes index: [github.com/spring-projects/spring-boot/wiki](https://github.com/spring-projects/spring-boot/wiki)
