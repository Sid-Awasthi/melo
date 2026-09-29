import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // =========================
  // CURRENT USER
  // =========================
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // =========================
  // CONTROLLER
  // =========================
  final TextEditingController usernameController = TextEditingController();

  // =========================
  // EDITING STATE
  // =========================
  bool isEditing = false;

  // =========================
  // GET USER DATA
  // =========================
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
  }

  // =========================
  // UPDATE USERNAME
  // =========================
  Future<void> updateUsername() async {
    final String username = usernameController.text.trim().toLowerCase();

    // Check empty username
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty.')),
      );
      return;
    }

    try {
      // Check whether username already exists
      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      // If username exists
      if (usernameQuery.docs.isNotEmpty &&
          usernameQuery.docs.first.id != currentUser!.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This username is already taken.')),
        );
        return;
      }

      // Update username
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'username': username});

      // Exit editing mode
      if (mounted) {
        setState(() {
          isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update username: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),

      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getUserData(),

        builder: (context, snapshot) {
          // =========================
          // LOADING
          // =========================
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // =========================
          // ERROR
          // =========================
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // =========================
          // NO DATA
          // =========================
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No user data found.'));
          }

          // =========================
          // USER DATA
          // =========================
          final userData = snapshot.data!.data();

          final String username = userData?['username'] ?? 'N/A';

          final String email = userData?['email'] ?? 'N/A';

          // =========================
          // INITIALIZE CONTROLLER
          // =========================
          if (!isEditing && usernameController.text != username) {
            usernameController.text = username;
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // =========================
                  // PROFILE PICTURE
                  // =========================
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // EMAIL
                  // =========================
                  Text('Email: $email'),

                  const SizedBox(height: 15),

                  // =========================
                  // USERNAME
                  // =========================
                  if (isEditing)
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    Text(
                      'Username: $username',
                      style: const TextStyle(fontSize: 16),
                    ),

                  const SizedBox(height: 15),

                  // =========================
                  // EDIT / SAVE BUTTON
                  // =========================
                  ElevatedButton(
                    onPressed: () {
                      if (isEditing) {
                        updateUsername();
                      } else {
                        setState(() {
                          isEditing = true;
                        });
                      }
                    },
                    child: Text(isEditing ? 'Save' : 'Edit Username'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
