# Toolchain Version Check (Java, Kotlin, Maven, Gradle)

Run this check **before** starting any migration. If any tool is below the
minimum, upgrade it BEFORE proceeding with the Spring Boot migration so
JDK/build issues surface separately from Spring upgrade churn.

## Minimum supported versions for Spring Boot 4.x

| Tool | Minimum | Recommended | How to check |
|------|---------|-------------|--------------|
| Java | 17 | 25 (LTS) — 17, 21, 25 all supported | `java -version` or `javac -version` |
| Kotlin | 2.2 | 2.2.x (latest) | Check `kotlin.version` in build file or `kotlinc -version` |
| Maven | 3.6.3 | 3.9.x+ | `mvn -version` or `./mvnw -version` |
| Gradle | 8.14 | 9.x | `gradle -version` or `./gradlew -version` |

## If older versions are detected

- **Java < 17**: Upgrade JDK before anything else. Boot 4 will not compile.
  Install JDK 25 (latest LTS, recommended) or JDK 17 (minimum). Boot 4 also
  supports JDK 21. Update `JAVA_HOME`,
  `sourceCompatibility`/`targetCompatibility` (Gradle), or
  `<maven.compiler.source>`/`<maven.compiler.target>` (Maven).
- **Kotlin < 2.2**: Update `kotlin.version` property in your build file to
  2.2.x. Spring Boot 4 requires Kotlin 2.2 baseline for JSpecify null-safety
  support. If upgrading from Kotlin 1.x, review the Kotlin 2.0 migration
  guide first.
- **Maven < 3.6.3**: Upgrade Maven wrapper: `mvn wrapper:wrapper -Dmaven=3.9.9`
  or download a newer distribution. Older Maven versions may fail to resolve
  Boot 4 dependencies or run the Boot Maven plugin.
- **Gradle < 8.14**: Upgrade Gradle wrapper:
  `./gradlew wrapper --gradle-version=9.0` (or `8.14` minimum). Older Gradle
  versions are not supported by the Spring Boot 4 Gradle plugin.

After resolving any gaps, confirm the project still compiles and tests pass
before continuing with the Spring Boot version bump.

## Note for projects on Boot 2.7.x or earlier (Java 8/11 baseline)

The table above is the destination for Boot 4. The 2 → 3 leg has its own
intermediate minimum (Java 17, Maven 3.6.3, Gradle 8.5). See
`references/spring-boot-2-to-3-migration.md` for the 2 → 3 toolchain
prerequisites table.
