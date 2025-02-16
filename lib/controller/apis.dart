import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../model/user_model.dart';
import '../view/auth_ui/login_screen.dart';

class Api {
  static final auth = FirebaseAuth.instance;
  static final userRef = FirebaseFirestore.instance.collection('users');
  static final videoRef = FirebaseFirestore.instance.collection('videos');
  static File? video;
  static ImagePicker videoPicker = ImagePicker();
  static UserModel? user;

  static Future<void> logout(BuildContext context) async {
    await auth.signOut().then((value) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    });
  }

  static Future<bool> pickVideo({required bool fromGallery}) async {
    try {
      final pickedFile = await videoPicker.pickVideo(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera,
        maxDuration: Duration(seconds: 59),
      );

      if (pickedFile != null) {
        video = File(pickedFile.path);
        log("Picked video: ${video!.path}");
        return true; // Return true if video is picked
      } else {
        log("No video selected");
        return false; // Return false if no video was picked
      }
    } catch (e) {
      log("Error picking video: $e");
      return false; // Return false on error
    }
  }

  // static Future<String> uploadVideo(File videoFile , String date) async {
  //   try {
  //     final ext = videoFile.path.split(".").last;
  //     final storageRef = FirebaseStorage.instance.ref(
  //         'videos/${auth.currentUser!.uid}/${date}.$ext');
  //     await storageRef.putFile(
  //         videoFile, SettableMetadata(contentType: 'video/$ext'));
  //     final videoUrl = await storageRef.getDownloadURL();
  //     return videoUrl;
  //   } catch (e) {
  //     print("Error uploading video: $e");
  //     return '';
  //   }
  // }

  static Future<String> uploadVideo(File videoFile, String date) async {
    try {
      final ext = videoFile.path.split(".").last;
      final storageRef = FirebaseStorage.instance
          .ref('videos/${FirebaseAuth.instance.currentUser!.uid}/$date.$ext');

      UploadTask uploadTask = storageRef.putFile(
          videoFile, SettableMetadata(contentType: 'video/$ext'));

      final TaskSnapshot snapshot = await uploadTask;

      print('Upload completed: ${snapshot.state}');

      final videoUrl = await storageRef.getDownloadURL();
      print('Video URL: $videoUrl');

      return videoUrl;
    } catch (e) {
      print("Error uploading video: $e");
      return '';
    }
  }

}
