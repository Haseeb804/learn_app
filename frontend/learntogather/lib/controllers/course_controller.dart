import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/course_model.dart';
import '../models/category_model.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';

class CourseController extends ChangeNotifier {
  final ApiService _apiService;
  
  List<CategoryModel> _categories = [];
  List<CourseModel> _courses = [];
  List<CourseModel> _enrolledCourses = [];
  List<LessonModel> _currentCourseLessons = [];
  List<QuizModel> _currentCourseQuizzes = [];
  
  // Search and filter state
  String _currentSearchQuery = '';
  int? _currentCategoryFilter;
  
  bool _isLoading = false;
  String? _error;
  
  // Add connection status tracking
  bool _isConnected = true;
  bool _useOfflineMode = false;
  
  CourseController(this._apiService);
  
  // Getters
  List<CategoryModel> get categories => _categories;
  List<CourseModel> get courses => _courses;
  List<CourseModel> get enrolledCourses => _enrolledCourses;
  List<LessonModel> get currentCourseLessons => _currentCourseLessons;
  List<QuizModel> get currentCourseQuizzes => _currentCourseQuizzes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentSearchQuery => _currentSearchQuery;
  int? get currentCategoryFilter => _currentCategoryFilter;
  bool get isConnected => _isConnected;
  bool get useOfflineMode => _useOfflineMode;
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setConnectionStatus(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  void toggleOfflineMode() {
    _useOfflineMode = !_useOfflineMode;
    notifyListeners();
  }
  
  // Enhanced load categories with retry logic
  Future<void> loadCategories({int maxRetries = 3}) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        _setLoading(true);
        _setError(null);
        
        if (!_useOfflineMode) {
          _categories = await _apiService.getCategories();
          _setConnectionStatus(true);
          break;
        } else {
          throw Exception('Offline mode enabled');
        }
        
      } catch (e) {
        retryCount++;
        _setConnectionStatus(false);
        
        if (retryCount >= maxRetries || _useOfflineMode) {
          // Use fallback categories
          _categories = _getFallbackCategories();
          debugPrint('Using fallback categories due to API error: $e');
          break;
        } else {
          // Wait before retry
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
    }
    
    _setLoading(false);
  }
  
  List<CategoryModel> _getFallbackCategories() {
    return [
      CategoryModel(
        id: 1, 
        name: 'Programming', 
        description: 'Learn programming languages and concepts',
        iconUrl: null,
        color: '#4CAF50'
      ),
      CategoryModel(
        id: 2, 
        name: 'Web Development', 
        description: 'Frontend and backend web development',
        iconUrl: null,
        color: '#2196F3'
      ),
      CategoryModel(
        id: 3, 
        name: 'Data Science', 
        description: 'Analytics, ML, and data visualization',
        iconUrl: null,
        color: '#FF9800'
      ),
      CategoryModel(
        id: 4, 
        name: 'Mobile Development', 
        description: 'iOS, Android, and cross-platform apps',
        iconUrl: null,
        color: '#9C27B0'
      ),
      CategoryModel(
        id: 5, 
        name: 'Design', 
        description: 'UI/UX, graphic design, and creativity',
        iconUrl: null,
        color: '#E91E63'
      ),
      CategoryModel(
        id: 6, 
        name: 'Business', 
        description: 'Entrepreneurship, marketing, and management',
        iconUrl: null,
        color: '#795548'
      ),
    ];
  }
  
  // Enhanced load courses with retry logic and better caching
  Future<void> loadCourses({
    int? categoryId, 
    String? search, 
    int maxRetries = 2
  }) async {
    int retryCount = 0;
    
    // Update current filters
    _currentSearchQuery = search ?? '';
    _currentCategoryFilter = categoryId;
    
    while (retryCount < maxRetries) {
      try {
        _setLoading(true);
        _setError(null);
        
        if (!_useOfflineMode) {
          _courses = await _apiService.getCourses(
            categoryId: categoryId,
            search: search,
          );
          _setConnectionStatus(true);
          break;
        } else {
          throw Exception('Offline mode enabled');
        }
        
      } catch (e) {
        retryCount++;
        _setConnectionStatus(false);
        
        if (retryCount >= maxRetries || _useOfflineMode) {
          // Use cached/mock data
          _courses = _getMockCourses();
          
          // Apply filters to mock data
          if (categoryId != null) {
            _courses = _courses.where((course) => course.categoryId == categoryId).toList();
          }
          if (search != null && search.isNotEmpty) {
            final query = search.toLowerCase();
            _courses = _courses.where((course) =>
              course.title.toLowerCase().contains(query) ||
              (course.description?.toLowerCase().contains(query) ?? false) ||
              (course.instructorName?.toLowerCase().contains(query) ?? false)
            ).toList();
          }
          
          debugPrint('Using cached/mock courses due to API error: $e');
          break;
        } else {
          // Wait before retry
          await Future.delayed(Duration(seconds: retryCount));
        }
      }
    }
    
    _setLoading(false);
  }
  
  // Enhanced mock courses data with more variety
  List<CourseModel> _getMockCourses() {
    return [
      CourseModel(
        id: 1,
        title: 'Complete Flutter Development Bootcamp',
        description: 'Master Flutter and Dart to build native iOS and Android apps from scratch. This comprehensive course covers everything from basic UI widgets to advanced state management patterns.',
        thumbnailUrl: null,
        categoryId: 4,
        categoryName: 'Mobile Development',
        instructorName: 'Dr. Angela Yu',
        durationMinutes: 840,
        level: 'Beginner',
        price: 99.99,
        isFree: false,
        rating: 4.8,
        totalRatings: 25430,
        totalEnrollments: 180000,
        isEnrolled: false,
        progressPercentage: 0.0,
        courseUrl: 'https://www.youtube.com/watch?v=1gDhl4leEzA',
      ),
      CourseModel(
        id: 2,
        title: 'UI/UX Design with Figma - Complete Course',
        description: 'Learn professional UI/UX design principles and master Figma to create stunning digital experiences. Perfect for beginners and designers looking to upgrade their skills.',
        thumbnailUrl: null,
        categoryId: 5,
        categoryName: 'Design',
        instructorName: 'Gary Simon',
        durationMinutes: 720,
        level: 'Beginner',
        price: 0,
        isFree: true,
        rating: 4.7,
        totalRatings: 18750,
        totalEnrollments: 320000,
        isEnrolled: false,
        progressPercentage: 0.0,
        courseUrl: 'https://www.youtube.com/watch?v=c9Wg6Cb_YlU',
      ),
      CourseModel(
        id: 3,
        title: 'React Native - The Practical Guide',
        description: 'Build native mobile apps with React Native and JavaScript. Learn to create cross-platform applications that run on both iOS and Android devices.',
        thumbnailUrl: null,
        categoryId: 4,
        categoryName: 'Mobile Development',
        instructorName: 'Maximilian Schwarzmüller',
        durationMinutes: 660,
        level: 'Intermediate',
        price: 89.99,
        isFree: false,
        rating: 4.6,
        totalRatings: 12450,
        totalEnrollments: 95000,
        isEnrolled: false,
        progressPercentage: 0.0,
        courseUrl: 'https://www.youtube.com/watch?v=obH0Po_RdWk',
      ),
      CourseModel(
        id: 4,
        title: 'Python Programming for Everybody',
        description: 'This course aims to teach everyone the basics of programming computers using Python. We cover the basics of how one constructs a program from a series of simple instructions in Python.',
        thumbnailUrl: null,
        categoryId: 1,
        categoryName: 'Programming',
        instructorName: 'Dr. Charles Severance',
        durationMinutes: 960,
        level: 'Beginner',
        price: 0,
        isFree: true,
        rating: 4.9,
        totalRatings: 45230,
        totalEnrollments: 850000,
        isEnrolled: false,
        progressPercentage: 0.0,
        courseUrl: 'https://www.youtube.com/watch?v=8DvywoWv6fI',
      ),
      CourseModel(
        id: 5,
        title: 'The Complete Web Developer Bootcamp',
        description: 'The only course you need to learn web development - HTML, CSS, JS, Node, and More! Build 16 web development projects and learn the latest technologies.',
        thumbnailUrl: null,
        categoryId: 2,
        categoryName: 'Web Development',
        instructorName: 'Colt Steele',
        durationMinutes: 1440,
        level: 'Beginner',
        price: 129.99,
        isFree: false,
        rating: 4.7,
        totalRatings: 35670,
        totalEnrollments: 450000,
        isEnrolled: false,
        progressPercentage: 0.0,
        courseUrl: 'https://www.youtube.com/watch?v=pQN-pnXPaVg',
      ),
      CourseModel(
        id: 6,
        title: 'Data Science and Machine Learning with Python',
        description: 'Learn how to use NumPy, Pandas, Seaborn, Matplotlib, Plotly, Scikit-Learn, Machine Learning, Tensorflow, and more for data science and machine learning!',
        thumbnailUrl: null,
        categoryId: 3,
        categoryName: 'Data Science',
        instructorName: 'Jose Portilla',
        durationMinutes: 1200,
        level: 'Intermediate',
        price: 149.99,
        isFree: false,
        rating: 4.8,
        totalRatings: 28940,
        totalEnrollments: 280000,
        isEnrolled: false,
        progressPercentage: 0.0,
        courseUrl: 'https://www.youtube.com/watch?v=rfscVS0vtbw',
      ),
      CourseModel(
        id: 7,
        title: 'JavaScript - The Complete Guide',
        description: 'Modern JavaScript from the beginning - all the way up to JS expert level! THE course for JavaScript beginners AND for those who want to sharpen their JS skills.',
        thumbnailUrl: null,
        categoryId: 1,
        categoryName: 'Programming',
        instructorName: 'Maximilian Schwarzmüller',
        durationMinutes: 1560,
        level: 'Beginner',
        price: 109.99,
        isFree: false,
        rating: 4.6,
        totalRatings: 41230,
        totalEnrollments: 380000,
        isEnrolled: false,
        progressPercentage: 0.0,
        courseUrl: 'https://www.youtube.com/watch?v=PkZNo7MFNFg',
      ),
      CourseModel(
        id: 8,
        title: 'Digital Marketing Complete Course',
        description: 'Learn Digital Marketing: SEO, YouTube Marketing, Facebook Marketing, Google Adwords, Google Analytics & more! Get Started with Digital Marketing Today.',
        thumbnailUrl: null,
        categoryId: 6,
        categoryName: 'Business',
        instructorName: 'Daragh Walsh',
        durationMinutes: 840,
        level: 'Beginner',
        price: 79.99,
        isFree: false,
        rating: 4.4,
        totalRatings: 15670,
        totalEnrollments: 125000,
        isEnrolled: false,
        progressPercentage: 0.0,
        courseUrl: 'https://www.youtube.com/watch?v=bixR-KIJKYM',
      ),
      CourseModel(
        id: 9,
        title: 'Docker & Kubernetes Complete Guide',
        description: 'Build, test, and deploy Docker applications with Kubernetes while learning production-style development workflows.',
        thumbnailUrl: null,
        categoryId: 2,
        categoryName: 'Web Development',
        instructorName: 'Stephen Grider',
        durationMinutes: 1020,
        level: 'Advanced',
        price: 119.99,
        isFree: false,
        rating: 4.7,
        totalRatings: 18450,
        totalEnrollments: 95000,
        isEnrolled: false,
        progressPercentage: 0.0,
        courseUrl: 'https://www.youtube.com/watch?v=3c-iBn73dDE',
      ),
      CourseModel(
        id: 10,
        title: 'Complete Android Development Course',
        description: 'Learn Android App Development from scratch. Build real Android apps using Java and Kotlin programming languages.',
        thumbnailUrl: null,
        categoryId: 4,
        categoryName: 'Mobile Development',
        instructorName: 'Rahul Pandey',
        durationMinutes: 900,
        level: 'Intermediate',
        price: 0,
        isFree: true,
        rating: 4.5,
        totalRatings: 22340,
        totalEnrollments: 210000,
        isEnrolled: false,
        progressPercentage: 0.0,
        courseUrl: 'https://www.youtube.com/watch?v=fis26HvvDII',
      ),
    ];
  }
  
  // Enhanced load enrolled courses
  Future<void> loadEnrolledCourses({int maxRetries = 2}) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        _setLoading(true);
        _setError(null);
        
        if (!_useOfflineMode) {
          _enrolledCourses = await _apiService.getUserEnrollments();
          _setConnectionStatus(true);
          break;
        } else {
          throw Exception('Offline mode enabled');
        }
        
      } catch (e) {
        retryCount++;
        _setConnectionStatus(false);
        
        if (retryCount >= maxRetries || _useOfflineMode) {
          // Initialize empty if API fails
          _enrolledCourses = [];
          debugPrint('No enrolled courses or API error: $e');
          break;
        } else {
          // Wait before retry
          await Future.delayed(Duration(seconds: retryCount));
        }
      }
    }
    
    _setLoading(false);
  }
  
  // Enhanced course detail with fallback
  Future<CourseModel?> getCourseDetail(int courseId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (!_useOfflineMode) {
        try {
          final course = await _apiService.getCourseDetail(courseId);
          _setConnectionStatus(true);
          return course;
        } catch (e) {
          _setConnectionStatus(false);
          // Fallback to local course data
          final course = getCourseById(courseId);
          if (course != null) {
            debugPrint('Using cached course data: $e');
            return course;
          }
          throw Exception('Course not found');
        }
      } else {
        // Offline mode - use cached data
        return getCourseById(courseId);
      }
    } catch (e) {
      _setError('Failed to get course details: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Enhanced enroll course with better error handling
  Future<bool> enrollCourse(int courseId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Find the course first
      CourseModel? course = getCourseById(courseId);
      if (course == null) {
        // Try to get from mock data
        final allMockCourses = _getMockCourses();
        course = allMockCourses.firstWhere(
          (c) => c.id == courseId,
          orElse: () => throw Exception('Course not found'),
        );
      }
      
      bool enrollmentSuccessful = false;
      
      if (!_useOfflineMode) {
        try {
          await _apiService.enrollCourse(courseId);
          enrollmentSuccessful = true;
          _setConnectionStatus(true);
        } catch (e) {
          _setConnectionStatus(false);
          // Mock successful enrollment for demo
          debugPrint('API enrollment failed, mocking success: $e');
          enrollmentSuccessful = true;
        }
      } else {
        // Offline mode - always mock success
        enrollmentSuccessful = true;
      }
      
      if (enrollmentSuccessful) {
        // Update course enrollment status locally
        final courseIndex = _courses.indexWhere((c) => c.id == courseId);
        if (courseIndex != -1) {
          _courses[courseIndex] = _courses[courseIndex].copyWith(
            isEnrolled: true,
            totalEnrollments: _courses[courseIndex].totalEnrollments + 1,
          );
        }
        
        // Add to enrolled courses if not already present
        if (!_enrolledCourses.any((c) => c.id == courseId)) {
          final enrolledCourse = course.copyWith(
            isEnrolled: true,
            progressPercentage: 0.0,
          );
          _enrolledCourses.add(enrolledCourse);
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('Enrollment failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Enhanced load course lessons
  Future<void> loadCourseLessons(int courseId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (!_useOfflineMode) {
        try {
          _currentCourseLessons = await _apiService.getCourseLessons(courseId);
          _setConnectionStatus(true);
        } catch (e) {
          _setConnectionStatus(false);
          _currentCourseLessons = _getMockLessons(courseId);
          debugPrint('Using mock lessons due to API error: $e');
        }
      } else {
        _currentCourseLessons = _getMockLessons(courseId);
      }
    } catch (e) {
      _setError('Failed to load lessons: ${e.toString()}');
      _currentCourseLessons = _getMockLessons(courseId);
    } finally {
      _setLoading(false);
    }
  }
  
  // Enhanced mock lessons with video URLs
  List<LessonModel> _getMockLessons(int courseId) {
    // Get course details to customize lesson content
    final course = getCourseById(courseId);
    final courseTitle = course?.title ?? 'Course';
    
    return [
      LessonModel(
        id: 1,
        courseId: courseId,
        title: 'Welcome to $courseTitle',
        description: 'Introduction to the course and what you will learn. Get familiar with the course structure and requirements.',
        videoUrl: course?.courseUrl ?? 'https://www.youtube.com/watch?v=1gDhl4leEzA',
        durationSeconds: 480,
        orderIndex: 1,
        isPreview: true,
        isWatched: false,
        watchedDuration: 0,
      ),
      LessonModel(
        id: 2,
        courseId: courseId,
        title: 'Setting Up Your Development Environment',
        description: 'Install and configure all necessary tools and software for the course.',
        videoUrl: course?.courseUrl ?? 'https://www.youtube.com/watch?v=1gDhl4leEzA',
        durationSeconds: 720,
        orderIndex: 2,
        isPreview: false,
        isWatched: false,
        watchedDuration: 0,
      ),
      LessonModel(
        id: 3,
        courseId: courseId,
        title: 'Understanding the Fundamentals',
        description: 'Core concepts and principles you need to master before moving to advanced topics.',
        videoUrl: course?.courseUrl ?? 'https://www.youtube.com/watch?v=1gDhl4leEzA',
        durationSeconds: 900,
        orderIndex: 3,
        isPreview: false,
        isWatched: false,
        watchedDuration: 0,
      ),
      LessonModel(
        id: 4,
        courseId: courseId,
        title: 'Your First Practical Project',
        description: 'Apply what you have learned by building your first project step by step.',
        videoUrl: course?.courseUrl ?? 'https://www.youtube.com/watch?v=1gDhl4leEzA',
        durationSeconds: 1200,
        orderIndex: 4,
        isPreview: false,
        isWatched: false,
        watchedDuration: 0,
      ),
      LessonModel(
        id: 5,
        courseId: courseId,
        title: 'Advanced Techniques and Best Practices',
        description: 'Learn advanced techniques and industry best practices to enhance your skills.',
        videoUrl: course?.courseUrl ?? 'https://www.youtube.com/watch?v=1gDhl4leEzA',
        durationSeconds: 1080,
        orderIndex: 5,
        isPreview: false,
        isWatched: false,
        watchedDuration: 0,
      ),
    ];
  }

  // Enhanced lesson progress update
  Future<bool> updateLessonProgress({
    required int lessonId,
    required int watchedDurationSeconds,
    bool isCompleted = false,
  }) async {
    try {
      if (!_useOfflineMode) {
        try {
          await _apiService.updateLessonProgress(
            lessonId: lessonId,
            watchedDurationSeconds: watchedDurationSeconds,
            isCompleted: isCompleted,
          );
          _setConnectionStatus(true);
        } catch (e) {
          _setConnectionStatus(false);
          debugPrint('API progress update failed, updating locally: $e');
        }
      }
      
      // Update local lesson progress
      final lessonIndex = _currentCourseLessons.indexWhere((lesson) => lesson.id == lessonId);
      if (lessonIndex != -1) {
        _currentCourseLessons[lessonIndex] = _currentCourseLessons[lessonIndex].copyWith(
          isWatched: isCompleted,
          watchedDuration: watchedDurationSeconds,
        );
        
        // Update course progress if lesson belongs to an enrolled course
        _updateCourseProgress(_currentCourseLessons[lessonIndex].courseId);
        
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to update progress: ${e.toString()}');
      return false;
    }
  }

  // Helper method to update course progress based on completed lessons
  void _updateCourseProgress(int courseId) {
    final courseLessons = _currentCourseLessons.where((lesson) => lesson.courseId == courseId).toList();
    if (courseLessons.isEmpty) return;
    
    final completedLessons = courseLessons.where((lesson) => lesson.isWatched).length;
    final progressPercentage = (completedLessons / courseLessons.length) * 100;
    
    // Update enrolled course progress
    final enrolledCourseIndex = _enrolledCourses.indexWhere((course) => course.id == courseId);
    if (enrolledCourseIndex != -1) {
      _enrolledCourses[enrolledCourseIndex] = _enrolledCourses[enrolledCourseIndex].copyWith(
        progressPercentage: progressPercentage,
      );
    }
  }
  
  // Enhanced load course quizzes
  Future<void> loadCourseQuizzes(int courseId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (!_useOfflineMode) {
        try {
          _currentCourseQuizzes = await _apiService.getCourseQuizzes(courseId);
          _setConnectionStatus(true);
        } catch (e) {
          _setConnectionStatus(false);
          _currentCourseQuizzes = _getMockQuizzes(courseId);
          debugPrint('Using mock quizzes due to API error: $e');
        }
      } else {
        _currentCourseQuizzes = _getMockQuizzes(courseId);
      }
    } catch (e) {
      _setError('Failed to load quizzes: ${e.toString()}');
      _currentCourseQuizzes = _getMockQuizzes(courseId);
    } finally {
      _setLoading(false);
    }
  }
  
  // Enhanced mock quizzes
  List<QuizModel> _getMockQuizzes(int courseId) {
    return [
      QuizModel(
        id: 1,
        courseId: courseId,
        lessonId: 1,
        title: 'Course Introduction Quiz',
        description: 'Test your understanding of the course objectives and structure.',
        totalQuestions: 5,
        timeLimitMinutes: 10,
        passingScorePercentage: 70.0,
        attemptsAllowed: 3,
        userAttempts: 0,
        bestScore: null,
        isPassed: false,
      ),
      QuizModel(
        id: 2,
        courseId: courseId,
        lessonId: 3,
        title: 'Fundamentals Assessment',
        description: 'Evaluate your knowledge of the core concepts and principles.',
        totalQuestions: 10,
        timeLimitMinutes: 20,
        passingScorePercentage: 75.0,
        attemptsAllowed: 2,
        userAttempts: 0,
        bestScore: null,
        isPassed: false,
      ),
      QuizModel(
        id: 3,
        courseId: courseId,
        lessonId: 5,
        title: 'Advanced Techniques Quiz',
        description: 'Challenge yourself with advanced concepts and best practices.',
        totalQuestions: 15,
        timeLimitMinutes: 30,
        passingScorePercentage: 80.0,
        attemptsAllowed: 2,
        userAttempts: 0,
        bestScore: null,
        isPassed: false,
      ),
    ];
  }

  // Get quiz questions with mock data
  Future<List<QuestionModel>?> getQuizQuestions(int quizId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (!_useOfflineMode) {
        try {
          final questions = await _apiService.getQuizQuestions(quizId);
          _setConnectionStatus(true);
          return questions;
        } catch (e) {
          _setConnectionStatus(false);
          debugPrint('Using mock quiz questions due to API error: $e');
          return _getMockQuizQuestions(quizId);
        }
      } else {
        return _getMockQuizQuestions(quizId);
      }
    } catch (e) {
      _setError('Failed to load quiz questions: ${e.toString()}');
      return _getMockQuizQuestions(quizId);
    } finally {
      _setLoading(false);
    }
  }

  // Mock quiz questions
  List<QuestionModel> _getMockQuizQuestions(int quizId) {
    return [
      QuestionModel(
        id: 1,
        quizId: quizId,
        questionText: 'What is the main objective of this course?',
        questionType: 'multiple_choice',
        points: 10,
        orderIndex: 1,
        options: [
          {'id': 1, 'text': 'Learn basic concepts', 'is_correct': false},
          {'id': 2, 'text': 'Master advanced techniques', 'is_correct': true},
          {'id': 3, 'text': 'Get a certificate', 'is_correct': false},
          {'id': 4, 'text': 'Network with peers', 'is_correct': false},
        ],
      ),
      QuestionModel(
        id: 2,
        quizId: quizId,
        questionText: 'Which tool is recommended for development?',
        questionType: 'multiple_choice',
        points: 10,
        orderIndex: 2,
        options: [
          {'id': 1, 'text': 'VS Code', 'is_correct': true},
          {'id': 2, 'text': 'Notepad', 'is_correct': false},
          {'id': 3, 'text': 'Word', 'is_correct': false},
          {'id': 4, 'text': 'Excel', 'is_correct': false},
        ],
      ),
    ];
  }
  
  // Submit quiz with local handling
  Future<Map<String, dynamic>?> submitQuiz({
    required int quizId,
    required List<Map<String, dynamic>> answers,
    required int timeTakenSeconds,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      Map<String, dynamic>? result;
      
      if (!_useOfflineMode) {
        try {
          result = await _apiService.submitQuiz(
            quizId: quizId,
            answers: answers,
            timeTakenSeconds: timeTakenSeconds,
          );
          _setConnectionStatus(true);
        } catch (e) {
          _setConnectionStatus(false);
          // Mock quiz result
          result = _mockQuizSubmission(quizId, answers, timeTakenSeconds);
          debugPrint('Using mock quiz result due to API error: $e');
        }
      } else {
        result = _mockQuizSubmission(quizId, answers, timeTakenSeconds);
      }
      
      // Update quiz status locally
      if (result != null) {
        final quizIndex = _currentCourseQuizzes.indexWhere((quiz) => quiz.id == quizId);
        if (quizIndex != -1) {
          final quiz = _currentCourseQuizzes[quizIndex];
          _currentCourseQuizzes[quizIndex] = quiz.copyWith(
            userAttempts: quiz.userAttempts + 1,
            bestScore: quiz.bestScore != null 
                ? (result['score_percentage'] > quiz.bestScore! 
                    ? result['score_percentage'] 
                    : quiz.bestScore)
                : result['score_percentage'],
            isPassed: result['is_passed'] || quiz.isPassed,
          );
          notifyListeners();
        }
      }
      
      return result;
    } catch (e) {
      _setError('Failed to submit quiz: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Mock quiz submission result
  Map<String, dynamic> _mockQuizSubmission(int quizId, List<Map<String, dynamic>> answers, int timeTakenSeconds) {
    // Simple scoring logic - assume 70% correct for demo
    final totalQuestions = answers.length;
    final correctAnswers = (totalQuestions * 0.7).round();
    final scorePercentage = (correctAnswers / totalQuestions * 100).toDouble();
    
    final quiz = _currentCourseQuizzes.firstWhere((q) => q.id == quizId);
    final isPassed = scorePercentage >= quiz.passingScorePercentage;
    
    return {
      'attempt_id': DateTime.now().millisecondsSinceEpoch,
      'score_percentage': scorePercentage,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'is_passed': isPassed,
      'passing_score': quiz.passingScorePercentage,
      'time_taken_seconds': timeTakenSeconds,
    };
  }
  
  // Get user quiz attempts with mock data
  Future<List<Map<String, dynamic>>?> getUserQuizAttempts(int quizId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (!_useOfflineMode) {
        try {
          final attempts = await _apiService.getUserQuizAttempts(quizId);
          _setConnectionStatus(true);
          return attempts;
        } catch (e) {
          _setConnectionStatus(false);
          debugPrint('Using mock quiz attempts due to API error: $e');
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      _setError('Failed to load quiz attempts: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  // All the utility methods remain the same but with better error handling
  List<CourseModel> searchCourses(String query) {
    if (query.isEmpty) return _courses;
    
    final lowercaseQuery = query.toLowerCase();
    
    return _courses.where((course) {
      return course.title.toLowerCase().contains(lowercaseQuery) ||
             (course.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (course.instructorName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (course.categoryName?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }
  
  List<CourseModel> getCoursesByCategory(int categoryId) {
    return _courses.where((course) => course.categoryId == categoryId).toList();
  }
  
  List<CourseModel> getFeaturedCourses() {
    return _courses
        .where((course) => 
            course.rating != null && 
            course.rating! >= 4.5 && 
            course.totalEnrollments > 100000)
        .take(6)
        .toList();
  }
  
  List<CourseModel> getRecommendedCourses() {
    return _courses
        .where((course) => course.totalEnrollments > 80000)
        .toList()
        ..sort((a, b) => b.totalEnrollments.compareTo(a.totalEnrollments));
  }
  
  List<CourseModel> getCoursesByLevel(String level) {
    return _courses.where((course) => 
        course.level?.toLowerCase() == level.toLowerCase()).toList();
  }
  
  List<CourseModel> getFreeCourses() {
    return _courses.where((course) => course.isFree).toList();
  }
  
  List<CourseModel> getPaidCourses() {
    return _courses.where((course) => !course.isFree).toList();
  }
  
  List<CourseModel> getCoursesByRating({double minRating = 0.0}) {
    return _courses
        .where((course) => (course.rating ?? 0.0) >= minRating)
        .toList()
        ..sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
  }
  
  // Utility methods
  CategoryModel? getCategoryById(int categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }
  
  CourseModel? getCourseById(int courseId) {
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      try {
        return _enrolledCourses.firstWhere((course) => course.id == courseId);
      } catch (e) {
        return null;
      }
    }
  }
  
  bool isUserEnrolled(int courseId) {
    return _enrolledCourses.any((course) => course.id == courseId);
  }
  
  double getCourseProgress(int courseId) {
    final course = _enrolledCourses
        .where((course) => course.id == courseId)
        .firstOrNull;
    return course?.progressPercentage ?? 0.0;
  }

  // Clear all data
  void clearAllData() {
    _categories.clear();
    _courses.clear();
    _enrolledCourses.clear();
    _currentCourseLessons.clear();
    _currentCourseQuizzes.clear();
    _currentSearchQuery = '';
    _currentCategoryFilter = null;
    _error = null;
    notifyListeners();
  }
  
  // Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      loadCategories(),
      loadCourses(),
      loadEnrolledCourses(),
    ]);
  }

  // Clear search and filters
  void clearFilters() {
    _currentSearchQuery = '';
    _currentCategoryFilter = null;
    loadCourses();
  }
}