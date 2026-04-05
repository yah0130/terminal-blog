import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  Future<List<Article>> getArticles() async {
    final response = await http.get(Uri.parse('$baseUrl/api/articles'));
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
    final response = await http.get(Uri.parse('$baseUrl/api/articles/$id'));
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
}
