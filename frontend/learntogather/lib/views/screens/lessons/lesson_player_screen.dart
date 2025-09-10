// views/screens/lessons/lesson_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../controllers/course_controller.dart';
import '../../../models/lesson_model.dart';
import '../../../models/course_model.dart';
import '../../widgets/video_player_widget.dart';
import '../../../../app_theme.dart';

class LessonPlayerScreen extends StatefulWidget {
  final LessonModel lesson;
  final CourseModel course;
  final List<LessonModel> allLessons;

  const LessonPlayerScreen({
    Key? key,
    required this.lesson,
    required this.course,
    required this.allLessons,
  }) : super(key: key);

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  late LessonModel currentLesson;
  bool _showPlaylist = false;
  int _watchedSeconds = 0;

  @override
  void initState() {
    super.initState();
    currentLesson = widget.lesson;
    _watchedSeconds = currentLesson.watchedDuration;
  }

  Future<void> _updateProgress(int seconds) async {
    _watchedSeconds = seconds;
    
    // Update progress every 30 seconds
    if (seconds % 30 == 0 && seconds > 0) {
      final courseController = Provider.of<CourseController>(context, listen: false);
      final isCompleted = seconds >= (currentLesson.durationSeconds ?? 0) * 0.8;
      
      await courseController.updateLessonProgress(
        lessonId: currentLesson.id,
        watchedDurationSeconds: seconds,
        isCompleted: isCompleted,
      );
      
      if (isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lesson "${currentLesson.title}" completed!'),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onVideoComplete() {
    final courseController = Provider.of<CourseController>(context, listen: false);
    courseController.updateLessonProgress(
      lessonId: currentLesson.id,
      watchedDurationSeconds: currentLesson.durationSeconds ?? 0,
      isCompleted: true,
    );
    
    // Auto-play next lesson if available
    final nextLesson = _getNextLesson();
    if (nextLesson != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lesson Complete!'),
          content: Text('Would you like to continue with "${nextLesson.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Stay Here'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _playLesson(nextLesson);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text('Next Lesson'),
            ),
          ],
        ),
      );
    }
  }

  void _playLesson(LessonModel lesson) {
    setState(() {
      currentLesson = lesson;
      _watchedSeconds = lesson.watchedDuration;
    });
  }

  LessonModel? _getNextLesson() {
    final currentIndex = widget.allLessons.indexWhere((l) => l.id == currentLesson.id);
    if (currentIndex < widget.allLessons.length - 1) {
      return widget.allLessons[currentIndex + 1];
    }
    return null;
  }

  LessonModel? _getPreviousLesson() {
    final currentIndex = widget.allLessons.indexWhere((l) => l.id == currentLesson.id);
    if (currentIndex > 0) {
      return widget.allLessons[currentIndex - 1];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Section
            _buildVideoPlayer(),
            
            // Content Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Lesson Info Header
                    _buildLessonHeader(),
                    
                    // Tab Content
                    Expanded(
                      child: _showPlaylist 
                          ? _buildPlaylistView()
                          : _buildLessonContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // In-App Video Player
          InAppVideoPlayer(
            videoUrl: currentLesson.videoUrl,
            title: currentLesson.title,
            onProgressUpdate: _updateProgress,
            onVideoComplete: _onVideoComplete,
          ),
          
          // Back button
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Playlist toggle button
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showPlaylist = !_showPlaylist;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _showPlaylist ? Icons.video_library : Icons.list,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLesson.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.course.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showPlaylist = !_showPlaylist;
                  });
                },
                child: Text(
                  _showPlaylist ? 'Hide Playlist' : 'Show Playlist',
                  style: const TextStyle(color: AppColors.primaryGreen),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getPreviousLesson() != null
                      ? () => _playLesson(_getPreviousLesson()!)
                      : null,
                  icon: const Icon(Icons.skip_previous),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getNextLesson() != null
                      ? () => _playLesson(_getNextLesson()!)
                      : null,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson description
          if (currentLesson.description != null) ...[
            Text(
              'About this lesson',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              currentLesson.description!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Lesson stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  icon: Icons.access_time,
                  value: currentLesson.formattedDuration,
                  label: 'Duration',
                ),
                _buildStatColumn(
                  icon: Icons.play_circle,
                  value: '${widget.allLessons.indexOf(currentLesson) + 1}/${widget.allLessons.length}',
                  label: 'Lesson',
                ),
                _buildStatColumn(
                  icon: Icons.trending_up,
                  value: '${currentLesson.progressPercentage.toStringAsFixed(0)}%',
                  label: 'Progress',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Course navigation
          Text(
            'Course Navigation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick lesson navigation
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.allLessons.length,
              itemBuilder: (context, index) {
                final lesson = widget.allLessons[index];
                final isCurrentLesson = lesson.id == currentLesson.id;
                
                return GestureDetector(
                  onTap: () => _playLesson(lesson),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isCurrentLesson 
                          ? AppColors.primaryGreen 
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentLesson 
                            ? AppColors.primaryGreen 
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          lesson.isWatched ? Icons.check_circle : Icons.play_circle,
                          color: isCurrentLesson ? Colors.white : AppColors.primaryGreen,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrentLesson ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${(lesson.durationSeconds ?? 0) ~/ 60}m',
                          style: TextStyle(
                            color: isCurrentLesson ? Colors.white70 : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.allLessons.length,
      itemBuilder: (context, index) {
        final lesson = widget.allLessons[index];
        final isCurrentLesson = lesson.id == currentLesson.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCurrentLesson ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentLesson ? AppColors.primaryGreen : Colors.grey[300]!,
            ),
            boxShadow: isCurrentLesson ? [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: lesson.isWatched
                    ? AppColors.primaryGreen
                    : (isCurrentLesson ? AppColors.primaryGreen : Colors.grey[300]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                lesson.isWatched ? Icons.check : Icons.play_arrow,
                color: lesson.isWatched || isCurrentLesson ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            title: Text(
              lesson.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isCurrentLesson ? AppColors.primaryGreen : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${lesson.formattedDuration} • Lesson ${index + 1}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (lesson.isWatched) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: lesson.progressPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  ),
                ],
              ],
            ),
            trailing: isCurrentLesson
                ? const Icon(Icons.play_circle, color: AppColors.primaryGreen)
                : null,
            onTap: () => _playLesson(lesson),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
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
}