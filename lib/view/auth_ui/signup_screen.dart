import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../constants/roundButton.dart';
import '../../constants/utilities.dart';
import '../../controller/apis.dart';
import '../../main.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Sign Up',
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
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 30),
                      buildTextField(
                        controller: nameController,
                        hintText: 'Enter your name',
                        icon: Icons.person,
                      ),
                      SizedBox(height: 15),
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
                        obscureText: true,
                      ),
                      SizedBox(height: 30),
                      RoundButton(
                        title: 'Sign Up',
                        loading: loading,
                        onTap: handleSignUp,
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account?"),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            ),
                            child: Text(
                              'Login',
                              style: TextStyle(color: Colors.purple.shade800),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

  void handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      try {
        final time = DateTime.now().millisecondsSinceEpoch.toString();
        await Api.auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        await Api.userRef.doc(Api.auth.currentUser?.uid).set({
          'joined_on': time,
          'email': emailController.text,
          'profilePic': "",
          'uid': Api.auth.currentUser?.uid,
          'name': nameController.text,
          'push_token':""
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } catch (error) {
        Utilities().showMessage(context ,error.toString());
      } finally {
        setState(() => loading = false);
      }
    }
  }
}
