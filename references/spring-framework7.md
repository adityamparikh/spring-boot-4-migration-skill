# Spring Framework 7 Changes Reference

Spring Boot 4.0 uses Spring Framework 7.x.

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
to JSpecify:

| Old | New |
|-----|-----|
| `@org.springframework.lang.Nullable` | `@org.jspecify.annotations.Nullable` |
| `@org.springframework.lang.NonNull` | Not needed — non-null is the default in JSpecify |
| `@org.springframework.lang.NonNullApi` | `@org.jspecify.annotations.NullMarked` (on package) |

**Impact on Kotlin**: Framework APIs now correctly declare nullability.
This means some Kotlin code that previously compiled may now fail because
parameters/returns that were incorrectly treated as platform types now
have explicit null/non-null contracts.

**Impact on null checkers**: If using NullAway, SpotBugs, or similar,
the new annotations provide more precise contracts — array/vararg elements
and generic types now specify nullness.

JSpecify dependency:
```xml
<dependency>
    <groupId>org.jspecify</groupId>
    <artifactId>jspecify</artifactId>
</dependency>
```
(Managed by Boot BOM)

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

Spring Framework 7 includes core retry/resilience in `org.springframework.core.retry`:

```java
// New annotations in Framework 7
@Retryable(maxAttempts = 3)
public String callExternalService() { ... }

@ConcurrencyLimit(permits = 10)
public String limitedEndpoint() { ... }

// RetryTemplate is now in core
import org.springframework.core.retry.RetryTemplate;

RetryTemplate template = RetryTemplate.builder()
    .maxAttempts(3)
    .fixedBackoff(Duration.ofSeconds(1))
    .build();
```

If using `spring-retry` library, you need to add explicit version since
Boot no longer manages it. Consider migrating to the core retry API.

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

## HTTP Service Client

### @HttpServiceClient Annotation (New)

```java
@HttpServiceClient
public interface UserClient {
    @GetExchange("/users/{id}")
    User getUser(@PathVariable long id);

    @PostExchange("/users")
    User createUser(@RequestBody User user);
}
```

Annotated interfaces excluded from `@ImportHttpServices` scans.

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

## SpEL Improvements

- Optional chaining: `user?.address?.city`
- Null-safe navigation improvements
- Elvis operator enhancements

## API Versioning (New Feature)

```java
@RestController
@RequestMapping("/api")
public class UserController {

    @GetMapping(value = "/users/{id}", version = "1")
    public UserV1 getUserV1(@PathVariable long id) { ... }

    @GetMapping(value = "/users/{id}", version = "2")
    public UserV2 getUserV2(@PathVariable long id) { ... }
}
```

Configure versioning strategy in Boot properties.
