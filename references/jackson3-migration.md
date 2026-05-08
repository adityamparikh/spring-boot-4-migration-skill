# Jackson 3 Migration Reference

Jackson 3 is the default JSON library in Spring Boot 4.0.

## Contents

- [Group ID Changes](#group-id-changes)
- [Package Changes](#package-changes)
- [Spring Boot Class Renames](#spring-boot-class-renames)
- [Core API Changes](#core-api-changes)
- [Jackson 2 Compatibility Module](#jackson-2-compatibility-module)
- [Spring Security Jackson Changes](#spring-security-jackson-changes)
- [Spring Integration Jackson Changes](#spring-integration-jackson-changes)
- [Search and Replace Patterns](#search-and-replace-patterns)
- [Maven Dependency Changes](#maven-dependency-changes)
- [Kotlin Module Changes](#kotlin-module-changes)
- [Auto-Module Detection](#auto-module-detection)
- [Automated Migration with OpenRewrite](#automated-migration-with-openrewrite)

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

Jackson 3 uses `JsonMapper` as the primary entry point. `JsonMapper` is
**immutable** after building — configuration is locked.

```java
// Jackson 2 — mutable
ObjectMapper mapper = new ObjectMapper();
mapper.registerModule(new JavaTimeModule());
mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

// Jackson 3 — immutable builder
JsonMapper mapper = JsonMapper.builder()
    .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
    .build();
// Use mapper.rebuild() to create a new builder from existing instance
```

### Built-in Modules (No Registration Needed)

Jackson 3 merges these into jackson-databind — do NOT register them:
- `ParameterNamesModule`
- `Jdk8Module`
- `JavaTimeModule` (JSR310) — built-in as of 3.0.0-rc3

```java
// Jackson 2 — required
ObjectMapper mapper = new ObjectMapper()
    .registerModule(new ParameterNamesModule())
    .registerModule(new Jdk8Module())
    .registerModule(new JavaTimeModule());

// Jackson 3 — all built-in, just build
JsonMapper mapper = JsonMapper.builder().build();
```

### StreamReadFeature / StreamWriteFeature

Jackson 2's `JsonParser.Feature` and `JsonGenerator.Feature` are
**removed** in Jackson 3. Use the replacements:

| Removed (Jackson 2) | Replacement (Jackson 3) |
|---------------------|------------------------|
| `JsonParser.Feature.*` | `StreamReadFeature.*` (format-agnostic) or `JsonReadFeature.*` (JSON-specific) |
| `JsonGenerator.Feature.*` | `StreamWriteFeature.*` (format-agnostic) or `JsonWriteFeature.*` (JSON-specific) |

```java
// Jackson 3
JsonFactory f = JsonFactory.builder()
    .disable(StreamWriteFeature.AUTO_CLOSE_TARGET)
    .enable(JsonReadFeature.ALLOW_TRAILING_COMMA)
    .build();
```

### Default Behavior Changes

**These are the most impactful changes — they silently break tests:**

| Feature | Jackson 2 Default | Jackson 3 Default |
|---------|------------------|------------------|
| `WRITE_DATES_AS_TIMESTAMPS` | `true` (timestamps) | `false` (ISO-8601 strings) |
| `FAIL_ON_TRAILING_TOKENS` | `false` | `true` |
| `SORT_PROPERTIES_ALPHABETICALLY` | `false` | `true` |
| `ALLOW_FINAL_FIELDS_AS_MUTATORS` | enabled | disabled |
| `DEFAULT_VIEW_INCLUSION` | enabled | disabled |
| Locale serialization | `zh_CN` | `zh-CN` (LanguageTag format) |

Set `spring.jackson.use-jackson2-defaults=true` to get Jackson 2-compatible
defaults in Boot 4. Or programmatically:

```java
@Bean
public JsonMapperBuilderCustomizer jackson2Compatible() {
    return builder -> builder.configureForJackson2();
}
```

### JsonNode Changes

**Critical behavioral changes:**

| Jackson 2 | Jackson 3 |
|-----------|-----------|
| `TextNode` | Renamed to `StringNode` |
| `JsonNode.textValue()` | `JsonNode.stringValue()` — throws on NullNode |
| `JsonNode.asText()` | `JsonNode.asString()` — returns `""` for null (was `null`) |
| `JsonNode.fields()` | **Removed** — use `JsonNode.properties()` |
| `JsonNodeFactory.textNode()` | `JsonNodeFactory.stringNode()` |
| `TreeNode.isContainerNode()` | `TreeNode.isContainer()` |

**Null handling change (critical):**
```java
// Jackson 2: returns null for NullNode
node.get("password").textValue()  // → null

// Jackson 3: returns "" for NullNode
node.get("password").asString()   // → "" (empty string!)
// Use stringValue() which throws JsonNodeException for NullNode
```

### Serializer/Deserializer Renames

| Jackson 2 | Jackson 3 |
|-----------|-----------|
| `JsonSerializer<T>` | `ValueSerializer<T>` |
| `JsonDeserializer<T>` | `ValueDeserializer<T>` |
| `SerializerProvider` | `SerializationContext` |
| `JsonSerializable` | `JacksonSerializable` |
| `Module` | `JacksonModule` |
| `ResolvableDeserializer` | Removed — `resolve()` now in `ValueDeserializer` |
| `ResolvableSerializer` | Removed — `resolve()` now in `ValueSerializer` |

### Polymorphic Type Handling (Security)

Jackson 3 tightens polymorphic deserialization security:
- **Avoid** `@JsonTypeInfo(use = Id.CLASS)` — classname-based is a security risk
- **Use** `@JsonTypeInfo(use = Id.NAME)` with `@JsonSubTypes`
- Configure `PolymorphicTypeValidator` for any remaining classname-based usage

### Removed MapperFeatures

- `USE_STD_BEAN_NAMING`
- `AUTO_DETECT_CREATORS`, `AUTO_DETECT_FIELDS`, `AUTO_DETECT_GETTERS`, `AUTO_DETECT_IS_GETTERS`, `AUTO_DETECT_SETTERS`

New: `DETECT_PARAMETER_NAMES` — allows disabling parameter-names detection.

### Accessor Naming

Tighter rules: no leading lower-case or non-letter character for
getters/setters. Review custom accessors.

### Java 17 Minimum

Jackson 3 requires Java 17+ (was Java 8 for Jackson 2).

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

## Kotlin Module Changes

```xml
<!-- Jackson 2 -->
<groupId>com.fasterxml.jackson.module</groupId>
<artifactId>jackson-module-kotlin</artifactId>

<!-- Jackson 3 -->
<groupId>tools.jackson.module</groupId>
<artifactId>jackson-module-kotlin</artifactId>
```

Key behavioral changes:
- `isRequired` from kotlin-module no longer overrides
  `JacksonAnnotationIntrospector` — `@JsonProperty(required = true)` for
  nullable parameters is now determined as required
- `FAIL_ON_TRAILING_TOKENS` enabled by default (validates no extra content)

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
