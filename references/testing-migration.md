# Testing Migration Reference

## @MockBean / @SpyBean → @MockitoBean / @MockitoSpyBean

`@MockBean` and `@SpyBean` were deprecated in Spring Boot 3.4 and
**removed in Spring Boot 4.0**. You must migrate to `@MockitoBean` and
`@MockitoSpyBean` before upgrading. If still on 3.5.x, migrate these
annotations first — they are available since 3.4.

### Basic Replacement

```java
// Spring Boot 3.x
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.mock.mockito.SpyBean;

@SpringBootTest
class MyTest {
    @MockBean
    private MyService myService;

    @SpyBean
    private MyRepository myRepository;
}

// Spring Boot 4.0
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;

@SpringBootTest
class MyTest {
    @MockitoBean
    private MyService myService;

    @MockitoSpyBean
    private MyRepository myRepository;
}
```

### Key Behavioral Difference

`@MockBean` scanned the entire application context for matching beans by
type. `@MockitoBean` targets a **specific bean** — it does NOT scan all
beans of that type.

If your test relied on `@MockBean` replacing multiple beans of the same
type, you need to mock each one explicitly or use `@Qualifier`:

```java
@MockitoBean
@Qualifier("primaryService")
private MyService primaryService;

@MockitoBean
@Qualifier("secondaryService")
private MyService secondaryService;
```

### Search and Replace Patterns

1. `import org.springframework.boot.test.mock.mockito.MockBean` → `import org.springframework.test.context.bean.override.mockito.MockitoBean`
2. `import org.springframework.boot.test.mock.mockito.SpyBean` → `import org.springframework.test.context.bean.override.mockito.MockitoSpyBean`
3. `@MockBean` → `@MockitoBean`
4. `@SpyBean` → `@MockitoSpyBean`
5. `@MockBeans` → check and replace container annotation usage
6. `@SpyBeans` → check and replace container annotation usage

## HTTP Test Client Changes

### MockMvc No Longer Auto-Configured

```java
// Boot 3.x — MockMvc auto-configured in @SpringBootTest
@SpringBootTest
class MyTest {
    @Autowired
    private MockMvc mockMvc;  // Worked without extra annotation
}

// Boot 4.0 — Must explicitly enable
@SpringBootTest
@AutoConfigureMockMvc  // REQUIRED
class MyTest {
    @Autowired
    private MockMvc mockMvc;
}
```

### TestRestTemplate

```java
// Boot 4.0 — Must explicitly enable
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate  // REQUIRED
class MyTest {
    @Autowired
    private TestRestTemplate restTemplate;
}
```

### RestTestClient (New in Boot 4)

Modern alternative to TestRestTemplate with fluent API:

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureRestTestClient
class MyTest {
    @Autowired
    private RestTestClient restTestClient;

    @Test
    void shouldGetUser() {
        restTestClient.get().uri("/api/users/1")
            .exchange()
            .expectStatus().isOk()
            .expectBody(User.class)
            .value(user -> assertThat(user.getName()).isEqualTo("Alice"));
    }
}
```

`RestTestClient` works with both MockMvc (default) and live server instances.

## Testcontainers 2.0

### Dependency Changes

Module prefix added:

| Testcontainers 1.x | Testcontainers 2.0 |
|--------------------|-------------------|
| `org.testcontainers:postgresql` | `org.testcontainers:testcontainers-postgresql` |
| `org.testcontainers:mysql` | `org.testcontainers:testcontainers-mysql` |
| `org.testcontainers:mongodb` | `org.testcontainers:testcontainers-mongodb` |
| `org.testcontainers:kafka` | `org.testcontainers:testcontainers-kafka` |
| `org.testcontainers:elasticsearch` | `org.testcontainers:testcontainers-elasticsearch` |
| `org.testcontainers:rabbitmq` | `org.testcontainers:testcontainers-rabbitmq` |
| `org.testcontainers:solr` | `org.testcontainers:testcontainers-solr` |

Pattern: `org.testcontainers:<module>` → `org.testcontainers:testcontainers-<module>`

### Package Relocations

Container classes moved to module-specific packages.
Example: `org.testcontainers.containers.PostgreSQLContainer` may have
new package location. Check Testcontainers 2.0 migration guide for
your specific containers.

### Removed

- JUnit 4 support fully removed from Testcontainers
- Must use JUnit Jupiter or JUnit 6

### @ServiceConnection

Boot 4 adds `@ServiceConnection` for MongoDB's `MongoDBAtlasLocalContainer`.

## JUnit 6

### Migration Scope

JUnit 6 is largely a drop-in replacement for JUnit 5. Only APIs deprecated
for over two years were removed.

### Key Changes

1. **SpringRunner deprecated**:
```java
// Deprecated
@RunWith(SpringRunner.class)
public class MyTest { }

// Use instead
@ExtendWith(SpringExtension.class)
class MyTest { }
// Or just use @SpringBootTest which includes this
```

2. **JUnit Vintage engine deprecated** — remove `junit-vintage-engine`
   dependency if present.

3. **JSpecify annotations adopted** — improved null safety in test APIs.

4. **@Nested test class support enhanced** — better dependency injection
   semantics. But: `SpringExtension` now uses test-method scoped
   `ExtensionContext`. If `@Nested` tests break:
```java
@SpringExtensionConfig(useTestClassScope = true)
@SpringBootTest
class TopLevelTest {
    @Nested
    class InnerTest { }
}
```

### Deprecated Classes (Remove Usage)

- `SpringRunner` → `@ExtendWith(SpringExtension.class)`
- `SpringClassRule` → `@ExtendWith(SpringExtension.class)`
- `SpringMethodRule` → `@ExtendWith(SpringExtension.class)`
- `AbstractJUnit4SpringContextTests` → Use `@SpringBootTest`
- `AbstractTransactionalJUnit4SpringContextTests` → Use `@SpringBootTest` + `@Transactional`

## Test Starter Dependencies

Add test starters for technologies used in test code:

| If tests use... | Add test dependency |
|----------------|-------------------|
| `@WithMockUser`, `@WithUserDetails` | `spring-boot-starter-security-test` |
| `@WebMvcTest`, `MockMvc` | `spring-boot-starter-webmvc-test` |
| `@WebFluxTest` | `spring-boot-starter-webflux-test` |
| `@DataJpaTest` | `spring-boot-starter-data-jpa-test` |
| `@DataMongoTest` | `spring-boot-starter-data-mongodb-test` |
| `@DataRedisTest` | `spring-boot-starter-data-redis-test` |
| `@JdbcTest` | `spring-boot-starter-jdbc-test` |
| `@JooqTest` | `spring-boot-starter-jooq-test` |
| `@JsonTest` (Jackson) | `spring-boot-starter-jackson-test` |
| `@RestClientTest` | `spring-boot-starter-restclient-test` |
| `@GraphQlTest` | `spring-boot-starter-graphql-test` |

## Context Caching Improvement

Spring Framework 7 automatically **pauses** cached application contexts
when not in use and restarts them when needed. This prevents background
threads (scheduled jobs, message listeners) from interfering across
cached contexts during parallel test execution.

This is transparent but may change timing behavior in tests that relied
on background processes running during context caching.

## @PropertyMapping Relocation

`@PropertyMapping` has moved:
```java
// Old
import org.springframework.boot.test.autoconfigure.properties.PropertyMapping;

// New
import org.springframework.boot.test.context.PropertyMapping;
```

## Checklist

- [ ] All `@MockBean` → `@MockitoBean`
- [ ] All `@SpyBean` → `@MockitoSpyBean`
- [ ] `@AutoConfigureMockMvc` added where `MockMvc` is autowired
- [ ] `@AutoConfigureTestRestTemplate` added where `TestRestTemplate` is autowired
- [ ] Testcontainers dependencies updated with `testcontainers-` prefix
- [ ] JUnit Vintage engine removed
- [ ] `SpringRunner` replaced with `@ExtendWith(SpringExtension.class)` or `@SpringBootTest`
- [ ] Test starters added for each technology used in tests
- [ ] Verified `@Nested` test classes still pass
