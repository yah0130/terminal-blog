import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class AuthUser {
  final int id;
  final String email;
  final bool isAdmin;

  AuthUser({required this.id, required this.email, required this.isAdmin});
}

class AuthResult {
  final String token;
  final AuthUser user;

  AuthResult({required this.token, required this.user});
}

class AdminUser {
  final int id;
  final String email;
  final bool isAdmin;
  final DateTime createdAt;

  AdminUser(
      {required this.id,
      required this.email,
      required this.isAdmin,
      required this.createdAt});
}

class AdminTag {
  final int id;
  final String name;

  AdminTag({required this.id, required this.name});
}

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _authHeaders {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<List<Article>> getArticles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/articles'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => Article(
                id: json['id'],
                title: json['title'],
                date: DateTime.parse(json['date']),
                tags:
                    json['tags'] != null ? List<String>.from(json['tags']) : [],
                content: '',
              ))
          .toList();
    } else {
      throw Exception('Failed to load articles');
    }
  }

  Future<Article> getArticle(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/articles/$id'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Article(
        id: data['id'],
        title: data['title'],
        date: DateTime.parse(data['date']),
        tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
        content: data['content'],
      );
    } else {
      throw Exception('Failed to load article');
    }
  }

  Future<AuthResult> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return AuthResult(
        token: data['token'],
        user: AuthUser(
          id: data['user']['id'],
          email: data['user']['email'],
          isAdmin: data['user']['is_admin'] ?? false,
        ),
      );
    } else {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  Future<AuthResult> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AuthResult(
        token: data['token'],
        user: AuthUser(
          id: data['user']['id'],
          email: data['user']['email'],
          isAdmin: data['user']['is_admin'] ?? false,
        ),
      );
    } else {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  Future<List<AdminUser>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => AdminUser(
                id: json['id'],
                email: json['email'],
                isAdmin: json['is_admin'] ?? false,
                createdAt: DateTime.parse(json['created_at']),
              ))
          .toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> updateUser(int id, {bool? isAdmin}) async {
    final body = <String, dynamic>{};
    if (isAdmin != null) body['is_admin'] = isAdmin;

    final response = await http.put(
      Uri.parse('$baseUrl/api/admin/users/$id'),
      headers: _authHeaders,
      body: json.encode(body),
    );
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to update user');
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/users/$id'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to delete user');
    }
  }

  Future<List<AdminTag>> getTags() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/tags'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => AdminTag(
                id: json['id'],
                name: json['name'],
              ))
          .toList();
    } else {
      throw Exception('Failed to load tags');
    }
  }

  Future<void> createTag(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/tags'),
      headers: _authHeaders,
      body: json.encode({'name': name}),
    );
    if (response.statusCode != 201) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to create tag');
    }
  }

  Future<void> deleteTag(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/tags/$id'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to delete tag');
    }
  }

  Future<void> createArticle(
      String title, String content, String date, List<String> tags) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/articles'),
      headers: _authHeaders,
      body: json.encode({
        'title': title,
        'content': content,
        'date': date,
        'tags': tags,
      }),
    );
    if (response.statusCode != 201) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to create article');
    }
  }

  Future<void> updateArticle(int id, String title, String content, String date,
      List<String> tags) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/admin/articles/$id'),
      headers: _authHeaders,
      body: json.encode({
        'title': title,
        'content': content,
        'date': date,
        'tags': tags,
      }),
    );
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to update article');
    }
  }

  Future<void> deleteArticle(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/articles/$id'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to delete article');
    }
  }
}
