# Style Guide

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
