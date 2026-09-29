import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDatabase {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // =========================
  // GET USERNAME
  // =========================
  Future<String> getUsername(String uid) async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!userSnapshot.exists) {
      return 'Unknown User';
    }

    final data = userSnapshot.data();

    if (data == null) {
      return 'Unknown User';
    }

    return data['username'] ?? 'Unknown User';
  }

  // =========================
  // ADD POST
  // =========================
  Future<void> addPost(String content) async {
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    final String username = await getUsername(currentUser!.uid);

    await FirebaseFirestore.instance.collection('posts').add({
      'uid': currentUser!.uid,
      'username': username,
      'content': content,
      'email': currentUser!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
    });
  }

  // =========================
  // UPDATE POST
  // =========================
  Future<void> updatePost(String postId, String newContent) async {
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    final String content = newContent.trim();

    if (content.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'content': content,
    });
  }

  // =========================
  // DELETE POST
  // =========================
  Future<void> deletePost(String postId) async {
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
  }

  // =========================
  // GET POSTS
  // =========================
  Stream<QuerySnapshot<Map<String, dynamic>>> getPostsStream() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // =========================
  // LIKE / UNLIKE POST
  // =========================
  Future<void> toggleLike(String postId) async {
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    final postSnapshot = await postRef.get();

    if (!postSnapshot.exists) {
      throw Exception('Post not found');
    }

    final data = postSnapshot.data() as Map<String, dynamic>;

    final List<dynamic> likes = data['likes'] ?? [];

    final String uid = currentUser!.uid;

    if (likes.contains(uid)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // =========================
  // ADD COMMENT
  // =========================
  Future<void> addComment(String postId, String comment) async {
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    final String text = comment.trim();

    if (text.isEmpty) {
      return;
    }

    final String username = await getUsername(currentUser!.uid);

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
          'uid': currentUser!.uid,
          'username': username,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // =========================
  // UPDATE COMMENT
  // =========================
  Future<void> updateComment(
    String postId,
    String commentId,
    String newText,
  ) async {
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    final String text = newText.trim();

    if (text.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({'text': text});
  }

  // =========================
  // DELETE COMMENT
  // =========================
  Future<void> deleteComment(String postId, String commentId) async {
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}
