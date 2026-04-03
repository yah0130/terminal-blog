import 'package:flutter/material.dart';
import '../models/article.dart';
import '../data/mock_articles.dart';

enum ViewState { welcome, list, article }

class OutputLine {
  final String text;
  final Color? color;

  OutputLine(this.text, {this.color});
}

class TerminalState extends ChangeNotifier {
  ViewState _currentView = ViewState.welcome;
  final List<OutputLine> _outputHistory = [];
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  Article? _currentArticle;

  ViewState get currentView => _currentView;
  List<OutputLine> get outputHistory => _outputHistory;
  List<String> get commandHistory => _commandHistory;
  Article? get currentArticle => _currentArticle;

  TerminalState() {
    _showWelcome();
  }

  void _showWelcome() {
    _addLine('');
    _addLine('╔════════════════════════════════════════════════════════════╗', color: const Color(0xFF4EC9B0));
    _addLine('║                                                            ║', color: const Color(0xFF4EC9B0));
    _addLine('║   ██╗    ██╗   ██╗    ██╗                                  ║', color: const Color(0xFF4EC9B0));
    _addLine('║    ██╗  ██╗╝   ██║    ██║                                  ║', color: const Color(0xFF4EC9B0));
    _addLine('║     ████╗═╝    █████████║                                  ║', color: const Color(0xFF4EC9B0));
    _addLine('║      ██╔╝      ██║    ██║                                  ║', color: const Color(0xFF4EC9B0));
    _addLine('║      ██║       ██║    ██║                                  ║', color: const Color(0xFF4EC9B0));
    _addLine('║      ╚═╝       ╚═╝    ╚═╝                                  ║', color: const Color(0xFF4EC9B0));
    _addLine('║                                                            ║', color: const Color(0xFF4EC9B0));
    _addLine('║   TERMINAL BLOG v1.0.0                                     ║', color: const Color(0xFFDCDCAA));
    _addLine('║                                                            ║', color: const Color(0xFF4EC9B0));
    _addLine('╚════════════════════════════════════════════════════════════╝', color: const Color(0xFF4EC9B0));
    _addLine('');
    _addLine('Welcome to Terminal Blog!', color: const Color(0xFFD4D4D4));
    _addLine("Type 'help' for available commands.", color: const Color(0xFF808080));
    _addLine('');
  }

  void _addLine(String text, {Color? color}) {
    _outputHistory.add(OutputLine(text, color: color));
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
        _addLine("Type 'help' for available commands.", color: const Color(0xFF808080));
    }
    notifyListeners();
  }

  void _showHelp() {
    _addLine('');
    _addLine('Available commands:', color: const Color(0xFFDCDCAA));
    _addLine('');
    _addLine('  help                 Show this help message', color: const Color(0xFF808080));
    _addLine('  blog list            List all articles', color: const Color(0xFF808080));
    _addLine('  blog read <id>       Read article by ID', color: const Color(0xFF808080));
    _addLine('  blog search <word>  Search articles by keyword', color: const Color(0xFF808080));
    _addLine('  clear                Clear terminal screen', color: const Color(0xFF808080));
    _addLine('  exit                 Return to previous view', color: const Color(0xFF808080));
    _addLine('');
    _addLine('Examples:', color: const Color(0xFFDCDCAA));
    _addLine('  \$ blog list', color: const Color(0xFF4EC9B0));
    _addLine('  \$ blog read 1', color: const Color(0xFF4EC9B0));
    _addLine('  \$ blog search flutter', color: const Color(0xFF4EC9B0));
  }

  void _handleBlogCommand(List<String> args) {
    if (args.isEmpty) {
      _addLine('Usage: blog <list|read|search>', color: const Color(0xFFF44747));
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
          _addLine('Usage: blog search <keyword>', color: const Color(0xFFF44747));
        } else {
          _searchArticles(args.sublist(1).join(' '));
        }
        break;
      default:
        _addLine('Unknown subcommand: ${args[0]}', color: const Color(0xFFF44747));
        _addLine('Usage: blog <list|read|search>', color: const Color(0xFF808080));
    }
  }

  void _showArticleList() {
    _currentView = ViewState.list;
    _addLine('');
    _addLine('┌─────────────────────────────────────────────────────────────┐', color: const Color(0xFF4EC9B0));
    _addLine('│ ID     Title                              Date       Tags   │', color: const Color(0xFFDCDCAA));
    _addLine('├─────────────────────────────────────────────────────────────┤', color: const Color(0xFF4EC9B0));
    
    for (final article in mockArticles) {
      final id = article.id.toString().padRight(6);
      final title = article.title.padRight(38).substring(0, 38);
      final date = article.formattedDate.padRight(11);
      final tags = article.tags.join(', ').padRight(12).substring(0, 12);
      _addLine('│ ${id} ${title} ${date} ${tags}│', color: const Color(0xFFD4D4D4));
    }
    
    _addLine('└─────────────────────────────────────────────────────────────┘', color: const Color(0xFF4EC9B0));
    _addLine('');
    _addLine("Use 'blog read <id>' to read an article.", color: const Color(0xFF808080));
    notifyListeners();
  }

  void _readArticle(int? id) {
    if (id == null) {
      _addLine('Invalid article ID', color: const Color(0xFFF44747));
      return;
    }

    final article = mockArticles.where((a) => a.id == id).firstOrNull;
    if (article == null) {
      _addLine('Article not found', color: const Color(0xFFF44747));
      return;
    }

    _currentArticle = article;
    _currentView = ViewState.article;
    
    _addLine('');
    _addLine('═══════════════════════════════════════════════════════════════', color: const Color(0xFF4EC9B0));
    _addLine('');
    _addLine('# ${article.title}', color: const Color(0xFFDCDCAA));
    _addLine('');
    _addLine('Date: ${article.formattedDate} | Tags: ${article.tags.join(", ")}', color: const Color(0xFF808080));
    _addLine('');
    _addLine('─────────────────────────────────────────────────────────────', color: const Color(0xFF4EC9B0));
    
    for (final line in article.content.split('\n')) {
      _addLine(line);
    }
    
    _addLine('─────────────────────────────────────────────────────────────', color: const Color(0xFF4EC9B0));
    _addLine('');
    _addLine("[Press 'exit' to return to list]", color: const Color(0xFF808080));
    notifyListeners();
  }

  void _searchArticles(String keyword) {
    final results = mockArticles.where((a) =>
      a.title.toLowerCase().contains(keyword.toLowerCase()) ||
      a.content.toLowerCase().contains(keyword.toLowerCase()) ||
      a.tags.any((t) => t.toLowerCase().contains(keyword.toLowerCase()))
    ).toList();

    _addLine('');
    if (results.isEmpty) {
      _addLine('No articles found matching "$keyword"', color: const Color(0xFFF44747));
    } else {
      _addLine('Found ${results.length} result(s):', color: const Color(0xFFDCDCAA));
      _addLine('');
      for (final article in results) {
        _addLine('  [${article.id}] ${article.title}', color: const Color(0xFF4FC1FF));
        _addLine('      ${article.formattedDate} - ${article.tags.join(", ")}', color: const Color(0xFF808080));
      }
    }
    notifyListeners();
  }

  void _handleExit() {
    switch (_currentView) {
      case ViewState.article:
        _currentView = ViewState.list;
        _currentArticle = null;
        _addLine('');
        _addLine('Returning to article list...', color: const Color(0xFF808080));
        _addLine('');
        _showArticleList();
        break;
      case ViewState.list:
        _currentView = ViewState.welcome;
        _addLine('');
        _addLine('Returning to home...', color: const Color(0xFF808080));
        _addLine('');
        _addLine('Welcome to Terminal Blog!', color: const Color(0xFFD4D4D4));
        _addLine("Type 'help' for available commands.", color: const Color(0xFF808080));
        break;
      case ViewState.welcome:
        _addLine('Already at home. Type "help" for commands.', color: const Color(0xFF808080));
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
}