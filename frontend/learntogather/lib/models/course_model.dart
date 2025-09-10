class CourseModel {
  final int id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int? categoryId;
  final String? categoryName;
  final String? instructorName;
  final int? durationMinutes;
  final String? level;
  final double? price;
  final bool isFree;
  final double? rating;
  final int totalRatings;
  final int totalEnrollments;
  final bool isEnrolled;
  final double progressPercentage;
  final String? courseUrl;

  CourseModel({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.categoryId,
    this.categoryName,
    this.instructorName,
    this.durationMinutes,
    this.level,
    this.price,
    required this.isFree,
    this.rating,
    required this.totalRatings,
    required this.totalEnrollments,
    required this.isEnrolled,
    required this.progressPercentage,
    this.courseUrl,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    try {
      return CourseModel(
        id: _parseInt(json['id']) ?? 0,
        title: _parseString(json['title']) ?? 'Untitled Course',
        description: _parseString(json['description']),
        thumbnailUrl: _parseString(json['thumbnail_url']),
        categoryId: _parseInt(json['category_id']),
        categoryName: _parseString(json['category_name']),
        instructorName: _parseString(json['instructor_name']),
        durationMinutes: _parseInt(json['duration_minutes']),
        level: _parseString(json['level']),
        price: _parseDouble(json['price']),
        isFree: _parseBool(json['is_free']) ?? true,
        rating: _parseDouble(json['rating']),
        totalRatings: _parseInt(json['total_ratings']) ?? 0,
        totalEnrollments: _parseInt(json['total_enrollments']) ?? 0,
        isEnrolled: _parseBool(json['is_enrolled']) ?? false,
        progressPercentage: _parseDouble(json['progress_percentage']) ?? 0.0,
        courseUrl: _parseString(json['course_url']),
      );
    } catch (e) {
      print('Error parsing CourseModel from JSON: $e');
      // Return a default course model to prevent crashes
      return CourseModel(
        id: 0,
        title: 'Error Loading Course',
        isFree: true,
        totalRatings: 0,
        totalEnrollments: 0,
        isEnrolled: false,
        progressPercentage: 0.0,
      );
    }
  }

  // Helper methods for safe parsing
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.round();
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'category_id': categoryId,
      'category_name': categoryName,
      'instructor_name': instructorName,
      'duration_minutes': durationMinutes,
      'level': level,
      'price': price,
      'is_free': isFree,
      'rating': rating,
      'total_ratings': totalRatings,
      'total_enrollments': totalEnrollments,
      'is_enrolled': isEnrolled,
      'progress_percentage': progressPercentage,
      'course_url': courseUrl,
    };
  }

  String get formattedDuration {
    if (durationMinutes == null || durationMinutes! <= 0) return 'N/A';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get difficultyBadgeColor {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return '#4CAF50'; // Green
      case 'intermediate':
        return '#FF9800'; // Orange
      case 'advanced':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  bool get isFeatured => 
      rating != null && 
      rating! >= 4.5 && 
      totalEnrollments > 100000;
  
  bool get isPopular => totalEnrollments > 200000;

  // Create a copy with updated values
  CourseModel copyWith({
    int? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    int? categoryId,
    String? categoryName,
    String? instructorName,
    int? durationMinutes,
    String? level,
    double? price,
    bool? isFree,
    double? rating,
    int? totalRatings,
    int? totalEnrollments,
    bool? isEnrolled,
    double? progressPercentage,
    String? courseUrl,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      instructorName: instructorName ?? this.instructorName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      level: level ?? this.level,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalEnrollments: totalEnrollments ?? this.totalEnrollments,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      courseUrl: courseUrl ?? this.courseUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CourseModel{id: $id, title: $title, isEnrolled: $isEnrolled}';
  }
}