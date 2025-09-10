import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'controllers/auth_controller.dart';
import 'controllers/course_controller.dart';
import 'controllers/theme_controller.dart';
import 'views/screens/splash_screen.dart';
import 'views/screens/auth/login_screen.dart';
import 'views/screens/home/home_screen.dart';
import 'views/screens/profile/edit_profile_screen.dart';
import 'app_theme.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WebView platform with better error handling
  if (!kIsWeb) {
    try {
      late PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance == null) {
        if (Platform.isAndroid) {
          params = AndroidWebViewControllerCreationParams();
        } else if (Platform.isIOS) {
          params = WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          );
        } else {
          params = const PlatformWebViewControllerCreationParams();
        }
        
        // Initialize the platform instance
        if (Platform.isAndroid) {
          WebViewPlatform.instance = AndroidWebViewPlatform();
        } else if (Platform.isIOS) {
          WebViewPlatform.instance = WebKitWebViewPlatform();
        }
      }
    } catch (e) {
      print('WebView platform initialization warning: $e');
      // Continue without WebView if platform initialization fails
    }
  }

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD2ii-AXhCuhIwjTYZQfxlZLsXEu8kwY3k",
        appId: "1:502330410824:web:de2028b08abbd38b9b557d",
        messagingSenderId: "502330410824",
        projectId: "rentelease-77e8b",
        authDomain: "rentelease-77e8b.firebaseapp.com",
        storageBucket: "rentelease-77e8b.firebasestorage.app",
      ),
    );
  } catch (e) {
    print('Firebase initialization error: $e');
    // You might want to show an error dialog here
  }
  
  final prefs = await SharedPreferences.getInstance();
  final apiService = ApiService();
  
  runApp(MyApp(
    prefs: prefs,
    apiService: apiService,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final ApiService apiService;

  const MyApp({
    Key? key,
    required this.prefs,
    required this.apiService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeController(prefs),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthController(apiService),
        ),
        ChangeNotifierProvider(
          create: (context) => CourseController(apiService),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'Internee.pk Learning',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/edit-profile': (context) => const EditProfileScreen(),
            },
            // Add global error handling
            builder: (context, widget) {
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return Material(
                  child: Container(
                    color: Colors.red[100],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[700],
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Something went wrong!',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (kDebugMode)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                errorDetails.exceptionAsString(),
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              };
              
              return widget ?? Container();
            },
          );
        },
      ),
    );
  }
}