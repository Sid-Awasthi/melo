import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream() {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientUid', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: getNotificationsStream(),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading notifications:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // =========================
          // EMPTY
          // =========================
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notificationDoc = notifications[index];
              final notification = notificationDoc.data();

              final String senderUsername =
                  notification['senderUsername'] ?? 'Someone';

              final String message = notification['message'] ?? '';

              final String type = notification['type'] ?? '';

              final bool isRead = notification['isRead'] ?? false;

              // =========================
              // ICON
              // =========================
              IconData notificationIcon;

              if (type == 'like') {
                notificationIcon = Icons.favorite;
              } else if (type == 'comment') {
                notificationIcon = Icons.comment;
              } else {
                notificationIcon = Icons.notifications;
              }

              return ListTile(
                onTap: () async {
                  if (!isRead) {
                    await markAsRead(notificationDoc.id);
                  }
                },
                leading: CircleAvatar(child: Icon(notificationIcon)),
                title: Text(
                  senderUsername,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  message,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                trailing: isRead
                    ? null
                    : Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
