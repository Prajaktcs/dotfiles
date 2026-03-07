---
name: flutter-mobile
description: Applies Flutter conventions for iOS and Android consumer apps using Bloc/Cubit for state management. Use when the user asks about Flutter widgets, Dart code, Bloc, Cubit, navigation, API integration, app architecture, performance optimization, or mobile-specific platform concerns.
---

# Flutter Mobile Skill

## When to use this skill
- Writing Flutter widgets (stateless or stateful)
- Implementing Bloc or Cubit state management
- Designing app architecture and feature folder structure
- Writing Dart code for mobile (iOS/Android)
- Handling navigation with GoRouter or Navigator 2.0
- Integrating REST APIs or platform channels
- Writing widget tests or unit tests for Blocs/Cubits

## Do not use this skill when
- Flutter Web or Desktop targets (different performance and layout considerations)
- Non-Flutter mobile work (React Native, native Swift/Kotlin)

---

## Project Structure

Use a feature-first structure — not layer-first:

```
lib/
├── core/
│   ├── api/           # HTTP client, interceptors, base models
│   ├── theme/         # Colors, typography, spacing constants
│   ├── router/        # GoRouter config and route definitions
│   ├── utils/         # Extensions, formatters, helpers
│   └── widgets/       # Shared/reusable widgets
├── features/
│   ├── auth/
│   │   ├── data/      # Repository impl, data sources, DTOs
│   │   ├── domain/    # Entities, repository interfaces, use cases
│   │   └── presentation/
│   │       ├── bloc/  # AuthBloc / AuthCubit + State + Event
│   │       └── pages/ # Screens and their local widgets
│   └── home/
│       └── ...
└── main.dart
```

- Keep `presentation/`, `domain/`, and `data/` layers per feature
- `core/` is for truly cross-cutting concerns — not a dumping ground
- Never import from another feature's `presentation/` layer directly

---

## Bloc / Cubit Conventions

### When to use which
- **Cubit**: Simple state with no complex event logic — toggles, form state, loading/error/data
- **Bloc**: Complex flows with multiple event types, transformations, or event debouncing

### State design
- Always use sealed classes (Dart 3+) for state — exhaustive pattern matching catches missing cases at compile time
- States should be immutable — use `copyWith` or `freezed`
- Never put business logic in the UI — it belongs in the Cubit/Bloc

```dart
// Cubit example with sealed state
sealed class ProductsState {}
final class ProductsInitial extends ProductsState {}
final class ProductsLoading extends ProductsState {}
final class ProductsLoaded extends ProductsState {
  final List<Product> products;
  const ProductsLoaded(this.products);
}
final class ProductsError extends ProductsState {
  final String message;
  const ProductsError(this.message);
}

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._repository) : super(ProductsInitial());

  final ProductRepository _repository;

  Future<void> loadProducts() async {
    emit(ProductsLoading());
    try {
      final products = await _repository.getProducts();
      emit(ProductsLoaded(products));
    } on AppException catch (e) {
      emit(ProductsError(e.message));
    }
  }
}
```

### BlocProvider placement
- Provide Blocs/Cubits at the route level, not above `MaterialApp` (unless truly global, e.g., auth)
- Use `BlocProvider.value` when passing an existing Bloc to a child route
- Never create a Bloc inside `build()` — use `BlocProvider` or inject via constructor

### Listening vs building
- `BlocBuilder`: rebuild UI based on state
- `BlocListener`: side effects only (navigation, snackbars, dialogs) — never rebuild UI here
- `BlocConsumer`: when you need both — keep `listenWhen` and `buildWhen` tight to avoid unnecessary rebuilds

---

## Widget Conventions

### General rules
- Prefer `StatelessWidget` — reach for `StatefulWidget` only when local ephemeral state is genuinely needed (e.g., animation controllers, focus nodes)
- Extract widgets into named classes when they exceed ~40 lines or are reused — avoid deeply nested anonymous builders
- Never put business logic or API calls inside widgets
- Use `const` constructors everywhere possible — it's free performance

### Performance
- Use `const` widgets aggressively — they're skipped in rebuild cycles
- Avoid rebuilding large subtrees; use `BlocSelector` to subscribe to only the slice of state you need
- Use `ListView.builder` / `SliverList` for any list that could exceed ~20 items
- Never call `.toList()` inside `build()` on large collections without caching

```dart
// Good: BlocSelector for targeted rebuilds
BlocSelector<CartCubit, CartState, int>(
  selector: (state) => state.itemCount,
  builder: (context, itemCount) => Badge(count: itemCount),
)
```

### Theming
- Never hardcode colors or font sizes — always use `Theme.of(context)` or a custom `AppTheme` class
- Define spacing constants in `core/theme/` — avoid magic numbers like `SizedBox(height: 16)`

```dart
// core/theme/spacing.dart
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
```

---

## Navigation (GoRouter)

- Use GoRouter for all navigation — not `Navigator.push` directly
- Define all routes in `core/router/` as named constants
- Use `redirect` for auth guard logic — not inside screens
- Pass only IDs in route parameters — fetch full objects from repository/cache in the destination screen

```dart
final router = GoRouter(
  redirect: (context, state) {
    final isAuthenticated = context.read<AuthCubit>().state is AuthAuthenticated;
    if (!isAuthenticated && !state.matchedLocation.startsWith('/auth')) {
      return '/auth/login';
    }
    return null;
  },
  routes: [...],
);
```

---

## Data Layer

### Repository pattern
- Always define a repository interface in `domain/` and implement it in `data/`
- Inject the interface into Blocs/Cubits — never the concrete implementation
- Map network/database exceptions to domain-level `AppException` types at the repository boundary — Blocs should never handle `DioException` or `SocketException` directly

### API integration
- Use `Dio` with interceptors for auth token injection, retry logic, and error normalization
- Always model API responses with typed DTOs — never pass raw `Map<String, dynamic>` across layers
- Handle 401s globally in an interceptor; handle other errors at the repository layer

---

## Error Handling
- Define a sealed `AppException` hierarchy for domain errors (`NetworkException`, `AuthException`, `NotFoundError`, etc.)
- Never show raw error messages from the network to the user — map to user-friendly strings
- Log errors with context (user ID, route, action) before surfacing to the UI

---

## Testing

- **Unit test every Cubit/Bloc** using `bloc_test` package — test every state transition
- **Widget test** critical screens with `BlocProvider` wrapping a mock Bloc
- **Never skip tests** because "it's just a UI component" — at minimum test that the correct state renders the correct widget tree

```dart
blocTest<ProductsCubit, ProductsState>(
  'emits [Loading, Loaded] when loadProducts succeeds',
  build: () {
    when(() => mockRepository.getProducts()).thenAnswer((_) async => fakeProducts);
    return ProductsCubit(mockRepository);
  },
  act: (cubit) => cubit.loadProducts(),
  expect: () => [isA<ProductsLoading>(), isA<ProductsLoaded>()],
);
```

---

## What to Avoid
- Never use `BuildContext` across async gaps without checking `mounted`
- Never use `setState` in a screen that has a Bloc — pick one approach
- Never put `MediaQuery` or `Theme` lookups in constructors — only in `build()`
- Never use `dynamic` — use explicit types or generics
- Avoid `GlobalKey` unless absolutely necessary (e.g., form validation) — it breaks widget tree optimization
- Never commit with `flutter analyze` warnings unresolved
