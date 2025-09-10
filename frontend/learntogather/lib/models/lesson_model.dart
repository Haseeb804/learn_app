class LessonModel {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final String? videoUrl;
  final int? durationSeconds;
  final int orderIndex;
  final bool isPreview;
  final bool isWatched;
  final int watchedDuration;

  LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.videoUrl,
    this.durationSeconds,
    required this.orderIndex,
    required this.isPreview,
    required this.isWatched,
    required this.watchedDuration,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] ?? 0,
      courseId: json['course_id'] ?? 0,
      title: json['title'] ?? 'Untitled Lesson',
      description: json['description'],
      videoUrl: json['video_url'],
      durationSeconds: json['duration_seconds'],
      orderIndex: json['order_index'] ?? 0,
      isPreview: json['is_preview'] ?? false,
      isWatched: json['is_watched'] ?? false,
      watchedDuration: json['watched_duration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'duration_seconds': durationSeconds,
      'order_index': orderIndex,
      'is_preview': isPreview,
      'is_watched': isWatched,
      'watched_duration': watchedDuration,
    };
  }

  String get formattedDuration {
    if (durationSeconds == null || durationSeconds! <= 0) return 'N/A';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progressPercentage {
    if (durationSeconds == null || durationSeconds == 0) return 0.0;
    return (watchedDuration / durationSeconds!) * 100;
  }

  int get duration {
    if (durationSeconds == null) return 0;
    return durationSeconds! ~/ 60;
  }

  // Add copyWith method
  LessonModel copyWith({
    int? id,
    int? courseId,
    String? title,
    String? description,
    String? videoUrl,
    int? durationSeconds,
    int? orderIndex,
    bool? isPreview,
    bool? isWatched,
    int? watchedDuration,
  }) {
    return LessonModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      orderIndex: orderIndex ?? this.orderIndex,
      isPreview: isPreview ?? this.isPreview,
      isWatched: isWatched ?? this.isWatched,
      watchedDuration: watchedDuration ?? this.watchedDuration,
    );
  }
}