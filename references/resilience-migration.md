# Resilience Migration Reference

Spring Framework 7 introduces native retry and concurrency limiting
in spring-core, replacing the need for Spring Retry in most cases.

## Contents

- [Key Changes Summary](#key-changes-summary)
- [Native Retry (Spring Framework 7)](#native-retry-spring-framework-7)
- [Concurrency Limiting (Bulkhead)](#concurrency-limiting-bulkhead)
- [Migration from Spring Retry](#migration-from-spring-retry)
- [When to Keep Resilience4j](#when-to-keep-resilience4j)
- [Testing Resilience](#testing-resilience)
- [Migration Checklist](#migration-checklist)

## Key Changes Summary

1. `@Retryable` and `@ConcurrencyLimit` now in `org.springframework.resilience.annotation`
2. `RetryTemplate` now in `org.springframework.core.retry`
3. `@EnableRetry` replaced by `@EnableResilientMethods`
4. Spring Retry project is in **maintenance mode**
5. Circuit breakers, rate limiting still require Resilience4j

## Native Retry (Spring Framework 7)

### Enable Resilience Annotations

```java
@Configuration
@EnableResilientMethods  // Activates @Retryable and @ConcurrencyLimit
public class AppConfig { }
```

### Declarative Retry

```java
import org.springframework.resilience.annotation.Retryable;

@Retryable(
    includes = {MessageDeliveryException.class, TimeoutException.class},
    maxRetries = 3,
    delay = 1000,
    multiplier = 2.0,
    maxDelay = 10000,
    jitter = 100
)
public void sendNotification() {
    jmsClient.destination("notifications").send(...);
}
```

### Programmatic Retry

```java
import org.springframework.core.retry.RetryTemplate;
import org.springframework.core.retry.RetryPolicy;

// Simple
var retryTemplate = new RetryTemplate();
retryTemplate.execute(() -> externalService.call());

// Custom policy
var policy = RetryPolicy.builder()
    .includes(MessageDeliveryException.class)
    .maxAttempts(5)
    .delay(Duration.ofMillis(100))
    .multiplier(2)
    .maxDelay(Duration.ofSeconds(1))
    .jitter(Duration.ofMillis(10))
    .build();
var retryTemplate = new RetryTemplate(policy);
retryTemplate.execute(() -> externalService.call());
```

### Reactive Support

`@Retryable` works natively with `Mono`/`Flux`:

```java
@Retryable(maxRetries = 5, delay = 100)
public Mono<Void> sendNotification() {
    return Mono.from(...);
}
```

### Recovery Methods

```java
@Retryable(includes = SQLException.class, maxRetries = 3)
public PaymentResponse processPayment(Payment payment) {
    return externalGateway.process(payment);
}

@Recover
public PaymentResponse recoverPayment(SQLException ex, Payment payment) {
    return backupGateway.process(payment);
}
```

## Concurrency Limiting (Bulkhead)

`@ConcurrencyLimit` prevents resource exhaustion, especially useful
with Virtual Threads:

```java
@ConcurrencyLimit(10)  // Max 10 concurrent executions
public void processOrder(Order order) { ... }
```

Class-level with method override:

```java
@Service
@ConcurrencyLimit(5)
public class NotificationService {
    public void sendEmail() { }           // limit 5
    public void sendSms() { }             // limit 5

    @ConcurrencyLimit(20)
    public void sendPushNotification() { } // limit 20
}
```

### AMQP and Kafka Retry

AMQP and Kafka retry infrastructure has moved from Spring Retry to
Spring Framework. If using retry customizers, update:

```java
// Old (Spring Retry-based)
RetryOperationsInterceptor interceptor = ...;

// Boot 4 (Spring Framework-based)
RabbitTemplateRetrySettingsCustomizer templateCustomizer = ...;
RabbitListenerRetrySettingsCustomizer listenerCustomizer = ...;
```

## Migration from Spring Retry

### OpenRewrite Automation

```xml
<plugin>
    <groupId>org.openrewrite.maven</groupId>
    <artifactId>rewrite-maven-plugin</artifactId>
    <configuration>
        <activeRecipes>
            <recipe>org.openrewrite.java.spring.boot4.MigrateSpringRetryToSpringFramework7</recipe>
        </activeRecipes>
    </configuration>
</plugin>
```

### Manual Migration

#### Step 1: Remove Spring Retry Dependency

```xml
<!-- REMOVE -->
<dependency>
    <groupId>org.springframework.retry</groupId>
    <artifactId>spring-retry</artifactId>
</dependency>
```

#### Step 2: Update Imports

| Old Import | New Import |
|-----------|-----------|
| `org.springframework.retry.annotation.Retryable` | `org.springframework.resilience.annotation.Retryable` |
| `org.springframework.retry.annotation.EnableRetry` | `org.springframework.resilience.annotation.EnableResilientMethods` |
| `org.springframework.retry.support.RetryTemplate` | `org.springframework.core.retry.RetryTemplate` |

#### Step 3: Update Annotation Attributes

| Spring Retry Attribute | Framework 7 Attribute |
|-----------------------|----------------------|
| `value` or `retryFor` | `includes` |
| `maxAttempts` | `maxRetries` |
| `backoff = @Backoff(delay = 1000)` | `delay = 1000` |
| `backoff = @Backoff(multiplier = 2)` | `multiplier = 2` |
| `backoff = @Backoff(maxDelay = 5000)` | `maxDelay = 5000` |
| `exclude` | `excludes` |

#### Step 4: Adjust maxRetries Value

**Critical behavioral difference:**

- **Spring Retry**: `maxAttempts = 3` means 1 initial call + 2 retries = **3 total calls**
- **Framework 7**: `maxRetries = 3` means 1 initial call + 3 retries = **4 total calls**

To preserve the same behavior:

```java
// Spring Retry: maxAttempts=3 → 3 total calls
@Retryable(maxAttempts = 3)

// Framework 7 equivalent: maxRetries=2 → 3 total calls
@Retryable(maxRetries = 2)
```

### Before/After Example

**Before (Spring Retry):**
```java
import org.springframework.retry.annotation.Retryable;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Recover;
import org.springframework.retry.annotation.EnableRetry;

@Configuration
@EnableRetry
public class AppConfig { }

@Service
public class DataService {
    @Retryable(
        value = {SQLException.class},
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2.0, maxDelay = 5000)
    )
    public void processData() { ... }

    @Recover
    public void recover(SQLException ex) { ... }
}
```

**After (Framework 7):**
```java
import org.springframework.resilience.annotation.Retryable;
import org.springframework.resilience.annotation.EnableResilientMethods;

@Configuration
@EnableResilientMethods
public class AppConfig { }

@Service
public class DataService {
    @Retryable(
        includes = {SQLException.class},
        maxRetries = 2,  // Was maxAttempts=3, subtract 1
        delay = 1000,
        multiplier = 2.0,
        maxDelay = 5000
    )
    public void processData() { ... }

    @Recover
    public void recover(SQLException ex) { ... }
}
```

## When to Keep Resilience4j

Spring Framework 7 covers retry and concurrency limiting. For these
patterns, Resilience4j is still needed:

| Pattern | Framework 7 | Resilience4j |
|---------|------------|-------------|
| Retry | `@Retryable` | `@Retry` |
| Concurrency Limit / Bulkhead | `@ConcurrencyLimit` (semaphore) | `@Bulkhead` (semaphore + thread pool) |
| Circuit Breaker | Not available | `@CircuitBreaker` |
| Rate Limiter | Not available | `@RateLimiter` |
| Time Limiter | Not available | `@TimeLimiter` |

### Decision Guide

```
Do you use Circuit Breaker?
  YES → Keep Resilience4j
  NO  → Do you use Rate Limiting?
          YES → Keep Resilience4j
          NO  → Migrate to Framework 7 @Retryable
```

### Hybrid Approach

Use Framework 7 for basic patterns, Resilience4j for advanced:

```java
@Service
public class HybridService {
    @Retryable(maxRetries = 3, delay = 1000)       // Framework 7
    public void simpleRetry() { }

    @CircuitBreaker(name = "backend", fallbackMethod = "fallback")  // Resilience4j
    public String advancedResilience() { }

    @ConcurrencyLimit(10)                            // Framework 7
    public void limitConcurrency() { }
}
```

### Resilience4j Boot 4 Compatibility

Resilience4j support for Spring Boot 4 is actively being developed.
Check [Resilience4j GitHub](https://github.com/resilience4j/resilience4j)
for the latest Boot 4-compatible releases.

## Testing Resilience

```java
@SpringBootTest
class RetryServiceTest {

    @Autowired
    private RetryService retryService;

    @MockBean
    private ExternalService externalService;

    @Test
    void testRetryBehavior() {
        when(externalService.call())
            .thenThrow(new ServiceException("Failure"))
            .thenThrow(new ServiceException("Failure"))
            .thenReturn("Success");

        String result = retryService.callWithRetry();

        verify(externalService, times(3)).call();
        assertEquals("Success", result);
    }

    @Test
    void testRetryExhaustion() {
        when(externalService.call())
            .thenThrow(new ServiceException("Always fails"));

        assertThrows(ServiceException.class,
            () -> retryService.callWithRetry());
    }
}
```

## Migration Checklist

- [ ] Remove `spring-retry` dependency from build file
- [ ] Replace `@EnableRetry` with `@EnableResilientMethods`
- [ ] Update `@Retryable` imports to `org.springframework.resilience.annotation`
- [ ] Rename `value`/`retryFor` to `includes`
- [ ] Rename `maxAttempts` to `maxRetries` and subtract 1 from the value
- [ ] Remove `@Backoff` and move attributes directly to `@Retryable`
- [ ] Update `RetryTemplate` imports to `org.springframework.core.retry`
- [ ] If using circuit breaker or rate limiter, keep Resilience4j
- [ ] Run tests to verify retry counts match expected behavior
