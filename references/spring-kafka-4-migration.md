# Spring for Apache Kafka 4 Migration Reference

Spring for Apache Kafka 4.0 ships with Spring Boot 4.0 and brings the
project on to the Apache Kafka 4.x client (KRaft only), Spring Framework 7
core retry, Jackson 3, and a new modular `spring-boot-starter-kafka-test`.
It also adds early-access support for KIP-932 (Queues / share consumers)
and KIP-848 (the new consumer rebalance protocol).

Read this file when migrating any project that uses Spring Kafka — it
plugs into Phase 1 (build), Phase 3 (Jackson 3), Phase 7 (testing) and
Phase 8 (Framework 7 retry) of the main 3.x → 4.x workflow.

## Contents

- [Key Changes Summary](#key-changes-summary)
- [Toolchain Requirements](#toolchain-requirements)
- [OpenRewrite Automation](#openrewrite-automation)
- [Build / Dependency Changes](#build--dependency-changes)
- [Apache Kafka 4 Client and KRaft-only `@EmbeddedKafka`](#apache-kafka-4-client-and-kraft-only-embeddedkafka)
- [Spring Retry Removal (Framework 7 Core Retry)](#spring-retry-removal-framework-7-core-retry)
- [Jackson 3 in (De)Serializers](#jackson-3-in-deserializers)
- [Kafka Streams API Changes](#kafka-streams-api-changes)
- [New Consumer Rebalance Protocol (KIP-848)](#new-consumer-rebalance-protocol-kip-848)
- [Kafka Queues / Share Consumers (KIP-932)](#kafka-queues--share-consumers-kip-932)
- [Other Notable Additions](#other-notable-additions)
- [Migration Checklist](#migration-checklist)
- [References](#references)

## Key Changes Summary

1. **Apache Kafka 4.x client** — ZooKeeper code paths are gone; the
   embedded broker is now KRaft-only, `EmbeddedKafkaZKBroker` is removed,
   and ZooKeeper-related `@EmbeddedKafka` attributes
   (`zookeeperPort`, `zkConnectionTimeout`, `zkSessionTimeout`, `kraft`)
   are removed.
2. **Spring Retry dependency removed** in favour of Spring Framework 7
   core retry (`org.springframework.core.retry.*`,
   `org.springframework.resilience.annotation.*`). Kafka retry templates
   and `BackOffValuesGenerator` now use Spring Framework's `BackOff`
   directly instead of `BackOffPolicy`.
3. **New modular test starter** `spring-boot-starter-kafka-test` replaces
   direct use of `org.springframework.kafka:spring-kafka-test`.
4. **Jackson 3 by default** — `JsonSerializer`/`JsonDeserializer` and the
   header mappers move to the `tools.jackson.*` package tree. Jackson 2
   keeps working through the `spring-boot-jackson2` bridge.
5. **KIP-848 new consumer rebalance protocol** is opt-in via
   `spring.kafka.consumer.properties.group.protocol=consumer`; rebalance
   logic moves to the broker-side group coordinator.
6. **KIP-932 Queues for Kafka (early access)** — new
   `ShareConsumerFactory`, `ShareKafkaListenerContainerFactory`,
   `@KafkaListener` over share groups with `EXPLICIT` / `MANUAL` /
   `IMPLICIT` acknowledgment modes.
7. **Per-record observation in batch listeners** and listener-container
   `getRecordInterceptor()` customisation.

## Toolchain Requirements

Boot 4 / Spring Kafka 4 demos and reference apps target:

- Java 25 (LTS) — Boot 4 supports Java 17+ but Spring Kafka 4 demos and
  the new client features are exercised on Java 25
- Maven 3.9.0+ (or the bundled Maven Wrapper)
- Docker / Docker Compose 24.0+ for Kafka 4.x with KRaft and Schema Registry
- Apache Kafka broker 4.x (KRaft mode; ZooKeeper is no longer supported
  by the broker)

If your toolchain is below these, complete the Toolchain Version Check
in the main SKILL before continuing.

## OpenRewrite Automation

Run OpenRewrite first to handle the bulk mechanical changes, then come
back to address the manual items below (KIP-848 opt-in, share consumer
adoption, custom retry callbacks, etc.).

### Recipes

| Recipe ID | Coverage |
|-----------|----------|
| `org.openrewrite.java.spring.boot4.UpgradeSpringBoot_4_0` | Spring Boot 3.x → 4.0 (run alongside Kafka recipes) |
| `org.openrewrite.java.spring.kafka.UpgradeSpringKafka_4_0` | Spring Kafka 3.x → 4.0 — bumps coordinates and applies known package/import shifts |
| `org.openrewrite.java.jackson.UpgradeJackson_2_3` | Jackson 2 → Jackson 3 across the project (covers Kafka serializers/deserializers and header mappers) |

The Spring I/O 2026 demo composes these into a custom recipe and adds
three project-specific Kafka rewrites that you can copy verbatim:

```yaml
# rewrite.yml — based on the Spring I/O 2026 demo
type: specs.openrewrite.org/v1beta/recipe
name: com.example.spring.kafka.CustomUpgradeSpringKafka_4_0
displayName: Custom Spring Kafka 4 migration
description: Dependency, starter and @EmbeddedKafka rewrites for Spring Kafka 3 → 4
recipeList:
  - com.example.spring.kafka.MigrateSpringBootJsonToJacksonStarter
  - com.example.spring.kafka.MigrateSpringKafkaTestToSpringBootStarterKafkaTest
  - com.example.spring.kafka.RemoveDeprecatedEmbeddedKafkaParameters

---
type: specs.openrewrite.org/v1beta/recipe
name: com.example.spring.kafka.MigrateSpringBootJsonToJacksonStarter
displayName: Migrate spring-boot-starter-json to spring-boot-starter-jackson
recipeList:
  - org.openrewrite.maven.ChangeDependencyGroupIdAndArtifactId:
      oldGroupId: org.springframework.boot
      oldArtifactId: spring-boot-starter-json
      newGroupId: org.springframework.boot
      newArtifactId: spring-boot-starter-jackson

---
type: specs.openrewrite.org/v1beta/recipe
name: com.example.spring.kafka.MigrateSpringKafkaTestToSpringBootStarterKafkaTest
displayName: Migrate spring-kafka-test to spring-boot-starter-kafka-test
recipeList:
  - org.openrewrite.maven.ChangeDependencyGroupIdAndArtifactId:
      oldGroupId: org.springframework.kafka
      oldArtifactId: spring-kafka-test
      newGroupId: org.springframework.boot
      newArtifactId: spring-boot-starter-kafka-test

---
type: specs.openrewrite.org/v1beta/recipe
name: com.example.spring.kafka.RemoveDeprecatedEmbeddedKafkaParameters
displayName: Remove deprecated @EmbeddedKafka parameters
description: Removes ZooKeeper-era and now-default kraft parameters from @EmbeddedKafka
recipeList:
  - org.openrewrite.java.RemoveAnnotationAttribute:
      annotationType: org.springframework.kafka.test.context.EmbeddedKafka
      attributeName: zookeeperPort
  - org.openrewrite.java.RemoveAnnotationAttribute:
      annotationType: org.springframework.kafka.test.context.EmbeddedKafka
      attributeName: kraft
  - org.openrewrite.java.RemoveAnnotationAttribute:
      annotationType: org.springframework.kafka.test.context.EmbeddedKafka
      attributeName: zkConnectionTimeout
  - org.openrewrite.java.RemoveAnnotationAttribute:
      annotationType: org.springframework.kafka.test.context.EmbeddedKafka
      attributeName: zkSessionTimeout
```

### Wiring the plugin (Maven)

```xml
<plugin>
    <groupId>org.openrewrite.maven</groupId>
    <artifactId>rewrite-maven-plugin</artifactId>
    <version>${rewrite-maven-plugin.version}</version>
    <configuration>
        <configLocation>${project.basedir}/rewrite.yml</configLocation>
        <activeRecipes>
            <recipe>org.openrewrite.java.spring.boot4.UpgradeSpringBoot_4_0</recipe>
            <recipe>org.openrewrite.java.spring.kafka.UpgradeSpringKafka_4_0</recipe>
            <recipe>com.example.spring.kafka.CustomUpgradeSpringKafka_4_0</recipe>
        </activeRecipes>
    </configuration>
    <dependencies>
        <dependency>
            <groupId>org.openrewrite.recipe</groupId>
            <artifactId>rewrite-spring</artifactId>
            <version>${rewrite-spring.version}</version>
        </dependency>
    </dependencies>
</plugin>
```

Run with:

```bash
./mvnw rewrite:run
# or, on Gradle
./gradlew rewriteRun
```

## Build / Dependency Changes

### Boot starter for Kafka

`spring-boot-starter-kafka` is unchanged — the Boot 4 modular starter
keeps the same coordinates and brings in `org.springframework.kafka:spring-kafka:4.x`.

### Test starter

| Boot 3.x | Boot 4.x |
|----------|----------|
| `org.springframework.kafka:spring-kafka-test` | `org.springframework.boot:spring-boot-starter-kafka-test` |

```xml
<!-- Before (Boot 3.x) -->
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka-test</artifactId>
    <scope>test</scope>
</dependency>

<!-- After (Boot 4.x) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-kafka-test</artifactId>
    <scope>test</scope>
</dependency>
```

### JSON starter

If your Kafka project picked up Jackson via `spring-boot-starter-json`,
move to the explicit Jackson 3 starter:

| Boot 3.x | Boot 4.x |
|----------|----------|
| `spring-boot-starter-json` | `spring-boot-starter-jackson` |

### Removed transitively

- `org.springframework.retry:spring-retry` — no longer pulled in by
  Spring Kafka. Either drop it or add it back explicitly with a pinned
  version, but prefer migrating to Framework 7 core retry (see below).
- `org.apache.zookeeper:zookeeper` — no longer needed for embedded testing.

## Apache Kafka 4 Client and KRaft-only `@EmbeddedKafka`

Spring Kafka 4 upgrades to the Apache Kafka 4.0.0+ client. The broker
must run in KRaft mode; the ZooKeeper code path has been deleted from
both the client and the test framework.

### Removed test classes / attributes

- `org.springframework.kafka.test.EmbeddedKafkaZKBroker` — **removed**.
  Use `EmbeddedKafkaKraftBroker` (the default `EmbeddedKafkaBroker`
  implementation in 4.x).
- `@EmbeddedKafka` attributes that are gone:
  - `zookeeperPort`
  - `zkConnectionTimeout`
  - `zkSessionTimeout`
  - `kraft` (KRaft is now the default and only mode)

### Before / after

```java
// Before (Spring Kafka 3.x)
@SpringJUnitConfig
@EmbeddedKafka(
    partitions = 1,
    topics = {"orders"},
    kraft = true,
    zookeeperPort = 2181,
    zkConnectionTimeout = 10_000,
    zkSessionTimeout = 10_000)
class OrderListenerTests { … }

// After (Spring Kafka 4.x)
@SpringJUnitConfig
@EmbeddedKafka(partitions = 1, topics = {"orders"})
class OrderListenerTests { … }
```

If you injected the broker explicitly:

```java
// Before
@Autowired EmbeddedKafkaZKBroker broker;

// After
@Autowired EmbeddedKafkaBroker broker;        // resolves to EmbeddedKafkaKraftBroker
```

### Docker / runtime broker

Local Compose stacks must run a KRaft broker. The Spring I/O 2026 demo
uses Apache Kafka 4.2 in KRaft mode plus Confluent Schema Registry —
you can copy the `docker-compose.yml` from
[`j-tim/spring-io-barcelona-2026-what-s-new-in-spring-kafka-4`](https://github.com/j-tim/spring-io-barcelona-2026-what-s-new-in-spring-kafka-4)
as a starting point.

## Spring Retry Removal (Framework 7 Core Retry)

Spring for Apache Kafka 4 no longer depends on Spring Retry. Internal
retry (e.g. Kafka Streams retry templates, `RetryableTopic`'s
`BackOffValuesGenerator`) now uses Spring Framework's `BackOff` directly
instead of `BackOffPolicy`. Behaviour is preserved; the import surface
changes.

### What to update

| Old (Spring Retry) | New (Spring Framework 7) |
|---|---|
| `org.springframework.retry.annotation.Retryable` | `org.springframework.resilience.annotation.Retryable` |
| `org.springframework.retry.annotation.EnableRetry` | `org.springframework.resilience.annotation.EnableResilientMethods` |
| `org.springframework.retry.support.RetryTemplate` | `org.springframework.core.retry.RetryTemplate` |
| `org.springframework.retry.backoff.BackOffPolicy` | `org.springframework.util.backoff.BackOff` |

### `@RetryableTopic` and DLT

`@RetryableTopic` itself is still in Spring Kafka, but any custom
back-off you wired through Spring Retry needs to be expressed as a
Spring Framework `BackOff` (e.g. `ExponentialBackOff`,
`FixedBackOff`). Pre-generated back-off arrays now flow through
`BackOffValuesGenerator` against `BackOff` instead of `BackOffPolicy`.

```java
// Before — Spring Retry-based custom back-off
BackOffPolicy backOff = new ExponentialBackOffPolicy();
backOff.setInitialInterval(1_000);

// After — Spring Framework 7 BackOff
ExponentialBackOff backOff = new ExponentialBackOff();
backOff.setInitialInterval(1_000);
```

See `references/resilience-migration.md` for the full Spring Retry →
Framework 7 migration (annotation attribute renames, the
`maxAttempts → maxRetries` semantic shift, etc.). Apply that guidance
to any Kafka listener / producer code that used `@Retryable`.

## Jackson 3 in (De)Serializers

Kafka serializer/deserializer classes that delegate to Jackson are now
backed by Jackson 3 (`tools.jackson.*`).

### Imports

| Jackson 2 (Spring Kafka 3.x) | Jackson 3 (Spring Kafka 4.x) |
|------------------------------|------------------------------|
| `com.fasterxml.jackson.databind.ObjectMapper` | `tools.jackson.databind.ObjectMapper` |
| `com.fasterxml.jackson.databind.json.JsonMapper` | `tools.jackson.databind.json.JsonMapper` |
| `com.fasterxml.jackson.databind.JavaType` | `tools.jackson.databind.JavaType` |

### Custom `JsonSerializer` / `JsonDeserializer`

```java
// Before — building the deserializer with Jackson 2
ObjectMapper mapper = new ObjectMapper();         // com.fasterxml…
JsonDeserializer<Order> deserializer = new JsonDeserializer<>(Order.class, mapper);
deserializer.addTrustedPackages("com.example");

// After — Jackson 3
JsonMapper mapper = JsonMapper.builder().build(); // tools.jackson.databind.json.JsonMapper
JsonDeserializer<Order> deserializer = new JsonDeserializer<>(Order.class, mapper);
deserializer.addTrustedPackages("com.example");
```

### Header mappers

`JsonKafkaHeaderMapper` and `SimpleKafkaHeaderMapper` now also support
multi-value header mapping for Kafka records. No code change is required
to take advantage of this; a single header key can carry multiple values.

### Stopgap: keep Jackson 2 for now

If you can't migrate every Kafka serializer in the same change, add the
`spring-boot-jackson2` bridge as documented in
`references/jackson3-migration.md` — it lets the Kafka 2 code paths
keep working alongside Boot 4 until you finish Track B.

## Kafka Streams API Changes

- `StreamBuilderFactoryBeanCustomizer` (Boot) is **removed** — use
  Spring Kafka's `StreamsBuilderFactoryBeanConfigurer` instead. (This
  is also called out in `references/api-changes.md`.)
- Kafka Streams retry templates now use Spring Framework's `BackOff` /
  `RetryTemplate`. Replace any `BackOffPolicy` instances passed into
  `BackOffValuesGenerator` with a Spring Framework `BackOff`.

## New Consumer Rebalance Protocol (KIP-848)

Kafka 4 introduces a server-side coordinator-driven rebalance protocol.
Spring Kafka 4 supports it transparently — opt in by setting:

```properties
spring.kafka.consumer.properties.group.protocol=consumer
```

Or in YAML:

```yaml
spring:
  kafka:
    consumer:
      properties:
        group.protocol: consumer   # default is "classic"
```

Trade-offs:

- Faster, incremental rebalances; no client-side global synchronization
  barrier.
- Assignment strategy moves to the broker. The following client configs
  are **disabled / ignored** when `group.protocol=consumer`:
  - `partition.assignment.strategy`
  - `heartbeat.interval.ms`
  - `session.timeout.ms`
  - Custom `ConsumerPartitionAssignor` implementations
- New Kafka client metrics; existing dashboards may need adjustments.
- Rollback is supported — drop the `group.protocol` property and the
  group is converted back to `classic` after the last new-protocol
  consumer leaves.

### Live-upgrade pattern

1. Start a new consumer instance with `group.protocol=consumer` in the
   same group; the coordinator converts the group from `classic` to
   `consumer`.
2. Scale up new-protocol consumers, scale down classic-protocol consumers.
3. Don't leave the group in a mixed state for long — finish the cutover
   in a single deployment window.

## Kafka Queues / Share Consumers (KIP-932)

Spring Kafka 4 ships **early-access** support for KIP-932 share consumers
(Kafka Queues), which let multiple consumers cooperatively process the
same partition.

### Programmatic configuration

```java
@Configuration
@EnableKafka
public class ShareConsumerConfig {

    @Bean
    public ShareConsumerFactory<String, String> shareConsumerFactory() {
        Map<String, Object> props = new HashMap<>();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        return new DefaultShareConsumerFactory<>(props);
    }

    @Bean
    public ShareKafkaListenerContainerFactory<String, String> shareKafkaListenerContainerFactory(
            ShareConsumerFactory<String, String> shareConsumerFactory) {
        return new ShareKafkaListenerContainerFactory<>(shareConsumerFactory);
    }
}
```

`@KafkaListener` then targets a share group via the new factory:

```java
@KafkaListener(
    topics = "transactions",
    groupId = "annotation-driven-share-group",
    containerFactory = "shareKafkaListenerContainerFactory")
public void onMessage(ConsumerRecord<String, String> record) { … }
```

### Acknowledgment modes

| Mode | Who acknowledges | On listener error | Use when |
|------|------------------|-------------------|----------|
| `EXPLICIT` (default) | Container | Recoverer decides (`REJECT` by default) | Business logic doesn't need fine-grained per-record control |
| `MANUAL` | Listener code (`acknowledge()` / `release()` / `reject()`) | Listener decides | You need fine-grained per-record control |
| `IMPLICIT` | Kafka broker (auto-`ACCEPT`) | Broker auto-`ACCEPT` (no recovery) | Per-record delivery guarantees are not required |

### Limitations / caveats (early access)

- No Spring Boot auto-configuration for share consumers yet —
  `ShareConsumerFactory` and `ShareKafkaListenerContainerFactory` must
  be defined as `@Bean`s.
- Several `ShareConsumerConfig` keys are unsupported on the client and
  must be set on the broker via `kafka-configs --entity-type groups`,
  e.g. `share.auto.offset.reset`, `share.heartbeat.interval.ms`,
  `share.isolation.level`, `share.record.lock.duration.ms`,
  `share.session.timeout.ms`.
- Client-side configs that are **not** supported on share consumers:
  `auto.offset.reset`, `enable.auto.commit`, `group.instance.id`,
  `isolation.level`, `partition.assignment.strategy`,
  `interceptor.classes`, `session.timeout.ms`, `heartbeat.interval.ms`,
  `group.protocol`, `group.remote.assignor`. See
  `org.apache.kafka.clients.consumer.ShareConsumerConfig#SHARE_GROUP_UNSUPPORTED_CONFIGS`.

## Other Notable Additions

- **Per-record observation in batch listeners** — when using a batch
  `@KafkaListener`, you can now get a Micrometer `Observation` per
  record (instead of one per batch), useful for tracing per-message
  spans.
- **Listener container interceptor customisation** —
  `MessageListenerContainer#getRecordInterceptor()` lets you customise
  the configured record interceptor at runtime, and a new composite
  batch interceptor is configurable.
- **JSpecify nullability** annotations are applied across the Spring
  Kafka codebase, in line with Spring Framework 7. If you implement
  Spring Kafka SPIs, follow the JSpecify guidance in
  `references/spring-framework7.md`.

## Migration Checklist

- [ ] Toolchain meets Boot 4 / Kafka 4 minimums (Java 17+, Maven 3.9+,
      Docker 24+ if you use Compose, KRaft broker for runtime/integration tests)
- [ ] Replace `org.springframework.kafka:spring-kafka-test` with
      `org.springframework.boot:spring-boot-starter-kafka-test`
- [ ] Replace `spring-boot-starter-json` with `spring-boot-starter-jackson`
      (or add the `spring-boot-jackson2` bridge if you need a stopgap)
- [ ] Remove `zookeeperPort`, `kraft`, `zkConnectionTimeout`,
      `zkSessionTimeout` from every `@EmbeddedKafka` annotation
- [ ] Replace `EmbeddedKafkaZKBroker` references with `EmbeddedKafkaBroker`
      (resolves to `EmbeddedKafkaKraftBroker`)
- [ ] Move Jackson imports in custom `JsonSerializer` /
      `JsonDeserializer` / header mappers from `com.fasterxml.jackson.*`
      to `tools.jackson.*` (or add the Jackson 2 bridge)
- [ ] Migrate any `@Retryable` / `@EnableRetry` / `RetryTemplate` /
      `BackOffPolicy` usage to the Spring Framework 7 equivalents
      (see `references/resilience-migration.md`)
- [ ] Replace `StreamBuilderFactoryBeanCustomizer` with
      `StreamsBuilderFactoryBeanConfigurer`
- [ ] Run `./mvnw rewrite:run` (or `./gradlew rewriteRun`) with the
      recipes above; review the diff
- [ ] `mvn clean verify` / `gradle clean build`; full integration tests
      against a KRaft broker
- [ ] (Optional) opt in to KIP-848 with
      `spring.kafka.consumer.properties.group.protocol=consumer` and
      validate metrics / dashboards
- [ ] (Optional) prototype KIP-932 share consumers in a non-critical
      consumer group before adopting widely

## References

- Spring I/O 2026 — "What's new in Spring for Apache Kafka 4" demo
  repository: https://github.com/j-tim/spring-io-barcelona-2026-what-s-new-in-spring-kafka-4
- Spring I/O 2026 slides — "What's new in Spring for Apache Kafka 4":
  https://2026.springio.net/slides/whats-new-in-spring-for-apache-kafka-4-springio26.pdf
- Spring for Apache Kafka 4.0.0 GA blog:
  https://spring.io/blog/2025/11/18/spring-kafka-4
- Spring for Apache Kafka — What's New:
  https://docs.spring.io/spring-kafka/reference/whats-new.html
- Spring for Apache Kafka — Change History:
  https://docs.spring.io/spring-kafka/reference/appendix/change-history.html
- KIP-848 — Next-generation consumer rebalance protocol:
  https://cwiki.apache.org/confluence/display/KAFKA/KIP-848
- KIP-932 — Queues for Kafka:
  https://cwiki.apache.org/confluence/display/KAFKA/KIP-932
- Apache Kafka 4.0 release notes:
  https://archive.apache.org/dist/kafka/4.0.0/RELEASE_NOTES.html
- OpenRewrite — `rewrite-spring` recipes catalogue:
  https://docs.openrewrite.org/recipes/java/spring
