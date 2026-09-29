import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(child: Image.asset('assets/logo.jpg')),

          // Home
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: ListTile(
              leading: const Icon(Icons.home),
              title: const Text('H O M E'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Profile
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('P R O F I L E'),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ),

          // Users
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: ListTile(
              leading: const Icon(Icons.people),
              title: const Text('U S E R S'),
              onTap: () {
                Navigator.pushNamed(context, '/users');
              },
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('L O G O U T'),
              onTap: () {
                logout();

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
