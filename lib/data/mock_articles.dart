import '../models/article.dart';

final mockArticles = [
  Article(
    id: 1,
    title: 'Getting Started with Flutter',
    date: DateTime(2024, 1, 15),
    tags: ['flutter', 'beginner'],
    content: '''Welcome to my first article on Flutter!

Flutter is Google's UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.

In this article, we'll cover:
- What is Flutter?
- Setting up your development environment
- Creating your first Flutter app
- Understanding the widget tree

Let's get started!'''),
  Article(
    id: 2,
    title: 'Dart Null Safety Guide',
    date: DateTime(2024, 1, 10),
    tags: ['dart', 'null-safety'],
    content: '''Understanding Dart's Null Safety feature.

Null safety prevents null reference errors at compile time rather than runtime. This guide covers:

- Nullable types (String?)
- Non-nullable types (String)
- The ! operator (null assertion)
- The ?. operator (conditional access)
- Late variables

Null safety makes your code more robust and predictable.'''),
  Article(
    id: 3,
    title: 'Flutter Web Deployment',
    date: DateTime(2024, 1, 5),
    tags: ['flutter', 'web', 'deployment'],
    content: '''How to deploy your Flutter web application.

In this guide, we'll explore different deployment options:

1. Firebase Hosting
2. GitHub Pages
3. Vercel
4. Netlify

Each platform has its own advantages. Firebase is recommended for Flutter projects due to tight integration with Google services.'''),
  Article(
    id: 4,
    title: 'State Management in Flutter',
    date: DateTime(2024, 1, 1),
    tags: ['flutter', 'state-management'],
    content: '''Comparing state management solutions in Flutter.

There are many ways to manage state in Flutter:

- setState: Simple but limited
- Provider: Official recommendation for simple cases
- Riverpod: Advanced Provider with compile-time safety
- Bloc: Pattern-based state management
- GetX: All-in-one solution

Choose based on your project complexity.'''),
  Article(
    id: 5,
    title: 'Building Custom Widgets',
    date: DateTime(2023, 12, 25),
    tags: ['flutter', 'widgets', 'advanced'],
    content: '''Creating reusable custom widgets in Flutter.

Custom widgets help you:
- Reduce code duplication
- Encapsulate complex UI
- Share components across projects

We'll build a custom button, a card component, and a loading indicator.'''),
];