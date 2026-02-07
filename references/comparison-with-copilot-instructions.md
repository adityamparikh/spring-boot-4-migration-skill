# Spring Boot 4 Migration: Claude Code Skill vs. GitHub Copilot Instructions — FAQ

A comparison between this Claude Code skill ([adityamparikh/spring-boot-4-migration-skill](https://github.com/adityamparikh/spring-boot-4-migration-skill)) and the [awesome-copilot-instructions](https://github.com/OctopBP/awesome-copilot-instructions/blob/main/spring-boot-4/.instructions.md) Spring Boot 4 migration guide for GitHub Copilot.

---

## At a Glance

| Dimension | GitHub awesome-copilot | This Skill |
|---|---|---|
| **Format** | Single `.instructions.md` file (~1,500 lines) | Multi-file skill: `SKILL.md` + 13 reference docs + verification script |
| **Target Tool** | GitHub Copilot (VS Code instructions) | Claude Code (`claude install-skill`) |
| **Build System Focus** | Gradle Kotlin DSL + `libs.versions.toml` only | Both Maven and Gradle |
| **Language Bias** | Kotlin-first (all examples in Kotlin) | Java and Kotlin |
| **Migration Strategy** | Linear checklist (pre-migration, core, verify) | Two strategies: all-at-once (9 phases) or gradual upgrade (Day-1 baseline + 6 independent tracks) |
| **Scope** | Spring Boot 4.0 only | 4.0 GA + minor version tracking (4.1, 4.2+) |
| **Verification** | Manual `./gradlew clean build` | `verify_migration.sh` script with PASS/FAIL/WARN/BRIDGE checks |
| **Enterprise Support** | None | Wave-based rollout strategy for organizations |
| **Sources Cited** | Spring Boot wiki + Jackson wiki | 9+ official sources cross-referenced |

---

## General Questions

### What is the GitHub awesome-copilot Spring Boot 4 instruction?

It is a single `.instructions.md` file (~1,500 lines) from the [awesome-copilot-instructions](https://github.com/OctopBP/awesome-copilot-instructions) community repository. You drop it into `.github/instructions/` in a VS Code workspace and GitHub Copilot uses it as context when assisting with Spring Boot 4 migration. It is a comprehensive reference document covering core breaking changes with inline Kotlin code examples and Gradle Kotlin DSL snippets.

### How does this Claude Code skill differ in format?

This skill uses a modular multi-file architecture: a main `SKILL.md` orchestrator plus 13 dedicated reference documents and a verification shell script. Claude Code loads only the relevant reference files per migration phase rather than ingesting one massive document at once.

### Can I use both together?

They target different tools (Copilot vs. Claude Code), so they cannot be used simultaneously in the same IDE session. However, the content is complementary — teams using Copilot could still consult this skill's reference docs manually, and vice versa.

---

## Coverage & Content

### What do both guides cover equally well?

Both cover the core Spring Boot 4 breaking changes thoroughly:

- **Modular starters** — renamed starters (`spring-boot-starter-web` to `spring-boot-starter-webmvc`), classic starters as bridge, technology-specific test starters
- **Jackson 3 migration** — package namespace change (`com.fasterxml.jackson` to `tools.jackson`), annotation renames (`@JsonComponent` to `@JacksonComponent`), `spring-boot-jackson2` compatibility module
- **Property changes** — MongoDB restructuring, Spring Session renames, Kafka retry `random` to `jitter`
- **Package relocations** — `BootstrapRegistry`, `EnvironmentPostProcessor`, `EntityScan`
- **Testing changes** — `MockitoExtension` requirement, explicit `@AutoConfigureMockMvc`/`@AutoConfigureWebTestClient`, `RestTestClient` replacement
- **Removed features** — Undertow, Spock, executable jar launch scripts, classic uber-jar loader
- **Elasticsearch** — `RestClient` to `Rest5Client`
- **JSpecify nullability annotations**
- **Health probes enabled by default**

### What does the Copilot guide have that this skill doesn't?

The Copilot guide includes several granular items not yet covered (or covered less deeply) here:

1. **Granular `libs.versions.toml` snippets** — Every migration step includes exact TOML and `build.gradle.kts` changes side by side, very copy-paste friendly for Gradle Kotlin DSL users.
2. **Jersey + Jackson 3 incompatibility** — Explicit callout that Jersey 4.0 doesn't support Jackson 3 yet, with the `spring-boot-jackson2` workaround specifically for Jersey.
3. **`HttpMessageConverters` deprecation** — Migration to the new split `ClientHttpMessageConvertersCustomizer` / `ServerHttpMessageConvertersCustomizer` pattern.
4. **`PropertyMapper` behavioral change** — Documents the subtle null-handling change and the `.always()` migration pattern, referencing the specific Spring Boot commit.
5. **Kafka Streams `StreamsBuilderFactoryBeanConfigurer`** — Migration from the deprecated `StreamBuilderFactoryBeanCustomizer`.
6. **RabbitMQ retry customizer split** — `RabbitRetryTemplateCustomizer` to separate `RabbitTemplateRetrySettingsCustomizer` / `RabbitListenerRetrySettingsCustomizer`.
7. **Spring Retry to Framework 7 core retry** — Includes both the recommended migration path (Spring Framework `RetryTemplate`) and the temporary explicit-version fallback.
8. **Spring Authorization Server** — Now managed under Spring Security 7 versioning, no longer separately versioned.
9. **Hibernate dependency renames** — `hibernate-jpamodelgen` to `hibernate-processor`, removal of `hibernate-proxool` and `hibernate-vibur`.
10. **Optional dependencies in uber jars** — `includeOptional` flag change in `bootJar`.
11. **DevTools LiveReload disabled by default**
12. **Logback UTF-8 default charset**
13. **Static resource `/fonts/**` addition** and security configuration implications.
14. **Complete "Common Pitfalls" section** with 10 numbered gotchas for quick reference.
15. **Inline before/after code examples for every change** — full Kotlin code blocks, not just instructions.

### What does this skill have that the Copilot guide doesn't?

This skill covers significantly more ground beyond the core breaking changes:

1. **Structured multi-file architecture** — 13 dedicated reference files (`jackson3-migration.md`, `spring-security7.md`, `testing-migration.md`, `observability-migration.md`, etc.) let the LLM load only what's relevant rather than parsing one massive file.
2. **Two migration strategies** — The gradual upgrade with Day-1 baseline + 6 independent tracks is a major differentiator for teams that can't do a big-bang migration.
3. **Spring Security 7 dedicated guide** — DSL migration, request matchers, breaking changes. The Copilot guide barely mentions Security beyond OAuth starter renames.
4. **Spring Framework 7 coverage** — Path matching changes, Hibernate 7.1 integration, resilience features. The Copilot guide treats Framework 7 as a footnote.
5. **Observability/OpenTelemetry migration** — Dedicated guide for OTLP, Micrometer updates, Actuator decoupling. The Copilot guide only lists the new module artifacts.
6. **HTTP clients guide** — `RestClient`, `WebClient`, `@HttpExchange`, Feign migration in a dedicated document.
7. **API versioning** — Native API versioning strategies, semantic ranges, testing patterns. Not in the Copilot guide at all.
8. **Resilience migration** — Spring Retry to Framework 7 retry, `@Retryable`, `@ConcurrencyLimit`. The Copilot guide covers the dependency change but not the code patterns.
9. **AOT/Native image** — AOT processing, `BeanRegistrar`, `RuntimeHints`, GraalVM 25 considerations.
10. **Minor version roadmap** — Bridge removal timelines, deprecation promotions for 4.1, 4.2+. Forward-looking in a way the static Copilot instruction is not.
11. **Verification script** — `verify_migration.sh` checks for bridge usage, validates migration completeness, and outputs structured PASS/FAIL/WARN/BRIDGE results.
12. **Enterprise rollout** — Wave-based deployment strategy for organizations with many microservices.
13. **Compatibility bridge awareness** — `spring-boot-starter-classic`, `spring-boot-jackson2`, `spring-security-access` treated as first-class concepts with removal timelines.

---

## Architecture & Design Philosophy

### How is the Copilot guide structured?

It's a single monolithic instruction file that Copilot loads as context for the entire workspace. There is no phased loading — Copilot sees all ~1,500 lines at once.

**Strengths:**
- Zero friction — one file, drop it in `.github/instructions/`, done
- Every change has inline code — no need to look elsewhere
- Very Gradle/Kotlin focused — no ambiguity about which build system
- Strong "Common Pitfalls" and "Performance Considerations" sections
- Migration checklist at the end is thorough

**Weaknesses:**
- ~1,500 lines in a single file is a lot of context to load at once
- No phased migration strategy — it's "do all the things"
- Kotlin-only examples (no Java)
- No verification tooling
- No coverage of Security 7, Framework 7, observability, or native image changes
- Static — doesn't account for 4.1/4.2 evolution

### How is this Claude Code skill structured?

It uses a modular skill with a main `SKILL.md` orchestrator that references topic-specific documents. Claude Code loads what's needed per-phase.

**Strengths:**
- Modular architecture lets the agent load relevant context per task
- Two migration strategies accommodate different team situations
- Covers the full ecosystem (Security 7, Framework 7, observability, native, resilience)
- Forward-looking with minor version tracking
- Verification script provides automated validation
- Enterprise-ready with rollout planning

**Weaknesses:**
- More complex to contribute to / maintain (13+ files)
- Requires Claude Code specifically (not portable to Copilot)
- The README is the primary documentation — harder to evaluate without reading every reference file
- Some of the granular before/after code snippets (like Jersey+Jackson, PropertyMapper, HttpMessageConverters) from the Copilot guide are missing or less detailed

---

## Build Systems & Languages

### Which build systems does each guide support?

The **Copilot guide** targets Gradle Kotlin DSL exclusively, with `libs.versions.toml` snippets throughout. Maven users get no direct guidance.

**This skill** supports both Maven and Gradle. The `build-and-dependencies.md` reference covers both build systems, and the verification script works regardless of build tool.

### Which languages does each guide support?

The **Copilot guide** is Kotlin-first — all examples are in Kotlin. Java users must mentally translate.

**This skill** covers both Java and Kotlin, including Kotlin-specific concerns like `spring-boot-starter-kotlin-serialization` and JSpecify nullability interaction with Kotlin's type system.

---

## Migration Strategy

### Does the Copilot guide support gradual migration?

No. It provides a single linear checklist: pre-migration checks, core changes, then verification. It's designed for a complete migration in one pass.

### Does this skill support gradual migration?

Yes. This is a key differentiator. The skill offers two strategies:

1. **All-at-once** — 9 sequential phases, best for small or greenfield projects
2. **Gradual upgrade** — Day-1 baseline using compatibility bridges gets you running on Boot 4 quickly, then 6 independent tracks can be completed over time by different teams

The gradual strategy is particularly valuable for enterprise teams with large codebases or many microservices.

---

## Verification & Tooling

### How does each guide handle verification?

The **Copilot guide** recommends running `./gradlew clean build` manually and checking the output.

**This skill** includes `scripts/verify_migration.sh`, a shell script that:
- Detects remaining bridge dependencies and flags them
- Validates migration completeness across all phases
- Outputs structured PASS/FAIL/WARN/BRIDGE results
- Works with both Maven and Gradle projects

---

## Enterprise & Forward-Looking

### Does the Copilot guide cover enterprise rollout?

No. It is focused on a single project's migration without organizational rollout considerations.

### Does this skill cover enterprise rollout?

Yes. The `gradual-upgrade-strategy.md` reference includes a wave-based rollout strategy for organizations with many microservices, including guidance on which services to migrate first and how to manage bridges across a fleet.

### Which guide tracks future Spring Boot versions?

Only this skill. The `minor-version-changes.md` reference tracks changes per 4.x minor version, including bridge removal timelines, deprecation promotions, and new features. The Copilot guide covers 4.0 only.

---

## Gaps & Improvement Opportunities

### What could be added to this skill based on the Copilot guide?

These items from the Copilot guide would make this skill strictly more comprehensive:

1. **Jersey + Jackson 3 incompatibility** — Add to `jackson3-migration.md`
2. **`HttpMessageConverters` to `ClientHttpMessageConvertersCustomizer` / `ServerHttpMessageConvertersCustomizer`** — Add to `api-changes.md`
3. **`PropertyMapper` null-handling behavioral change** with `.always()` — Add to `api-changes.md`
4. **Kafka `StreamsBuilderFactoryBeanConfigurer`** and **RabbitMQ retry customizer split** — Verify coverage and add if missing
5. **DevTools LiveReload disabled by default** — Add to `property-changes.md`
6. **Logback UTF-8 default** — Minor but worth noting
7. **Static resources `/fonts/**`** addition — Add to security or web changes
8. **Optional dependencies in uber jars** (`includeOptional`) — Add to `build-and-dependencies.md`
9. **Hibernate `hibernate-processor` rename** and removed artifacts — Add to `build-and-dependencies.md`
10. **Spring Authorization Server version management change** — Add to `spring-security7.md`

Adding these would close the gap entirely and make this skill a superset of the Copilot guide, with the added benefit of phased migration, verification tooling, and ecosystem coverage.

### What could be added to the Copilot guide based on this skill?

The Copilot guide would benefit from:
- A gradual migration strategy
- Security 7, Framework 7, and observability coverage
- Verification tooling
- Java examples alongside Kotlin
- Minor version tracking
- Enterprise rollout planning
- Maven support
