import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:quickpost/view/play_video.dart';
import 'package:quickpost/view/post_video.dart';
import 'package:quickpost/view/video_analytics_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import '../constants/utilities.dart';
import '../controller/apis.dart';
import '../main.dart';
import 'comments_screen.dart';

class MyVideos extends StatefulWidget {
  const MyVideos({super.key});

  @override
  State<MyVideos> createState() => _MyVideosState();
}

class _MyVideosState extends State<MyVideos> {
  Stream<dynamic>? stream;
  final Map<String, Uint8List?> _thumbnailCache = {};
  int totalLikes = 0;
  int totalDislikes = 0;

  Future<Uint8List?> _getThumbnail(String videoUrl) async {
    try {
      // Clear specific cache related to videoUrl, if it exists
      await _clearSpecificCache(videoUrl);

      // Download video locally using cache manager
      final file = await DefaultCacheManager().getSingleFile(videoUrl);
      if (file == null || !file.existsSync()) {
        print("Failed to download video from: $videoUrl");
        return null;
      }

      // Generate output path with a unique name (e.g., adding a timestamp)
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/thumbnail_$timestamp.jpg';

      // Run FFmpeg to extract a frame at 1 second (1000ms)
      await FFmpegKit.execute(
          '-i ${file.path} -ss 00:00:01 -vframes 1 $outputPath');

      // Read the generated thumbnail
      File thumbFile = File(outputPath);
      if (thumbFile.existsSync()) {
        return await thumbFile.readAsBytes();
      } else {
        print("Thumbnail generation failed.");
        return null;
      }
    } catch (e) {
      print("Error generating thumbnail: $e");
      return null;
    }
  }

// Method to clear the cache for a specific video URL
  Future<void> _clearSpecificCache(String videoUrl) async {
    try {
      final cache = await DefaultCacheManager().getFileFromCache(videoUrl);
      if (cache != null) {
        await DefaultCacheManager()
            .removeFile(videoUrl); // Remove the cached file
      }
    } catch (e) {
      print("Error clearing cache for $videoUrl: $e");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    stream = Api.videoRef
        .where('uid', isEqualTo: Api.auth.currentUser!.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'My Shorts',
                style: TextStyle(
                    color: Colors.purple.shade800, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              leading: BackButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                color: Colors.purple.shade800,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => VideoAnalyticsScreen()));
                      },
                      icon: Icon(Icons.analytics)),
                )
              ],
            ),
            body: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var videoDoc = snapshot.data!.docs[index];
                String videoUrl = videoDoc['url'];
                String title = videoDoc['title'];
                String description = videoDoc['description'];
                List<dynamic> categories = videoDoc['category'];
                int views = videoDoc['views'];
                int dop = int.parse(videoDoc['posted_on']);
                List<dynamic> likes = List.from(videoDoc['likes'] ?? []);
                List<dynamic> dislikes = List.from(videoDoc['dislikes'] ?? []);
                totalLikes = likes.length;
                totalDislikes = dislikes.length;
                DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(dop);
                String date =
                    "${dateTime.year}-${dateTime.month}-${dateTime.day}";
                String time = "${dateTime.hour}:${dateTime.minute}";
                String vid = videoDoc['uid'];



                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<Uint8List?>(
                          future: _getThumbnail(videoUrl),
                          builder: (context, thumbSnapshot) {
                            if (thumbSnapshot.connectionState ==
                                    ConnectionState.done &&
                                thumbSnapshot.hasData) {
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlayVideo(
                                          videoUrl: videoUrl, id: vid),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    thumbSnapshot.data!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: Center(
                                  child: thumbSnapshot.connectionState ==
                                          ConnectionState.waiting
                                      ? CircularProgressIndicator()
                                      : Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 50,
                                        ),
                                ),
                              );
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "Categories: ${categories.join(', ')}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: Api.user!.profilePic.isEmpty
                                    ? null
                                    : NetworkImage(Api.user!.profilePic)
                                        as ImageProvider<Object>?,
                                child: Api.user!.profilePic.isEmpty
                                    ? Icon(Icons.person,
                                        size: 30, color: Colors.white)
                                    : null,
                              ),
                              SizedBox(width: 8),
                              Text(
                                Api.user!.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    if (!likes.contains(Api.user!.email)) {
                                      dislikes.remove(Api.user!.email);
                                      likes.add(Api.user!.email);
                                    } else {
                                      likes.remove(Api.user!.email);
                                    }
                                    totalLikes = likes.length;
                                    totalDislikes = dislikes.length;
                                  });

                                  await Api.videoRef.doc(dop.toString()).update(
                                      {'likes': likes, 'dislikes': dislikes});
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.remove_red_eye,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '${views}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(width: 15),
                                    Icon(
                                      likes.contains(Api.user!.email)
                                          ? Icons.thumb_up
                                          : Icons.thumb_up_alt_outlined,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '$totalLikes',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 15),
                              GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    if (!dislikes.contains(Api.user!.email)) {
                                      likes.remove(Api.user!.email);
                                      dislikes.add(Api.user!.email);
                                    } else {
                                      dislikes.remove(Api.user!.email);
                                    }
                                    totalLikes = likes.length;
                                    totalDislikes = dislikes.length;
                                  });

                                  await Api.videoRef.doc(dop.toString()).update(
                                      {'likes': likes, 'dislikes': dislikes});
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      dislikes.contains(Api.user!.email)
                                          ? Icons.thumb_down
                                          : Icons.thumb_down_alt_outlined,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '$totalDislikes',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 15),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommentsScreen(
                                        videoId: videoDoc['posted_on'],
                                        title: title,
                                        userId: videoDoc['uid'],
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.comment,
                                        color: Colors.grey.shade600, size: 28),
                                    SizedBox(width: 5),
                                    Text(
                                      '${videoDoc['comments']}',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Date and Time
                              Text(
                                "$date  •  $time",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),

                              Row(
                                children: [
                                  // Rename Button
                                  IconButton(
                                    onPressed: () {
                                      showRenameDialog(
                                          context, dop.toString(), title);
                                    },
                                    icon: Icon(Icons.edit,
                                        color: Colors.purple.shade800),
                                    tooltip: 'Rename',
                                  ),

                                  // Delete Button
                                  IconButton(
                                    onPressed: () {
                                      showDeleteDialog(
                                          context, dop.toString(), videoUrl);
                                    },
                                    icon: Icon(Icons.delete,
                                        color: Colors.red.shade600),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else {
          return Center(
            child: DefaultTextStyle(
              child: Text('No videos uploaded yet.'),
              style: TextStyle(fontSize: 14),
            ),
          );
        }
      },
    );
  }

  void showVideoSourceDialog(BuildContext context) {
    bool isLoading = false; // Boolean to control loading state

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Video Source'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Show CircularProgressIndicator if isLoading is true
                  if (isLoading)
                    Center(child: CircularProgressIndicator())
                  else ...[
                    ListTile(
                      leading: Icon(Icons.videocam),
                      title: Text('Record Video'),
                      onTap: () async {
                        // Set loading state
                        if (context.mounted) {
                          setState(() {
                            isLoading = true;
                          });
                        }

                        //Navigator.pop(context); // Close the dialog immediately

                        // Pick the video from the camera
                        bool isPicked = await Api.pickVideo(fromGallery: false);

                        // Wait for 1500 ms before proceeding
                        await Future.delayed(Duration(milliseconds: 1500));

                        // Reset loading state and check for video
                        if (context.mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }

                        if (isPicked && Api.video != null) {
                          // Navigate if widget is still mounted
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostVideo(video: Api.video!),
                              ),
                            );
                          } else {
                            log("Widget is not mounted. Cannot navigate.");
                          }
                        } else {
                          Utilities()
                              .showMessage(context, 'No video to upload');
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.video_library),
                      title: Text('Pick from Gallery'),
                      onTap: () async {
                        // Set loading state
                        if (context.mounted) {
                          setState(() {
                            isLoading = true;
                          });
                        }

                        //  Navigator.pop(context); // Close the dialog immediately

                        // Pick the video from the gallery
                        bool isPicked = await Api.pickVideo(fromGallery: true);

                        // Wait for 1500 ms before proceeding
                        await Future.delayed(Duration(milliseconds: 1500));

                        // Reset loading state and check for video
                        if (context.mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }

                        if (isPicked && Api.video != null) {
                          // Navigate if widget is still mounted
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostVideo(video: Api.video!),
                              ),
                            );
                          } else {
                            log("Widget is not mounted. Cannot navigate.");
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

  Future<void> showRenameDialog(
      BuildContext context, String id, String name) async {
    TextEditingController nameController = TextEditingController(text: name);
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: mq.height / 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          InputDecoration(border: UnderlineInputBorder()),
                    ),
                    SizedBox(height: mq.height * .01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 40,
                            width: 80,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.blue),
                                borderRadius: BorderRadius.circular(20)),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        InkWell(
                          onTap: () async {
                            if (nameController.text.isEmpty) {
                              Utilities().showMessage(
                                  context, 'Title cannot be empty');
                            } else {
                              await Api.videoRef
                                  .doc(id)
                                  .update({'title': nameController.text});
                            }
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 40,
                            width: 80,
                            decoration: BoxDecoration(
                                color: Colors.purple.shade800,
                                borderRadius: BorderRadius.circular(20)),
                            child: Center(
                              child: Text(
                                'Save',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> showDeleteDialog(
      BuildContext context, String id, String videoUrl) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: mq.height / 7,
                child: Column(
                  children: [
                    Text('Are you sure ? '),
                    SizedBox(height: mq.height * .025),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 40,
                            width: 80,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border:
                                    Border.all(color: Colors.purple.shade800),
                                borderRadius: BorderRadius.circular(20)),
                            child: Center(
                              child: Text(
                                'No',
                                style: TextStyle(color: Colors.purple.shade800),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        InkWell(
                          onTap: () async {
                            await Api.videoRef.doc(id).delete();
                            Navigator.pop(context);
                            await FirebaseStorage.instance
                                .refFromURL(videoUrl)
                                .delete();
                          },
                          child: Container(
                            height: 40,
                            width: 80,
                            decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(20)),
                            child: Center(
                              child: Text(
                                'Yes',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

//1703299975756
