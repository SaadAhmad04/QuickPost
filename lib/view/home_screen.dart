import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:quickpost/view/post_video.dart';
import 'package:quickpost/view/profile_screen.dart';
import 'package:quickpost/view/shorts_screen.dart';
import 'package:quickpost/view/view_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/utilities.dart';
import '../controller/apis.dart';
import '../controller/notifications.dart';
import '../main.dart';
import 'my_videos.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String name;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [Colors.purple, Colors.blue, Colors.red],
            ).createShader(bounds);
          },
          child: Text(
            'Home',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NotificationsScreen()));
            },
            icon: Icon(
              Icons.notifications,
              color: Colors.purple.shade800,
            )),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'images/logo.png',
              height: 50,
              width: 50,
            ),
          ),
        ],
      ),
      body: Container(
        height: mq.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.purple.shade100],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: mq.height * .15, horizontal: mq.width * .05),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [Colors.red, Colors.green, Colors.blue],
                    ).createShader(bounds);
                  },
                  child: Text(
                    'Welcome, ${Api.user!.name}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildGridItem(
                      context,
                      title: 'Upload',
                      icon: Icons.videocam_rounded,
                      onTap: () => showVideoSourceDialog(context),
                    ),
                    _buildGridItem(
                      context,
                      title: 'Shorts',
                      icon: Icons.post_add,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShortsScreen(
                            stream: Api.videoRef.snapshots(),
                          ),
                        ),
                      ),
                    ),
                    _buildGridItem(
                      context,
                      title: 'My Videos',
                      icon: Icons.video_collection_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyVideos()),
                      ),
                    ),
                    _buildGridItem(context,
                        title: 'Profile', icon: Icons.person, onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfileScreen()),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context,
      {required String title,
      required IconData icon,
      required Function onTap}) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade200, Colors.purple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void showVideoSourceDialog(BuildContext context) {
    bool isLoading = false;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.purple.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                'Select Video Source',
                style: TextStyle(color: Colors.purple.shade800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    Center(child: CircularProgressIndicator())
                  else ...[
                    _buildDialogOption(
                      context,
                      icon: Icons.videocam,
                      title: 'Record Video',
                      onTap: () async {
                        setState(() => isLoading = true);
                        bool isPicked = await Api.pickVideo(fromGallery: false);
                        setState(() => isLoading = false);

                        if (isPicked && Api.video != null) {
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostVideo(video: Api.video!),
                              ),
                            );
                          }
                        } else {
                          Utilities()
                              .showMessage(context, 'No video to upload');
                        }
                      },
                    ),
                    _buildDialogOption(
                      context,
                      icon: Icons.video_library,
                      title: 'Pick from Gallery',
                      onTap: () async {
                        setState(() => isLoading = true);
                        bool isPicked = await Api.pickVideo(fromGallery: true);
                        setState(() => isLoading = false);

                        if (isPicked && Api.video != null) {
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostVideo(video: Api.video!),
                              ),
                            );
                          }
                        } else {
                          Utilities()
                              .showMessage(context, 'No video to upload');
                        }
                      },
                    ),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogOption(BuildContext context,
      {required IconData icon,
      required String title,
      required Function onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple.shade800),
      title: Text(title, style: TextStyle(color: Colors.black)),
      onTap: () => onTap(),
    );
  }
}
