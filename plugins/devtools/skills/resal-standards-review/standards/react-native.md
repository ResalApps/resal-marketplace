# Resal React Native Standards

> **Inherits [`core.md`](core.md).** Read core first. Tags: **[STANDARD]** / **[GOOD-TO-HAVE]** / **[NICE-TO-HAVE]** / **⚠️**.
>
> **Baseline:** **`resal-mobile`** — Expo SDK 53 managed workflow, the modern source of truth. The legacy bare-RN apps (`ResalMobileApp` RN 0.64 / Redux+axios, `PartnerMobileApp` RN 0.61) are **not** the standard.
>
> This stack is **GraphQL-first** (graphql-codegen → React Query hooks over a custom `fetch`), styling is **`twrnc`** (Tailwind-in-StyleSheet, not NativeWind), navigation is **React Navigation v6** (not expo-router).

## Stack [STANDARD]

Expo **managed workflow** (SDK 53, Hermes, **EAS Build + EAS Update/OTA**) · React Native 0.79 · React 19 · **React Navigation v6** (native-stack + bottom-tabs) · **React Query** (server state, persisted) · **Zustand** (client state, `persist`) · **react-hook-form + zod** · **graphql-codegen → typed RQ hooks** over `utils/fetcher.ts` · **`twrnc`** Tailwind · `expo-secure-store` + `expo-local-authentication` · Sentry · OpenFeature/Unleash · `react-native-dotenv`. Node pinned (`engines.node`).

**Convention:** `app.config.js` (JS config, not static `app.json`); native `/ios` `/android` are **gitignored**, regenerated via `expo prebuild --clean`. EAS Update channels map to env (`production`/`staging`/…); `runtimeVersion` + `appVersionSource:"remote"`.

## 1. Structure & navigation [STANDARD]

Flat top-level domain folders (no `src/`): `navigation/ screens/ components/ hooks/ stores/ utils/ style/ constants/ localization/ graphql/`. The API layer lives in `utils/fetcher.ts` + per-feature `utils/*-infinite-query.ts` + generated `graphql/`.

**Navigation:** nested native-stacks under one root; **every navigator is typed** — `createNativeStackNavigator<XStackParams>()` with an exported `XStackParams` union; nested stacks use `NavigatorScreenParams<>`; cross-stack typing via `CompositeNavigationProp`; modals via a `Group screenOptions={{ presentation:'modal' }}`. **Deep linking** centralized as a typed `LinkingOptions<RootParamList>` (prefixes + per-stack `config.screens`).

## 2. Naming [STANDARD]

Screens suffixed `*Screen` in `screens/<feature>/`; components `components/<name>/<name>.tsx` + co-located `<name>.spec.tsx`; hooks `use*`; Zustand stores `*Store.tsx` exposing `use<X>Store`; per-feature `utils/<feature>-infinite-query.ts`. Barrel-export each dir. ⚠️ **Pick one casing** (PascalCase for components/screens, camelCase for hooks/utils) — the baseline mixes `OrdersScreen` / `cardScreen` / `app-wrapper`.

## 3. Components [STANDARD]

Function components only; props via explicit `interface XProps`; screen props typed from the nav stack (`NativeStackNavigationProp<RootStackParams>`). Variant-driven components use a lookup-schema object (good). **List perf:** memoize `renderItem`/`keyExtractor`/`ListEmptyComponent`/`ListFooterComponent` with `useCallback`, derived data with `useMemo`. **[GOOD-TO-HAVE]** use `FlashList` for long lists (⚠️ baseline is all `FlatList`); apply `React.memo` on hot list rows (⚠️ virtually unused).

## 4. State [STANDARD]

**React Query = server state, Zustand = client state**; both persisted to storage. Configure the QueryClient once in `App.tsx` with a **global error handler that logs out on auth error** and a bounded cache. Zustand stores use `persist` + `createJSONStorage`, narrow selectors (`useStore(s => s.x)`), `getState()` outside React, and an `_hydrated` flag via `onRehydrateStorage`. ⚠️ Set a global `retry`/`networkMode` policy (defaults today).

```tsx
// App.tsx
const queryClient = new QueryClient({ defaultOptions: { queries: {
  onError: async (e) => { if (e.message.startsWith('Access denied!')) { useTokenStore.getState().clearTokens();
    await SecureStore.deleteItemAsync(REFRESH_TOKEN_KEY); } },
  cacheTime: 1000*60*60*24 }}});
```

## 5. Data / API layer (GraphQL over `fetch`) [STANDARD]

Single network client `utils/fetcher.ts`: refresh-before-request (`assertFreshTokens()`), token from Zustand (`getState()`), device/version headers, normalize GraphQL `errors[]`, Sentry on failure, thread `AbortSignal`. Base URL from env (`react-native-dotenv`). **graphql-codegen → typed React Query hooks** wired to `fetcher`; infinite lists get a dedicated helper. Serialized **token-refresh queue** with a skew window; 401/`Access denied!` → logout. Network errors debounced into one global alert.
⚠️ **Don't `console.log` queries/variables in production** (PII leak). ⚠️ Add offline/NetInfo awareness (installed but unused).

## 6. Forms & validation [STANDARD]

react-hook-form + zod via `zodResolver`; **schema is a function of the translator `t`** so messages localize; form type is always `z.infer<ReturnType<typeof XSchema>>`; inputs `Controller`-wrapped. reCAPTCHA gates auth.

## 7. Styling / theming & RTL [STANDARD]

**`twrnc`** single instance from `tailwind.config.js`, imported app-wide as `@tw`; design tokens in `constants/colors` shared into the Tailwind config; `react-native-safe-area-context` for insets; `Dimensions` for responsive. ⚠️ **RTL must use `I18nManager`** for true mirrored layout — the baseline approximates RTL per-component (`text-left`), which is fragile. ⚠️ Implement a real dark theme if `userInterfaceStyle:'automatic'` is declared.

## 8. Navigation & auth-guarding [STANDARD]

⚠️ Prefer a **conditional auth-stack / app-stack switch** keyed on `loggedIn()` over mixing auth + app routes in one stack with per-screen `ProtectedScreen` guards (the baseline's fragile approach). Typed params + centralized deep-link config throughout.

## 9. TypeScript [STANDARD]

`strict: true` + `strictNullChecks` + `noImplicitAny`, `moduleResolution:"bundler"`, path aliases (`@tw`, `@i18n`) kept in sync in `tsconfig.json` **and** `babel.config.js`. `tsc --noEmit` in pre-commit + CI. GraphQL + navigation fully typed. ⚠️ Eliminate `any` (~62 in baseline) — prefer `unknown` + narrowing (as `fetcher.ts` already models).

## 10. i18n / localization [STANDARD]

Type-safe in-house i18n: JSON dictionaries `localization/{ar,en}.json` + a `useTranslation` hook exposing `t`, `locale`, `toCurrency`; **dotted-path keys are type-checked**. Initial locale from `expo-localization`; language change persisted server-side then `invalidateQueries(['Me'])`; native locales wired via `app.config.js`. ⚠️ Missing keys should fail loudly (not silently return a placeholder).

## 11. Secure storage & mobile security [STANDARD — high-stakes]

- **Tokens & sensitive data in `expo-secure-store` (Keychain/Keystore)**, gated by `expo-local-authentication` (`biometricsSecurityLevel:'strong'`, `disableDeviceFallback:true`).
- ⚠️ **CRITICAL: do NOT persist live `accessToken`/`refreshToken` (or PII-bearing React Query cache) to AsyncStorage in plaintext** — the baseline does this in `tokenStore` while only the biometric refresh token uses SecureStore. Move session tokens to SecureStore/encrypted storage.
- ⚠️ **Do NOT commit `.env*`** — `react-native-dotenv` inlines values into the JS bundle; baseline commits `.env`/`.env.staging`/`.env.production` with live third-party tokens. Read build-time secrets from CI `process.env` (as `app.config.js` already does for Sentry).
- **[GOOD-TO-HAVE]** `preventScreenCaptureAsync` on payment/card screens (baseline only *detects* screenshots); certificate/SSL pinning; reCAPTCHA + device fingerprint (present).

## 12. Error handling & crash reporting [STANDARD]

Sentry initialized in `App.tsx` (`enabled:!__DEV__`, env+release+`dist`=update id, navigation integration, runtime-tunable sample rate via flag), app wrapped with `Sentry.wrap`. ⚠️ **Add a React error boundary with fallback UI** (`Sentry.ErrorBoundary`) — baseline has none, so a render error white-screens. Explicit loading/empty states via `ListEmptyComponent` + skeletons + `RefreshControl`; one global alert; maintenance/forced-update gating + OTA-update screen.

## 13. Performance [STANDARD]

Hermes on; Metro `inlineRequires:true`; memoized list callbacks + infinite scroll; narrow Zustand selectors + RQ `notifyOnChangeProps`. **[GOOD-TO-HAVE]** `FlashList` for large lists; standardize on `expo-image` (partial today); enable Android Proguard/R8 for release; `React.memo` on hot rows; lazy/`React.lazy` heavy screens.

## 14. Testing [STANDARD]

Jest + `@testing-library/react-native` (+ jest-native), preset `jest-expo`; tests co-located `*.spec.tsx`; **MSW v2** for network mocking; shared `setUpTest`/`testUtils`. ⚠️ Add a **coverage gate** and **Detox e2e** (neither present).

## 15. Tooling [STANDARD]

Prettier (`singleQuote`, `trailingComma:es5`); Husky pre-commit runs `typecheck` + lang-check. ⚠️ **Add ESLint** (baseline has none — relies on tsc+Prettier only), **commitlint**, and **lint-staged**. EAS profiles per env; env via `.env`/`.env.staging`/`.env.production` (but **uncommitted** — see §11); `patch-package` in `postinstall`; `env.d.ts` types the dotenv module.

## Capability matrix (resal-mobile)

| Capability | Status |
|---|---|
| Expo managed + EAS Build/Update | ✅ |
| React Navigation v6 (typed) + deep linking | ✅ |
| React Query (persisted) + Zustand (persist) | ✅ |
| RHF + zod (t-localized) | ✅ |
| graphql-codegen → RQ hooks over `fetcher` | ✅ |
| SecureStore + biometric | ✅ (⚠️ live tokens in AsyncStorage) |
| Type-safe i18n | ✅ (⚠️ RTL per-component, not I18nManager) |
| Sentry | ✅ (⚠️ no error boundary) |
| ESLint / commitlint / coverage gate / Detox | ❌ |
| FlashList / expo-image / Proguard | partial/❌ |

## React-Native anti-patterns (+ core §15)

⚠️ **live tokens persisted to AsyncStorage plaintext** (high) · **committed `.env*` with live tokens + bundle-inlined secrets** (high) · **no React error boundary** (high) · **no ESLint / commitlint / lint-staged** (high) · `console.log` of GraphQL queries in all builds (PII) · no SSL pinning; screenshot detected-not-prevented on sensitive screens · auth+app routes share one stack · RTL per-component not `I18nManager`; dark mode declared-not-implemented · no offline/NetInfo or RQ retry policy · ~62 `any` despite strict · `FlatList` everywhere / `React.memo` unused / partial `expo-image` / Proguard off / no Detox · inconsistent file casing.

## Checklists

**New app:** Expo managed + EAS Build/Update + pinned Node · typed React Navigation v6 + deep-link config (or conditional auth/app stacks) · React Query (global auth-error logout + retry policy) + Zustand `persist` · RHF + zod (t-localized) · graphql-codegen → RQ hooks over one `fetcher` (refresh gate, AbortSignal, no prod query logging) · `twrnc` + single token source + **I18nManager RTL** + dark theme · type-safe i18n · **SecureStore for live tokens** (never AsyncStorage) + biometric + uncommitted `.env*` + CI build-time secrets · Sentry + **error boundary** · Jest + RTL + MSW + coverage gate (+ Detox) · ESLint + Prettier + commitlint + lint-staged + husky.

**New screen:** `*Screen` in `screens/<feature>/` + typed nav props · RQ hook (+ infinite-query helper) · zod form · loading/empty/error states · co-located `*.spec.tsx` · `ProtectedScreen`/stack guard if auth-gated.
