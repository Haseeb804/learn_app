// views/screens/courses/course_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controllers/course_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/course_model.dart';
import '../../../models/lesson_model.dart';
import '../../../../app_theme.dart';
import '../lessons/lesson_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseContent();
    });
  }

  Future<void> _loadCourseContent() async {
    if (widget.course.isEnrolled) {
      final courseController = Provider.of<CourseController>(context, listen: false);
      await Future.wait([
        courseController.loadCourseLessons(widget.course.id),
        courseController.loadCourseQuizzes(widget.course.id),
      ]);
    }
  }

  Future<void> _enrollInCourse() async {
    setState(() {
      _isLoading = true;
    });

    final courseController = Provider.of<CourseController>(context, listen: false);
    final success = await courseController.enrollCourse(widget.course.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully enrolled in course!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      await _loadCourseContent();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(courseController.error ?? 'Enrollment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _launchCourseUrl() async {
    if (widget.course.courseUrl != null) {
      final uri = Uri.parse(widget.course.courseUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open course URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Course Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCategoryColor().withOpacity(0.8),
                      _getCategoryColor().withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: widget.course.thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(widget.course.thumbnailUrl!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.course.isFree ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.course.isFree 
                                ? 'FREE COURSE' 
                                : '\$${widget.course.price?.toStringAsFixed(0) ?? '0'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.course.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.course.instructorName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'by ${widget.course.instructorName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Course Stats
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.star,
                    value: widget.course.rating?.toStringAsFixed(1) ?? 'N/A',
                    label: 'Rating',
                    color: Colors.amber,
                  ),
                  _buildStatItem(
                    icon: Icons.people,
                    value: _formatNumber(widget.course.totalEnrollments),
                    label: 'Students',
                    color: Colors.blue,
                  ),
                  _buildStatItem(
                    icon: Icons.access_time,
                    value: widget.course.formattedDuration,
                    label: 'Duration',
                    color: Colors.green,
                  ),
                  _buildStatItem(
                    icon: Icons.signal_cellular_alt,
                    value: widget.course.level ?? 'Beginner',
                    label: 'Level',
                    color: _getLevelColor(),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<CourseController>(
                builder: (context, courseController, child) {
                  final isEnrolled = courseController.enrolledCourses
                      .any((c) => c.id == widget.course.id) || widget.course.isEnrolled;

return SingleChildScrollView(
  child: Column(
    children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : isEnrolled
                  ? () => _showLessonsBottomSheet(context)
                  : _enrollInCourse,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  isEnrolled ? 'View Course Content' : 'Enroll Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
      const SizedBox(height: 12),
      if (widget.course.courseUrl != null)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _launchCourseUrl,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.open_in_new, size: 20),
                SizedBox(width: 8),
                Text(
                  'Open Original Course',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  ),
);
                },
              ),
            ),
          ),

          // Course Description
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About this course',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.course.description ?? 'No description available',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Lessons'),
                  Tab(text: 'Quizzes'),
                  Tab(text: 'Reviews'),
                ],
                indicator: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLessonsTab(),
                _buildQuizzesTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab() {
    return Consumer<CourseController>(
      builder: (context, courseController, child) {
        if (!widget.course.isEnrolled && 
            !courseController.enrolledCourses.any((c) => c.id == widget.course.id)) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Enroll to access lessons',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        if (courseController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (courseController.currentCourseLessons.isEmpty) {
          return const Center(
            child: Text('No lessons available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: courseController.currentCourseLessons.length,
          itemBuilder: (context, index) {
            final lesson = courseController.currentCourseLessons[index];
            return _buildLessonTile(lesson, index);
          },
        );
      },
    );
  }

  Widget _buildLessonTile(LessonModel lesson, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: lesson.isWatched 
                ? AppColors.primaryGreen 
                : AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            lesson.isWatched ? Icons.check_circle : Icons.play_arrow,
            color: lesson.isWatched ? Colors.white : AppColors.primaryGreen,
            size: 24,
          ),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (lesson.description != null)
              Text(
                lesson.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  lesson.formattedDuration,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                if (lesson.isPreview)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PREVIEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (lesson.isWatched && lesson.progressPercentage > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: lesson.progressPercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            ],
          ],
        ),
        trailing: lesson.isPreview || widget.course.isEnrolled
            ? const Icon(Icons.play_circle_outline, color: AppColors.primaryGreen)
            : const Icon(Icons.lock, color: Colors.grey),
        onTap: lesson.isPreview || widget.course.isEnrolled
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LessonPlayerScreen(
                      lesson: lesson,
                      course: widget.course,
                      allLessons: Provider.of<CourseController>(context, listen: false)
                          .currentCourseLessons,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }

  Widget _buildQuizzesTab() {
    return Consumer<CourseController>(
      builder: (context, courseController, child) {
        if (!widget.course.isEnrolled && 
            !courseController.enrolledCourses.any((c) => c.id == widget.course.id)) {
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
                  'Enroll to access quizzes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        if (courseController.currentCourseQuizzes.isEmpty) {
          return const Center(
            child: Text('No quizzes available for this course'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: courseController.currentCourseQuizzes.length,
          itemBuilder: (context, index) {
            final quiz = courseController.currentCourseQuizzes[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: quiz.isPassed
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    quiz.isPassed ? Icons.check_circle : Icons.quiz,
                    color: quiz.isPassed ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(
                  quiz.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quiz.description != null) ...[
                      const SizedBox(height: 4),
                      Text(quiz.description!),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('${quiz.totalQuestions} questions'),
                        const SizedBox(width: 16),
                        if (quiz.timeLimitMinutes != null)
                          Text('${quiz.timeLimitMinutes} minutes'),
                      ],
                    ),
                    if (quiz.userAttempts > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Best Score: ${quiz.bestScore?.toStringAsFixed(1) ?? 0}%',
                        style: TextStyle(
                          color: quiz.isPassed ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: quiz.canTakeQuiz
                    ? const Icon(Icons.play_arrow, color: AppColors.primaryGreen)
                    : const Icon(Icons.done, color: Colors.grey),
                onTap: quiz.canTakeQuiz
                    ? () {
                        // Navigate to quiz screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quiz feature coming soon!')),
                        );
                      }
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Reviews coming soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Student reviews and ratings will be available here',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLessonsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        'Course Lessons',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<CourseController>(
                    builder: (context, courseController, child) {
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: courseController.currentCourseLessons.length,
                        itemBuilder: (context, index) {
                          final lesson = courseController.currentCourseLessons[index];
                          return _buildLessonTile(lesson, index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Color _getCategoryColor() {
    switch (widget.course.categoryId) {
      case 1: // Programming
        return const Color(0xFF4CAF50);
      case 2: // Web Development
        return const Color(0xFF2196F3);
      case 3: // Data Science
        return const Color(0xFFFF9800);
      case 4: // Mobile Development
        return const Color(0xFF9C27B0);
      case 5: // Design
        return const Color(0xFFE91E63);
      default:
        return AppColors.primaryGreen;
    }
  }

  Color _getLevelColor() {
    switch (widget.course.level?.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFFFF9800);
      case 'advanced':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}