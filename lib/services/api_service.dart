import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class AuthUser {
  final int id;
  final String email;

  AuthUser({required this.id, required this.email});
}

class AuthResult {
  final String token;
  final AuthUser user;

  AuthResult({required this.token, required this.user});
}

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<List<Article>> getArticles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/articles'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => Article(
                id: json['id'],
                title: json['title'],
                date: DateTime.parse(json['date']),
                tags: List<String>.from(json['tags']),
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
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Article(
        id: data['id'],
        title: data['title'],
        date: DateTime.parse(data['date']),
        tags: List<String>.from(data['tags']),
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
        ),
      );
    } else {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Login failed');
    }
  }
}
