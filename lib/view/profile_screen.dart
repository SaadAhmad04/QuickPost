import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/utilities.dart';
import '../controller/apis.dart';
import '../main.dart';
import 'auth_ui/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  static File? image;
  static ImagePicker imagePicker = ImagePicker();

  Future<void> profilePic() async {
    try {
      final pickedFile = await imagePicker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        image = File(pickedFile.path);
        setState(() {});
      } else {
        Utilities().showMessage(context ,'No image selected');
      }
    } catch (e) {
      Utilities().showMessage(context ,e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(Api.user!.joinedOn));
    mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
              color: Colors.purple.shade800,
              fontWeight: FontWeight.bold),
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
                onPressed: () async {
                  await Api.auth.signOut().then((value) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LoginScreen()));
                  });
                },
                icon: Icon(
                  Icons.logout,
                  color: Colors.red.shade600,
                )),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade200, Colors.purple.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    backgroundColor: Api.user!.profilePic == ""
                        ? Colors.purple.shade800
                        : Colors.transparent,
                    maxRadius: mq.height * .15,
                    child: Api.user!.profilePic != ""
                        ? Image.network(Api.user!.profilePic)
                        : Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: mq.height * .2,
                  left: mq.width * .65,
                  child: MaterialButton(
                    color: Colors.purple.shade600,
                    shape: CircleBorder(
                        side: BorderSide(color: Colors.purple.shade600)),
                    onPressed: () {
                      profilePic();
                    },
                    child: Icon(Icons.edit, color: Colors.white),
                  ),
                )
              ],
            ),
            SizedBox(
              height: mq.height * .05,
            ),
            Text(
              'Joined on ${date.day}-${date.month}-${date.year}',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(
              height: mq.height * .05,
            ),
            Divider(
              thickness: 2,
              color: Colors.white.withOpacity(0.6),
              indent: mq.width * .1,
              endIndent: mq.width * .1,
            ),
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      initialValue: Api.user!.name,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon: Icon(Icons.person)),
                      validator: (val) {
                        if (val!.isEmpty) {
                          return 'Enter name';
                        }
                      },
                    ),
                    SizedBox(
                      height: mq.height * .02,
                    ),
                    TextFormField(
                      initialValue: Api.user!.email,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon: Icon(Icons.email)),
                      validator: (val) {
                        if (val!.isEmpty) {
                          return 'Enter phone number';
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
