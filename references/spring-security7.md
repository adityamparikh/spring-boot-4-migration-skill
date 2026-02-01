# Spring Security 7 Migration Reference

Spring Boot 4.0 ships with Spring Security 7.0.

## Preparation Strategy

Security 6.5 provides preparation steps that let you adopt 7.0 changes
incrementally with opt-out flags. If security migration is complex,
consider upgrading to 6.5 first, applying preparation steps, then moving
to 7.0.

## Breaking Changes

### Authorization API

```java
// REMOVED: AuthorizationManager#check
AuthorizationDecision decision = manager.check(authentication, object);

// Use instead: AuthorizationManager#authorize
AuthorizationDecision decision = manager.authorize(authentication, object);
```

### Legacy Access Decision API

`AccessDecisionManager` and `AccessDecisionVoter` require explicit dependency:
```xml
<dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-access</artifactId>
</dependency>
```

These have been deprecated since Security 5.5. Migrate to `AuthorizationManager`.

### Security DSL — `and()` Removed

```java
// REMOVED — and() chaining
http.authorizeHttpRequests()
    .requestMatchers("/public/**").permitAll()
    .and()
    .formLogin()
    .and()
    .httpBasic();

// Use lambda DSL instead
http
    .authorizeHttpRequests(auth -> auth
        .requestMatchers("/public/**").permitAll()
        .anyRequest().authenticated()
    )
    .formLogin(Customizer.withDefaults())
    .httpBasic(Customizer.withDefaults());
```

### Request Matchers

```java
// REMOVED
new AntPathRequestMatcher("/admin/**")
new MvcRequestMatcher(introspector, "/admin/**")

// Use instead
PathPatternRequestMatcher.withPattern("/admin/**")
// Or in DSL:
.requestMatchers("/admin/**")  // uses PathPattern by default
```

### Jackson Migration

```java
// Security 6.x (Jackson 2)
ObjectMapper mapper = new ObjectMapper();
mapper.registerModules(SecurityJackson2Modules.getModules(classLoader));

// Security 7.0 (Jackson 3)
JsonMapper.Builder builder = JsonMapper.builder();
SecurityJacksonModules.configure(builder, classLoader);
JsonMapper mapper = builder.build();
```

### Spring Authorization Server

Now part of Spring Security itself:
- Remove `spring-authorization-server.version` property override
- Use `spring-security.version` to override version
- Starter renamed: `spring-boot-starter-security-oauth2-authorization-server`

### SAML

- OpenSAML 4 removed → migrate to OpenSAML 5
- `Saml2AuthenticationTokenConverter` no longer processes GET requests by default
- `Saml2AuthenticatedPrincipal` replaced by `Saml2AssertionAuthentication` which implements `Saml2ResponseAssertionAccessor`

### Session Management

`SessionLimit` functional interface provides flexible session control.
Integer-based API still supported but functional approach preferred:

```java
http.sessionManagement(session -> session
    .sessionLimit(SessionLimit.of(user -> {
        // Dynamic limit per user
        return user.getAuthorities().contains(new SimpleGrantedAuthority("ADMIN")) ? 5 : 1;
    }))
);
```

### XML Namespace

Update schema reference to Security 7.0:
```xml
<beans:beans xmlns="http://www.springframework.org/schema/security"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.springframework.org/schema/security
        https://www.springframework.org/schema/security/spring-security-7.0.xsd">
```

## Common Migration Patterns

### WebSecurityConfigurerAdapter (Should Already Be Gone)

If `WebSecurityConfigurerAdapter` survived from Boot 2.x:
```java
// REMOVED long ago — if still present, migrate:
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) { ... }
}

// Boot 4 / Security 7
@Configuration
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/**").authenticated()
            .anyRequest().permitAll()
        );
        return http.build();
    }
}
```

### Method Security

```java
// Verify @EnableMethodSecurity is used (not @EnableGlobalMethodSecurity)
@Configuration
@EnableMethodSecurity
public class MethodSecurityConfig { }
```

## Checklist

- [ ] `and()` calls removed from security DSL
- [ ] Using lambda DSL everywhere
- [ ] `AntPathRequestMatcher` / `MvcRequestMatcher` → `PathPatternRequestMatcher`
- [ ] `AuthorizationManager#check` → `#authorize`
- [ ] Jackson 2 security modules → Jackson 3 `SecurityJacksonModules`
- [ ] Authorization Server starter renamed
- [ ] XML schema updated to 7.0 (if using XML)
- [ ] OpenSAML migrated to 5 (if using SAML)
