# Quizify

A modern quiz timer and analysis app built with Flutter, featuring comprehensive session tracking, detailed analytics, and a beautiful UI/UX design.

## Features

- **Session Management**: Create and manage quiz sessions with customizable subjects and sources
- **Real-time Timer**: Track total session time and individual question timing
- **Dynamic Question Addition**: Add questions during active sessions
- **Comprehensive Analytics**: View detailed statistics including accuracy, time per question, and performance trends
- **Answer Key Management**: Set and edit correct answers after session completion
- **Question Types Support**: Multiple choice questions (A, B, C, D)
- **Filterable History**: Browse and filter past sessions by subject and source
- **Modern UI/UX**: Beautiful Material Design 3 interface with dark/light theme support

## UI/UX Design System

### Theme Architecture
The app uses a centralized theme system with:

- **Google Fonts Integration**: Poppins font family used throughout the app
- **Blue-based Color Scheme**: Customizable primary colors centered around blue tones
- **Dark/Light Theme Support**: Automatic system theme detection with manual override capability
- **Material Design 3**: Following latest Material Design guidelines

### Theme Customization
All theme configurations are centralized in `lib/theme/app_theme.dart`:

```dart
// Change the primary color scheme
static const Color primaryBlue = Color(0xFF1976D2);

// Change the font family
static const String fontFamily = 'Poppins';
```

### Component Library
Reusable UI components in `lib/components/app_components.dart`:
- `AppCard`: Customizable card component
- `StatCard`: Statistics display cards
- `LoadingState`: Consistent loading indicators
- `EmptyState`: Empty state displays
- `ActionButton`: Standardized button component
- `InfoRow`: Information display rows
- `SectionHeader`: Section headers with subtitles

## Screen Architecture

1. **HomeScreen**: Dashboard with overall statistics and quick actions
2. **CreateSessionScreen**: Session setup with subject/topic selection
3. **ActiveSessionScreen**: Live quiz interface with timer and navigation
4. **AnswerKeyScreen**: Post-session answer key configuration
5. **SessionAnalysisScreen**: Detailed session statistics and question breakdown
6. **AnalysisListScreen**: Filterable list of all past sessions
7. **QuestionDetailScreen**: Individual question analysis

## Database Structure

- **Subjects**: Subject and topic management
- **Sessions**: Completed quiz sessions with metadata
- **Questions**: Individual question records with timing and answer data

## Getting Started

### Prerequisites
- Flutter SDK (>= 3.11.0)
- Dart SDK
- Android/iOS development environment

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd quizify
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Dependencies

- `google_fonts`: ^8.0.2 - Google Fonts integration
- `sqflite`: ^2.4.2 - SQLite database
- `intl`: ^0.20.2 - Internationalization
- `provider`: ^6.1.5+1 - State management
- `path_provider`: ^2.1.5 - File system access

## Theme Customization Guide

### Changing Colors
Edit `lib/theme/app_theme.dart`:

```dart
class AppTheme {
  // Modify these colors to change the entire app theme
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color accentBlue = Color(0xFF29B6F6);
}
```

### Changing Fonts
Update the font family constant:

```dart
static const String fontFamily = 'YourFontFamily';
```

Then update `pubspec.yaml` to include your font assets.

### Adding New Themes
Extend the `AppTheme` class with new theme methods:

```dart
static ThemeData get customTheme {
  // Your custom theme configuration
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the established design system
4. Test thoroughly on both light and dark themes
5. Submit a pull request

## License

This project is licensed under the MIT License.
