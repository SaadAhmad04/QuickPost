import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controller/apis.dart';
import '../controller/notifications.dart';
import 'comments_screen.dart';

class ShortsScreen extends StatefulWidget {
  final Stream<QuerySnapshot> stream;

  ShortsScreen({required this.stream});

  @override
  _ShortsScreenState createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                "An error occurred!",
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            body: Center(
              child: Text(
                'No videos uploaded yet.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          );
        }

        var videoDocs = snapshot.data!.docs;

        return Scaffold(
          body: PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videoDocs.length,
            itemBuilder: (context, index) {
              var videoDoc = videoDocs[index];
              return ShortsCard(videoData: videoDoc);
            },
          ),
        );
      },
    );
  }
}

class ShortsCard extends StatefulWidget {
  final QueryDocumentSnapshot videoData;

  ShortsCard({required this.videoData});

  @override
  _ShortsCardState createState() => _ShortsCardState();
}

class _ShortsCardState extends State<ShortsCard> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isLiked = false;
  bool _isDisliked = false;
  late Future<DocumentSnapshot> _userFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _hasViewed = false;

  @override
  void initState() {
    super.initState();

    // Observe app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Initialize video controller
    String? videoUrl = widget.videoData['url'];
    if (videoUrl != null && videoUrl.isNotEmpty) {
      _controller = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _controller.play();
              _controller.setLooping(true);
            });

            // Listen for video play to update views
            _controller.addListener(_trackVideoView);
          }
        }).catchError((error) {
          print('Error initializing video player: $error');
        });
    }

    // Fetch user data based on the uid from the video document
    _userFuture = Api.userRef
        .doc(widget.videoData['uid']) // Get user document based on the UID
        .get();

    // Initialize like/dislike state
    _isLiked = widget.videoData['likes'].contains(Api.user!.email);
    _isDisliked = widget.videoData['dislikes'].contains(Api.user!.email);
  }

  void _trackVideoView() {
    if (_controller.value.isPlaying && !_hasViewed) {
      _incrementViewCount();
      _hasViewed = true; // Ensure the view is counted only once
    }
  }

  // Function to update views in Firestore
  void _incrementViewCount() async {
    try {
      List<dynamic> viewedBy = widget.videoData['viewedBy'] ?? [];
      if (!viewedBy.contains(Api.user!.uid)) {
        await Api.videoRef.doc(widget.videoData['posted_on']).update({
          'views': FieldValue.increment(1),
          'viewedBy': FieldValue.arrayUnion([Api.user!.uid]),
        });
      }
    } catch (e) {
      print('Error updating view count: $e');
    }
  }

  @override
  void dispose() {
    // Remove observer and dispose video controller
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_trackVideoView);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.pause(); // Pause video when the app is minimized or inactive
    } else if (state == AppLifecycleState.resumed) {
      _controller.play(); // Resume video when the app is active again
    }
  }

  void _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) _isDisliked = false;
    });

    var likes = List.from(widget.videoData['likes']);
    var dislikes = List.from(widget.videoData['dislikes']);

    if (_isLiked) {
      likes.add(Api.user!.email);
      dislikes.remove(Api.user!.email);
    } else {
      likes.remove(Api.user!.email);
    }

    await Api.videoRef.doc(widget.videoData['posted_on']).update({
      'likes': likes,
      'dislikes': dislikes,
    });

    String userId = widget.videoData['uid'];
    String videoId = widget.videoData['posted_on'];
    String title = widget.videoData['title'];
    DocumentSnapshot userDoc = await Api.userRef.doc(userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      String receiverToken = data['push_token'] ?? 'No push token found';

      Map<String, String> userIdToken = {
        'userid': userId,
        'push_token': receiverToken,
      };

      Notifications.pushNotifications1(
          userIdToken,
          '${Api.user!.name} has liked your post ${widget.videoData['title']}',
          Api.user!.name,
          Api.user!.email,
          'Liked',
          {videoId: title});
    }
  }

  void _toggleDislike() async {
    setState(() {
      _isDisliked = !_isDisliked;
      if (_isDisliked) _isLiked = false;
    });

    var likes = List.from(widget.videoData['likes']);
    var dislikes = List.from(widget.videoData['dislikes']);

    if (_isDisliked) {
      dislikes.add(Api.user!.email);
      likes.remove(Api.user!.email);
    } else {
      dislikes.remove(Api.user!.email);
    }

    await Api.videoRef.doc(widget.videoData['posted_on']).update({
      'likes': likes,
      'dislikes': dislikes,
    });

    String userId = widget.videoData['uid'];
    String videoId = widget.videoData['posted_on'];
    String title = widget.videoData['title'];
    DocumentSnapshot userDoc = await Api.userRef.doc(userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      String receiverToken = data['push_token'] ?? 'No push token found';

      Map<String, String> userIdToken = {
        'userid': userId,
        'push_token': receiverToken,
      };

      Notifications.pushNotifications1(
          userIdToken,
          '${Api.user!.name} has disliked your post ${widget.videoData['title']}',
          Api.user!.name,
          Api.user!.email,
          'Disliked',
          {videoId: title});
    }
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = names.length > 1
        ? names[0][0].toUpperCase() + names[1][0].toUpperCase()
        : names[0][0].toUpperCase();
    return initials;
  }

  // Function to toggle the video play/pause
  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              color: Colors.black,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (userSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                "An error occurred while fetching user info!",
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Text(
                'User info not found.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          );
        }

        var userData = userSnapshot.data!;
        String userName = userData['name'] ?? 'Unknown User';
        String userProfilePic = userData['profilePic'] ?? '';

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.black, // Black background to fill unused space
                  child: Center(
                    child: _controller.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 10,
                child: CircleAvatar(
                  backgroundImage: userProfilePic.isNotEmpty &&
                          userProfilePic.startsWith('http')
                      ? NetworkImage(userProfilePic)
                      : null,
                  child: userProfilePic.isEmpty ||
                          !userProfilePic.startsWith('http')
                      ? Text(
                          _getInitials(userName),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                  backgroundColor: Colors.purple.shade800,
                ),
              ),
              Positioned(
                top: 50,
                left: 70,
                child: Text(
                  userName,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.remove_red_eye,
                          color: Colors.grey,
                          size: 28,
                        ),
                        Text(
                          '${widget.videoData['views']}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(width: 30),
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Column(
                        children: [
                          Icon(
                            _isLiked
                                ? Icons.thumb_up
                                : Icons.thumb_up_alt_outlined,
                            color: Colors.blue,
                            size: 28,
                          ),
                          Text(
                            '${widget.videoData['likes'].length}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 30),
                    GestureDetector(
                      onTap: _toggleDislike,
                      child: Column(
                        children: [
                          Icon(
                            _isDisliked
                                ? Icons.thumb_down
                                : Icons.thumb_down_alt_outlined,
                            color: Colors.red,
                            size: 28,
                          ),
                          Text(
                            '${widget.videoData['dislikes'].length}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 30),
                    GestureDetector(
                      onTap: () async {
                        _controller.pause();
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentsScreen(
                              videoId: widget.videoData['posted_on'],
                              title: widget.videoData['title'],
                              userId: widget.videoData['uid'],
                            ),
                          ),
                        );
                        _controller.play();
                      },
                      child: Column(
                        children: [
                          Icon(Icons.comment, color: Colors.white, size: 28),
                          Text(
                            'Comments',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
