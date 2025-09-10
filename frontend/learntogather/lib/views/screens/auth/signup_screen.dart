import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../../app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          // Navigate to home if authenticated
          if (authController.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/home');
            });
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGreen.withOpacity(0.1),
                  AppColors.lightGreen.withOpacity(0.05),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Back Button and Theme Toggle
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  Consumer<ThemeController>(
                                    builder: (context, themeController, child) {
                                      return IconButton(
                                        onPressed: () => themeController.toggleTheme(),
                                        icon: Icon(
                                          themeController.isDarkMode
                                              ? Icons.light_mode
                                              : Icons.dark_mode,
                                          color: AppColors.primaryGreen,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              
                              // Logo and Title
                              const Hero(
                                tag: 'app_logo',
                                child: Icon(
                                  Icons.school,
                                  size: 80,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Text(
                                'Create Account',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                'Join us and start your learning journey',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Sign Up Form
                              Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Display Name Field
                                        CustomTextField(
                                          controller: _displayNameController,
                                          label: 'Full Name',
                                          hint: 'Enter your full name',
                                          keyboardType: TextInputType.name,
                                          prefixIcon: Icons.person_outlined,
                                          validator: (value) {
                                            if (value?.isEmpty ?? true) {
                                              return 'Please enter your full name';
                                            }
                                            if (value!.length < 2) {
                                              return 'Name must be at least 2 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Email Field
                                        CustomTextField(
                                          controller: _emailController,
                                          label: 'Email',
                                          hint: 'Enter your email',
                                          keyboardType: TextInputType.emailAddress,
                                          prefixIcon: Icons.email_outlined,
                                          validator: (value) {
                                            if (value?.isEmpty ?? true) {
                                              return 'Please enter your email';
                                            }
                                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                .hasMatch(value!)) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Password Field
                                        CustomTextField(
                                          controller: _passwordController,
                                          label: 'Password',
                                          hint: 'Create a password',
                                          obscureText: _obscurePassword,
                                          prefixIcon: Icons.lock_outlined,
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value?.isEmpty ?? true) {
                                              return 'Please enter a password';
                                            }
                                            if (value!.length < 8) {
                                              return 'Password must be at least 8 characters';
                                            }
                                            if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)')
                                                .hasMatch(value)) {
                                              return 'Password must contain uppercase, lowercase, and number';
                                            }
                                            return null;
                                          },
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Confirm Password Field
                                        CustomTextField(
                                          controller: _confirmPasswordController,
                                          label: 'Confirm Password',
                                          hint: 'Confirm your password',
                                          obscureText: _obscureConfirmPassword,
                                          prefixIcon: Icons.lock_outlined,
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirmPassword = !_obscureConfirmPassword;
                                              });
                                            },
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value?.isEmpty ?? true) {
                                              return 'Please confirm your password';
                                            }
                                            if (value != _passwordController.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Terms and Conditions Checkbox
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Checkbox(
                                              value: _acceptTerms,
                                              onChanged: (value) {
                                                setState(() {
                                                  _acceptTerms = value ?? false;
                                                });
                                              },
                                              activeColor: AppColors.primaryGreen,
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _acceptTerms = !_acceptTerms;
                                                  });
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.only(top: 12),
                                                  child: RichText(
                                                    text: TextSpan(
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                      children: [
                                                        const TextSpan(text: 'I agree to the '),
                                                        TextSpan(
                                                          text: 'Terms of Service',
                                                          style: TextStyle(
                                                            color: AppColors.primaryGreen,
                                                            decoration: TextDecoration.underline,
                                                          ),
                                                        ),
                                                        const TextSpan(text: ' and '),
                                                        TextSpan(
                                                          text: 'Privacy Policy',
                                                          style: TextStyle(
                                                            color: AppColors.primaryGreen,
                                                            decoration: TextDecoration.underline,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // Error Message
                                        if (authController.error != null)
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(bottom: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              authController.error!,
                                              style: const TextStyle(color: Colors.red),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        
                                        // Sign Up Button
                                        CustomButton(
                                          text: 'Create Account',
                                          isLoading: authController.isLoading,
                                          onPressed: _acceptTerms ? () => _handleSignUp(context) : null,
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Divider
                                        Row(
                                          children: [
                                            const Expanded(child: Divider()),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Text(
                                                'OR',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                              ),
                                            ),
                                            const Expanded(child: Divider()),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Google Sign Up
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Sign In Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('Sign In'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Future<void> _handleSignUp(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service and Privacy Policy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final authController = Provider.of<AuthController>(context, listen: false);
    final success = await authController.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      _displayNameController.text.trim(),
    );
    
    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please verify your email.'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate to login or home based on your flow
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
  

}