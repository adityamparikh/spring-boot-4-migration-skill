# AOT Processing and Native Image Reference

Spring Boot 4 / Spring Framework 7 significantly enhances Ahead-of-Time
(AOT) processing with faster startup, lower memory usage, and improved
native image support.

## Contents

- [Key Changes from Boot 3.x](#key-changes-from-boot-3x)
- [GraalVM 25 Requirement](#graalvm-25-requirement)
- [BeanRegistrar (New)](#beanregistrar-new)
- [RuntimeHints API](#runtimehints-api)
- [Spring Data AOT Repositories](#spring-data-aot-repositories)
- [AOT Cache (Java 25+)](#aot-cache-java-25)
- [Testing AOT](#testing-aot)
- [Troubleshooting](#troubleshooting)
- [Custom AOT Processors](#custom-aot-processors)
- [Migration Checklist](#migration-checklist)

## Key Changes from Boot 3.x

- **GraalVM 25+ required** for native image compilation
- **BeanRegistrar** — new AOT-friendly programmatic bean registration
- **Spring Data AOT repositories** — build-time query generation
- **Modular architecture** — smaller modules improve native image size
- **Auto-detected hints** — fewer custom `RuntimeHintsRegistrar` needed
- **AOT Cache** — with Java 25, 60-75% startup reduction via CDS

## GraalVM 25 Requirement

Spring Framework 7 enforces GraalVM 25+ at runtime:

```bash
# Install via SDKMAN
sdk install java 25.r25-nik
sdk use java 25.r25-nik
```

**Build configuration:**

Maven:
```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.0.2</version>
</parent>
<build>
    <plugins>
        <plugin>
            <groupId>org.graalvm.buildtools</groupId>
            <artifactId>native-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>
```

```bash
mvn -Pnative spring-boot:build-image
# or
mvn clean package -Pnative
```

Gradle:
```kotlin
plugins {
    id("org.springframework.boot") version "4.0.2"
    id("org.graalvm.buildtools.native") version "0.10.4"
}
```

```bash
./gradlew bootBuildImage
# or
./gradlew nativeCompile
```

## BeanRegistrar (New)

AOT-compatible programmatic bean registration replacing
`ImportBeanDefinitionRegistrar` for native-friendly code:

```java
@Configuration
@Import(MyBeanRegistrar.class)
public class AppConfig { }

class MyBeanRegistrar implements BeanRegistrar {
    @Override
    public void register(BeanRegistry registry, Environment env) {
        registry.registerBean("foo", Foo.class);

        registry.registerBean("bar", Bar.class, spec -> spec
            .prototype()
            .lazyInit()
            .supplier(context -> new Bar(context.bean(Foo.class)))
        );

        if (env.matchesProfiles("production")) {
            registry.registerBean("prodService", ProductionService.class);
        }
    }
}
```

Kotlin DSL support:

```kotlin
class MyKotlinRegistrar : BeanRegistrar {
    override fun register(registry: BeanRegistry, env: Environment) {
        registry.registerBean("userService") {
            UserService(env.getProperty("api.url"))
        }
    }
}
```

## RuntimeHints API

Use `RuntimeHintsRegistrar` to declare reflection, resources, proxies,
and serialization hints for native image:

```java
public class MyRuntimeHints implements RuntimeHintsRegistrar {
    @Override
    public void registerHints(RuntimeHints hints, ClassLoader classLoader) {
        // Reflection
        hints.reflection().registerType(MyClass.class, builder -> builder
            .withMembers(MemberCategory.INVOKE_DECLARED_CONSTRUCTORS,
                        MemberCategory.INVOKE_DECLARED_METHODS));

        // Resources
        hints.resources()
            .registerPattern("config/*.properties")
            .registerPattern("templates/**/*.html");

        // Serialization
        hints.serialization().registerType(MySerializableClass.class);

        // JDK proxies
        hints.proxies().registerJdkProxy(MyInterface.class);
    }
}
```

### Registration Methods

**@ImportRuntimeHints** (on class or @Bean method):
```java
@SpringBootApplication
@ImportRuntimeHints(MyRuntimeHints.class)
public class MyApplication { }
```

**@RegisterReflectionForBinding** (for JSON DTOs):
```java
@Configuration
@RegisterReflectionForBinding({Customer.class, Order.class})
public class DomainConfig { }
```

**META-INF/spring/aot.factories**:
```properties
org.springframework.aot.hint.RuntimeHintsRegistrar=\
  com.example.MyRuntimeHints
```

### Important: Manual reflect-config.json NOT Merged

Manual files in `META-INF/native-image/` are NOT merged with
AOT-generated files. Use `RuntimeHintsRegistrar` instead.

## Spring Data AOT Repositories

Build-time query generation for JPA and MongoDB repositories.

### How It Works

- Enabled by default when AOT processing is active
- Query methods compiled to source code at build time
- SQL/queries validated at compile time
- JSON metadata generated for each repository method

```java
public interface UserRepository extends JpaRepository<User, Long> {
    // Compiled at build time — query validated, implementation generated
    List<User> findByLastNameAndFirstName(String lastName, String firstName);

    @Query("SELECT u FROM User u WHERE u.email = :email")
    Optional<User> findByEmail(@Param("email") String email);
}
```

### Supported Modules

- Spring Data JPA (Hibernate only)
- Spring Data MongoDB

### Migration Note

Remove explicit enablement from Boot 3 — no longer needed:

```properties
# Boot 3 (remove this line)
# spring.aot.repositories.enabled=true
# Boot 4: enabled by default with AOT
```

## AOT Cache (Java 25+)

With Java 25, Spring Boot 4 supports AOT caching for 60-75% startup
reduction:

```bash
# 1. Build the application
mvn clean package

# 2. Extract the JAR
mkdir -p target/extracted && cd target/extracted
jar -xf ../myapp.jar

# 3. Training run (creates cache)
java -XX:CacheDataStore=app.cds -jar ../myapp.jar

# 4. Subsequent runs use the cache
java -XX:CacheDataStore=app.cds -jar ../myapp.jar
```

Requires extracted JAR format and Java 25+.

## Testing AOT

### Run AOT on JVM (without native image)

```bash
# Maven
mvn spring-boot:run -Dspring.aot.enabled=true

# Or with JAR
java -Dspring.aot.enabled=true -jar myapplication.jar
```

### Native Tests

Maven:
```bash
mvn -PnativeTest test
```

Gradle:
```bash
./gradlew nativeTest
```

### @DisabledInAotMode

Skip tests incompatible with AOT:

```java
@Test
@DisabledInAotMode
void testThatUsesDynamicClassloading() { ... }
```

## Troubleshooting

### Reflection Errors (`NoSuchMethodException`, `IllegalAccessException`)

Missing reflection hints. Add:

```java
hints.reflection().registerType(MyClass.class, hint -> hint
    .withMembers(MemberCategory.INVOKE_DECLARED_CONSTRUCTORS,
                MemberCategory.INVOKE_DECLARED_METHODS,
                MemberCategory.DECLARED_FIELDS));
```

### Resources Not Found (`FileNotFoundException`)

```java
hints.resources()
    .registerPattern("config/*.yml")
    .registerPattern("static/**")
    .registerResourceBundle("messages");
```

### Out of Memory During Build

```bash
export MAVEN_OPTS="-Xmx8g"
```

Or in pom.xml:
```xml
<plugin>
    <groupId>org.graalvm.buildtools</groupId>
    <artifactId>native-maven-plugin</artifactId>
    <configuration>
        <buildArgs>
            <buildArg>-J-Xmx8g</buildArg>
        </buildArgs>
    </configuration>
</plugin>
```

### Third-Party Library Compatibility

Enable GraalVM Reachability Metadata Repository:

```kotlin
graalvmNative {
    metadataRepository {
        enabled = true
    }
}
```

## Custom AOT Processors

For library authors or advanced use cases:

```java
public class MyAotProcessor implements BeanFactoryInitializationAotProcessor {
    @Override
    public BeanFactoryInitializationAotContribution processAheadOfTime(
            ConfigurableListableBeanFactory beanFactory) {
        String[] beanNames = beanFactory.getBeanNamesForType(MyBean.class);
        if (beanNames.length == 0) return null;

        return (generationContext, code) -> {
            generationContext.getRuntimeHints()
                .reflection().registerType(MyBean.class);
        };
    }
}
```

Register in `META-INF/spring/aot.factories`:
```properties
org.springframework.beans.factory.aot.BeanFactoryInitializationAotProcessor=\
  com.example.MyAotProcessor
```

## Migration Checklist

- [ ] Upgrade GraalVM to 25+ for native image builds
- [ ] Update `native-maven-plugin` or `org.graalvm.buildtools.native` plugin
- [ ] Remove `spring.aot.repositories.enabled=true` (now default)
- [ ] Replace `ImportBeanDefinitionRegistrar` with `BeanRegistrar` where possible
- [ ] Move manual `reflect-config.json` to `RuntimeHintsRegistrar`
- [ ] Review custom `@NativeHint`/`@TypeHint` annotations (removed, use `@RegisterReflectionForBinding`)
- [ ] Test AOT on JVM with `-Dspring.aot.enabled=true`
- [ ] Run native tests with `-PnativeTest`
- [ ] Consider AOT Cache with Java 25 for production deployments
