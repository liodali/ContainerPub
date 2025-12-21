# Style Guide

**Last Updated**: 2025-12-21  
**Owner**: Frontend Lead

## UI Library: Forui

We exclusively use the [Forui](https://forui.dev/) library for all UI components to maintain a consistent design system.
**Do not** use Material Design widgets (`Scaffold`, `AppBar`, `FloatingActionButton`, `Switch`, etc.) unless absolutely necessary and wrapped/hidden.

### Core Principles
- **Consistency**: Use `FTheme` to access colors, typography, and spacing.
- **Simplicity**: Prefer `forui`'s pre-built components (`FButton`, `FCard`, `FTextField`) over custom implementations.
- **Responsiveness**: Ensure layouts work on both desktop and mobile web.

## Theming

The application supports **Light**, **Dark**, and **System** modes.

### Architecture
- **State Management**: `ThemeNotifier` (in `lib/providers/theme_provider.dart`) manages the current `AppThemeMode`.
- **Persistence**: Theme preference is saved locally using `Hive` (Box: `settings`, Key: `theme_mode`).
- **Provider**: `fThemeDataProvider` returns the active `FThemeData` based on the mode and system brightness.

### Usage
To access the current theme data in any widget:
```dart
final theme = context.theme; // Returns FThemeData
final primaryColor = theme.colorScheme.primary;
```

### switching Themes
To toggle or set the theme:
```dart
ref.read(themeProvider.notifier).setTheme(AppThemeMode.dark);
// or
ref.read(themeProvider.notifier).toggleTheme();
```

### Adding New Themes
Currently, we use `FThemes.zinc`. If custom colors are needed, extend `FThemeData` or configure `FThemes` in `theme_provider.dart`.

## Icons

Use `FIcons` from `forui` (or `forui_assets`) for all iconography.
```dart
Icon(FIcons.sun, size: 16)
```
Avoid `Icons` (Material Icons) to ensure visual consistency with the `forui` design language.

## Components

### Buttons
Use `FButton`:
- Primary actions: `FButtonStyle.primary()`
- Secondary/neutral: `FButtonStyle.outline()`
- Destructive: `FButtonStyle.destructive()`

### Layout
- `FScaffold` instead of `Scaffold`.
- `FHeader` for page headers.
- `FCard` for grouping content.

## Typography
Access typography via `context.theme.typography`:
- `context.theme.typography.h1` ... `h4` for headings.
- `context.theme.typography.base` or `lg`, `sm` for body text.

## Localization

- All user-visible strings must come from `AppLocalizations` (`lib/l10n/app_*.arb`).
- Do not hard-code English strings in widgets.
- When adding a new string:
  - Add key to `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`
  - Use `AppLocalizations.of(context)!.<key>` in UI

## Accessibility

- Ensure interactive elements have:
  - Sufficient hit target sizes
  - Clear focus states (keyboard navigation on web)
  - Readable contrast in light/dark themes
- Prefer semantic widgets when available and avoid purely visual state without text.
- For forms:
  - Provide labels and clear error messaging
  - Avoid using placeholder text as the only label

## Widget Conventions

- Prefer dedicated widget classes over helper functions that return `Widget` for non-trivial UI pieces.
- Keep stateful logic close to the UI it drives (e.g., a tab owns its own controllers).

## Notifications and Errors

- Prefer `forui` patterns for user feedback:
  - `showFToast` for transient success/failure feedback
  - `FAlert` or `ErrorCardComponent` for persistent page-level errors
- Avoid using Material `SnackBar` unless there is a documented reason and it is wrapped to match styling.
