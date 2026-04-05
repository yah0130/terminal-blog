import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/api_service.dart';

enum ViewState { welcome, list, article, loading, error }

class OutputLine {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;

  OutputLine(this.text, {this.color, this.fontWeight});
}

class TerminalState extends ChangeNotifier {
  ViewState _currentView = ViewState.welcome;
  final List<OutputLine> _outputHistory = [];
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  Article? _currentArticle;
  List<Article> _articles = [];
  final ApiService _apiService = ApiService();

  ViewState get currentView => _currentView;
  List<OutputLine> get outputHistory => _outputHistory;
  List<String> get commandHistory => _commandHistory;
  Article? get currentArticle => _currentArticle;
  List<Article> get articles => _articles;

  TerminalState() {
    _showWelcome();
  }

  void _showWelcome() {
    _addLine('');
    _addLine('╔════════════════════════════════════════════════════════════╗',
        color: const Color(0xFF4EC9B0));
    _addLine('║                                                            ║',
        color: const Color(0xFF4EC9B0));
    _addLine('║   ██╗    ██╗   ██╗    ██╗                                  ║',
        color: const Color(0xFF4EC9B0));
    _addLine('║    ██╗  ██╗╝   ██║    ██║                                  ║',
        color: const Color(0xFF4EC9B0));
    _addLine('║     ████╗═╝    █████████║                                  ║',
        color: const Color(0xFF4EC9B0));
    _addLine('║      ██╔╝      ██║    ██║                                  ║',
        color: const Color(0xFF4EC9B0));
    _addLine('║      ██║       ██║    ██║                                  ║',
        color: const Color(0xFF4EC9B0));
    _addLine('║      ╚═╝       ╚═╝    ╚═╝                                  ║',
        color: const Color(0xFF4EC9B0));
    _addLine('║                                                            ║',
        color: const Color(0xFF4EC9B0));
    _addLine('║   TERMINAL BLOG v1.0.0                                     ║',
        color: const Color(0xFFDCDCAA));
    _addLine('║                                                            ║',
        color: const Color(0xFF4EC9B0));
    _addLine('╚════════════════════════════════════════════════════════════╝',
        color: const Color(0xFF4EC9B0));
    _addLine('');
    _addLine('Welcome to Terminal Blog!', color: const Color(0xFFD4D4D4));
    _addLine("Type 'help' for available commands.",
        color: const Color(0xFF808080));
    _addLine('');
  }

  void _addLine(String text, {Color? color, FontWeight? fontWeight}) {
    _outputHistory.add(OutputLine(text, color: color, fontWeight: fontWeight));
    notifyListeners();
  }

  void executeCommand(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    _addLine('visitor@blog:~\$ $trimmed', color: const Color(0xFF4EC9B0));
    _commandHistory.add(trimmed);
    _historyIndex = _commandHistory.length;

    final parts = trimmed.split(' ');
    final cmd = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    switch (cmd) {
      case 'help':
        _showHelp();
        break;
      case 'blog':
        _handleBlogCommand(args);
        break;
      case 'clear':
        _outputHistory.clear();
        _showWelcome();
        break;
      case 'exit':
        _handleExit();
        break;
      default:
        _addLine("Command not found: $cmd", color: const Color(0xFFF44747));
        _addLine("Type 'help' for available commands.",
            color: const Color(0xFF808080));
    }
    notifyListeners();
  }

  void _showHelp() {
    _addLine('');
    _addLine('Available commands:', color: const Color(0xFFDCDCAA));
    _addLine('');
    _addLine('  help                 Show this help message',
        color: const Color(0xFF808080));
    _addLine('  blog list            List all articles',
        color: const Color(0xFF808080));
    _addLine('  blog read <id>       Read article by ID',
        color: const Color(0xFF808080));
    _addLine('  blog search <word>  Search articles by keyword',
        color: const Color(0xFF808080));
    _addLine('  clear                Clear terminal screen',
        color: const Color(0xFF808080));
    _addLine('  exit                 Return to previous view',
        color: const Color(0xFF808080));
    _addLine('');
    _addLine('Examples:', color: const Color(0xFFDCDCAA));
    _addLine('  \$ blog list', color: const Color(0xFF4EC9B0));
    _addLine('  \$ blog read 1', color: const Color(0xFF4EC9B0));
    _addLine('  \$ blog search flutter', color: const Color(0xFF4EC9B0));
  }

  void _handleBlogCommand(List<String> args) {
    if (args.isEmpty) {
      _addLine('Usage: blog <list|read|search>',
          color: const Color(0xFFF44747));
      return;
    }

    switch (args[0]) {
      case 'list':
        _showArticleList();
        break;
      case 'read':
        if (args.length < 2) {
          _addLine('Usage: blog read <id>', color: const Color(0xFFF44747));
        } else {
          _readArticle(int.tryParse(args[1]));
        }
        break;
      case 'search':
        if (args.length < 2) {
          _addLine('Usage: blog search <keyword>',
              color: const Color(0xFFF44747));
        } else {
          _searchArticles(args.sublist(1).join(' '));
        }
        break;
      default:
        _addLine('Unknown subcommand: ${args[0]}',
            color: const Color(0xFFF44747));
        _addLine('Usage: blog <list|read|search>',
            color: const Color(0xFF808080));
    }
  }

  Future<void> _showArticleList() async {
    _currentView = ViewState.loading;
    _addLine('');
    _addLine('Loading articles...', color: const Color(0xFF808080));

    try {
      _articles = await _apiService.getArticles();
      _currentView = ViewState.list;
      _outputHistory.clear();

      _addLine(
          '┌────┬──────────────────────────────────────────────────────┬────────────┬─────────────────────┐',
          color: const Color(0xFF4EC9B0));
      _addLine(
          '│ ID │ Title                                                │ Date       │ Tags                │',
          color: const Color(0xFFDCDCAA));
      _addLine(
          '├────┼──────────────────────────────────────────────────────┼────────────┼─────────────────────┤',
          color: const Color(0xFF4EC9B0));

      for (final article in _articles) {
        final id = article.id.toString().padRight(2);
        final title = _truncate(article.title, 52);
        final date = article.formattedDate;
        final tags = _truncate(article.tags.join(', '), 19);
        _addLine('│ $id │ $title │ $date │ $tags │',
            color: const Color(0xFFD4D4D4));
      }

      _addLine(
          '└────┴──────────────────────────────────────────────────────┴────────────┴─────────────────────┘',
          color: const Color(0xFF4EC9B0));
      _addLine('');
      _addLine("Use 'blog read <id>' to read an article.",
          color: const Color(0xFF808080));
    } catch (e) {
      _currentView = ViewState.error;
      _addLine('Failed to load articles: $e', color: const Color(0xFFF44747));
      _addLine("Make sure the API server is running on port 8080.",
          color: const Color(0xFF808080));
    }
    notifyListeners();
  }

  Future<void> _readArticle(int? id) async {
    if (id == null) {
      _addLine('Invalid article ID', color: const Color(0xFFF44747));
      return;
    }

    _currentView = ViewState.loading;
    _addLine('');
    _addLine('Loading article...', color: const Color(0xFF808080));

    try {
      final article = await _apiService.getArticle(id);
      _currentArticle = article;
      _currentView = ViewState.article;
      _outputHistory.clear();

      _addLine('');
      _addLine(
          '═══════════════════════════════════════════════════════════════',
          color: const Color(0xFF4EC9B0));
      _addLine('');
      _addLine('# ${article.title}', color: const Color(0xFFDCDCAA));
      _addLine('');
      _addLine(
          'Date: ${article.formattedDate} | Tags: ${article.tags.join(", ")}',
          color: const Color(0xFF808080));
      _addLine('');
      _addLine('─────────────────────────────────────────────────────────────',
          color: const Color(0xFF4EC9B0));

      _renderMarkdown(article.content);

      _addLine('─────────────────────────────────────────────────────────────',
          color: const Color(0xFF4EC9B0));
      _addLine('');
      _addLine("[Press 'exit' to return to list]",
          color: const Color(0xFF808080));
    } catch (e) {
      _currentView = ViewState.error;
      _addLine('Failed to load article: $e', color: const Color(0xFFF44747));
    }
    notifyListeners();
  }

  void _renderMarkdown(String content) {
    final lines = content.split('\n');
    bool inCodeBlock = false;
    final codeBlockLines = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim().startsWith('```')) {
        if (!inCodeBlock) {
          inCodeBlock = true;
          codeBlockLines.clear();
        } else {
          for (final codeLine in codeBlockLines) {
            _addLine('  $codeLine', color: const Color(0xFFCE9178));
          }
          codeBlockLines.clear();
          inCodeBlock = false;
        }
        continue;
      }

      if (inCodeBlock) {
        codeBlockLines.add(line);
        continue;
      }

      if (line.trim().isEmpty) {
        _addLine('');
        continue;
      }

      if (line.trim().startsWith('# ')) {
        _addLine(line.substring(2),
            color: const Color(0xFFDCDCAA), fontWeight: FontWeight.bold);
      } else if (line.trim().startsWith('## ')) {
        _addLine(line.substring(3),
            color: const Color(0xFF4EC9B0), fontWeight: FontWeight.bold);
      } else if (line.trim().startsWith('### ')) {
        _addLine(line.substring(4),
            color: const Color(0xFF4FC1FF), fontWeight: FontWeight.bold);
      } else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        _addLine('  • ${line.trim().substring(2)}',
            color: const Color(0xFFD4D4D4));
      } else if (RegExp(r'^(\d+)\.\s').hasMatch(line.trim())) {
        final match = RegExp(r'^(\d+)\.\s(.*)').firstMatch(line.trim());
        if (match != null) {
          _addLine(
              '  ${match.group(1)}. ${_parseInlineMarkdown(match.group(2)!)}',
              color: const Color(0xFFD4D4D4));
        }
      } else if (line.trim().startsWith('> ')) {
        _addLine('  │ ${line.trim().substring(2)}',
            color: const Color(0xFF808080));
      } else {
        _addLine(_parseInlineMarkdown(line), color: const Color(0xFFD4D4D4));
      }
    }
  }

  String _parseInlineMarkdown(String text) {
    var result = text;
    result =
        result.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!);
    result = result.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1)!);
    result = result.replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m.group(1)!);
    return result;
  }

  Future<void> _searchArticles(String keyword) async {
    _addLine('');
    _addLine('Searching for "$keyword"...', color: const Color(0xFF808080));

    try {
      if (_articles.isEmpty) {
        _articles = await _apiService.getArticles();
      }

      final results = _articles
          .where((a) =>
              a.title.toLowerCase().contains(keyword.toLowerCase()) ||
              a.tags
                  .any((t) => t.toLowerCase().contains(keyword.toLowerCase())))
          .toList();

      if (results.isEmpty) {
        _addLine('No articles found matching "$keyword"',
            color: const Color(0xFFF44747));
      } else {
        _addLine('Found ${results.length} result(s):',
            color: const Color(0xFFDCDCAA));
        _addLine('');
        for (final article in results) {
          _addLine('  [${article.id}] ${article.title}',
              color: const Color(0xFF4FC1FF));
          _addLine(
              '      ${article.formattedDate} - ${article.tags.join(", ")}',
              color: const Color(0xFF808080));
        }
      }
    } catch (e) {
      _addLine('Search failed: $e', color: const Color(0xFFF44747));
    }
    notifyListeners();
  }

  void _handleExit() {
    switch (_currentView) {
      case ViewState.article:
        _currentView = ViewState.list;
        _currentArticle = null;
        _showArticleList();
        break;
      case ViewState.list:
        _currentView = ViewState.welcome;
        _outputHistory.clear();
        _addLine('');
        _addLine('Returning to home...', color: const Color(0xFF808080));
        _addLine('');
        _addLine('Welcome to Terminal Blog!', color: const Color(0xFFD4D4D4));
        _addLine("Type 'help' for available commands.",
            color: const Color(0xFF808080));
        break;
      case ViewState.welcome:
        _addLine('Already at home. Type "help" for commands.',
            color: const Color(0xFF808080));
        break;
      case ViewState.loading:
      case ViewState.error:
        _currentView = ViewState.welcome;
        _outputHistory.clear();
        _addLine('');
        _addLine('Welcome to Terminal Blog!', color: const Color(0xFFD4D4D4));
        _addLine("Type 'help' for available commands.",
            color: const Color(0xFF808080));
        break;
    }
    notifyListeners();
  }

  void navigateHistory(bool up) {
    if (_commandHistory.isEmpty) return;

    if (up) {
      if (_historyIndex > 0) {
        _historyIndex--;
      }
    } else {
      if (_historyIndex < _commandHistory.length - 1) {
        _historyIndex++;
      } else {
        _historyIndex = _commandHistory.length;
      }
    }
    notifyListeners();
  }

  String? get historyCommand {
    if (_historyIndex >= _commandHistory.length) return '';
    if (_historyIndex < 0) return null;
    return _commandHistory[_historyIndex];
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text.padRight(maxLen);
    return '${text.substring(0, maxLen - 3)}...';
  }
}
