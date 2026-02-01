# Property Changes Reference

All property key renames, value changes, and removals from Boot 3.x → 4.0.

## Property Key Renames

### Jackson Properties

| Old Key | New Key |
|---------|---------|
| `spring.jackson.read.*` | `spring.jackson.json.read.*` |
| `spring.jackson.write.*` | `spring.jackson.json.write.*` |

### MongoDB Properties

Many `spring.data.mongodb.*` properties moved to `spring.mongodb.*`:

| Old Key | New Key |
|---------|---------|
| `spring.data.mongodb.uri` | `spring.mongodb.uri` |
| `spring.data.mongodb.host` | `spring.mongodb.host` |
| `spring.data.mongodb.port` | `spring.mongodb.port` |
| `spring.data.mongodb.database` | `spring.mongodb.database` |
| `spring.data.mongodb.username` | `spring.mongodb.username` |
| `spring.data.mongodb.password` | `spring.mongodb.password` |
| `spring.data.mongodb.authentication-database` | `spring.mongodb.authentication-database` |
| `spring.data.mongodb.auto-index-creation` | Remains `spring.data.mongodb.auto-index-creation` (Spring Data specific) |

### MongoDB Management Properties

| Old Key | New Key |
|---------|---------|
| `management.health.mongo.enabled` | `management.health.mongodb.enabled` |
| `management.metrics.mongo.command.enabled` | `management.metrics.mongodb.command.enabled` |
| `management.metrics.mongo.connectionpool.enabled` | `management.metrics.mongodb.connectionpool.enabled` |

### Session Properties

| Old Key | New Key |
|---------|---------|
| `spring.session.redis.*` | `spring.session.data.redis.*` |
| `spring.session.mongodb.*` | `spring.session.data.mongodb.*` |

### Persistence Properties

| Old Key | New Key |
|---------|---------|
| `spring.dao.exceptiontranslation.enabled` | `spring.persistence.exceptiontranslation.enabled` |

### Hibernate Naming Strategy

| Old Value | New Value |
|-----------|-----------|
| `org.springframework.boot.orm.jpa.hibernate.SpringImplicitNamingStrategy` | `org.springframework.boot.hibernate.SpringImplicitNamingStrategy` |

This affects `spring.jpa.hibernate.naming.implicit-strategy`.

### Templating Properties (Deprecated with Comment)

These properties are deprecated and no longer required:
- `spring.freemarker.enabled` — To use FreeMarker without auto-configuration, depend directly on FreeMarker instead of `spring-boot-freemarker`
- `spring.groovy.template.enabled` — Same pattern for Groovy Templates
- `spring.mustache.enabled` — Same pattern for Mustache
- `spring.thymeleaf.enabled` — Same pattern for Thymeleaf

### Kafka Properties

| Old Key | New Key |
|---------|---------|
| `spring.kafka.retry.topic.backoff.random` | `spring.kafka.retry.topic.backoff.jitter` |

### OTLP / Observability Properties

| Old Key | New Key |
|---------|---------|
| `management.otlp.tracing.endpoint` | `management.opentelemetry.tracing.export.endpoint` |
| `management.otlp.tracing.timeout` | `management.opentelemetry.tracing.export.timeout` |
| `management.otlp.tracing.compression` | `management.opentelemetry.tracing.export.compression` |
| `management.otlp.tracing.headers.*` | `management.opentelemetry.tracing.export.headers.*` |
| `management.otlp.metrics.url` | `management.metrics.export.otlp.url` |
| `management.otlp.metrics.headers.*` | `management.metrics.export.otlp.headers.*` |

See `references/observability-migration.md` for the complete OTLP
configuration property tree and environment variable support.

### Testing Properties

| Old Key | New Key |
|---------|---------|
| `spring.test.observability.auto-configure` | Superseded by `spring.test.metrics.export` and `spring.test.tracing.export` |

## Property Value Changes

### Jackson 2 Compatibility Mode

New property for backward compatibility:
```properties
spring.jackson.use-jackson2-defaults=true
```
When set, the auto-configured `JsonMapper` uses defaults aligned with Jackson 2 behavior from Boot 3.x.

### Jackson 2 Fallback Properties

If using `spring-boot-jackson2` module, configure via `spring.jackson2.*` 
(equivalent to old `spring.jackson.*` from Boot 3.x).

### DevTools

```properties
# Live reload now disabled by default. To re-enable:
spring.devtools.livereload.enabled=true
```

### Liveness and Readiness Probes

Now enabled by default. To disable:
```properties
management.endpoint.health.probes.enabled=false
```

## Properties in Annotations

Property keys inside `@SpringBootTest(properties = ...)` annotations also
need updating. Search for `@SpringBootTest` and `@TestPropertySource` and
apply the same renames above.

### MongoDB UUID and BigDecimal Representations

Spring Data MongoDB no longer provides defaults for UUID and
BigInteger/BigDecimal representations. If your application relies on
specific MongoDB codec behavior for these types, configure them
explicitly via properties:

```properties
spring.data.mongodb.uuid-representation=standard
```

## Where to Check

Scan these file locations:
- `src/main/resources/application.properties`
- `src/main/resources/application.yml`
- `src/main/resources/application-*.properties` (profiles)
- `src/main/resources/application-*.yml` (profiles)
- `src/test/resources/application*.properties`
- `src/test/resources/application*.yml`
- `@SpringBootTest(properties = {...})` in test classes
- `@TestPropertySource(properties = {...})` in test classes
- `bootstrap.properties` / `bootstrap.yml` (if using Spring Cloud)
