import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:melo/database/firestore.dart';

class CommentsPage extends StatefulWidget {
  final String postId;

  const CommentsPage({super.key, required this.postId});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController commentController = TextEditingController();

  // =========================
  // ADD COMMENT
  // =========================
  Future<void> addComment() async {
    final comment = commentController.text.trim();

    if (comment.isEmpty) {
      return;
    }

    try {
      await FirestoreDatabase().addComment(widget.postId, comment);

      commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
      }
    }
  }

  // =========================
  // EDIT COMMENT
  // =========================
  Future<void> editComment(String commentId, String currentText) async {
    final TextEditingController editController = TextEditingController(
      text: currentText,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: editController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Edit your comment...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            // CANCEL
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            // SAVE
            ElevatedButton(
              onPressed: () async {
                final newText = editController.text.trim();

                if (newText.isEmpty) {
                  return;
                }

                try {
                  await FirestoreDatabase().updateComment(
                    widget.postId,
                    commentId,
                    newText,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update comment: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    // Dispose after dialog is removed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      editController.dispose();
    });
  }

  // =========================
  // DELETE COMMENT
  // =========================
  Future<void> deleteComment(String commentId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: [
            // CANCEL
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),

            // DELETE
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) {
      return;
    }

    try {
      await FirestoreDatabase().deleteComment(widget.postId, commentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
      }
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          // =========================
          // COMMENTS
          // =========================
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No comments yet.'));
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentDoc = comments[index];

                    final comment = commentDoc.data();

                    // =========================
                    // COMMENT DATA
                    // =========================
                    final String username =
                        comment['username'] ?? 'Unknown User';

                    final String text = comment['text'] ?? '';

                    final String commentOwnerUid = comment['uid'] ?? '';

                    // =========================
                    // CHECK COMMENT OWNER
                    // =========================
                    final bool isOwner =
                        currentUser != null &&
                        currentUser.uid == commentOwnerUid;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                        ),
                      ),

                      // =========================
                      // COMMENT TEXT
                      // =========================
                      title: Text(
                        username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      subtitle: Text(text),

                      // =========================
                      // EDIT / DELETE
                      // =========================
                      trailing: isOwner
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // EDIT
                                IconButton(
                                  onPressed: () {
                                    editComment(commentDoc.id, text);
                                  },
                                  icon: const Icon(Icons.edit),
                                ),

                                // DELETE
                                IconButton(
                                  onPressed: () {
                                    deleteComment(commentDoc.id);
                                  },
                                  icon: const Icon(Icons.delete),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // =========================
          // ADD COMMENT
          // =========================
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => addComment(),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(onPressed: addComment, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
