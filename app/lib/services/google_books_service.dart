import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class GoogleBooksException implements Exception {
  final String message;
  const GoogleBooksException(this.message);
  @override
  String toString() => 'GoogleBooksException: $message';
}

/// Looks up a single book by ISBN from the Google Books API.
/// Called only on a cache miss (see contracts/google-books-lookup.md).
class GoogleBooksService {
  static const _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const _timeout = Duration(seconds: 8);

  final http.Client _httpClient;

  GoogleBooksService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Returns a partial [Book] (empty id) or throws [GoogleBooksException]
  /// when not found or on any failure (so the caller can fall through to manual).
  Future<Book> lookupByIsbn(String isbn) async {
    final uri = Uri.parse('$_baseUrl?q=isbn:$isbn');

    final http.Response response;
    try {
      response = await _httpClient.get(uri).timeout(_timeout);
    } catch (_) {
      throw const GoogleBooksException('Lookup failed');
    }

    if (response.statusCode != 200) {
      throw const GoogleBooksException('API request failed');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final totalItems = json['totalItems'] as int? ?? 0;
    final items = json['items'] as List<dynamic>?;
    if (totalItems == 0 || items == null || items.isEmpty) {
      throw const GoogleBooksException('ISBN not found');
    }

    final volumeInfo =
        (items.first as Map<String, dynamic>)['volumeInfo'] as Map<String, dynamic>;
    final authors = volumeInfo['authors'] as List<dynamic>?;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final publishedDate = volumeInfo['publishedDate'] as String?;

    return Book(
      id: '',
      isbn: isbn,
      title: volumeInfo['title'] as String? ?? 'Unknown Title',
      author: authors?.map((a) => a as String).join(', '),
      coverUrl: (imageLinks?['thumbnail'] as String?)
          ?.replaceFirst('http://', 'https://'),
      description: volumeInfo['description'] as String?,
      publisher: volumeInfo['publisher'] as String?,
      publishedYear: publishedDate != null && publishedDate.length >= 4
          ? int.tryParse(publishedDate.substring(0, 4))
          : null,
      pageCount: volumeInfo['pageCount'] as int?,
      source: 'google',
    );
  }
}
