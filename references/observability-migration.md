# Observability Migration Reference

Spring Boot 4 significantly restructures observability (metrics, tracing,
logging) into modular components and introduces first-class OpenTelemetry
support decoupled from Actuator.

## Key Changes Summary

1. Observability modules renamed and split into dedicated artifacts
2. New `spring-boot-starter-opentelemetry` replaces multiple dependencies
3. OpenTelemetry no longer requires Actuator
4. OTLP configuration properties reorganized under `management.opentelemetry.*`
5. Observation annotations require `spring-boot-starter-aspectj`

## Module Renames

Internal Boot modules have been renamed. This affects you if you depend on
them directly (rare) or reference their packages in configuration.

| Old Module (Boot 3.x) | New Module (Boot 4.x) |
|------------------------|-----------------------|
| `spring-boot-metrics` | `spring-boot-micrometer-metrics` |
| `spring-boot-observation` | `spring-boot-micrometer-observation` |
| `spring-boot-tracing` | `spring-boot-micrometer-tracing` |

Package roots follow the module rename:
- `org.springframework.boot.metrics` → `org.springframework.boot.micrometer.metrics`
- `org.springframework.boot.observation` → `org.springframework.boot.micrometer.observation`
- `org.springframework.boot.tracing` → `org.springframework.boot.micrometer.tracing`

## New Modular Observability Modules

Boot 4 splits observability into fine-grained modules:

| Module | Purpose |
|--------|---------|
| `spring-boot-health` | Health endpoint support (separated from actuator core) |
| `spring-boot-micrometer-metrics` | Metrics collection via Micrometer |
| `spring-boot-micrometer-observation` | Micrometer Observation API integration |
| `spring-boot-micrometer-tracing` | Distributed tracing core |
| `spring-boot-micrometer-tracing-brave` | Brave (Zipkin) tracing instrumentation |
| `spring-boot-micrometer-tracing-opentelemetry` | OpenTelemetry tracing instrumentation |
| `spring-boot-opentelemetry` | OpenTelemetry SDK auto-configuration |
| `spring-boot-zipkin` | Zipkin reporter integration |

## Starters

| Technology | Main Starter | Test Starter |
|-----------|-------------|-------------|
| Actuator | `spring-boot-starter-actuator` | `spring-boot-starter-actuator-test` |
| Micrometer Metrics | `spring-boot-starter-micrometer-metrics` | `spring-boot-starter-micrometer-metrics-test` |
| OpenTelemetry | `spring-boot-starter-opentelemetry` | `spring-boot-starter-opentelemetry-test` |
| Zipkin | `spring-boot-starter-zipkin` | `spring-boot-starter-zipkin-test` |

## Migrating from Boot 3 Observability Setup

### Before (Boot 3.x — typical distributed tracing setup)

```xml
<!-- Boot 3.x: Multiple dependencies needed -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-otel</artifactId>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
</dependency>
<!-- Plus possibly: micrometer-registry-otlp, opentelemetry-sdk, etc. -->
```

### After (Boot 4.x — single starter)

```xml
<!-- Boot 4.x: Single starter covers OTel API + Micrometer bridge + OTLP exporters -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-opentelemetry</artifactId>
</dependency>
```

The `spring-boot-starter-opentelemetry` includes:
- OpenTelemetry API
- Micrometer Tracing bridge for OpenTelemetry
- OTLP exporters for metrics and traces
- Auto-configuration for the OpenTelemetry SDK

### Gradle (Kotlin DSL)

```kotlin
// Boot 3.x
implementation("org.springframework.boot:spring-boot-starter-actuator")
implementation("io.micrometer:micrometer-tracing-bridge-otel")
implementation("io.opentelemetry:opentelemetry-exporter-otlp")

// Boot 4.x — replace all of the above with:
implementation("org.springframework.boot:spring-boot-starter-opentelemetry")
```

## Decoupled from Actuator

In Boot 3.x, distributed tracing and metrics export required
`spring-boot-starter-actuator`. In Boot 4, `spring-boot-starter-opentelemetry`
works independently.

**When to still use Actuator alongside OpenTelemetry:**
- You need `/actuator/health`, `/actuator/info`, or other management endpoints
- You need the `/actuator/prometheus` endpoint for Prometheus scraping
- You need custom actuator endpoints

**When you can drop Actuator:**
- You only need OTLP export of metrics and traces
- Your observability backend (Grafana, Datadog, etc.) receives OTLP directly
- You don't need management HTTP endpoints

```xml
<!-- Observability without Actuator -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-opentelemetry</artifactId>
</dependency>
<!-- No spring-boot-starter-actuator needed! -->

<!-- Observability WITH Actuator (for management endpoints) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-opentelemetry</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

**Note**: In Boot 4.0.0, log export still required Actuator. This was fixed
in 4.0.1 — update to at least 4.0.1 if using OTel log export without Actuator.

## OTLP Configuration Properties

### New Property Tree (Boot 4.x)

```yaml
management:
  opentelemetry:
    resource-attributes:
      environment: production
      service.version: "1.0.0"
    tracing:
      export:
        endpoint: http://localhost:4318/v1/traces
        timeout: 10s
        compression: gzip
    logging:
      export:
        otlp:
          endpoint: http://localhost:4318/v1/logs
          transport: http

  metrics:
    export:
      otlp:
        url: http://localhost:4318/v1/metrics
        step: 1m
```

### Property Migrations

| Old (Boot 3.x) | New (Boot 4.x) |
|-----------------|-----------------|
| `management.otlp.tracing.endpoint` | `management.opentelemetry.tracing.export.endpoint` |
| `management.otlp.tracing.timeout` | `management.opentelemetry.tracing.export.timeout` |
| `management.otlp.tracing.compression` | `management.opentelemetry.tracing.export.compression` |
| `management.otlp.tracing.headers.*` | `management.opentelemetry.tracing.export.headers.*` |
| `management.otlp.metrics.url` | `management.metrics.export.otlp.url` |
| `management.otlp.metrics.headers.*` | `management.metrics.export.otlp.headers.*` |
| `spring.test.observability.auto-configure` | Superseded by `spring.test.metrics.export` and `spring.test.tracing.export` |

### OpenTelemetry Environment Variables

Boot 4 supports standard OTel environment variables:

| Variable | Purpose |
|----------|---------|
| `OTEL_SERVICE_NAME` | Service name for traces/metrics |
| `OTEL_RESOURCE_ATTRIBUTES` | Key-value pairs (e.g., `key1=value1,key2=value2`) |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP collector endpoint |
| `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT` | Metrics-specific endpoint override |
| `OTEL_EXPORTER_OTLP_HEADERS` | Auth headers for OTLP |
| `OTEL_EXPORTER_OTLP_METRICS_HEADERS` | Metrics-specific header override |

**Precedence**: Spring Boot configuration properties take priority over
environment variables.

## Observation Annotations

Boot 4 supports Micrometer observation annotations. To use them, you need
`spring-boot-starter-aspectj` (which provides `org.aspectj:aspectjweaver`):

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aspectj</artifactId>
</dependency>
```

Enable annotation support:
```yaml
management:
  observations:
    annotations:
      enabled: true
```

Supported annotations:
- `@Observed` — creates an observation around the method
- `@Timed` — records execution time as a timer metric
- `@Counted` — increments a counter metric
- `@MeterTag` — adds tags to metrics from method parameters
- `@NewSpan` — creates a new trace span

## Observation Configuration

### Common Tags (Applied to All Observations)

```yaml
management:
  observations:
    key-values:
      region: us-east-1
      stack: prod
```

### Disabling Specific Observations

```yaml
management:
  observations:
    enable:
      spring.security: false
      http.server.requests: false
```

## Auto-Instrumentation

With `spring-boot-starter-opentelemetry`, Boot 4 automatically instruments:
- **HTTP server requests** — all controller endpoints
- **HTTP client requests** — RestClient, WebClient, RestTemplate (deprecated)
- **JDBC** — when using Datasource Micrometer (`datasource-micrometer-spring-boot`)
- **R2DBC** — when `io.r2dbc:r2dbc-proxy` is on the classpath

## Three Integration Approaches

### 1. Spring Boot Starter (Recommended)

Use `spring-boot-starter-opentelemetry` for Spring-native observability.
Micrometer Observation API is the primary API. Best for new projects and
Boot 4 migrations.

### 2. OpenTelemetry Java Agent

Attach `-javaagent:opentelemetry-javaagent.jar` at startup for zero-code
bytecode instrumentation. Covers more libraries automatically but is
independent of Spring's Observation API.

### 3. Hybrid

Use the Boot starter for Spring-native observations AND the OTel agent
for additional library instrumentation. Requires careful configuration
to avoid double-instrumentation.

**Recommendation**: For most Boot 4 migrations, approach 1 (starter only)
is sufficient. Add the Java agent only if you need instrumentation for
libraries not covered by Spring's auto-instrumentation.

## Brave (Zipkin) to OpenTelemetry Migration

If your Boot 3.x project uses Brave (Zipkin) for tracing:

### Before (Boot 3.x with Brave)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-brave</artifactId>
</dependency>
<dependency>
    <groupId>io.zipkin.reporter2</groupId>
    <artifactId>zipkin-reporter-brave</artifactId>
</dependency>
```

### After — Option A: Switch to OpenTelemetry

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-opentelemetry</artifactId>
</dependency>
```

### After — Option B: Keep Brave/Zipkin

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-zipkin</artifactId>
</dependency>
```

Both approaches work. OpenTelemetry is the recommended path forward as it's
vendor-neutral and has the broadest ecosystem support.

## Context Propagation

### Reactive Applications (WebFlux)

```yaml
spring:
  reactor:
    context-propagation: auto
```

### Async Methods (@Async)

Register the context-propagating task decorator:

```java
@Configuration(proxyBeanMethods = false)
class ContextPropagationConfiguration {
    @Bean
    ContextPropagatingTaskDecorator contextPropagatingTaskDecorator() {
        return new ContextPropagatingTaskDecorator();
    }
}
```

## Migration Checklist

- [ ] Replace individual Micrometer/OTel dependencies with `spring-boot-starter-opentelemetry`
- [ ] Or replace Brave/Zipkin dependencies with `spring-boot-starter-zipkin`
- [ ] Update OTLP properties from `management.otlp.*` to `management.opentelemetry.*`
- [ ] Update `spring.test.observability.auto-configure` to new properties
- [ ] Evaluate whether Actuator is still needed (may not be if only using OTLP export)
- [ ] If using observation annotations, add `spring-boot-starter-aspectj` and enable in config
- [ ] Update any direct references to renamed module packages
- [ ] Verify traces and metrics export to your backend after migration
- [ ] Check auto-instrumentation covers your HTTP clients (RestClient/WebClient)
