import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import '../constants/utilities.dart';
import '../controller/apis.dart';
import '../main.dart';
import 'home_screen.dart';

class PostVideo extends StatefulWidget {
  final File video;
  const PostVideo({super.key, required this.video});

  @override
  State<PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<PostVideo> {
  var values = Set();
  late IconData _floatingButtonIcon;
  late VideoPlayerController _controller;
  final videoTitleController = TextEditingController();
  final videoDescriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  double? latitude;
  double? longitude;

  List<VideoCategory> categories = [
    VideoCategory(name: 'Entertainment'),
    VideoCategory(name: 'Education'),
    VideoCategory(name: 'Sports'),
    VideoCategory(name: 'News'),
    VideoCategory(name: 'Travel'),
    VideoCategory(name: 'Technology'),
    VideoCategory(name: 'Other')
  ];

  Future<void> getCurrentLocation() async {
    try {
      var status = await Permission.location.request();
      // bool isPermissionGranted =
      // await GeolocatorPlatform.instance.isLocationServiceEnabled();
      // print(isPermissionGranted);
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        latitude = await position.latitude;
        longitude = await position.longitude;
        print('Latitude : ${latitude}\nLon : ${longitude}');
        // List<Placemark> placemarks = await placemarkFromCoordinates(
        //     position.latitude, position.longitude);
        // print(placemarks[0].country);
        // print(placemarks[0].locality);
      } else {
        print('Not granted');
      }
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.file(File(widget.video.path))
      ..initialize().then((_) {
        setState(() {}); // Ensure UI updates after initialization
      });

    // Initial icon should be play
    _floatingButtonIcon = Icons.play_arrow;

    // Adding a listener to manage icon updates correctly
    _controller.addListener(() {
      setState(() {
        if (_controller.value.isCompleted) {
          _floatingButtonIcon = Icons.replay;
        } else if (_controller.value.isPlaying) {
          _floatingButtonIcon = Icons.pause; // Ensure pause icon when playing
        } else {
          _floatingButtonIcon = Icons.play_arrow;
        }
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
  }

  @override

  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: loading
          ? Scaffold(
        backgroundColor: Colors.purple.shade800,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 10),
              Text('Uploading...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      )
          : Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () => showDiscardDialog(context),
          ),
          title: Text(
            'Review & Post',
            style: TextStyle(
              color: Colors.purple.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (values.isNotEmpty) {
                    setState(() => loading = true);
                    final date = DateTime.now().millisecondsSinceEpoch.toString();
                    String videoUrl = await Api.uploadVideo(widget.video, date);
                    await getCurrentLocation().then((_) async {
                      await Api.videoRef.doc(date).set({
                        'title': videoTitleController.text,
                        'description': videoDescriptionController.text,
                        'url': videoUrl,
                        'category': values,
                        'posted_on': date,
                        'uid': Api.auth.currentUser!.uid,
                        'latitude': latitude,
                        'longitude': longitude,
                        'likes': [],
                        'dislikes': [],
                        'comments': 0,
                        'views':0
                      });
                      setState(() => loading = false);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                      Utilities().showMessage(context ,'Posted Successfully!');
                    }).catchError((error) {
                      setState(() => loading = false);
                      Utilities().showMessage(context ,error.toString());
                    });
                  } else {
                    Utilities().showMessage(context ,'Select at least one category');
                  }
                }
              },
              child: Text('Post', style: TextStyle(color: Colors.purple.shade800)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _controller.value.isInitialized
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                )
                    : CircularProgressIndicator(color: Colors.purple.shade800),
                SizedBox(height: 10),
                MaterialButton(
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                        _floatingButtonIcon = Icons.play_arrow;
                      } else {
                        _controller.play();
                        _floatingButtonIcon = Icons.pause;
                      }
                    });
                  },
                  color: Colors.purple.shade800,
                  shape: CircleBorder(),
                  child: Icon(_floatingButtonIcon, color: Colors.white, size: 30),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: videoTitleController,
                        decoration: InputDecoration(
                          labelText: 'Video Title',
                          prefixIcon: Icon(Icons.title, color: Colors.purple.shade800),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) => val!.isEmpty ? 'Enter title' : null,
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: videoDescriptionController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description, color: Colors.purple.shade800),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) => val!.isEmpty ? 'Enter description' : null,
                      ),
                      SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Select Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          return CheckboxListTile(
                            title: Text(categories[index].name),
                            value: categories[index].isChecked,
                            activeColor: Colors.purple.shade800,
                            onChanged: (val) {
                              setState(() {
                                categories[index].isChecked = val!;
                                if (val) values.add(categories[index].name);
                                else values.remove(categories[index].name);
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showDiscardDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          content: SizedBox(
            height: 130,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Are you sure you want to discard this video?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.purple.shade800),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.purple.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        backgroundColor: Colors.purple.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Yes',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

class VideoCategory {
  final String name;
  bool isChecked = false;

  VideoCategory({required this.name});
}
