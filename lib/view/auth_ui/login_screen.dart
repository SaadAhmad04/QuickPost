import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickpost/view/admin_home_screen.dart';
import 'package:quickpost/view/auth_ui/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/notifications.dart';
import '../../model/user_model.dart';
import '../../constants/roundButton.dart';
import '../../constants/utilities.dart';
import '../../controller/apis.dart';
import '../../main.dart';
import '../home_screen.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  bool showPassword = false;
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () async {
          SystemNavigator.pop();
          return true;
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Login',
              style: TextStyle(
                color: Colors.purple.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade100, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: mq.height / 5,
                      horizontal: mq.width * 0.1,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.purple.shade700,
                            child: Icon(
                              Icons.lock,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 30),
                          buildTextField(
                            controller: emailController,
                            hintText: 'Enter your email',
                            icon: Icons.email,
                          ),
                          SizedBox(height: 15),
                          buildTextField(
                            controller: passwordController,
                            hintText: 'Enter your password',
                            icon: Icons.lock,
                            obscureText: !showPassword,
                          ),
                          SizedBox(height: 30),
                          RoundButton(
                            title: 'Login',
                            loading: loading,
                            onTap: handleLogin,
                          ),
                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen(),
                                ),
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                    color: Colors.purple.shade800,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account?"),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignUpScreen(),
                                  ),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                      color: Colors.purple.shade800,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.purple.shade800),
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: hintText == 'Enter your password'
            ? IconButton(
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
                icon: showPassword
                    ? Icon(
                        Icons.visibility_off,
                        color: Colors.purple.shade800,
                      )
                    : Icon(
                        Icons.visibility,
                        color: Colors.purple.shade800,
                      ))
            : SizedBox(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $hintText';
        }
        return null;
      },
    );
  }

  // void handleLogin() async {
  //   if (_formKey.currentState!.validate()) {
  //     setState(() => loading = true);
  //     try {
  //       UserCredential value = await _auth.signInWithEmailAndPassword(
  //         email: emailController.text.trim(),
  //         password: passwordController.text.trim(),
  //       );
  //       String uid = value.user!.uid;
  //       DocumentSnapshot userDoc = await Api.userRef.doc(uid).get();
  //       if (userDoc.exists) {
  //         UserModel userModel = UserModel.fromFirestore(
  //           userDoc.data()! as Map<String, dynamic>,
  //         );
  //         Api.user = userModel;
  //         Api.user!.push_token = await Notifications.init();
  //         await Api.userRef
  //             .doc(Api.auth.currentUser!.uid)
  //             .update({'push_token': Api.user!.push_token});
  //         final pref = await SharedPreferences.getInstance();
  //         String currentUser = jsonEncode(userModel.toJson());
  //         await pref.setString('user', currentUser);
  //         Utilities().showMessage(context, 'Signed in as: ${userModel.name}');
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => const HomeScreen()),
  //         );
  //       } else {
  //         Utilities().showMessage(context, 'User document not found.');
  //       }
  //     } catch (error) {
  //       debugPrint(error.toString());
  //       Utilities().showMessage(context, error.toString());
  //     } finally {
  //       setState(() => loading = false);
  //     }
  //   }
  // }

  void handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      try {
        UserCredential value = await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        String uid = value.user!.uid;

        // 1) Check admin collection first
        final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(uid).get();

        if (adminDoc.exists) {
          final adminData = adminDoc.data()! as Map<String, dynamic>;
          final adminModel = UserModel.fromFirestore(adminData);

          Api.user = adminModel;
          Api.user!.push_token = await Notifications.init();
          await FirebaseFirestore.instance.collection('admin').doc(uid).update({
            'push_token': Api.user!.push_token,
          });

          // Set the API flag and persist role
          Api.isAdmin = true;
          final pref = await SharedPreferences.getInstance();
          await pref.setString('user', jsonEncode(adminModel.toJson()));
          await pref.setBool('isAdmin', true);

          Utilities().showMessage(context, 'Signed in as Admin: ${adminModel.name}');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
          );
        }
        else {
          DocumentSnapshot userDoc = await Api.userRef.doc(uid).get();
          if (userDoc.exists) {
            UserModel userModel = UserModel.fromFirestore(userDoc.data()! as Map<String, dynamic>);
            Api.user = userModel;
            Api.user!.push_token = await Notifications.init();
            await Api.userRef.doc(Api.auth.currentUser!.uid).update({
              'push_token': Api.user!.push_token
            });

            // Set API flag and persist role
            Api.isAdmin = false;
            final pref = await SharedPreferences.getInstance();
            await pref.setString('user', jsonEncode(userModel.toJson()));
            await pref.setBool('isAdmin', false);

            Utilities().showMessage(context, 'Signed in as: ${userModel.name}');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            Utilities().showMessage(context, 'User document not found.');
          }
        }

      } catch (error) {
        debugPrint(error.toString());
        Utilities().showMessage(context, error.toString());
      } finally {
        if (mounted) setState(() => loading = false);
      }
    }
  }
}
