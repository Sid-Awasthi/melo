import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:melo/components/my_textfield.dart';
import 'package:melo/components/mybutton.dart';
import 'package:melo/helper/helperfile.dart';
import 'package:melo/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // =========================
  // TEXT CONTROLLERS
  // =========================
  final TextEditingController usernameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  // =========================
  // REGISTER
  // =========================
  Future<void> register() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Registering...'),
            ],
          ),
        );
      },
    );

    final String username = usernameController.text.trim();
    final String normalizedUsername = username.toLowerCase();
    final String email = emailController.text.trim();
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;

    // =========================
    // VALIDATE FIELDS
    // =========================
    if (username.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty &&
        confirmPassword.isNotEmpty) {
      // =========================
      // CHECK PASSWORD
      // =========================
      if (password == confirmPassword) {
        try {
          // =========================
          // CREATE FIREBASE ACCOUNT
          // =========================
          final UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);

          // =========================
          // CHECK USERNAME
          // =========================
          final usernameQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: normalizedUsername)
              .limit(1)
              .get();

          // =========================
          // USERNAME ALREADY EXISTS
          // =========================
          if (usernameQuery.docs.isNotEmpty) {
            // Delete the newly created Firebase account
            await userCredential.user!.delete();

            if (mounted) {
              Navigator.pop(context);

              showDisplayMessage(context, 'This username is already taken.');
            }

            return;
          }

          // =========================
          // CREATE FIRESTORE USER
          // =========================
          await createUserDocument(userCredential, normalizedUsername);

          // Close loading dialog
          if (mounted) {
            Navigator.pop(context);

            // Go to login page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        } on FirebaseAuthException catch (e) {
          // Close loading dialog
          if (mounted) {
            Navigator.pop(context);
          }

          String message = 'Registration failed';

          if (e.code == 'email-already-in-use') {
            message = 'This email is already registered.';
          } else if (e.code == 'invalid-email') {
            message = 'Please enter a valid email address.';
          } else if (e.code == 'weak-password') {
            message = 'Password is too weak.';
          }

          if (mounted) {
            showDisplayMessage(context, message);
          }
        } catch (e) {
          // Close loading dialog
          if (mounted) {
            Navigator.pop(context);

            showDisplayMessage(context, e.toString());
          }
        }
      } else {
        // Passwords don't match
        if (mounted) {
          Navigator.pop(context);

          showDisplayMessage(context, 'Passwords do not match');
        }
      }
    } else {
      // Fields are empty
      if (mounted) {
        Navigator.pop(context);

        showDisplayMessage(context, 'Please fill in all fields');
      }
    }
  }

  // =========================
  // CREATE USER DOCUMENT
  // =========================
  Future<void> createUserDocument(
    UserCredential userCredential,
    String username,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({'email': userCredential.user!.email, 'username': username});
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.vertical -
                  40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // =========================
                // LOGO
                // =========================
                Image.asset('assets/logo.jpg', width: 100, height: 100),

                // =========================
                // APP NAME
                // =========================
                const Text(
                  'M E L O',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                // =========================
                // USERNAME
                // =========================
                MyTextField(
                  obscureText: false,
                  hintText: 'Enter your username',
                  controller: usernameController,
                ),

                const SizedBox(height: 10),

                // =========================
                // EMAIL
                // =========================
                MyTextField(
                  obscureText: false,
                  hintText: 'Enter your email',
                  controller: emailController,
                ),

                const SizedBox(height: 10),

                // =========================
                // PASSWORD
                // =========================
                MyTextField(
                  obscureText: true,
                  hintText: 'Enter your password',
                  controller: passwordController,
                ),

                const SizedBox(height: 10),

                // =========================
                // CONFIRM PASSWORD
                // =========================
                MyTextField(
                  obscureText: true,
                  hintText: 'Confirm your password',
                  controller: confirmPasswordController,
                ),

                const SizedBox(height: 10),

                // =========================
                // REGISTER BUTTON
                // =========================
                MyButton(text: 'Register', onPressed: register),

                const SizedBox(height: 10),

                // =========================
                // LOGIN
                // =========================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Login Here',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
