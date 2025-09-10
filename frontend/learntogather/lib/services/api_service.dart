import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/category_model.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000'; // Change to your server URL
  static const Duration timeoutDuration = Duration(seconds: 30);
  
  String? _authToken;
  
  void setAuthToken(String token) {
    _authToken = token;
  }
  
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Helper method for making HTTP requests with better error handling
  Future<http.Response> _makeRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: _headers)
              .timeout(timeoutDuration);
          break;
        case 'POST':
          response = await http.post(
            uri, 
            headers: _headers, 
            body: body != null ? jsonEncode(body) : null,
          ).timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await http.put(
            uri, 
            headers: _headers, 
            body: body != null ? jsonEncode(body) : null,
          ).timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: _headers)
              .timeout(timeoutDuration);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return response;
    } on SocketException {
      throw Exception('No internet connection. Please check your network settings.');
    } on HttpException {
      throw Exception('Server error occurred. Please try again later.');
    } on FormatException {
      throw Exception('Invalid response format from server.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  // Helper method to handle API responses
  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('API Response: ${response.statusCode} - ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw Exception('Failed to parse server response');
      }
    } else {
      String errorMessage = 'Request failed with status: ${response.statusCode}';
      
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && errorBody.containsKey('detail')) {
          errorMessage = errorBody['detail'].toString();
        } else if (errorBody is Map && errorBody.containsKey('message')) {
          errorMessage = errorBody['message'].toString();
        }
      } catch (e) {
        // Use default error message if parsing fails
      }
      
      throw Exception(errorMessage);
    }
  }
  
  // Auth endpoints with better error handling
  Future<UserModel> registerUser({
    required String firebaseUid,
    required String email,
    String? displayName,
    String? profilePicture,
  }) async {
    try {
      final response = await _makeRequest(
        method: 'POST',
        endpoint: '/auth/register',
        body: {
          'firebase_uid': firebaseUid,
          'email': email,
          'display_name': displayName,
          'profile_picture': profilePicture,
        },
      );
      
      final data = _handleResponse(response);
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to register user: ${e.toString()}');
    }
  }
  
  Future<UserModel> getUserProfile() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/auth/profile',
      );
      
      final data = _handleResponse(response);
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  Future<UserModel> updateProfile(UserModel user) async {
    try {
      final response = await _makeRequest(
        method: 'PUT',
        endpoint: '/auth/profile',
        body: {
          'display_name': user.displayName,
          'profile_picture': user.profilePicture,
        },
      );
      
      final data = _handleResponse(response);
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
  
  // Category endpoints
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/categories',
      );
      
      final data = _handleResponse(response);
      if (data is! List) {
        throw Exception('Invalid categories response format');
      }
      
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get categories: ${e.toString()}');
    }
  }
  
  // Enhanced course endpoints
  Future<List<CourseModel>> getCourses({
    int? categoryId,
    String? search,
    String? level,
    bool? isFree,
    double? minRating,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (level != null) queryParams['level'] = level;
      if (isFree != null) queryParams['is_free'] = isFree.toString();
      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/courses',
        queryParams: queryParams,
      );
      
      final data = _handleResponse(response);
      if (data is! List) {
        throw Exception('Invalid courses response format');
      }
      
      return data.map((json) => CourseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get courses: ${e.toString()}');
    }
  }
  
  Future<CourseModel> getCourseDetail(int courseId) async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/courses/$courseId',
      );
      
      final data = _handleResponse(response);
      return CourseModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get course details: ${e.toString()}');
    }
  }
  
  Future<void> enrollCourse(int courseId) async {
    try {
      final response = await _makeRequest(
        method: 'POST',
        endpoint: '/courses/enroll',
        body: {
          'course_id': courseId,
        },
      );
      
      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to enroll course: ${e.toString()}');
    }
  }
  
  Future<List<CourseModel>> getUserEnrollments() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/user/enrollments',
      );
      
      final data = _handleResponse(response);
      if (data is! List) {
        throw Exception('Invalid enrollments response format');
      }
      
      return data.map((json) => CourseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user enrollments: ${e.toString()}');
    }
  }
  
  // Lesson endpoints
  Future<List<LessonModel>> getCourseLessons(int courseId) async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/courses/$courseId/lessons',
      );
      
      final data = _handleResponse(response);
      if (data is! List) {
        throw Exception('Invalid lessons response format');
      }
      
      return data.map((json) => LessonModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get course lessons: ${e.toString()}');
    }
  }
  
  Future<void> updateLessonProgress({
    required int lessonId,
    required int watchedDurationSeconds,
    bool isCompleted = false,
  }) async {
    try {
      final response = await _makeRequest(
        method: 'POST',
        endpoint: '/lessons/progress',
        body: {
          'lesson_id': lessonId,
          'watched_duration_seconds': watchedDurationSeconds,
          'is_completed': isCompleted,
        },
      );
      
      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update lesson progress: ${e.toString()}');
    }
  }
  
  // Quiz endpoints
  Future<List<QuizModel>> getCourseQuizzes(int courseId) async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/courses/$courseId/quizzes',
      );
      
      final data = _handleResponse(response);
      if (data is! List) {
        throw Exception('Invalid quizzes response format');
      }
      
      return data.map((json) => QuizModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get course quizzes: ${e.toString()}');
    }
  }
  
  Future<List<QuestionModel>> getQuizQuestions(int quizId) async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/quizzes/$quizId/questions',
      );
      
      final data = _handleResponse(response);
      if (data is! List) {
        throw Exception('Invalid questions response format');
      }
      
      return data.map((json) => QuestionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get quiz questions: ${e.toString()}');
    }
  }
  
  Future<Map<String, dynamic>> submitQuiz({
    required int quizId,
    required List<Map<String, dynamic>> answers,
    required int timeTakenSeconds,
  }) async {
    try {
      final response = await _makeRequest(
        method: 'POST',
        endpoint: '/quizzes/submit',
        body: {
          'quiz_id': quizId,
          'answers': answers,
          'time_taken_seconds': timeTakenSeconds,
        },
      );
      
      final data = _handleResponse(response);
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid quiz submission response format');
      }
      
      return data;
    } catch (e) {
      throw Exception('Failed to submit quiz: ${e.toString()}');
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserQuizAttempts(int quizId) async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/user/quiz-attempts/$quizId',
      );
      
      final data = _handleResponse(response);
      if (data is! List) {
        throw Exception('Invalid quiz attempts response format');
      }
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Failed to get quiz attempts: ${e.toString()}');
    }
  }
  
  // Get featured courses
  Future<List<CourseModel>> getFeaturedCourses() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/courses/featured',
      );
      
      final data = _handleResponse(response);
      if (data is! List) {
        throw Exception('Invalid featured courses response format');
      }
      
      return data.map((json) => CourseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get featured courses: ${e.toString()}');
    }
  }
  
  // Get popular courses
  Future<List<CourseModel>> getPopularCourses() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/courses/popular',
      );
      
      final data = _handleResponse(response);
      if (data is! List) {
        throw Exception('Invalid popular courses response format');
      }
      
      return data.map((json) => CourseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get popular courses: ${e.toString()}');
    }
  }
  
  // Advanced search and filtering
  Future<List<CourseModel>> searchCoursesAdvanced({
    String? query,
    List<int>? categoryIds,
    List<String>? levels,
    bool? isFree,
    double? minRating,
    double? maxPrice,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (query != null && query.isNotEmpty) queryParams['search'] = query;
      if (categoryIds != null && categoryIds.isNotEmpty) {
        queryParams['category_ids'] = categoryIds.join(',');
      }
      if (levels != null && levels.isNotEmpty) {
        queryParams['levels'] = levels.join(',');
      }
      if (isFree != null) queryParams['is_free'] = isFree.toString();
      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/courses/search',
        queryParams: queryParams,
      );
      
      final data = _handleResponse(response);
      if (data is! List) {
        throw Exception('Invalid search results response format');
      }
      
      return data.map((json) => CourseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search courses: ${e.toString()}');
    }
  }
  
  // Get course statistics
  Future<Map<String, dynamic>> getCourseStats() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/courses/stats',
      );
      
      final data = _handleResponse(response);
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid course stats response format');
      }
      
      return data;
    } catch (e) {
      throw Exception('Failed to get course statistics: ${e.toString()}');
    }
  }

  // Connection test method
  Future<bool> testConnection() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/',
      );
      
      _handleResponse(response);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Connection test failed: $e');
      }
      return false;
    }
  }

  // Health check endpoint
  Future<Map<String, dynamic>?> healthCheck() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/health',
      );
      
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Health check failed: $e');
      }
      return null;
    }
  }
}