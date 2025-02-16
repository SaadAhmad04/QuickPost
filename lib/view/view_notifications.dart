import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:quickpost/view/comments_screen.dart';
import 'package:quickpost/view/my_videos.dart';
import '../controller/apis.dart';

class NotificationsScreen extends StatelessWidget {
  final Stream<QuerySnapshot> notificationStream = Api.userRef
      .doc(Api.user!.uid)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
              color: Colors.purple.shade800, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.purple.shade800),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No Notifications',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var notification = snapshot.data!.docs[index];
              String message = notification['message'];
              String type = notification['type'];
              String memberName = notification['memberName'];
              String videoTitle = notification['title'];
              int timestamp = int.parse(notification['timestamp']);
              String formattedDate = DateFormat('yyyy-MM-dd – kk:mm')
                  .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
              String extractedComment = _extractComment(message, type);

              IconData icon = _getNotificationIcon(type);

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child: Icon(icon, color: Colors.purple.shade800),
                    ),
                    title: type != 'Commented'
                        ? Text(
                            '$memberName $type your post "$videoTitle"',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        : Text(
                            '${extractedComment}\n${videoTitle}',
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold),
                          ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            formattedDate,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios,
                        color: Colors.purple.shade800, size: 16),
                    onTap: () {
                      if (type == 'Commented') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentsScreen(
                              videoId: notification['videoId'],
                              title: notification['title'],
                              userId: notification['senderId'],
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyVideos()),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _extractComment(String message, String type) {
    if (type == 'Commented' && message.contains('has commented on your post')) {
      int startIndex = message.indexOf('post') + 5;
      return message.substring(startIndex).trim();
    }
    return '';
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'Liked':
        return Icons.thumb_up;
      case 'Disliked':
        return Icons.thumb_down;
      case 'Commented':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }
}

class VideoScreen extends StatelessWidget {
  final String videoId;

  VideoScreen({required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Screen'),
      ),
      body: Center(
        child: Text('Display video with ID: $videoId'),
      ),
    );
  }
}
