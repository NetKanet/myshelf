import 'book.dart';

enum ReadingStatus {
  wantToRead('want_to_read'),
  reading('reading'),
  finished('finished');

  const ReadingStatus(this.value);
  final String value;

  static ReadingStatus fromString(String s) =>
      ReadingStatus.values.firstWhere((e) => e.value == s);

  String get label {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'Want to Read';
      case ReadingStatus.reading:
        return 'Reading';
      case ReadingStatus.finished:
        return 'Finished';
    }
  }
}

/// The user's relationship to a [Book] — one per book per user.
class UserBook {
  final String id;
  final String userId;
  final String bookId;
  final ReadingStatus status;
  final DateTime? dateStarted;
  final DateTime? dateFinished;
  final double? rating; // half-star 0.5–5; set only while finished
  final String? review; // set only while finished
  final DateTime createdAt;
  final DateTime updatedAt;
  final Book? book;

  const UserBook({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    this.dateStarted,
    this.dateFinished,
    this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
    this.book,
  });

  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      status: ReadingStatus.fromString(json['status'] as String),
      dateStarted: json['date_started'] != null
          ? DateTime.parse(json['date_started'] as String)
          : null,
      dateFinished: json['date_finished'] != null
          ? DateTime.parse(json['date_finished'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      book: json['books'] != null
          ? Book.fromJson(json['books'] as Map<String, dynamic>)
          : null,
    );
  }

  UserBook copyWith({
    ReadingStatus? status,
    DateTime? dateStarted,
    bool clearDateStarted = false,
    DateTime? dateFinished,
    bool clearDateFinished = false,
    double? rating,
    bool clearRating = false,
    String? review,
    bool clearReview = false,
    DateTime? updatedAt,
    Book? book,
  }) {
    return UserBook(
      id: id,
      userId: userId,
      bookId: bookId,
      status: status ?? this.status,
      dateStarted: clearDateStarted ? null : (dateStarted ?? this.dateStarted),
      dateFinished:
          clearDateFinished ? null : (dateFinished ?? this.dateFinished),
      rating: clearRating ? null : (rating ?? this.rating),
      review: clearReview ? null : (review ?? this.review),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      book: book ?? this.book,
    );
  }
}
