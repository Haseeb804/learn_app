import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final ApiService _apiService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  AuthController(this._apiService) {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      try {
        final idToken = await user.getIdToken();
        _apiService.setAuthToken(idToken ?? '');
        await _loadUserProfile();
      } catch (e) {
        _setError(e.toString());
      }
    } else {
      _currentUser = null;
      _apiService.setAuthToken('');
      notifyListeners();
    }
  }
  
  Future<void> _loadUserProfile() async {
    try {
      _currentUser = await _apiService.getUserProfile();
      _setError(null);
      notifyListeners();
    } catch (e) {
      // If user profile doesn't exist, create it
      if (e.toString().contains('404')) {
        await _createUserProfile();
      } else {
        _setError(e.toString());
      }
    }
  }
  
  Future<void> _createUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        _currentUser = await _apiService.registerUser(
          firebaseUid: user.uid,
          email: user.email!,
          displayName: user.displayName,
          profilePicture: user.photoURL,
        );
        _setError(null);
        notifyListeners();
      } catch (e) {
        _setError(e.toString());
      }
    }
  }
  
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getFirebaseAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> signUpWithEmail(String email, String password, String displayName) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await credential.user?.updateDisplayName(displayName);
      
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getFirebaseAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _auth.signOut();
      _currentUser = null;
      _apiService.setAuthToken('');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      _setError(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Updated updateProfile method to handle base64 image data
  Future<void> updateProfile(UserModel user) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No authenticated user');
      }

      // Update Firebase display name if it changed
      if (user.displayName != null && 
          user.displayName != firebaseUser.displayName) {
        await firebaseUser.updateDisplayName(user.displayName);
      }
      
      // Update profile via API service
      _currentUser = await _apiService.updateProfile(user);
      _setError(null);
      notifyListeners();
      
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete account method
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _setError(null);

      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No authenticated user');
      }

      // Delete from Firebase
      await firebaseUser.delete();
      
      _currentUser = null;
      _apiService.setAuthToken('');
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check authentication state manually
  Future<void> checkAuthState() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        final idToken = await firebaseUser.getIdToken();
        _apiService.setAuthToken(idToken ?? '');
        await _loadUserProfile();
      } else {
        _currentUser = null;
        _apiService.setAuthToken('');
        notifyListeners();
      }
    } catch (e) {
      print('Error checking auth state: $e');
    }
  }
  
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
