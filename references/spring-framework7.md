# Spring Framework 7 Changes Reference

Spring Boot 4.0 uses Spring Framework 7.x.

## Contents

- [Module Removal](#module-removal)
- [Annotation Changes](#annotation-changes)
- [Web Changes](#web-changes)
- [Spring Retry → Core Resilience](#spring-retry--core-resilience)
- [Testing Changes](#testing-changes)
- [Jackson](#jackson)
- [Hibernate ORM 7.1](#hibernate-orm-71)
- [HTTP Interfaces](#http-interfaces)
- [Programmatic Bean Registration](#programmatic-bean-registration)
- [JMS Client API (New)](#jms-client-api-new)
- [SpEL Improvements](#spel-improvements)
- [API Versioning (New Feature)](#api-versioning-new-feature)

## Module Removal

### spring-jcl

The `spring-jcl` module is removed. Apache Commons Logging 1.3.0 is used
directly. Transparent for most applications — logging API calls unchanged.

## Annotation Changes

### javax.* No Longer Supported

Fully removed (should already be gone from Boot 3.x migration):

| Old | New |
|-----|-----|
| `@javax.annotation.Resource` | `@jakarta.annotation.Resource` |
| `@javax.annotation.PostConstruct` | `@jakarta.annotation.PostConstruct` |
| `@javax.annotation.PreDestroy` | `@jakarta.annotation.PreDestroy` |
| `@javax.inject.Inject` | `@jakarta.inject.Inject` |
| `@javax.inject.Named` | `@jakarta.inject.Named` |

### JSpecify Null Safety

Spring Framework 7 migrates from `org.springframework.lang` annotations
to JSpecify 1.0. See also `references/api-changes.md` for the
annotation mapping.

| Deprecated Spring Annotation | JSpecify Replacement | Scope |
|------------------------------|---------------------|-------|
| `@org.springframework.lang.Nullable` | `@org.jspecify.annotations.Nullable` | Type usage |
| `@org.springframework.lang.NonNull` | Not needed — non-null is the default in `@NullMarked` scope |
| `@org.springframework.lang.NonNullApi` | `@org.jspecify.annotations.NullMarked` (on package/class) |
| `@org.springframework.lang.NonNullFields` | `@org.jspecify.annotations.NullMarked` (on package/class) |

JSpecify dependency (managed by Boot BOM):
```xml
<dependency>
    <groupId>org.jspecify</groupId>
    <artifactId>jspecify</artifactId>
</dependency>
```

**Critical difference**: JSpecify `@Nullable` is a TYPE_USE annotation,
so it goes on the type rather than the declaration:

```java
// Old (Spring)
@Nullable
public String getName() { ... }

// New (JSpecify) — annotation on the type
public @Nullable String getName() { ... }
```

#### Package-Level @NullMarked

Add `package-info.java` to each package to set non-null defaults:

```java
@NullMarked
package com.example.myapp.service;

import org.jspecify.annotations.NullMarked;
```

`@NullMarked` does NOT cascade to sub-packages — each package needs its
own `package-info.java`. Within a `@NullMarked` scope, all types are
non-null by default; use `@Nullable` only where null is expected.

#### @NullUnmarked for Incremental Migration

Opt out specific classes/methods during migration:

```java
@NullMarked
package com.example.service;

@NullUnmarked  // Temporarily excluded from null checks
public class LegacyDatabaseService { ... }
```

#### Impact on Kotlin (Kotlin 2.2+)

Platform types become explicit nullable/non-null types:

```kotlin
// Boot 3 — platform type (unsafe)
val user = userService.findById(id)  // Type: User!
println(user.name)  // Could NPE at runtime

// Boot 4 — explicit nullable (compiler enforced)
val user = userService.findById(id)  // Type: User?
user?.let { println(it.name) }  // Safe call required
```

Kotlin code that compiled on Boot 3 may fail on Boot 4 where methods
now return `@Nullable` types. Fix by adding null checks or safe calls.

#### Impact on Null Checkers

If using NullAway or SpotBugs, JSpecify provides more precise contracts:
- Array/vararg element nullness: `@Nullable String[]` vs `String @Nullable []`
- Generic type parameters: `List<@Nullable String>` vs `@Nullable List<String>`

#### NullAway Configuration

Gradle:
```gradle
plugins {
    id 'net.ltgt.errorprone' version '4.1.0'
}
dependencies {
    errorprone 'com.google.errorprone:error_prone_core:2.37.0'
    errorprone 'com.uber.nullaway:nullaway:0.12.6'
}
tasks.withType(JavaCompile).configureEach {
    options.errorprone {
        disableAllChecks = true
        option("NullAway:OnlyNullMarked", "true")
        error("NullAway")
    }
}
```

#### Annotations NOT Inherited on Override

When overriding Spring interfaces, re-annotate nullability:

```java
@Override
public @Nullable User findByEmail(String email) {  // Must repeat @Nullable
    return entityManager.find(User.class, email);
}
```

#### Lombok Configuration

```properties
# lombok.config
lombok.addNullAnnotations = jspecify
```

#### Common Issues

| Issue | Fix |
|-------|-----|
| Kotlin compile error: `Type mismatch: User? vs User` | Add null check or safe call `?.` |
| NullAway warning in lambda with Reactor | `@SuppressWarnings("NullAway")` on method |
| Actuator endpoint `@Nullable` parameter | Use `@OptionalParameter` from actuator |
| Missing `@Nullable` on override | Re-add annotation to overriding method |

## Web Changes

### MVC XML Config Deprecated

```xml
<!-- Deprecated — still works but won't receive updates -->
<mvc:annotation-driven />
<mvc:resources mapping="/resources/**" location="/public/" />
<mvc:view-controller path="/home" view-name="home" />
```

Migrate to Java config:
```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/home").setViewName("home");
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/resources/**")
                .addResourceLocations("/public/");
    }
}
```

### Path Matching — Fully Removed

Removed since deprecated in 6.0:
- `suffixPatternMatch` / `registeredSuffixPatternMatch`
- `trailingSlashMatch` on `AbstractHandlerMapping`
- `favorPathExtension` in content negotiation

Use explicit media types and URI templates.

### AntPathMatcher Deprecated for HTTP

`AntPathMatcher` for HTTP request mapping deprecated. `PathPatternParser`
(default since Boot 2.6) should be used. If `spring.mvc.pathmatch.matching-strategy=ant-path-matcher` is set, remove it.

### HttpHeaders API

Several map-like methods removed from `HttpHeaders`. Headers are
case-insensitive collections of pairs:
- `HttpHeaders#asMultiValueMap` introduced as deprecated fallback
- Prefer other access methods

### Message Converters Centralized

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void configureMessageConverters(
            HttpMessageConverters.ServerBuilder builder) {
        builder.jsonMessageConverter(
            new JacksonJsonHttpMessageConverter(
                JsonMapper.builder().build()
            )
        );
    }
}
```

### RestTestClient (New)

```java
// Bind to live server
RestTestClient client = RestTestClient.bindTo(URI.create("http://localhost:8080")).build();

// Bind to MockMvc
RestTestClient client = RestTestClient.bindTo(mockMvc).build();

// Bind to application context
RestTestClient client = RestTestClient.bindTo(applicationContext).build();
```

## Spring Retry → Core Resilience

See `references/resilience-migration.md` for the complete migration
guide including Spring Retry → Framework 7 attribute mapping, behavioral
differences, and Resilience4j guidance.

Spring Framework 7 includes core retry/resilience:

```java
import org.springframework.resilience.annotation.Retryable;
import org.springframework.resilience.annotation.ConcurrencyLimit;
import org.springframework.resilience.annotation.EnableResilientMethods;

@Configuration
@EnableResilientMethods
public class AppConfig { }

@Retryable(maxRetries = 3, delay = 1000, multiplier = 2)
public String callExternalService() { ... }

@ConcurrencyLimit(10)
public String limitedEndpoint() { ... }
```

Programmatic retry:
```java
import org.springframework.core.retry.RetryTemplate;
import org.springframework.core.retry.RetryPolicy;

var policy = RetryPolicy.builder()
    .includes(ServiceException.class)
    .maxAttempts(3)
    .delay(Duration.ofSeconds(1))
    .build();
new RetryTemplate(policy).execute(() -> externalService.call());
```

**Critical**: `maxRetries` in Framework 7 counts only retries (not the
initial call), unlike Spring Retry's `maxAttempts` which includes it.
`maxRetries=2` in Framework 7 = `maxAttempts=3` in Spring Retry.

## Testing Changes

### SpringExtension Scope Change

`SpringExtension` now uses test-method scoped `ExtensionContext` instead
of test-class scoped. This enables consistent dependency injection in
`@Nested` hierarchies but may break custom `TestExecutionListener` impls.

Fix for broken `@Nested` tests:
```java
@SpringExtensionConfig(useTestClassScope = true)
@SpringBootTest
class TopLevelTest {
    @Nested
    class InnerTest { ... }
}
```

### Context Pausing

Cached application contexts are automatically paused when not in use.
Scheduled jobs, message listeners, and background threads in cached
contexts no longer interfere with active test contexts.

### JUnit 4 Deprecated

`SpringRunner`, `SpringClassRule`, `SpringMethodRule` all deprecated.
Use `@ExtendWith(SpringExtension.class)` or `@SpringBootTest`.

## Jackson

Jackson 2.x support deprecated in Framework 7. Jackson 3.x is the
primary supported version. Jackson 2 auto-config will be removed in
Framework 7.1.

## Hibernate ORM 7.1

Boot 4 ships with Hibernate ORM 7.1. Key changes:

- **ID Generation**: Review `@GeneratedValue` strategies. Hibernate 7
  may change default ID generation behavior.
- **Schema Validation**: Stricter validation of entity mappings
- **Query Changes**: Some HQL/JPQL behavioral changes
- **Jakarta Persistence 3.2**: Minor JPA specification bump
- **Annotation Processor Rename**: `hibernate-jpamodelgen` is now
  `hibernate-processor`. Update your build configuration:

```xml
<!-- Old (remove) -->
<dependency>
    <groupId>org.hibernate.orm</groupId>
    <artifactId>hibernate-jpamodelgen</artifactId>
</dependency>

<!-- New -->
<dependency>
    <groupId>org.hibernate.orm</groupId>
    <artifactId>hibernate-processor</artifactId>
</dependency>
```

- **Removed Connection Pools**: `hibernate-proxool` and `hibernate-vibur`
  are no longer published. Use HikariCP (Boot's default) or another
  supported connection pool.

## HTTP Interfaces

See `references/http-clients.md` for complete HTTP interface and client
migration details.

### Declarative HTTP Interfaces with @ImportHttpServices (New)

```java
@HttpExchange(url = "https://api.example.com")
public interface UserClient {
    @GetExchange("/users/{id}")
    User getUser(@PathVariable long id);

    @PostExchange("/users")
    User createUser(@RequestBody User user);
}

@Configuration
@ImportHttpServices(group = "users", types = UserClient.class)
public class ClientConfig { }
```

**Note**: `@HttpServiceClient` was present in early milestones but
**removed before the final release**. Use `@ImportHttpServices` on
a configuration class instead.

## Programmatic Bean Registration

New `BeanRegistrar` interface for programmatic bean registration:
```java
public class MyBeanRegistrar implements BeanRegistrar {
    @Override
    public void register(BeanRegistry registry, Environment environment) {
        registry.registerBean("myBean", MyBean.class);
    }
}
```

## JMS Client API (New)

Framework 7 introduces a new fluent `JmsClient` API as a modern
alternative to `JmsTemplate`, supporting request-reply patterns and
quality-of-service settings:

```java
@Autowired
private JmsClient jmsClient;

// Simple send
jmsClient.destination("orders").send(order);

// With QoS
jmsClient.destination("priority-orders")
    .withPriority(9)
    .withTimeToLive(Duration.ofMinutes(5))
    .send(order);

// Request-reply
OrderConfirmation reply = jmsClient.destination("orders")
    .sendAndReceive(order, OrderConfirmation.class);
```

## SpEL Improvements

- Optional chaining: `user?.address?.city`
- Null-safe navigation improvements
- Elvis operator enhancements

## API Versioning (New Feature)

See `references/api-versioning.md` for the complete guide including
all four versioning strategies, semantic version ranges, client-side
versioning, deprecation handling, and testing.

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping(value = "/{id}", version = "1.0")
    public UserV1 getUserV1(@PathVariable long id) { ... }

    @GetMapping(value = "/{id}", version = "2.0")
    public UserV2 getUserV2(@PathVariable long id) { ... }
}
```

Configuration:
```yaml
spring:
  mvc:
    apiversion:
      default: v1.0
      use:
        header: API-Version       # or path-segment, query-param
```

Supports semantic version ranges: `"1.1+"`, `"[1.0,2.0)"`.
