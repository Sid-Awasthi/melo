import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:melo/components/myDrawer.dart';
import 'package:melo/components/my_postbutton.dart';
import 'package:melo/database/firestore.dart';
import 'package:melo/pages/comments_pages.dart';
import 'package:melo/pages/notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController newPost = TextEditingController();

  // =========================
  // CREATE POST
  // =========================
  Future<void> postMessage() async {
    final content = newPost.text.trim();

    if (content.isEmpty) {
      return;
    }

    try {
      await FirestoreDatabase().addPost(content);
      newPost.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
      }
    }
  }

  // =========================
  // LIKE / UNLIKE POST
  // =========================
  Future<void> likePost(String postId) async {
    try {
      await FirestoreDatabase().toggleLike(postId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to like post: $e')));
      }
    }
  }

  // =========================
  // EDIT POST
  // =========================
  Future<void> editPost(String postId, String currentContent) async {
    final TextEditingController editController = TextEditingController(
      text: currentContent,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Post'),
          content: TextField(
            controller: editController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Edit your post...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newContent = editController.text.trim();

                if (newContent.isEmpty) {
                  return;
                }

                try {
                  await FirestoreDatabase().updatePost(postId, newContent);

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update post: $e')),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      editController.dispose();
    });
  }

  // =========================
  // DELETE POST
  // =========================
  Future<void> deletePost(String postId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
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
      await FirestoreDatabase().deletePost(postId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
      }
    }
  }

  @override
  void dispose() {
    newPost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'M E L O',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),

      drawer: const MyDrawer(),

      body: Column(
        children: [
          // =========================
          // CREATE POST SECTION
          // =========================
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: newPost,
                    decoration: const InputDecoration(
                      hintText: 'Say something...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                MyPostButton(onPressed: postMessage),
              ],
            ),
          ),

          // =========================
          // POSTS
          // =========================
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreDatabase().getPostsStream(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No posts yet.'));
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,

                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final postData = post.data();

                    // =========================
                    // POST OWNER
                    // =========================
                    final String postOwnerUid = postData['uid'] ?? '';

                    final bool isOwner =
                        currentUser != null && currentUser.uid == postOwnerUid;

                    // =========================
                    // POST DATA
                    // =========================
                    final String content = postData['content'] ?? '';

                    final String username =
                        postData['username'] ?? 'Unknown User';

                    final List<dynamic> likes = postData['likes'] ?? [];

                    final bool isLiked =
                        currentUser != null && likes.contains(currentUser.uid);

                    final int likeCount = likes.length;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(12.0),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            // =========================
                            // USERNAME
                            // =========================
                            Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // =========================
                            // POST CONTENT
                            // =========================
                            Text(content, style: const TextStyle(fontSize: 16)),

                            const SizedBox(height: 5),

                            // =========================
                            // POST ACTIONS
                            // =========================
                            Row(
                              children: [
                                // LIKE BUTTON
                                IconButton(
                                  onPressed: currentUser == null
                                      ? null
                                      : () => likePost(post.id),

                                  icon: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,

                                    color: isLiked
                                        ? Colors.red
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                ),

                                // LIKE COUNT
                                Text(
                                  '$likeCount',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // COMMENT BUTTON
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CommentsPage(postId: post.id),
                                      ),
                                    );
                                  },

                                  icon: const Icon(Icons.comment_outlined),
                                ),

                                // =========================
                                // OWNER ACTIONS
                                // =========================
                                if (isOwner) ...[
                                  const Spacer(),

                                  // EDIT
                                  IconButton(
                                    onPressed: () {
                                      editPost(post.id, content);
                                    },
                                    icon: const Icon(Icons.edit),
                                  ),

                                  // DELETE
                                  IconButton(
                                    onPressed: () {
                                      deletePost(post.id);
                                    },
                                    icon: const Icon(Icons.delete),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
