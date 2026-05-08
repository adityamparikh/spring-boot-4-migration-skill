# Spring Boot 2.7.x → 3.5.x Migration Reference

This is the prelude to the 3.x → 4.x phases in `SKILL.md`. Reach **Boot 3.5.x latest** here, then chain into the existing 3.5 → 4.0 phases.

The 2 → 3 leap is the largest non-major Spring change in years: Java baseline jumps from 8/11 to 17, every `javax.*` import becomes `jakarta.*`, Spring Security and Hibernate get major-version bumps, and the observability stack moves from Spring Cloud Sleuth + custom filters to Micrometer Tracing + Observation API. Plan it as a multi-stage upgrade, not a one-day version bump.

---

## 1. Toolchain prerequisites (do this FIRST)

| Tool | Boot 2.7 minimum | Boot 3.5 minimum | Recommended for the upgrade |
|---|---|---|---|
| Java | 8 | **17** | 21 (LTS) |
| Maven | 3.5 | **3.6.3** | 3.9.x |
| Gradle | 6.8 | **8.5** (Boot 3.4+) / **8.14** (Boot 4) | 8.10+ |
| Kotlin | 1.6 | **1.9.20** | 2.0.x while still on Boot 3 |

**Java upgrade**: install JDK 17 (or 21), update `JAVA_HOME`, set `<maven.compiler.source>17</maven.compiler.source>` (Maven) or `sourceCompatibility = JavaVersion.VERSION_17` (Gradle). Re-run the build on Boot 2.7 with Java 17 BEFORE touching the Boot version — that surfaces JDK incompatibilities (removed APIs, sun.misc, etc.) one at a time instead of stacking them on top of the Boot upgrade.

**Maven/Gradle wrapper**: `./mvnw wrapper:wrapper -Dmaven=3.9.9` or `./gradlew wrapper --gradle-version=8.10`.

---

## 2. Pre-flight on Boot 2.7

Before changing the Boot version, do these on 2.7:

- Upgrade to **Boot 2.7 latest patch** (currently 2.7.18). It contains forward-compat fixes that smooth the 3.0 jump.
- Resolve every deprecation warning surfaced by the 2.7.18 build. Each one becomes a hard compile error in 3.0.
- Add the **Spring Boot Properties Migrator** — keep it temporarily through the upgrade so renamed/removed properties show up as runtime warnings instead of silent misconfigurations. Source: [docs.spring.io/spring-boot/upgrading.html](https://docs.spring.io/spring-boot/upgrading.html).

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-properties-migrator</artifactId>
    <scope>runtime</scope>
</dependency>
```

```kotlin
// Gradle Kotlin DSL
runtimeOnly("org.springframework.boot:spring-boot-properties-migrator")
```

After the migration is complete and the application is stable on 3.5.x, **remove** this dependency (it is for transition diagnostics only).

---

## 3. Automate with OpenRewrite

The single biggest win is letting OpenRewrite handle the mechanical transformations: `javax.*` → `jakarta.*`, property key renames, deprecated annotation replacements, and version bumps. Run it FIRST, then resolve what it cannot fix.

### One-shot 2.x → 3.5.x

```bash
# Maven
./mvnw org.openrewrite.maven:rewrite-maven-plugin:run \
  -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:RELEASE \
  -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5

# Gradle
./gradlew rewriteRun \
  -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5
```

`UpgradeSpringBoot_3_5` is composed: it runs `UpgradeSpringBoot_3_0` → `_3_1` → `_3_2` → `_3_3` → `_3_4` internally and finishes at 3.5.x. It also bumps Spring Security to 6.5 and Spring Cloud to 2025.0.x.

### Step-by-step (recommended for large codebases)

Run each step in a separate commit so failures are debuggable:

| Step | Recipe ID | Source |
|---|---|---|
| Bump to 3.0 (incl. Jakarta migration) | `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0` | [docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_0](https://docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_0) |
| 3.0 → 3.1 | `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_1` | [docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_1](https://docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_1) |
| 3.1 → 3.2 | `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_2` | [docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_2](https://docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_2) |
| 3.2 → 3.3 | `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_3` | [docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_3](https://docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_3) |
| 3.3 → 3.4 | `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_4` (Community Edition variant available) | [docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_4-community-edition](https://docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_4-community-edition) |
| 3.4 → 3.5 | `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5` (Community Edition variant available) | [docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_5-community-edition](https://docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_5-community-edition) |

### Property-only recipes (when build coordinates already match)

If you only need the property key renames (e.g., for a config-only fix between minors):

| Recipe | Purpose |
|---|---|
| `org.openrewrite.java.spring.boot3.SpringBootProperties_3_0` | 2.x → 3.0 property renames |
| `org.openrewrite.java.spring.boot3.SpringBootProperties_3_1` through `SpringBootProperties_3_5` | per-minor property renames |

OpenRewrite docs catalog: [docs.openrewrite.org/recipes/java/spring/boot3](https://docs.openrewrite.org/recipes/java/spring/boot3). End-to-end "Migrate to Spring Boot 3 from 2" guide: [docs.openrewrite.org/running-recipes/popular-recipe-guides/migrate-to-spring-3](https://docs.openrewrite.org/running-recipes/popular-recipe-guides/migrate-to-spring-3).

After OpenRewrite runs, **review the diff carefully**. The recipes do not catch behavioral changes (security DSL semantics, Hibernate dirty-checking changes, observability conventions), and they cannot rewrite logic that depends on internal Spring APIs.

---

## 4. Jakarta EE namespace migration

Spring Boot 3.0 moved from Java EE 8 / `javax.*` to Jakarta EE 9 / `jakarta.*`. This affects every project that imports `javax.servlet`, `javax.persistence`, `javax.validation`, `javax.annotation.PostConstruct/PreDestroy`, `javax.inject`, `javax.websocket`, `javax.ws.rs`, etc.

`UpgradeSpringBoot_3_0` handles the rename. If you need to apply Jakarta migration in isolation (e.g., before the Boot bump), use:

```bash
./mvnw org.openrewrite.maven:rewrite-maven-plugin:run \
  -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-migrate-java:RELEASE \
  -Drewrite.activeRecipes=org.openrewrite.java.migrate.jakarta.JakartaEE10
```

Manual cleanup spots OpenRewrite often misses:
- Reflection-based `Class.forName("javax.persistence.Entity")` lookups
- String literals used as JNDI lookup keys
- Generated code (Lombok `@SneakyThrows` referencing `javax.*` rarely; MapStruct rarely; Avro/protobuf-generated classes never auto-migrate)
- Third-party libraries you depend on that are still `javax.*` only — check whether a `jakarta`-flavored release exists. If not, add the Apache Tomcat `jakartaee-migration` shim or upgrade the dependency.

---

## 5. Per-minor highlights (3.0 → 3.5)

| Boot | Spring Framework | Java baseline | Notable |
|---|---|---|---|
| 3.0 | 6.0 | 17 | Jakarta migration, Spring Security 6, Micrometer Tracing/Observation, Native AOT (GraalVM 22.3), removed Trailing-Slash matching |
| 3.1 | 6.0 | 17 | Declarative HTTP clients (`@HttpExchange` GA), Testcontainers + Docker Compose dev support, virtual threads experimental |
| 3.2 | 6.1 | 17 (21 recommended) | Virtual threads GA (`spring.threads.virtual.enabled`), `RestClient`, `JdbcClient`, JVM Checkpoint Restore (CRaC), `@Scheduled` observation |
| 3.3 | 6.1 | 17 | Class Data Sharing (CDS) support, structured logging foundations, base image refresh |
| 3.4 | 6.2 | 17 | `RestClient` enhancements, Bean Validation method-level improvements, structured logging maturity, `@MockitoBean` / `@MockitoSpyBean` (replace `@MockBean` / `@SpyBean`) |
| 3.5 | 6.2 | 17 (21 recommended) | Final 3.x line — the launchpad for 4.0. Property migrations consolidated; `MockMvcTester` fluent API; community OpenRewrite recipes available |

After each bump, run `./mvnw verify` (or `./gradlew build`) and address compile errors and deprecation warnings before moving to the next minor.

Per-minor release notes (the authoritative source for breaking changes):
- 3.0: [github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Release-Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Release-Notes)
- 3.1: [github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.1-Release-Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.1-Release-Notes)
- 3.2: [github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.2-Release-Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.2-Release-Notes)
- 3.3: [github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.3-Release-Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.3-Release-Notes)
- 3.4: [github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.4-Release-Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.4-Release-Notes)
- 3.5: [github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.5-Release-Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.5-Release-Notes)

---

## 6. Spring Security 5 → 6

Security 5.7 deprecated `WebSecurityConfigurerAdapter`. Boot 3.0 ships Security 6, where it is **removed**. Replace with a `SecurityFilterChain` `@Bean` and the lambda DSL. Migration guide: [docs.spring.io/spring-security/reference/migration/index.html](https://docs.spring.io/spring-security/reference/migration/index.html).

```java
// Boot 2.7 / Security 5.7 — DEPRECATED
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            .authorizeRequests()
                .antMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
                .and()
            .formLogin();
    }
}

// Boot 3.0+ / Security 6 — REQUIRED
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .formLogin(Customizer.withDefaults())
            .build();
    }
}
```

Other notable Security 5 → 6 changes:
- `antMatchers(...)` / `mvcMatchers(...)` → `requestMatchers(...)` (and `RequestMatchers.antMatcher(...)` for path-only matching)
- `authorizeRequests(...)` → `authorizeHttpRequests(...)` (the new API uses `AuthorizationManager` and applies authorization on every dispatch type, not only `REQUEST`)
- `AuthorizationDecisionVoter` → `AuthorizationManager`
- `AccessDeniedHandler` semantics tightened around CSRF
- OAuth2 client: `authorizationEndpoint().baseUri()` configuration is now on `oauth2Login(o -> o.authorizationEndpoint(a -> a.baseUri(...)))` lambda style only

Bridge if you cannot migrate immediately: stay on Boot 2.7 with Security 5.8 (introduces forward-compat APIs and opt-out flags for 6.0 changes — same patterns documented in `references/gradual-upgrade-strategy.md` for the 3 → 4 leg).

---

## 7. Hibernate 5 → 6

Boot 3.0 ships Hibernate ORM 6.1 (group ID **`org.hibernate.orm`**, not `org.hibernate`). Migration guide: [github.com/hibernate/hibernate-orm/blob/6.0/migration-guide.adoc](https://github.com/hibernate/hibernate-orm/blob/6.0/migration-guide.adoc).

Most-likely-to-bite changes:
- **ID generation**: `GenerationType.AUTO` defaults differ. Hibernate 6 uses `SequenceStyleGenerator` for portable sequence-style generation. If you relied on table-per-class or implicit `IDENTITY` defaults, audit each `@GeneratedValue` and switch to explicit `strategy = SEQUENCE` (preferred — does not block JDBC batching) or explicit `IDENTITY`. The 2.x property `spring.jpa.hibernate.use-new-id-generator-mappings` is **removed** in Boot 3.0.
- **Naming strategy**: `ImplicitNamingStrategyJpaCompliantImpl` is the default, replacing `SpringImplicitNamingStrategy` for some collection table names. Either explicitly configure the old strategy on Boot 3 (`spring.jpa.hibernate.naming.implicit-strategy=org.springframework.boot.orm.jpa.hibernate.SpringImplicitNamingStrategy`) or migrate your schema (Flyway/Liquibase) to match the new defaults.
- **Query handling**: HQL parser was rewritten. Some legacy HQL idioms (positional parameters with mixed casing, certain `IN` subqueries) error where they previously parsed.
- **`@MappedSuperclass`**: stricter rules around abstract entity inheritance. Compile errors on previously-tolerated patterns.
- **Bytecode enhancement**: enhancement gradle/maven plugin moved to `org.hibernate.orm:hibernate-enhance-maven-plugin` / `org.hibernate.orm.tooling.gradle`.

For deep JPA review (N+1 detection, fetch plans, query count assertions, Hibernate 6 features), use the **`hibernate-jpa-validator`** skill — its `references/hibernate-features.md` covers Hibernate 6 specifics in detail and `references/entity-mapping-checklist.md` flags the migration patterns above.

---

## 8. Property migration

The Properties Migrator added in §2 will print warnings at startup for renamed/removed keys. Some you will hit on every project:

| Boot 2.7 | Boot 3.x |
|---|---|
| `spring.redis.*` | `spring.data.redis.*` |
| `spring.data.cassandra.*` | `spring.cassandra.*` |
| `server.max-http-header-size` | `server.max-http-request-header-size` |
| `management.metrics.export.<product>.*` | `management.<product>.metrics.export.*` |
| `spring.mvc.pathmatch.matching-strategy=ant_path_matcher` | removed; default is `path_pattern_parser`. Set `spring.mvc.pathmatch.matching-strategy=ant_path_matcher` only as an explicit opt-in, knowing it is deprecated. |
| `spring.jpa.hibernate.use-new-id-generator-mappings` | removed (always behaves as `true`) |

Also remove the Boot-2-era image banner (`banner.gif`/`.jpg`/`.png`) — Boot 3 dropped image banner support; only `banner.txt` remains.

Run `OpenRewrite SpringBootProperties_3_5` to apply the rename catalog wholesale across `application.yml`, `application.properties`, and profile variants.

---

## 9. Observability migration

Boot 2.7 used Spring Cloud Sleuth (separate dependency) for distributed tracing and Boot-specific filters (`WebMvcMetricsFilter`, `MetricsRestTemplateCustomizer`) for HTTP metrics. Boot 3.0 unified everything onto **Micrometer Observation API** + **Micrometer Tracing**.

| Boot 2.7 | Boot 3.x |
|---|---|
| `spring-cloud-starter-sleuth` | `io.micrometer:micrometer-tracing-bridge-otel` (or `-bridge-brave`) |
| `WebMvcMetricsFilter` (auto-wired) | `ServerHttpObservationFilter` (auto-wired) |
| `MetricsRestTemplateCustomizer` | `ObservationRegistry` injected into `RestTemplateBuilder.observationRegistry(...)` |
| Tag providers (`WebMvcTagsProvider` etc.) | Custom `ObservationConvention` extending `DefaultServerRequestObservationConvention` |
| `management.metrics.export.<product>.*` | `management.<product>.metrics.export.*` (mirrors §8) |

If you are exporting to OpenTelemetry, prefer the OTel bridge (`io.micrometer:micrometer-tracing-bridge-otel` + `io.opentelemetry:opentelemetry-exporter-otlp`) — that aligns the project with Boot 4's consolidated observability story (`spring-boot-starter-opentelemetry`).

---

## 10. Common pitfalls

- **Trailing slash matching** flips to `false` in Spring Framework 6. `GET /users/` no longer matches `@GetMapping("/users")`. Either issue redirects or set `configurePathMatch(c -> c.setUseTrailingSlashMatch(true))` (deprecated; planned for removal in 7).
- **`spring.factories` auto-config registration** is removed. Move entries from `META-INF/spring.factories` to `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`.
- **`@ConstructorBinding` on the type** is unnecessary on Boot 3 — keep it only on individual constructors when there is more than one. The `removeconstructorbindingannotation` recipe handles it.
- **`@EnableBatchProcessing`** is discouraged on Boot 3; Spring Batch auto-configures itself. Multi-job applications need refactoring per the [Boot 3.0 release notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Release-Notes#multiple-jobs).
- **MySQL JDBC driver coordinates** changed from `mysql:mysql-connector-java` to `com.mysql:mysql-connector-j`. Update `pom.xml` / `build.gradle.kts`.
- **Apache HttpClient**: HttpClient 4.x usage relocated to `httpclient5`. `RestTemplate` configurations using `HttpComponentsClientHttpRequestFactory` need the `org.apache.hc.client5.http.impl.classic.HttpClientBuilder` import.
- **Elasticsearch**: the high-level REST client is removed; the new client is auto-configured. Custom `RestHighLevelClient` beans must be replaced with `co.elastic.clients.elasticsearch.ElasticsearchClient`.
- **R2DBC**: the R2DBC BOM is no longer transitively imported. Pin `r2dbc-pool` and `r2dbc-postgresql` (or your driver) explicitly.

---

## 11. Verification before moving to the 3 → 4 leg

You are ready to start the existing 3.5 → 4.0 phases in `SKILL.md` when:

1. Build succeeds on Boot **3.5 latest patch** (`./mvnw verify` or `./gradlew build`).
2. `spring-boot-properties-migrator` prints **zero warnings** at startup. Then **remove the dependency**.
3. All deprecation warnings in the build output are addressed or have an explicit decision logged.
4. Application starts and serves a smoke-test health check: `curl localhost:8080/actuator/health`.
5. Integration tests pass against each active Spring profile.
6. Distributed tracing is producing spans correctly (verify in your tracing backend) — observability migration is the leg most often left half-done.

Now return to `SKILL.md` and follow the **Prerequisites** + **Phases 1–9** for 3.5 → 4.0. The existing content covers Jackson 3, Spring Security 7, Spring Framework 7, JUnit 6, Testcontainers 2, OpenTelemetry consolidation, AOT/native, and API versioning — all of which you skipped on the 2 → 3 leg.

---

## Official sources

- Spring Boot 3.0 Migration Guide: [github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide)
- Spring Boot upgrading docs: [docs.spring.io/spring-boot/upgrading.html](https://docs.spring.io/spring-boot/upgrading.html)
- OpenRewrite Spring 2 → 3 guide: [docs.openrewrite.org/running-recipes/popular-recipe-guides/migrate-to-spring-3](https://docs.openrewrite.org/running-recipes/popular-recipe-guides/migrate-to-spring-3)
- OpenRewrite Boot 3.x recipe catalog: [docs.openrewrite.org/recipes/java/spring/boot3](https://docs.openrewrite.org/recipes/java/spring/boot3)
- Spring Security migration index: [docs.spring.io/spring-security/reference/migration/index.html](https://docs.spring.io/spring-security/reference/migration/index.html)
- Hibernate ORM 6.0 migration guide: [github.com/hibernate/hibernate-orm/blob/6.0/migration-guide.adoc](https://github.com/hibernate/hibernate-orm/blob/6.0/migration-guide.adoc)
- Spring Boot release notes index: [github.com/spring-projects/spring-boot/wiki](https://github.com/spring-projects/spring-boot/wiki)
