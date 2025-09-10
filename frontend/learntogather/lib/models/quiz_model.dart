// views/widgets/quiz_widget.dart
import 'package:flutter/material.dart';

class QuizModel {
  final int id;
  final int courseId;
  final int? lessonId;
  final String title;
  final String? description;
  final int totalQuestions;
  final int? timeLimitMinutes;
  final double passingScorePercentage;
  final int attemptsAllowed;
  final int userAttempts;
  final double? bestScore;
  final bool isPassed;

  QuizModel({
    required this.id,
    required this.courseId,
    this.lessonId,
    required this.title,
    this.description,
    required this.totalQuestions,
    this.timeLimitMinutes,
    required this.passingScorePercentage,
    required this.attemptsAllowed,
    required this.userAttempts,
    this.bestScore,
    required this.isPassed,
  });

  QuizModel copyWith({
    int? id,
    int? courseId,
    int? lessonId,
    String? title,
    String? description,
    int? totalQuestions,
    int? timeLimitMinutes,
    double? passingScorePercentage,
    int? attemptsAllowed,
    int? userAttempts,
    double? bestScore,
    bool? isPassed,
  }) {
    return QuizModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      lessonId: lessonId ?? this.lessonId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      passingScorePercentage: passingScorePercentage ?? this.passingScorePercentage,
      attemptsAllowed: attemptsAllowed ?? this.attemptsAllowed,
      userAttempts: userAttempts ?? this.userAttempts,
      bestScore: bestScore ?? this.bestScore,
      isPassed: isPassed ?? this.isPassed,
    );
  }

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] ?? 0,
      courseId: json['course_id'] ?? 0,
      lessonId: json['lesson_id'],
      title: json['title'] ?? 'Untitled Quiz',
      description: json['description'],
      totalQuestions: json['total_questions'] ?? 0,
      timeLimitMinutes: json['time_limit_minutes'],
      passingScorePercentage: (json['passing_score_percentage'] ?? 70.0).toDouble(),
      attemptsAllowed: json['attempts_allowed'] ?? 1,
      userAttempts: json['user_attempts'] ?? 0,
      bestScore: json['best_score']?.toDouble(),
      isPassed: json['is_passed'] ?? false,
    );
  }

  bool get canTakeQuiz => userAttempts < attemptsAllowed;
  int get remainingAttempts => attemptsAllowed - userAttempts;
}

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback? onTap;

  const QuizCard({
    Key? key,
    required this.quiz,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _getStatusColor(),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              if (quiz.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  quiz.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildQuizInfo(),
              if (quiz.bestScore != null) ...[
                const SizedBox(height: 12),
                _buildScoreSection(),
              ],
              const SizedBox(height: 12),
              _buildActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color color;
    
    if (quiz.isPassed) {
      text = 'PASSED';
      color = Colors.green;
    } else if (quiz.userAttempts >= quiz.attemptsAllowed) {
      text = 'FAILED';
      color = Colors.red;
    } else if (quiz.userAttempts > 0) {
      text = 'IN PROGRESS';
      color = Colors.orange;
    } else {
      text = 'NOT STARTED';
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuizInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            icon: Icons.quiz,
            label: 'Questions',
            value: quiz.totalQuestions.toString(),
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            icon: Icons.timer,
            label: 'Time',
            value: quiz.timeLimitMinutes != null 
                ? '${quiz.timeLimitMinutes} min'
                : 'No limit',
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            icon: Icons.grade,
            label: 'Pass Score',
            value: '${quiz.passingScorePercentage.toInt()}%',
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            icon: Icons.refresh,
            label: 'Attempts',
            value: '${quiz.userAttempts}/${quiz.attemptsAllowed}',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Best Score:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${quiz.bestScore!.toInt()}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: quiz.isPassed ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    String buttonText;
    Color buttonColor;
    bool enabled = true;

    if (quiz.isPassed) {
      buttonText = 'Review Quiz';
      buttonColor = Colors.green;
    } else if (quiz.canTakeQuiz) {
      if (quiz.userAttempts == 0) {
        buttonText = 'Start Quiz';
      } else {
        buttonText = 'Retake Quiz (${quiz.remainingAttempts} left)';
      }
      buttonColor = Colors.blue;
    } else {
      buttonText = 'No Attempts Remaining';
      buttonColor = Colors.grey;
      enabled = false;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (quiz.isPassed) {
      return Colors.green;
    } else if (quiz.userAttempts >= quiz.attemptsAllowed) {
      return Colors.red;
    } else if (quiz.userAttempts > 0) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}

class QuizListWidget extends StatelessWidget {
  final List<QuizModel> quizzes;
  final Function(QuizModel quiz)? onQuizTap;

  const QuizListWidget({
    Key? key,
    required this.quizzes,
    this.onQuizTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (quizzes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No quizzes available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for course assessments',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        return QuizCard(
          quiz: quiz,
          onTap: onQuizTap != null ? () => onQuizTap!(quiz) : null,
        );
      },
    );
  }
}