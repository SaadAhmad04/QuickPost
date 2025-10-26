// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// import '../constants/utilities.dart';
// import '../controller/apis.dart';
// import '../main.dart';
// import 'auth_ui/login_screen.dart';
//
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final nameController = TextEditingController();
//   final phoneController = TextEditingController();
//   static File? image;
//   static ImagePicker imagePicker = ImagePicker();
//
//   Future<void> profilePic() async {
//     try {
//       final pickedFile = await imagePicker.pickImage(
//           source: ImageSource.gallery, imageQuality: 80);
//       if (pickedFile != null) {
//         image = File(pickedFile.path);
//         setState(() {});
//       } else {
//         Utilities().showMessage(context ,'No image selected');
//       }
//     } catch (e) {
//       Utilities().showMessage(context ,e.toString());
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(Api.user!.joinedOn));
//     mq = MediaQuery.of(context).size;
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text(
//           'My Profile',
//           style: TextStyle(
//               color: Colors.purple.shade800,
//               fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         leading: BackButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           color: Colors.purple.shade800,
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: IconButton(
//                 onPressed: () async {
//                   await Api.auth.signOut().then((value) {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => LoginScreen()));
//                   });
//                 },
//                 icon: Icon(
//                   Icons.logout,
//                   color: Colors.red.shade600,
//                 )),
//           )
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.purple.shade200, Colors.purple.shade700],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Stack(
//               children: [
//                 Align(
//                   alignment: Alignment.center,
//                   child: CircleAvatar(
//                     backgroundColor: Api.user!.profilePic == ""
//                         ? Colors.purple.shade800
//                         : Colors.transparent,
//                     maxRadius: mq.height * .15,
//                     child: Api.user!.profilePic != ""
//                         ? Image.network(Api.user!.profilePic)
//                         : Icon(
//                       Icons.person,
//                       size: 60,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   top: mq.height * .2,
//                   left: mq.width * .65,
//                   child: MaterialButton(
//                     color: Colors.purple.shade600,
//                     shape: CircleBorder(
//                         side: BorderSide(color: Colors.purple.shade600)),
//                     onPressed: () {
//                       profilePic();
//                     },
//                     child: Icon(Icons.edit, color: Colors.white),
//                   ),
//                 )
//               ],
//             ),
//             SizedBox(
//               height: mq.height * .05,
//             ),
//             Text(
//               'Joined on ${date.day}-${date.month}-${date.year}',
//               style: TextStyle(fontSize: 16, color: Colors.white),
//             ),
//             SizedBox(
//               height: mq.height * .05,
//             ),
//             Divider(
//               thickness: 2,
//               color: Colors.white.withOpacity(0.6),
//               indent: mq.width * .1,
//               endIndent: mq.width * .1,
//             ),
//             Form(
//               key: _formKey,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     TextFormField(
//                       initialValue: Api.user!.name,
//                       decoration: InputDecoration(
//                           filled: true,
//                           fillColor: Colors.white,
//                           border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10)),
//                           prefixIcon: Icon(Icons.person)),
//                       validator: (val) {
//                         if (val!.isEmpty) {
//                           return 'Enter name';
//                         }
//                       },
//                     ),
//                     SizedBox(
//                       height: mq.height * .02,
//                     ),
//                     TextFormField(
//                       initialValue: Api.user!.email,
//                       decoration: InputDecoration(
//                           filled: true,
//                           fillColor: Colors.white,
//                           border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10)),
//                           prefixIcon: Icon(Icons.email)),
//                       validator: (val) {
//                         if (val!.isEmpty) {
//                           return 'Enter phone number';
//                         }
//                       },
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickpost/utilities/usage_limiter.dart';
import '../constants/utilities.dart';
import '../controller/apis.dart';
import '../main.dart';
import 'auth_ui/login_screen.dart';
import 'block_screen.dart';

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

  // inside _ProfileScreenState
  int selectedHours = 0;
  int selectedMinutes = 0;
  bool limiterEnabled = false;
  bool autoLogout = false;

// to show human-friendly label if custom chosen
  bool _usingCustom = false;

  @override
  void initState() {
    super.initState();
    _loadLimiterSettings();
  }

  Future<int?> _showCustomDurationDialog() async {
    final hoursController = TextEditingController(text: '0');
    final minutesController = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Custom duration'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter hours and minutes (e.g. 1 hour 30 minutes):'),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: hoursController,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: 'Hours', hintText: '0'),
                        validator: (v) {
                          if (v == null) return null;
                          final n = int.tryParse(v);
                          if (n == null || n < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: minutesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: 'Minutes', hintText: '0'),
                        validator: (v) {
                          if (v == null) return null;
                          final n = int.tryParse(v);
                          if (n == null || n < 0 || n >= 60) return '0–59';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final h = int.tryParse(hoursController.text) ?? 0;
                  final m = int.tryParse(minutesController.text) ?? 0;
                  final seconds = h * 3600 + m * 60;
                  if (seconds <= 0) {
                    // require non-zero
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text('Please enter non-zero duration')));
                    return;
                  }
                  Navigator.of(ctx).pop(seconds);
                }
              },
              child: Text('Set'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadLimiterSettings() async {
    // read saved limit seconds
    final limitSeconds = UsageLimiter.instance.getLimitSeconds();
    if (limitSeconds > 0) {
      setState(() {
        selectedHours = limitSeconds ~/ 3600;
        selectedMinutes = (limitSeconds % 3600) ~/ 60;
        limiterEnabled = true;
      });
    }

    // blocked status
    final blocked = UsageLimiter.instance.isBlockedToday();
    setState(() {
      // keep limiterEnabled as previously set; blocked is just status
      // optionally you could set limiterEnabled = !blocked;
    });

    print(
        '[ProfileScreen] loaded limiter settings: limitSeconds=$limitSeconds blocked=$blocked');
  }

  Future<void> profilePic() async {
    try {
      final pickedFile = await imagePicker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        image = File(pickedFile.path);
        setState(() {});
      } else {
        Utilities().showMessage(context, 'No image selected');
      }
    } catch (e) {
      Utilities().showMessage(context, e.toString());
    }
  }

  // default action when limit reached (if not overridden)
  void _defaultOnLimitReached() {
    if (autoLogout) {
      print(
          '[ProfileScreen] Limit reached: auto-logout enabled -> signing out');
      Api.auth.signOut().then((_) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen()), (route) => false);
      });
    } else {
      // show block screen (modal full-screen)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => BlockScreen(onTryAgain: _onTryAgainFromBlock)),
        (route) => false,
      );
    }
  }

  void _onTryAgainFromBlock() {
    // called when user taps OK on block screen - re-check block status
    if (UsageLimiter.instance.isBlockedToday()) {
      Utilities().showMessage(context, 'Still blocked for today.');
    } else {
      // if not blocked anymore, pop to Profile or Home
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MyAppHomePlaceholder()));
    }
  }

  Future<void> _saveLimit() async {
    final seconds = selectedHours * 3600 + selectedMinutes * 60;
    print('[ProfileScreen] saving limit: ${selectedHours}h ${selectedMinutes}m => $seconds sec, enabled=$limiterEnabled, autoLogout=$autoLogout');

    if (limiterEnabled && seconds == 0) {
      Utilities().showMessage(context, 'Please choose a non-zero limit or disable the limiter.');
      return;
    }

    if (limiterEnabled) {
      await UsageLimiter.instance.setLimitSeconds(seconds);
      UsageLimiter.instance.startSession();
    } else {
      await UsageLimiter.instance.setLimitSeconds(0);
      await UsageLimiter.instance.stopSession();
    }

    await UsageLimiter.instance.setAutoLogout(autoLogout);

    Utilities().showMessage(context, 'Limit saved');
    setState(() {});
  }

  Future<void> _resetTodayUsage() async {
    await UsageLimiter.instance.resetToday();
    Utilities().showMessage(context, 'Today\'s usage reset (debug).');
    print('[ProfileScreen] Reset today usage via profile debug button');
    setState(() {});
  }

  // small helper to format seconds -> H:MM:SS
  String _formatDurationSeconds(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return '$h:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    DateTime date =
        DateTime.fromMillisecondsSinceEpoch(int.parse(Api.user!.joinedOn));
    final mq = MediaQuery.of(context).size;
    final accumulated = UsageLimiter.instance.getAccumulatedSeconds();
    final blocked = UsageLimiter.instance.isBlockedToday();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Profile',
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
                onPressed: () async {
                  await Api.auth.signOut().then((value) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => LoginScreen()));
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
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 24),
          children: [
            // Avatar block
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    backgroundColor: Api.user!.profilePic == ""
                        ? Colors.purple.shade800
                        : Colors.transparent,
                    maxRadius: mq.height * .12,
                    child: Api.user!.profilePic != ""
                        ? ClipOval(
                            child: Image.network(Api.user!.profilePic,
                                width: mq.height * .24,
                                height: mq.height * .24,
                                fit: BoxFit.cover))
                        : Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                  ),
                ),
                Positioned(
                  top: mq.height * .11,
                  left: mq.width * .64,
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

            SizedBox(height: 18),

            // Joined date
            Center(
              child: Text(
                'Joined on ${date.day}-${date.month}-${date.year}',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

            SizedBox(height: 18),
            Divider(
              thickness: 2,
              color: Colors.white.withOpacity(0.6),
              indent: mq.width * .1,
              endIndent: mq.width * .1,
            ),

            // Form fields
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
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
                    SizedBox(height: 12),
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
                    ),
                  ],
                ),
              ),
            ),

            // ---------- LIMITER SECTION (REPLACEMENT) ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily watch limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple.shade800)),
                    SizedBox(height: 8),

                    // Preset buttons + Custom
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _presetChip(0, 'Off'),
                        _presetChip(5 * 60, '5 m'),
                        _presetChip(10 * 60, '10 m'),
                        _presetChip(15 * 60, '15 m'),
                        _presetChip(30 * 60, '30 m'),
                        _presetChip(60 * 60, '1 h'),
                        ActionChip(
                          label: Text(_usingCustom ? 'Custom: ${selectedHours}h ${selectedMinutes}m' : 'Custom'),
                          onPressed: () async {
                            final seconds = await _showCustomDurationDialog();
                            if (seconds != null) {
                              setState(() {
                                _usingCustom = true;
                                selectedHours = seconds ~/ 3600;
                                selectedMinutes = (seconds % 3600) ~/ 60;
                                limiterEnabled = true;
                              });
                            }
                          },
                          backgroundColor: _usingCustom ? Colors.purple.shade100 : Colors.grey.shade200,
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    Row(
                      children: [
                        Text('Limiter: ', style: TextStyle(color: Colors.grey.shade800)),
                        Switch(
                          value: limiterEnabled,
                          onChanged: (v) => setState(() => limiterEnabled = v),
                          activeColor: Colors.purple.shade600,
                        ),
                        Spacer(),
                        // Auto logout option
                        Row(
                          children: [
                            Text('Auto logout', style: TextStyle(color: Colors.grey.shade800)),
                            Switch(
                              value: autoLogout,
                              onChanged: (v) => setState(() => autoLogout = v),
                              activeColor: Colors.red.shade600,
                            )
                          ],
                        )
                      ],
                    ),

                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _saveLimit,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700),
                          child: Text('Save' , style: TextStyle(color: Colors.white),),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final auto = UsageLimiter.instance.getAutoLogout();
                            final limitSeconds = UsageLimiter.instance.getLimitSeconds();
                            final acc = UsageLimiter.instance.getAccumulatedSeconds();
                            Utilities().showMessage(context, 'limitSec=$limitSeconds autoLogout=$auto accumulated=${_formatDurationSeconds(acc)} blocked=${UsageLimiter.instance.isBlockedToday()}');
                            print('[ProfileScreen] debug status limitSec=$limitSeconds autoLogout=$auto acc=$acc blocked=${UsageLimiter.instance.isBlockedToday()}');
                          },
                          child: Text('Show status'),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _resetTodayUsage,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                          child: Text('Reset'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Today used', style: TextStyle(color: Colors.grey.shade700)),
                        Text(_formatDurationSeconds(UsageLimiter.instance.getAccumulatedSeconds()), style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Blocked today?', style: TextStyle(color: Colors.grey.shade700)),
                        Text(UsageLimiter.instance.isBlockedToday() ? 'Yes' : 'No', style: TextStyle(fontWeight: FontWeight.bold, color: UsageLimiter.instance.isBlockedToday() ? Colors.red : Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(int seconds, String label) {
    final isSelected = (UsageLimiter.instance.getLimitSeconds() == seconds) ||
        (_usingCustom == false && selectedHours * 3600 + selectedMinutes * 60 == seconds && seconds != 0);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _usingCustom = false;
          final h = seconds ~/ 3600;
          final m = (seconds % 3600) ~/ 60;
          selectedHours = h;
          selectedMinutes = m;
          limiterEnabled = seconds > 0;
        });
      },
      selectedColor: Colors.purple.shade100,
    );
  }

}

// Small placeholder to navigate to when unblocked; replace with your HomeScreen
class MyAppHomePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QuickPost Home'),
      ),
      body: Center(child: Text('Home')),
    );
  }
}
