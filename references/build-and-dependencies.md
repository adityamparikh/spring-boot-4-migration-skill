# Build and Dependencies Reference

## Version Requirements

- Java 17+ (Java 21+ recommended, Java 25 supported)
- Kotlin 2.2+ (if using Kotlin)
- GraalVM 25+ (if using native-image)
- Jakarta EE 11 / Servlet 6.1
- Spring Framework 7.x (managed by Boot BOM)

## Gradle Version Support

Gradle 9 is now supported. Gradle 8.x (8.14 or later) remains supported.
If using an older Gradle version, upgrade your wrapper:

```bash
./gradlew wrapper --gradle-version=9.0
```

## Build Plugin Updates

### Maven

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.0.x</version> <!-- Use latest patch -->
</parent>

<!-- Or if using dependency management only -->
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>4.0.x</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

Remove any `<loaderImplementation>CLASSIC</loaderImplementation>` from
`spring-boot-maven-plugin` configuration. Remove `<includeOptional>` if
optional dependencies should NOT be in uber jars (new default: excluded).

### Gradle (Kotlin DSL)

```kotlin
plugins {
    id("org.springframework.boot") version "4.0.x" // latest patch
    id("io.spring.dependency-management") version "1.1.x"
}
```

Remove any `loaderImplementation = org.springframework.boot.loader.tools.LoaderImplementation.CLASSIC`.

### Gradle (Groovy DSL)

```groovy
plugins {
    id 'org.springframework.boot' version '4.0.x'
    id 'io.spring.dependency-management' version '1.1.x'
}
```

## Deprecated Starter Renames

Replace immediately — old names still work but will be removed:

| Old Starter | New Starter |
|-------------|-------------|
| `spring-boot-starter-web` | `spring-boot-starter-webmvc` |
| `spring-boot-starter-web-services` | `spring-boot-starter-webservices` |
| `spring-boot-starter-aop` | `spring-boot-starter-aspectj` |
| `spring-boot-starter-oauth2-authorization-server` | `spring-boot-starter-security-oauth2-authorization-server` |
| `spring-boot-starter-oauth2-client` | `spring-boot-starter-security-oauth2-client` |
| `spring-boot-starter-oauth2-resource-server` | `spring-boot-starter-security-oauth2-resource-server` |

## Removed Features — Remove These Dependencies

- **Undertow**: Not compatible with Servlet 6.1. Remove `spring-boot-starter-undertow`. Use `spring-boot-starter-tomcat` or `spring-boot-starter-jetty`.
- **Pulsar Reactive**: `spring-boot-starter-pulsar-reactive` removed.
- **Spring Session Hazelcast**: Now maintained by Hazelcast team separately.
- **Spring Session MongoDB**: Now maintained by MongoDB team separately.
- **Spock**: Removed (not yet compatible with Groovy 5).
- **Embedded launch scripts**: "Fully executable" jar support removed. Use `java -jar` or Gradle application plugin.
- **`spring-boot-autoconfigure` direct dependency**: No longer public. Use technology-specific starters.

## Classic Starters (Temporary Stopgap)

If modular migration is too disruptive initially:

| Replace | With |
|---------|------|
| `spring-boot-starter` | `spring-boot-starter-classic` |
| `spring-boot-starter-test` | `spring-boot-starter-test-classic` |

Classic starters provide all modules (like Boot 3.x) but without
transitive dependencies. Migrate away from these incrementally.

## Complete Modular Starter Mapping

Every technology now has a dedicated starter AND a test companion starter.
Add the test starter whenever your test code uses that technology's test
infrastructure.

### Core

| Technology | Main | Test |
|-----------|------|------|
| AspectJ | `spring-boot-starter-aspectj` | `spring-boot-starter-aspectj-test` |
| Jakarta Validation | `spring-boot-starter-validation` | `spring-boot-starter-validation-test` |
| Reactor | `spring-boot-starter-reactor` | `spring-boot-starter-reactor-test` |

### Web

| Technology | Main | Test |
|-----------|------|------|
| Spring Web MVC | `spring-boot-starter-webmvc` | `spring-boot-starter-webmvc-test` |
| Spring WebFlux | `spring-boot-starter-webflux` | `spring-boot-starter-webflux-test` |
| RestClient/RestTemplate | `spring-boot-starter-restclient` | `spring-boot-starter-restclient-test` |
| WebClient (Reactive) | `spring-boot-starter-webclient` | `spring-boot-starter-webclient-test` |
| Jersey | `spring-boot-starter-jersey` | `spring-boot-starter-jersey-test` |
| Spring GraphQL | `spring-boot-starter-graphql` | `spring-boot-starter-graphql-test` |
| Spring HATEOAS | `spring-boot-starter-hateoas` | `spring-boot-starter-hateoas-test` |
| Websockets | `spring-boot-starter-websocket` | `spring-boot-starter-websocket-test` |
| Webservices | `spring-boot-starter-webservices` | `spring-boot-starter-webservices-test` |

### Web Servers

| Technology | Main | Test |
|-----------|------|------|
| Tomcat | `spring-boot-starter-tomcat` | *none* |
| Jetty | `spring-boot-starter-jetty` | *none* |
| Reactor Netty | `spring-boot-starter-reactor-netty` | *none* |

### Database / Data Access

| Technology | Main | Test |
|-----------|------|------|
| JDBC | `spring-boot-starter-jdbc` | `spring-boot-starter-jdbc-test` |
| JPA (Hibernate) | `spring-boot-starter-data-jpa` | `spring-boot-starter-data-jpa-test` |
| Spring Data JDBC | `spring-boot-starter-data-jdbc` | `spring-boot-starter-data-jdbc-test` |
| Spring Data MongoDB | `spring-boot-starter-data-mongodb` | `spring-boot-starter-data-mongodb-test` |
| Spring Data MongoDB Reactive | `spring-boot-starter-data-mongodb-reactive` | `spring-boot-starter-data-mongodb-reactive-test` |
| Spring Data Redis | `spring-boot-starter-data-redis` | `spring-boot-starter-data-redis-test` |
| Spring Data Redis Reactive | `spring-boot-starter-data-redis-reactive` | `spring-boot-starter-data-redis-reactive-test` |
| Spring Data Elasticsearch | `spring-boot-starter-data-elasticsearch` | `spring-boot-starter-data-elasticsearch-test` |
| Spring Data R2DBC | `spring-boot-starter-data-r2dbc` | `spring-boot-starter-data-r2dbc-test` |
| Spring Data REST | `spring-boot-starter-data-rest` | `spring-boot-starter-data-rest-test` |
| Spring Data Neo4J | `spring-boot-starter-data-neo4j` | `spring-boot-starter-data-neo4j-test` |
| Spring Data Cassandra | `spring-boot-starter-data-cassandra` | `spring-boot-starter-data-cassandra-test` |
| Spring Data Couchbase | `spring-boot-starter-data-couchbase` | `spring-boot-starter-data-couchbase-test` |
| Spring Data LDAP | `spring-boot-starter-data-ldap` | `spring-boot-starter-data-ldap-test` |
| Flyway | `spring-boot-starter-flyway` | `spring-boot-starter-flyway-test` |
| Liquibase | `spring-boot-starter-liquibase` | `spring-boot-starter-liquibase-test` |
| jOOQ | `spring-boot-starter-jooq` | `spring-boot-starter-jooq-test` |
| Elasticsearch (low-level) | `spring-boot-starter-elasticsearch` | `spring-boot-starter-elasticsearch-test` |
| MongoDB (driver) | `spring-boot-starter-mongodb` | `spring-boot-starter-mongodb-test` |
| Cassandra (driver) | `spring-boot-starter-cassandra` | `spring-boot-starter-cassandra-test` |
| Couchbase (driver) | `spring-boot-starter-couchbase` | `spring-boot-starter-couchbase-test` |
| R2DBC | `spring-boot-starter-r2dbc` | `spring-boot-starter-r2dbc-test` |
| Neo4J (driver) | `spring-boot-starter-neo4j` | `spring-boot-starter-neo4j-test` |
| LDAP | `spring-boot-starter-ldap` | `spring-boot-starter-ldap-test` |

### Session

| Technology | Main | Test |
|-----------|------|------|
| Session JDBC | `spring-boot-starter-session-jdbc` | `spring-boot-starter-session-jdbc-test` |
| Session Data Redis | `spring-boot-starter-session-data-redis` | `spring-boot-starter-session-data-redis-test` |

### Messaging

| Technology | Main | Test |
|-----------|------|------|
| Apache Kafka | `spring-boot-starter-kafka` | `spring-boot-starter-kafka-test` |
| RabbitMQ (AMQP) | `spring-boot-starter-amqp` | `spring-boot-starter-amqp-test` |
| Apache Pulsar | `spring-boot-starter-pulsar` | `spring-boot-starter-pulsar-test` |
| ActiveMQ | `spring-boot-starter-activemq` | `spring-boot-starter-activemq-test` |
| Artemis | `spring-boot-starter-artemis` | `spring-boot-starter-artemis-test` |
| JMS | `spring-boot-starter-jms` | `spring-boot-starter-jms-test` |
| RSocket | `spring-boot-starter-rsocket` | `spring-boot-starter-rsocket-test` |
| Spring Integration | `spring-boot-starter-integration` | `spring-boot-starter-integration-test` |

### Security

| Technology | Main | Test |
|-----------|------|------|
| Spring Security | `spring-boot-starter-security` | `spring-boot-starter-security-test` |
| OAuth2 Authorization Server | `spring-boot-starter-security-oauth2-authorization-server` | `spring-boot-starter-security-oauth2-authorization-server-test` |
| OAuth2 Client | `spring-boot-starter-security-oauth2-client` | `spring-boot-starter-security-oauth2-client-test` |
| OAuth2 Resource Server | `spring-boot-starter-security-oauth2-resource-server` | `spring-boot-starter-security-oauth2-resource-server-test` |
| SAML 2 | `spring-boot-starter-security-saml2` | `spring-boot-starter-security-saml2-test` |

### JSON

| Technology | Main | Test |
|-----------|------|------|
| Jackson (3.x) | `spring-boot-starter-jackson` | `spring-boot-starter-jackson-test` |
| GSON | `spring-boot-starter-gson` | `spring-boot-starter-gson-test` |
| JSON-B | `spring-boot-starter-jsonb` | `spring-boot-starter-jsonb-test` |

### Batch

| Technology | Main | Test |
|-----------|------|------|
| Spring Batch (with JDBC) | `spring-boot-starter-batch-jdbc` | `spring-boot-starter-batch-jdbc-test` |
| Spring Batch (without JDBC) | `spring-boot-starter-batch` | `spring-boot-starter-batch-test` |

### Caching / IO

| Technology | Main | Test |
|-----------|------|------|
| Cache | `spring-boot-starter-cache` | `spring-boot-starter-cache-test` |
| Mail | `spring-boot-starter-mail` | `spring-boot-starter-mail-test` |
| Quartz | `spring-boot-starter-quartz` | `spring-boot-starter-quartz-test` |
| Hazelcast | `spring-boot-starter-hazelcast` | `spring-boot-starter-hazelcast-test` |

### Templating

| Technology | Main | Test |
|-----------|------|------|
| Thymeleaf | `spring-boot-starter-thymeleaf` | `spring-boot-starter-thymeleaf-test` |
| Freemarker | `spring-boot-starter-freemarker` | `spring-boot-starter-freemarker-test` |
| Mustache | `spring-boot-starter-mustache` | `spring-boot-starter-mustache-test` |

### Production / Observability

| Technology | Main | Test |
|-----------|------|------|
| Actuator | `spring-boot-starter-actuator` | `spring-boot-starter-actuator-test` |
| Micrometer Metrics | `spring-boot-starter-micrometer-metrics` | `spring-boot-starter-micrometer-metrics-test` |
| OpenTelemetry | `spring-boot-starter-opentelemetry` | `spring-boot-starter-opentelemetry-test` |
| Zipkin | `spring-boot-starter-zipkin` | `spring-boot-starter-zipkin-test` |

## Dependency Management Removals

- **Spring Retry**: Explicit version now required if still using it. Consider migrating to Spring Framework core retry (`org.springframework.core.retry`).
- **Spring Authorization Server**: Now part of Spring Security. Override with `spring-security.version`, not `spring-authorization-server.version`.
- **Elasticsearch rest-client/sniffer**: `org.elasticsearch.client:elasticsearch-rest-client` and `elasticsearch-rest-client-sniffer` removed. Use `co.elastic.clients:elasticsearch-java` which includes built-in sniffer.
- **CycloneDX Gradle Plugin**: Minimum version 3.0.0.

## Kotlin Serialization

A new module `spring-boot-starter-kotlin-serialization` provides
auto-configuration for `kotlinx.serialization.json.Json` and a
corresponding `HttpMessageConverter`. Configure via
`spring.kotlin-serialization.*` properties.

## Jersey + Jackson

Jersey 4.0 does not yet support Jackson 3. If using Jersey with JSON:
- Add `spring-boot-jackson2` alongside or instead of `spring-boot-jackson`
- Or add explicit Jackson 2 provider dependency for Jersey
