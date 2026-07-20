# Testing Migration Reference

Testing-specific changes for upgrading to Spring Boot 4.x. If you are on **2.7.x**, do the
[2 → 3 testing leg](#coming-from-spring-boot-27-the-2--3-testing-leg) first, then apply the
3.5 → 4.x sections. `references/spring-boot-2-to-3-migration.md` covers the non-testing
parts of the 2 → 3 leg.

## Contents

- [Coming from Spring Boot 2.7? The 2 → 3 testing leg](#coming-from-spring-boot-27-the-2--3-testing-leg)
- [@MockBean / @SpyBean → @MockitoBean / @MockitoSpyBean](#mockbean--spybean--mockitobean--mockitospybean)
- [HTTP Test Client Changes](#http-test-client-changes)
- [Testcontainers 2.0](#testcontainers-20)
- [JUnit 6](#junit-6)
- [Test Starter Dependencies](#test-starter-dependencies)
- [Context Caching Improvement](#context-caching-improvement)
- [@PropertyMapping Relocation](#propertymapping-relocation)
- [Checklist](#checklist)

## Coming from Spring Boot 2.7? The 2 → 3 testing leg

Reach **Boot 3.5.x latest** first (see `references/spring-boot-2-to-3-migration.md`).
OpenRewrite's `UpgradeSpringBoot_3_5` recipe handles most of the mechanical test changes
below; hand-fix the rest. These are the **testing-specific** deltas of that leg — do them
here, then continue with the 3.5 → 4.x sections below.

- **`javax.*` → `jakarta.*` in test code.** Test fixtures/helpers importing
  `javax.persistence`, `javax.servlet`, `javax.validation`, or `javax.annotation` move to
  `jakarta.*`, same as production code (Jakarta EE recipe covers the bulk).
- **JUnit 4 → JUnit 5.** Remove `@RunWith(SpringRunner.class)` /
  `@RunWith(MockitoJUnitRunner.class)` and the `junit-vintage-engine` dependency once no
  JUnit 4 tests remain. `org.junit.Test` → `org.junit.jupiter.api.Test`; `@Before`/`@After`
  → `@BeforeEach`/`@AfterEach`; `@BeforeClass`/`@AfterClass` → `@BeforeAll`/`@AfterAll`;
  `@RunWith` → `@ExtendWith`; `@Ignore` → `@Disabled`. The later JUnit 6 jump is small once
  you are on JUnit 5 — see [JUnit 6](#junit-6).
- **Spring Security test config.** `WebSecurityConfigurerAdapter` is removed in Spring
  Security 6 (Boot 3.0) — test security config that subclassed it must move to a
  `SecurityFilterChain` bean. `spring-security-test` and `@WithMockUser` are unchanged.
- **Mock beans stay `@MockBean` on this leg.** On 3.0–3.3, `@MockBean`/`@SpyBean` are still
  the norm; the switch to `@MockitoBean`/`@MockitoSpyBean` is the 3.4+/4.x change handled
  [below](#mockbean--spybean--mockitobean--mockitospybean) — don't do it twice.
- **Testcontainers stays 1.x on this leg.** Keep the 1.x coordinates for now;
  `@ServiceConnection` is available from Boot 3.1 (before that, `@DynamicPropertySource`).
  The 1.x → 2.0 coordinate/package migration is the 4.x change — see
  [Testcontainers 2.0](#testcontainers-20).
- **Test properties.** Renamed/removed test properties surface via
  `spring-boot-properties-migrator` (add as a `runtime` dependency during the upgrade,
  remove once stable) — same mechanism as production config.

Once the build is green on Boot 3.5.x latest, continue with the sections below.

## @MockBean / @SpyBean → @MockitoBean / @MockitoSpyBean

`@MockBean` and `@SpyBean` were deprecated in Spring Boot 3.4.
In Boot 4.0 they remain present but **deprecated** and will be removed
in a future release. Migrate to `@MockitoBean` and `@MockitoSpyBean`
(available since 3.4). Additionally, `MockitoTestExecutionListener` is
removed — use `MockitoExtension` directly via `@ExtendWith(MockitoExtension.class)`.

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

### HtmlUnit Settings

HtmlUnit configuration in `@AutoConfigureMockMvc` has moved:
```java
// Boot 3.x
@AutoConfigureMockMvc(webClientEnabled = false)

// Boot 4.0
@AutoConfigureMockMvc(htmlUnit = @HtmlUnit(webClient = false))
```

### TestRestTemplate

`TestRestTemplate` has been relocated to `org.springframework.boot.resttestclient`
and requires `spring-boot-resttestclient` + `spring-boot-restclient` dependencies.

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
