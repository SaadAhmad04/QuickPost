import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../controller/apis.dart';
import '../controller/notifications.dart';

class CommentsScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String userId;

  CommentsScreen(
      {Key? key,
      required this.videoId,
      required this.title,
      required this.userId})
      : super(key: key);

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  Stream<QuerySnapshot>? stream;
  final TextEditingController _commentController = TextEditingController();
  bool _isEmojiVisible = false;
  int numberOfComments = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    stream = Api.videoRef
        .doc(widget.videoId)
        .collection('comments')
        .orderBy('postedOn', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment(String comment) async {
    String commentId = DateTime.now().millisecondsSinceEpoch.toString();
    if (comment.trim().isEmpty) return;

    numberOfComments += 1;

    await Api.videoRef
        .doc(widget.videoId)
        .collection('comments')
        .doc(commentId)
        .set({
      'userId': Api.user!.uid,
      'userName': Api.user!.name,
      'comment': comment,
      'postedOn': commentId,
    });

    await Api.videoRef
        .doc(widget.videoId)
        .update({'comments': numberOfComments});

    _commentController.clear();

    DocumentSnapshot userDoc = await Api.userRef.doc(widget.userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      String receiverToken = data['push_token'] ?? 'No push token found';

      Map<String, String> userIdToken = {
        'userid': widget.userId,
        'push_token': receiverToken,
      };

      await Notifications.pushNotifications1(
          userIdToken,
          '${Api.user!.name} has commented on your post ${comment}',
          Api.user!.name,
          Api.user!.email,
          'Commented',
          {widget.videoId: widget.title});
      setState(() {
        if (_isEmojiVisible) {
          _isEmojiVisible = false;
        }
      });
    }
  }

  void _toggleEmojiKeyboard() {
    setState(() {
      _isEmojiVisible = !_isEmojiVisible;
    });
  }

  String _formatTimestamp(String timestamp) {
    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return "${dateTime.day}-${dateTime.month}-${dateTime.year} at ${dateTime.hour}:${dateTime.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comments',
          style: TextStyle(
              color: Colors.purple.shade800, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
          color: Colors.purple.shade800,
        ),
      ),
      body: Column(
        children: [
          // Comments Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet. Be the first to comment!',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                var comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    var commentData =
                        comments[index].data() as Map<String, dynamic>;
                    String postedOn = commentData['postedOn'];
                    String formattedDate = _formatTimestamp(postedOn);

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(10),
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade800,
                            child: Text(
                              commentData['userName'][0].toUpperCase(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            commentData['userName'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Text(
                            commentData['comment'],
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Section for Comments
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.emoji_emotions_outlined,
                      color: Colors.purple.shade800),
                  onPressed: _toggleEmojiKeyboard,
                ),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.purple.shade800),
                  onPressed: () {
                    _postComment(_commentController.text);
                  },
                ),
              ],
            ),
          ),

          // Emoji Picker Section
          if (_isEmojiVisible)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _commentController.text += emoji.emoji;
                },
              ),
            ),
        ],
      ),
    );
  }
}
