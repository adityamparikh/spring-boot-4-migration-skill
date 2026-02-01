# Minor Version Changes (4.x)

This file tracks breaking changes, deprecation removals, new defaults,
and notable features for each Spring Boot 4.x minor version beyond 4.0.

When upgrading to a new minor version, review the relevant section below
AND consult the official release notes for the target version.

## How to Use This File

1. Find the section for your **target** version.
2. Check "Breaking Changes" — these MUST be addressed before upgrading.
3. Check "Bridge Removals" — if you depend on a bridge being removed,
   complete the migration track first.
4. Check "Deprecations" — these still work but signal what will break
   in the next minor version.
5. Check "New Features" — opt-in improvements you may want to adopt.

## General Minor Version Upgrade Process

```
1. Read this file for the target version
2. Read the official release notes:
   https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-{VERSION}-Release-Notes
3. Update Spring Boot version in build file
4. Fix compilation errors
5. Run full test suite
6. Review deprecation warnings (build output + application logs)
7. Run verify_migration.sh
```

---

## Spring Boot 4.1

**Status**: Not yet released. Expected mid-2026 based on historical
release cadence (Spring Boot typically ships minor versions every ~6 months).

**Official release notes**: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.1-Release-Notes
(will be available when released)

### Anticipated Changes

Based on the 4.0 deprecation timeline and Spring team communications:

#### Bridge Removals (Likely)

| Bridge | Status in 4.0 | Expected in 4.1 |
|--------|--------------|-----------------|
| `spring-boot-jackson2` | Deprecated | Possible removal — prioritize Jackson 3 migration (Track B) |

**Action required**: If you are still using `spring-boot-jackson2`, complete
Track B (Jackson 3 migration) before upgrading to 4.1. Check the official
4.1 release notes when available to confirm.

#### Known Deprecation Promotions

Items deprecated in 4.0 that may see further action in 4.1:
- Deprecated starter names (e.g., `spring-boot-starter-web`) — still
  expected to work in 4.1, removed in 5.0
- `spring-boot-starter-classic` / `spring-boot-starter-test-classic` —
  still expected to work in 4.1, removed in 5.0

#### New Features to Watch For

Spring Boot minor versions typically introduce:
- New auto-configuration modules
- Additional starter modules
- Updated dependency versions (Spring Framework, Hibernate, etc.)
- New properties and configuration options
- Performance improvements

### Upgrade Checklist for 4.0 → 4.1

- [ ] Confirm `spring-boot-jackson2` bridge status in official release notes
- [ ] Complete Track B (Jackson 3) if bridge is removed
- [ ] Update Spring Boot version to 4.1.x
- [ ] Run full build and test suite
- [ ] Review new deprecation warnings
- [ ] Check for updated dependency minimum versions
- [ ] Run `verify_migration.sh`

---

## Spring Boot 4.2

**Status**: Not yet released.

**Official release notes**: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.2-Release-Notes
(will be available when released)

### Anticipated Changes

#### Bridge Removals (Likely)

| Bridge | Status | Expected in 4.2 |
|--------|--------|-----------------|
| `spring-boot-jackson2` | If not removed in 4.1 | Removal likely |

#### Upgrade Checklist

- [ ] Review 4.2 release notes
- [ ] Verify all bridges still in use are supported
- [ ] Update version and run full build
- [ ] Review deprecation warnings for 4.3/5.0 signals

---

## Template for Future Versions

When a new Spring Boot 4.x minor version is released, add a section
following this template:

```markdown
## Spring Boot 4.N

**Release date**: YYYY-MM-DD
**Official release notes**: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.N-Release-Notes

### Breaking Changes

List any changes that will cause compilation errors or runtime failures.

### Bridge Removals

| Bridge | Status |
|--------|--------|
| ... | Removed / Still available |

### Deprecations

List newly deprecated APIs, properties, or starters.

### New Features

Notable new features and auto-configurations.

### Dependency Version Changes

| Dependency | Old Version | New Version |
|-----------|-------------|-------------|
| ... | ... | ... |

### Upgrade Checklist for 4.(N-1) → 4.N

- [ ] Review official release notes
- [ ] Address breaking changes
- [ ] Complete migration for any removed bridges
- [ ] Update version and run full build
- [ ] Review deprecation warnings
- [ ] Run verify_migration.sh
```

---

## Official Sources for Minor Version Changes

Always cross-reference with:
- Release Notes: https://github.com/spring-projects/spring-boot/wiki
- Upgrading Guide: https://docs.spring.io/spring-boot/upgrading.html
- Spring Blog: https://spring.io/blog (announcements per release)
- Spring Boot Milestones: https://github.com/spring-projects/spring-boot/milestones
