# API Changes Reference

Package relocations, removed APIs, and renamed classes in Boot 4 / Framework 7.

## Package Relocations

### Spring Boot

| Old Location | New Location |
|-------------|-------------|
| `org.springframework.boot.autoconfigure.domain.EntityScan` | `org.springframework.boot.persistence.autoconfigure.EntityScan` |
| `org.springframework.boot.BootstrapRegistry` | `org.springframework.boot.bootstrap.BootstrapRegistry` |
| `org.springframework.boot.BootstrapRegistryInitializer` | `org.springframework.boot.bootstrap.BootstrapRegistryInitializer` |
| `org.springframework.boot.BootstrapContext` | `org.springframework.boot.bootstrap.BootstrapContext` |
| `org.springframework.boot.ConfigurableBootstrapContext` | `org.springframework.boot.bootstrap.ConfigurableBootstrapContext` |
| `org.springframework.boot.env.EnvironmentPostProcessor` | `org.springframework.boot.EnvironmentPostProcessor` (deprecated form still at old location) |

Update `META-INF/spring.factories` if declaring `BootstrapRegistryInitializer`
or `EnvironmentPostProcessor` implementations.

### Spring Framework

| Old Location | New Location / Status |
|-------------|----------------------|
| `org.springframework.lang.Nullable` | Deprecated → use `org.jspecify.annotations.Nullable` |
| `org.springframework.lang.NonNull` | Deprecated → use JSpecify default non-null |

### Jakarta

| Old (javax) | New (jakarta) — should already be done from Boot 3 |
|-------------|---------------------------------------------------|
| `javax.annotation.*` | `jakarta.annotation.*` |
| `javax.inject.*` | `jakarta.inject.*` |

Boot 4 fully removes support for `javax.annotation` and `javax.inject`.
If any lingered from the 2.x→3.x migration, fix them now.

## Removed APIs

### PropertyMapper

```java
// REMOVED — this no longer exists:
PropertyMapper.alwaysApplyingNotNull()

// Boot 4 behavior: map.from(source).to(dest) does NOT call dest if source is null
// To map null values, use always():
map.from(source::method).always().to(destination::method);
```

Reference commit for how Spring Boot adapted: `239f384ac0`.

### HttpMessageConverters

`org.springframework.boot.http.converter.autoconfigure.HttpMessageConverters` is deprecated.

Replace with:
```java
@Bean
public ClientHttpMessageConvertersCustomizer clientCustomizer() {
    return converters -> { /* customize client converters */ };
}

@Bean
public ServerHttpMessageConvertersCustomizer serverCustomizer() {
    return converters -> { /* customize server converters */ };
}
```

### Path Matching (Fully Removed)

These options were deprecated in 6.0, now removed completely:
- `suffixPatternMatch` / `registeredSuffixPatternMatch`
- `trailingSlashMatch` on `AbstractHandlerMapping`
- `favorPathExtension` in content negotiation

Replace with explicit media types and URI templates:
```java
// REMOVED — don't do this
@RequestMapping(value = "/users.json", produces = "application/json")

// Correct
@GetMapping(value = "/users", produces = MediaType.APPLICATION_JSON_VALUE)
```

### AntPathMatcher for HTTP Requests

`AntPathMatcher` for HTTP request mapping is deprecated.
Use `PathPatternParser` (default since Boot 2.6+).

### Elasticsearch

```java
// REMOVED
RestClient restClient = ...;
RestClientBuilderCustomizer customizer = ...;

// Boot 4
Rest5Client restClient = ...;
Rest5ClientBuilderCustomizer customizer = ...;
```

Module changes:
- Remove: `org.elasticsearch.client:elasticsearch-rest-client`
- Remove: `org.elasticsearch.client:elasticsearch-rest-client-sniffer`
- Use: `co.elastic.clients:elasticsearch-java` (includes sniffer)

### Spring Retry → Spring Framework Resilience

```java
// Old (Spring Retry)
import org.springframework.retry.annotation.Retryable;
import org.springframework.retry.annotation.Recover;
import org.springframework.retry.support.RetryTemplate;

// New (Spring Framework 7 core)
import org.springframework.core.retry.RetryTemplate;
// Or use the new annotations:
import org.springframework.retry.annotation.Retryable;  // Now in Framework
```

Spring Retry dependency management removed from Boot. If still using it,
declare explicit version. Prefer migrating to Framework 7 core retry API.

### Actuator

- `javax.annotations.NonNull` no longer supported for endpoint parameters — use `org.jspecify.annotations.Nullable` for optional params
- `org.springframework.lang.Nullable` no longer works for endpoint parameters

### Static Resources

`PathRequest.toStaticResources()` now includes `/fonts/**`.
To exclude:
```java
pathRequest.toStaticResources()
    .atCommonLocations()
    .excluding(StaticResourceLocation.FONTS);
```

### Logback

Default charset harmonized with Log4j2:
- File logging: UTF-8
- Console: `Console#charset()` if available, else UTF-8

### DevTools

Live Reload disabled by default. Enable with:
```properties
spring.devtools.livereload.enabled=true
```

### Liveness / Readiness Probes

Now enabled by default — health endpoint exposes `liveness` and `readiness`
groups. Disable with:
```properties
management.endpoint.health.probes.enabled=false
```

### Maven Optional Dependencies

Optional dependencies are no longer included in uber jars by default.
To include: `<includeOptional>true</includeOptional>` in plugin config.

## spring-jcl Removal

The `spring-jcl` module is removed. Apache Commons Logging 1.3.0 is used
directly. This should be transparent for most applications.

## Auto-Configuration Public Members Removed

Auto-configuration classes no longer expose public members (except
constants). This enforces that auto-configurations are not public API.
If your code directly references auto-configuration class methods or
fields, refactor to use the public API (starters, properties,
`@Bean` methods) instead.

## SSL Health Changes

The `WILL_EXPIRE_SOON` health status has been removed. Expiring SSL
certificates now report as `VALID` within configured thresholds and are
listed separately in the `expiringChains` section of the health response.

## @PropertyMapping Relocation

```java
// Old
import org.springframework.boot.test.autoconfigure.properties.PropertyMapping;

// New
import org.springframework.boot.test.context.PropertyMapping;
```

## Module Package Organization

Each Boot 4 module now uses dedicated package: `org.springframework.boot.<module>`
containing APIs, auto-configurations, and actuator support for that module.

If you import auto-configuration classes directly (not recommended), the
package structure has changed.
