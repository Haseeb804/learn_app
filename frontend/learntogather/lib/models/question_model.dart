class QuestionModel {
  final int id;
  final int quizId;
  final String questionText;
  final String questionType;
  final int points;
  final int orderIndex;
  final List<Map<String, dynamic>> options;

  QuestionModel({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.orderIndex,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? 0,
      quizId: json['quiz_id'] ?? 0,
      questionText: json['question_text'] ?? '',
      questionType: json['question_type'] ?? 'multiple_choice',
      points: json['points'] ?? 10,
      orderIndex: json['order_index'] ?? 0,
      options: List<Map<String, dynamic>>.from(json['options'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_type': questionType,
      'points': points,
      'order_index': orderIndex,
      'options': options,
    };
  }

  bool get isMultipleChoice => questionType == 'multiple_choice';
  bool get isTrueFalse => questionType == 'true_false';
  bool get isFillBlank => questionType == 'fill_blank';
}