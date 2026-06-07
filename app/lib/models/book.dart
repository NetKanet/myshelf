/// A shared catalog entry — one row per ISBN, reused across users.
class Book {
  final String id;
  final String? isbn;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? description;
  final String? publisher;
  final int? publishedYear;
  final int? pageCount;
  final String? source; // 'google' | 'manual'

  const Book({
    required this.id,
    this.isbn,
    required this.title,
    this.author,
    this.coverUrl,
    this.description,
    this.publisher,
    this.publishedYear,
    this.pageCount,
    this.source,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      isbn: json['isbn'] as String?,
      title: json['title'] as String? ?? 'Unknown Title',
      author: json['author'] as String?,
      // Normalize http → https so iOS ATS / Android cleartext don't block covers.
      coverUrl:
          (json['cover_url'] as String?)?.replaceFirst('http://', 'https://'),
      description: json['description'] as String?,
      publisher: json['publisher'] as String?,
      publishedYear: json['published_year'] as int?,
      pageCount: json['page_count'] as int?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (isbn != null) 'isbn': isbn,
      'title': title,
      if (author != null) 'author': author,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (description != null) 'description': description,
      if (publisher != null) 'publisher': publisher,
      if (publishedYear != null) 'published_year': publishedYear,
      if (pageCount != null) 'page_count': pageCount,
      if (source != null) 'source': source,
    };
  }

  Book copyWith({String? id, String? coverUrl}) {
    return Book(
      id: id ?? this.id,
      isbn: isbn,
      title: title,
      author: author,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description,
      publisher: publisher,
      publishedYear: publishedYear,
      pageCount: pageCount,
      source: source,
    );
  }
}
