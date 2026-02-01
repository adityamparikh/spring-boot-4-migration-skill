# Jackson 3 Migration Reference

Jackson 3 is the default JSON library in Spring Boot 4.0.

## Group ID Changes

| Jackson 2 Group ID | Jackson 3 Group ID |
|--------------------|-------------------|
| `com.fasterxml.jackson.core:jackson-core` | `tools.jackson.core:jackson-core` |
| `com.fasterxml.jackson.core:jackson-databind` | `tools.jackson.core:jackson-databind` |
| `com.fasterxml.jackson.core:jackson-annotations` | **UNCHANGED**: `com.fasterxml.jackson.core:jackson-annotations` |
| `com.fasterxml.jackson.datatype:jackson-datatype-*` | `tools.jackson.datatype:jackson-datatype-*` |
| `com.fasterxml.jackson.dataformat:jackson-dataformat-*` | `tools.jackson.dataformat:jackson-dataformat-*` |
| `com.fasterxml.jackson.module:jackson-module-*` | `tools.jackson.module:jackson-module-*` |

## Package Changes

| Jackson 2 Package | Jackson 3 Package |
|-------------------|-------------------|
| `com.fasterxml.jackson.core.*` | `tools.jackson.core.*` |
| `com.fasterxml.jackson.databind.*` | `tools.jackson.databind.*` |
| `com.fasterxml.jackson.annotation.*` | **UNCHANGED**: `com.fasterxml.jackson.annotation.*` |
| `com.fasterxml.jackson.datatype.*` | `tools.jackson.datatype.*` |
| `com.fasterxml.jackson.dataformat.*` | `tools.jackson.dataformat.*` |

## Spring Boot Class Renames

| Old Class | New Class |
|-----------|-----------|
| `org.springframework.boot.jackson.JsonObjectSerializer` | `org.springframework.boot.jackson.ObjectValueSerializer` |
| `org.springframework.boot.jackson.JsonObjectDeserializer` | `org.springframework.boot.jackson.ObjectValueDeserializer` |
| `Jackson2ObjectMapperBuilderCustomizer` | `JsonMapperBuilderCustomizer` |
| `@JsonComponent` | `@JacksonComponent` |
| `@JsonMixin` | `@JacksonMixin` |
| `JsonComponentModule` | `JacksonComponentModule` |

## Core API Changes

### ObjectMapper → JsonMapper

Jackson 3 uses `JsonMapper` as the primary entry point:

```java
// Jackson 2
ObjectMapper mapper = new ObjectMapper();
mapper.registerModule(new JavaTimeModule());

// Jackson 3
JsonMapper mapper = JsonMapper.builder()
    .addModule(new JavaTimeModule())
    .build();
```

`ObjectMapper` still exists in Jackson 3 but `JsonMapper` is preferred.

### Builder Pattern

Jackson 3 uses immutable builders:

```java
// Jackson 2
ObjectMapper mapper = new ObjectMapper();
mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

// Jackson 3
JsonMapper mapper = JsonMapper.builder()
    .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
    .build();
```

### Default Behavior Changes

Jackson 3 has different defaults than Jackson 2. Key differences:
- Date/time serialization defaults may differ
- Some `SerializationFeature`/`DeserializationFeature` defaults changed

Set `spring.jackson.use-jackson2-defaults=true` to get Jackson 2-compatible
defaults in Boot 4.

### Custom Serializers/Deserializers

```java
// Jackson 2 (Spring Boot 3.x)
@JsonComponent
public class MySerializer extends JsonObjectSerializer<MyType> {
    @Override
    protected void serializeObject(MyType value, JsonGenerator gen,
                                    SerializerProvider provider) {
        // ...
    }
}

// Jackson 3 (Spring Boot 4.0)
@JacksonComponent
public class MySerializer extends ObjectValueSerializer<MyType> {
    @Override
    protected void serializeObject(MyType value, JsonGenerator gen,
                                    SerializerProvider provider) {
        // ...
    }
}
```

### ObjectMapper Customizer

```java
// Jackson 2 (Spring Boot 3.x)
@Bean
public Jackson2ObjectMapperBuilderCustomizer customizer() {
    return builder -> builder.featuresToDisable(
        SerializationFeature.WRITE_DATES_AS_TIMESTAMPS
    );
}

// Jackson 3 (Spring Boot 4.0)
@Bean
public JsonMapperBuilderCustomizer customizer() {
    return builder -> builder.disable(
        SerializationFeature.WRITE_DATES_AS_TIMESTAMPS
    );
}
```

## Jackson 2 Compatibility Module

If full Jackson 3 migration is not yet feasible:

```xml
<!-- Maven -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-jackson2</artifactId>
</dependency>
```

```kotlin
// Gradle Kotlin DSL
implementation("org.springframework.boot:spring-boot-jackson2")
```

- Configure via `spring.jackson2.*` properties (equivalent to old `spring.jackson.*`)
- This module is **deprecated** and will be removed in a future release
- Jackson 2 `ObjectMapper` runs alongside Jackson 3 `JsonMapper`

## Spring Security Jackson Changes

```java
// Jackson 2 (Security 6.x)
ObjectMapper mapper = new ObjectMapper();
mapper.registerModules(SecurityJackson2Modules.getModules(classLoader));

// Jackson 3 (Security 7.0)
JsonMapper.Builder builder = JsonMapper.builder();
SecurityJacksonModules.configure(builder, classLoader);
JsonMapper mapper = builder.build();
```

## Spring Integration Jackson Changes

Jackson 2 based classes in Spring Integration deprecated for removal.
Key default differences in Jackson 3 for Integration:
- `WRITE_DATES_AS_TIMESTAMPS` was `true` in 2.x, now `false`
- `WRITE_DURATIONS_AS_TIMESTAMPS` was `true` in 2.x, now `false`

If your app relies on timestamp format for dates/durations, explicitly
configure these features.

## Search and Replace Patterns

For bulk migration, apply these find/replace operations:

1. `import com.fasterxml.jackson.core.` → `import tools.jackson.core.`
2. `import com.fasterxml.jackson.databind.` → `import tools.jackson.databind.`
3. `import com.fasterxml.jackson.datatype.` → `import tools.jackson.datatype.`
4. `import com.fasterxml.jackson.dataformat.` → `import tools.jackson.dataformat.`
5. `import com.fasterxml.jackson.module.` → `import tools.jackson.module.`
6. Do NOT change `import com.fasterxml.jackson.annotation.` — it stays the same
7. `@JsonComponent` → `@JacksonComponent`
8. `@JsonMixin` → `@JacksonMixin`
9. `JsonObjectSerializer` → `ObjectValueSerializer`
10. `JsonObjectDeserializer` → `ObjectValueDeserializer`
11. `Jackson2ObjectMapperBuilderCustomizer` → `JsonMapperBuilderCustomizer`

## Maven Dependency Changes

```xml
<!-- Jackson 2 (remove these) -->
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.datatype</groupId>
    <artifactId>jackson-datatype-jsr310</artifactId>
</dependency>

<!-- Jackson 3 (replacements — usually managed by Boot BOM) -->
<dependency>
    <groupId>tools.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
</dependency>
<dependency>
    <groupId>tools.jackson.datatype</groupId>
    <artifactId>jackson-datatype-jsr310</artifactId>
</dependency>
```

Note: If using Boot's starter (`spring-boot-starter-jackson`), these are
managed automatically — no explicit declaration needed.

## Auto-Module Detection

Jackson 3 automatically detects and registers all Jackson modules present
on the classpath. This is different from Jackson 2 where modules had to be
registered explicitly (Boot auto-configured this, but custom `ObjectMapper`
instances did not).

To disable automatic module detection:
```properties
spring.jackson.find-and-modules=false
```

## Automated Migration with OpenRewrite

For large codebases, use the OpenRewrite recipe to automate the mechanical
Jackson 2 → 3 migration:

```xml
<!-- Maven -->
<plugin>
    <groupId>org.openrewrite.maven</groupId>
    <artifactId>rewrite-maven-plugin</artifactId>
    <configuration>
        <activeRecipes>
            <recipe>org.openrewrite.java.jackson.UpgradeJackson_2_3</recipe>
        </activeRecipes>
    </configuration>
</plugin>
```

This handles package renames, import changes, and API migrations
automatically. Review the diff after running — some custom serializer
logic may still need manual adjustment.
