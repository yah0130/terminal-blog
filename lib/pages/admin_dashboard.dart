import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/article.dart';
import '../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  final ApiService apiService;

  const AdminDashboard({super.key, required this.apiService});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  ApiService get _apiService => widget.apiService;

  List<AdminUser> _users = [];
  List<AdminTag> _tags = [];
  List<Article> _articles = [];

  bool _isLoading = true;
  String? _error;

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getUsers(),
        _apiService.getTags(),
        _apiService.getArticles(),
      ]);

      setState(() {
        _users = results[0] as List<AdminUser>;
        _tags = results[1] as List<AdminTag>;
        _articles = results[2] as List<Article>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF323233),
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.jetBrainsMono(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF252526),
            child: Row(
              children: [
                _buildTab('Users', 0),
                _buildTab('Tags', 1),
                _buildTab('Articles', 2),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text('Error: $_error',
                            style: const TextStyle(color: Colors.red)))
                    : _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1E1E) : null,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF4EC9B0) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: isSelected ? const Color(0xFF4EC9B0) : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildUsersList();
      case 1:
        return _buildTagsList();
      case 2:
        return _buildArticlesList();
      default:
        return const SizedBox();
    }
  }

  Widget _buildUsersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          color: const Color(0xFF252526),
          child: ListTile(
            title:
                Text(user.email, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              'Admin: ${user.isAdmin ? "Yes" : "No"} | Created: ${user.createdAt.toLocal().toString().split('.')[0]}',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: user.isAdmin,
                  onChanged: (value) async {
                    try {
                      await _apiService.updateUser(user.id, isAdmin: value);
                      _loadData();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  activeColor: const Color(0xFF4EC9B0),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF252526),
                        title: const Text('Delete User',
                            style: TextStyle(color: Colors.white)),
                        content: Text('Delete ${user.email}?',
                            style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await _apiService.deleteUser(user.id);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'New tag name',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF3C3C3C),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (value) => _addTag(value),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showAddTagDialog(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4EC9B0)),
                child: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tags.length,
            itemBuilder: (context, index) {
              final tag = _tags[index];
              return Card(
                color: const Color(0xFF252526),
                child: ListTile(
                  title: Text(tag.name,
                      style: const TextStyle(color: Colors.white)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      try {
                        await _apiService.deleteTag(tag.id);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252526),
        title: const Text('Add Tag', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Tag name',
            hintStyle: TextStyle(color: Colors.white38),
          ),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addTag(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTag(String name) async {
    if (name.isEmpty) return;
    try {
      await _apiService.createTag(name);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildArticlesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _showArticleEditor(null),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EC9B0)),
            child: const Text('New Article'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _articles.length,
            itemBuilder: (context, index) {
              final article = _articles[index];
              return Card(
                color: const Color(0xFF252526),
                child: ListTile(
                  title: Text(article.title,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${article.formattedDate} | ${article.tags.join(", ")}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showArticleEditor(article),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF252526),
                              title: const Text('Delete Article',
                                  style: TextStyle(color: Colors.white)),
                              content: Text('Delete "${article.title}"?',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await _apiService.deleteArticle(article.id);
                              _loadData();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showArticleEditor(Article? article) async {
    if (article != null) {
      article = await _apiService.getArticle(article.id);
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleEditor(
          article: article,
          tags: _tags,
          onSave: (title, content, date, tags) async {
            if (article == null) {
              await _apiService.createArticle(title, content, date, tags);
            } else {
              await _apiService.updateArticle(
                  article.id, title, content, date, tags);
            }
            _loadData();
          },
        ),
      ),
    );
  }
}

class ArticleEditor extends StatefulWidget {
  final Article? article;
  final List<AdminTag> tags;
  final Function(String title, String content, String date, List<String> tags)
      onSave;

  const ArticleEditor({
    super.key,
    this.article,
    required this.tags,
    required this.onSave,
  });

  @override
  State<ArticleEditor> createState() => _ArticleEditorState();
}

class _ArticleEditorState extends State<ArticleEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _dateController;
  late List<String> _selectedTags;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article?.title ?? '');
    _contentController =
        TextEditingController(text: widget.article?.content ?? '');
    _dateController = TextEditingController(
      text: widget.article?.date.toString().split(' ')[0] ??
          DateTime.now().toString().split(' ')[0],
    );
    _selectedTags = List.from(widget.article?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF323233),
        title: Text(
          widget.article == null ? 'New Article' : 'Edit Article',
          style: GoogleFonts.jetBrainsMono(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            color: Colors.white,
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            color: const Color(0xFF4EC9B0),
            onPressed: _save,
          ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildEditor(),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF252526),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 16),
          const Text('Tags', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.tags.map((tag) {
              final isSelected = _selectedTags.contains(tag.name);
              return FilterChip(
                label: Text(tag.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag.name);
                    } else {
                      _selectedTags.remove(tag.name);
                    }
                  });
                },
                selectedColor: const Color(0xFF4EC9B0),
                checkmarkColor: Colors.black,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Content (Markdown)',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(
              hintText: 'Write your article in Markdown...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF252526),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14),
            maxLines: null,
            minLines: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleController.text,
            style: const TextStyle(
              color: Color(0xFFDCDCAA),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dateController.text,
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: _selectedTags
                .map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      backgroundColor: const Color(0xFF4EC9B0),
                    ))
                .toList(),
          ),
          const Divider(color: Colors.white24),
          MarkdownBody(
            data: _contentController.text,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(
                  color: Color(0xFFDCDCAA), fontWeight: FontWeight.bold),
              h2: const TextStyle(
                  color: Color(0xFF4EC9B0), fontWeight: FontWeight.bold),
              h3: const TextStyle(
                  color: Color(0xFF4FC1FF), fontWeight: FontWeight.bold),
              p: const TextStyle(color: Colors.white),
              code: TextStyle(
                  color: const Color(0xFFCE9178),
                  backgroundColor: const Color(0xFF2D2D2D)),
              codeblockDecoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  void _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    await widget.onSave(
      _titleController.text,
      _contentController.text,
      _dateController.text,
      _selectedTags,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
