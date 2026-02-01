#!/usr/bin/env bash
# Spring Boot 4.0 Migration Verification Script
# Run from the root of a migrated Spring Boot project.
# Usage: bash verify_migration.sh [maven|gradle]
#
# Supports both all-at-once and gradual migration strategies.
# Reports bridge status so you know which tracks are still in progress.

set -euo pipefail

BUILD_TOOL="${1:-auto}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0
BRIDGE=0

pass()   { echo -e "${GREEN}✓ PASS${NC}: $1"; ((PASS++)); }
fail()   { echo -e "${RED}✗ FAIL${NC}: $1"; ((FAIL++)); }
warn()   { echo -e "${YELLOW}⚠ WARN${NC}: $1"; ((WARN++)); }
bridge() { echo -e "${BLUE}⧖ BRIDGE${NC}: $1"; ((BRIDGE++)); }

# Detect build tool
if [ "$BUILD_TOOL" = "auto" ]; then
    if [ -f "pom.xml" ]; then BUILD_TOOL="maven"
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then BUILD_TOOL="gradle"
    else fail "Cannot detect build tool. Specify maven or gradle."; exit 1
    fi
fi

# Collect build files for searching
BUILD_FILES=""
if [ "$BUILD_TOOL" = "maven" ]; then
    BUILD_FILES=$(find . -name "pom.xml" -not -path "*/target/*" 2>/dev/null)
else
    BUILD_FILES=$(find . \( -name "build.gradle" -o -name "build.gradle.kts" \) -not -path "*/.gradle/*" 2>/dev/null)
fi

echo "=== Spring Boot 4.0 Migration Verification ==="
echo "Build tool: $BUILD_TOOL"
echo ""

# ================================================================
# SECTION 1: HARD REQUIREMENTS (must pass regardless of strategy)
# ================================================================
echo "━━━ HARD REQUIREMENTS (Day-1 Baseline) ━━━"
echo ""

# --- Check 1: Boot version ---
echo "--- Checking Spring Boot version ---"
if [ "$BUILD_TOOL" = "maven" ]; then
    BOOT_VER=$(grep -A1 'spring-boot-starter-parent' pom.xml 2>/dev/null | grep '<version>' | sed 's/.*<version>\(.*\)<\/version>.*/\1/' || echo "unknown")
elif [ "$BUILD_TOOL" = "gradle" ]; then
    BOOT_VER=$(grep -oP "org\.springframework\.boot.*version\s*['\"]?\K[0-9]+\.[0-9]+\.[0-9]+[^'\"]*" build.gradle* 2>/dev/null | head -1 || echo "unknown")
fi
if [[ "$BOOT_VER" == 4.* ]]; then pass "Spring Boot version: $BOOT_VER"
else fail "Spring Boot version is $BOOT_VER (expected 4.x)"; fi

# --- Check 2: Hard removals (no bridge possible) ---
echo ""
echo "--- Checking hard removals (no bridge available) ---"
if echo "$BUILD_FILES" | xargs grep -lq "spring-boot-starter-undertow" 2>/dev/null; then
    fail "Undertow starter found — removed in Boot 4. Use Tomcat or Jetty."
else
    pass "No Undertow dependency"
fi
if echo "$BUILD_FILES" | xargs grep -lq "loaderImplementation.*CLASSIC" 2>/dev/null; then
    fail "Classic loader implementation found — removed in Boot 4."
else
    pass "No classic loader configuration"
fi

# --- Check 3: javax.* imports ---
JAVAX_COUNT=$(grep -rn "import javax\.\(annotation\|inject\)\." src/ 2>/dev/null | wc -l || echo 0)
if [ "$JAVAX_COUNT" -gt 0 ]; then
    fail "Found $JAVAX_COUNT javax.annotation/javax.inject imports — migrate to jakarta.*"
else
    pass "No javax.annotation/javax.inject imports found"
fi

# --- Check 4: PropertyMapper.alwaysApplyingNotNull() ---
if grep -rqn "alwaysApplyingNotNull" src/ 2>/dev/null; then
    fail "PropertyMapper.alwaysApplyingNotNull() found — removed, use always()"
fi

# --- Check 5: AuthorizationManager#check ---
if grep -rqn "\.check(.*Authentication\|\.check(.*Supplier" src/ 2>/dev/null; then
    warn "Possible AuthorizationManager#check() usage — removed, use #authorize()"
fi

# ================================================================
# SECTION 2: BRIDGE STATUS (shows gradual migration progress)
# ================================================================
echo ""
echo "━━━ BRIDGE STATUS (Gradual Upgrade Tracks) ━━━"
echo ""

# --- Bridge: Classic starters (Track A) ---
echo "--- Track A: Modular Starters ---"
HAS_CLASSIC=false
if echo "$BUILD_FILES" | xargs grep -lq "spring-boot-starter-classic" 2>/dev/null; then
    bridge "spring-boot-starter-classic in use — Track A (Modular Starters) incomplete"
    HAS_CLASSIC=true
fi
if echo "$BUILD_FILES" | xargs grep -lq "spring-boot-starter-test-classic" 2>/dev/null; then
    bridge "spring-boot-starter-test-classic in use — Track A/E incomplete"
    HAS_CLASSIC=true
fi
if [ "$HAS_CLASSIC" = false ]; then
    pass "No classic starters — Track A complete"
fi

# Check deprecated starter names
# Use word-boundary-safe patterns that handle end-of-line and quote terminators
DEPRECATED_STARTERS_PATTERNS=(
    "spring-boot-starter-web[\"'<,)\s]|spring-boot-starter-web$"
    "spring-boot-starter-web-services"
    "spring-boot-starter-aop[\"'<,)\s]|spring-boot-starter-aop$"
    "spring-boot-starter-oauth2-authorization-server[\"'<,)\s]|spring-boot-starter-oauth2-authorization-server$"
    "spring-boot-starter-oauth2-client[\"'<,)\s]|spring-boot-starter-oauth2-client$"
    "spring-boot-starter-oauth2-resource-server[\"'<,)\s]|spring-boot-starter-oauth2-resource-server$"
)
DEPRECATED_STARTER_NAMES=(
    "spring-boot-starter-web (rename to spring-boot-starter-webmvc)"
    "spring-boot-starter-web-services (rename to spring-boot-starter-webservices)"
    "spring-boot-starter-aop (rename to spring-boot-starter-aspectj)"
    "spring-boot-starter-oauth2-authorization-server (rename to spring-boot-starter-security-oauth2-authorization-server)"
    "spring-boot-starter-oauth2-client (rename to spring-boot-starter-security-oauth2-client)"
    "spring-boot-starter-oauth2-resource-server (rename to spring-boot-starter-security-oauth2-resource-server)"
)
for i in "${!DEPRECATED_STARTERS_PATTERNS[@]}"; do
    if echo "$BUILD_FILES" | xargs grep -Eq "${DEPRECATED_STARTERS_PATTERNS[$i]}" 2>/dev/null; then
        warn "Deprecated starter: ${DEPRECATED_STARTER_NAMES[$i]}"
    fi
done

# Check direct autoconfigure dependency
if echo "$BUILD_FILES" | xargs grep -q "spring-boot-autoconfigure" 2>/dev/null; then
    if echo "$BUILD_FILES" | xargs grep -q "spring-boot-autoconfigure-classic" 2>/dev/null; then
        bridge "spring-boot-autoconfigure-classic in use"
    else
        warn "Direct spring-boot-autoconfigure dependency — no longer public in Boot 4"
    fi
fi

# --- Bridge: Jackson 2 (Track B) ---
echo ""
echo "--- Track B: Jackson 3 ---"
HAS_JACKSON2_BRIDGE=false
if echo "$BUILD_FILES" | xargs grep -lq "spring-boot-jackson2" 2>/dev/null; then
    bridge "spring-boot-jackson2 in use — Track B (Jackson 3) incomplete"
    HAS_JACKSON2_BRIDGE=true
fi
if grep -rqn "spring\.jackson\.use-jackson2-defaults" src/main/resources/ 2>/dev/null; then
    bridge "spring.jackson.use-jackson2-defaults=true — Jackson 2 compatibility mode active"
    HAS_JACKSON2_BRIDGE=true
fi

JACKSON2_IMPORTS=$(grep -rn "import com.fasterxml.jackson.core\.\|import com.fasterxml.jackson.databind\.\|import com.fasterxml.jackson.datatype\.\|import com.fasterxml.jackson.dataformat\.\|import com.fasterxml.jackson.module\." src/ 2>/dev/null | grep -v "import com.fasterxml.jackson.annotation" | wc -l || echo 0)
if [ "$JACKSON2_IMPORTS" -gt 0 ]; then
    if [ "$HAS_JACKSON2_BRIDGE" = true ]; then
        bridge "Found $JACKSON2_IMPORTS Jackson 2 imports — covered by jackson2 bridge"
    else
        fail "Found $JACKSON2_IMPORTS Jackson 2 imports (com.fasterxml.jackson) — migrate to tools.jackson or add spring-boot-jackson2 bridge"
    fi
    grep -rn "import com.fasterxml.jackson" src/ 2>/dev/null | grep -v "jackson.annotation" | head -5
elif [ "$HAS_JACKSON2_BRIDGE" = false ]; then
    pass "No Jackson 2 imports and no bridge — Track B complete"
fi

if grep -rn "@JsonComponent" src/ 2>/dev/null | grep -q "@JsonComponent"; then
    if [ "$HAS_JACKSON2_BRIDGE" = true ]; then
        bridge "@JsonComponent found — covered by jackson2 bridge, rename to @JacksonComponent when completing Track B"
    else
        fail "@JsonComponent found — rename to @JacksonComponent"
    fi
fi
if grep -rn "@JsonMixin" src/ 2>/dev/null | grep -q "@JsonMixin"; then
    if [ "$HAS_JACKSON2_BRIDGE" = true ]; then
        bridge "@JsonMixin found — covered by jackson2 bridge, rename to @JacksonMixin when completing Track B"
    else
        fail "@JsonMixin found — rename to @JacksonMixin"
    fi
fi

# --- Track C: Properties ---
echo ""
echo "--- Track C: Properties ---"
PROP_WARNS=0
PROP_FILES=$(find src/ -name "application*.properties" -o -name "application*.yml" 2>/dev/null)
for pf in $PROP_FILES; do
    if grep -q "spring\.data\.mongodb\.\(uri\|host\|port\|database\|username\|password\)" "$pf" 2>/dev/null; then
        warn "Old MongoDB properties in $pf — some moved to spring.mongodb.*"
        ((PROP_WARNS++))
    fi
    if grep -q "spring\.session\.redis\." "$pf" 2>/dev/null; then
        warn "Old session.redis property in $pf — moved to spring.session.data.redis.*"
        ((PROP_WARNS++))
    fi
    if grep -q "management\.health\.mongo\." "$pf" 2>/dev/null; then
        warn "Old management.health.mongo in $pf — renamed to management.health.mongodb.*"
        ((PROP_WARNS++))
    fi
    if grep -q "spring\.dao\.exceptiontranslation" "$pf" 2>/dev/null; then
        warn "spring.dao.exceptiontranslation in $pf — use spring.persistence.exceptiontranslation"
        ((PROP_WARNS++))
    fi
    if grep -q "spring\.jackson\.read\.\|spring\.jackson\.write\." "$pf" 2>/dev/null; then
        warn "Old Jackson property keys in $pf — use spring.jackson.json.read.*/spring.jackson.json.write.*"
        ((PROP_WARNS++))
    fi
done
if [ "$PROP_WARNS" -eq 0 ]; then
    pass "No deprecated property keys found — Track C complete"
fi

# --- Bridge: Security (Track D) ---
echo ""
echo "--- Track D: Security 7 ---"
HAS_SECURITY_BRIDGE=false
if echo "$BUILD_FILES" | xargs grep -lq "spring-security-access" 2>/dev/null; then
    bridge "spring-security-access in use — Track D (Security 7) incomplete"
    HAS_SECURITY_BRIDGE=true
fi
if grep -rqn "AccessDecisionManager\|AccessDecisionVoter" src/ 2>/dev/null; then
    if [ "$HAS_SECURITY_BRIDGE" = true ]; then
        bridge "Legacy AccessDecisionManager/Voter found — covered by security-access bridge"
    else
        fail "Legacy AccessDecisionManager/Voter found — migrate to AuthorizationManager or add spring-security-access bridge"
    fi
fi
# Search for .and() in files that likely contain security config
SECURITY_AND_COUNT=$(grep -rn "\.and()" src/ 2>/dev/null | grep -i "security\|HttpSecurity\|http\." | wc -l || echo 0)
if [ "$SECURITY_AND_COUNT" -gt 0 ]; then
    warn "Found $SECURITY_AND_COUNT possible and() calls in security-related files — removed in Security 7, use lambda DSL"
    grep -rn "\.and()" src/ 2>/dev/null | grep -i "security\|HttpSecurity\|http\." | head -3
fi
if [ "$HAS_SECURITY_BRIDGE" = false ] && ! grep -rqn "AccessDecisionManager\|AccessDecisionVoter" src/ 2>/dev/null; then
    pass "No security bridge and no legacy APIs — Track D baseline complete"
fi

# --- Track E: Testing ---
echo ""
echo "--- Track E: Testing ---"
MOCKBEAN_COUNT=$(grep -rn "@MockBean\b" src/test/ 2>/dev/null | wc -l || echo 0)
SPYBEAN_COUNT=$(grep -rn "@SpyBean\b" src/test/ 2>/dev/null | wc -l || echo 0)
if [ "$MOCKBEAN_COUNT" -gt 0 ]; then
    fail "Found $MOCKBEAN_COUNT @MockBean annotations — removed in Boot 4.0, migrate to @MockitoBean"
fi
if [ "$SPYBEAN_COUNT" -gt 0 ]; then
    fail "Found $SPYBEAN_COUNT @SpyBean annotations — removed in Boot 4.0, migrate to @MockitoSpyBean"
fi
if [ "$MOCKBEAN_COUNT" -eq 0 ] && [ "$SPYBEAN_COUNT" -eq 0 ]; then
    pass "No removed @MockBean/@SpyBean found"
fi

# --- Track F: Framework 7 ---
echo ""
echo "--- Track F: Framework 7 ---"
if grep -rn "import org.springframework.retry" src/ 2>/dev/null | grep -qv "org.springframework.core.retry"; then
    warn "Spring Retry imports found — consider migrating to Spring Framework core retry (Track F)"
fi
if grep -rqn "RestClientBuilderCustomizer" src/ 2>/dev/null; then
    fail "RestClientBuilderCustomizer found — migrate to Rest5ClientBuilderCustomizer"
fi
if grep -rqn "import org.springframework.lang.Nullable" src/ 2>/dev/null; then
    warn "spring.lang.Nullable found — migrate to org.jspecify.annotations.Nullable (Track F)"
fi

# ================================================================
# SECTION 3: BUILD VERIFICATION
# ================================================================
echo ""
echo "━━━ BUILD VERIFICATION ━━━"
echo ""
if [ "$BUILD_TOOL" = "maven" ]; then
    echo "Running: mvn compile -q"
    if mvn compile -q 2>/dev/null; then pass "Maven compile successful"
    else fail "Maven compile failed"; fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    echo "Running: gradle compileJava -q"
    if ./gradlew compileJava -q 2>/dev/null; then pass "Gradle compile successful"
    else fail "Gradle compile failed"; fi
fi

# ================================================================
# SUMMARY
# ================================================================
echo ""
echo "═══════════════════════════════════"
echo "          SUMMARY"
echo "═══════════════════════════════════"
echo -e "${GREEN}Passed:  $PASS${NC}"
echo -e "${RED}Failed:  $FAIL${NC}"
echo -e "${YELLOW}Warnings: $WARN${NC}"
echo -e "${BLUE}Bridges: $BRIDGE${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Migration has failures — fix before proceeding.${NC}"
    exit 1
elif [ "$BRIDGE" -gt 0 ]; then
    echo -e "${BLUE}Migration using $BRIDGE compatibility bridge(s) — gradual upgrade in progress.${NC}"
    echo -e "${BLUE}Complete remaining tracks to remove bridges. See references/gradual-upgrade-strategy.md${NC}"
    exit 0
elif [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}Migration mostly complete — review warnings.${NC}"
    exit 0
else
    echo -e "${GREEN}Migration fully complete — all tracks done, no bridges remaining!${NC}"
    exit 0
fi
