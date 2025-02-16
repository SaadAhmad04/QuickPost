import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import 'Secret.dart';
import 'apis.dart';

class Notifications {
  static FirebaseMessaging _msg = FirebaseMessaging.instance;

  static void requestNotificationPermission() async {
    NotificationSettings settings = await _msg.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        provisional: true,
        sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("Provisional");
    } else {
      print('Denied');
      Future.delayed(Duration(seconds: 3), () {
        AppSettings.openAppSettings(type: AppSettingsType.notification);
      });
    }
  }

  static Future<String?> init() async {
    try {
      // Request notification permissions
      await _msg.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Retrieve and return the push token
      String? token = await getAccessToken();
      print('token = ${token}');
      if (token != null) {
        return token;
      }
    } catch (e) {
      print('Error during Firebase initialization or permission request: $e');
    }
    return null;
  }

  static Future<String?> getAccessToken(
      {int maxRetries = 3, int delaySeconds = 5}) async {
    try {
      String? fcmToken;
      fcmToken = await FirebaseMessaging.instance.getToken();
      return fcmToken;
    } catch (e) {
      print(e);
      if (maxRetries > 0) {
        final newDelay = delaySeconds * 2;
        print('Retrying after $newDelay seconds...');
        await Future.delayed(Duration(seconds: newDelay));
        return getAccessToken(
            maxRetries: maxRetries - 1, delaySeconds: newDelay);
      } else {
        print('Failed to get token after maximum retries');
        return null;
      }
    }
  }

  static Future<String> getServerKey() async {
    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(Secret.serviceAccountJson),
      Secret.scopes,
    );

    auth.AccessCredentials credentials =
    await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(Secret.serviceAccountJson),
        Secret.scopes,
        client);

    client.close();
    return credentials.accessToken.data;
  }

  static Future<void> pushNotifications1(
      Map<String, String> tokenAndId,
      String msg,
      String memberName,
      String memberEmail,
      String type,
      Map<String, String> videoDetails) async {
    try {
      final String serverKey = await getServerKey();
      String endpointFirebaseMessaging =
          'https://fcm.googleapis.com/v1/projects/assignment-4ab3e/messages:send';

      String token = tokenAndId['push_token']!;
      String userId = tokenAndId['userid']!;

      Map<String, dynamic> message = {
        "message": {
          "token": token,
          "notification": {
            "title": "QuickPost",
            "body": msg,
            "image": "images/logo.png",
          },
          "data": {
            "email": memberEmail,
            "name": memberName,
            "videoId": videoDetails.keys.first,
            "title":videoDetails.values.first
          }
        }
      };

      print('message = ${message}');

      bool sent = false;
      int attempts = 0;

      while (!sent && attempts < 3) {
        final http.Response response = await http.post(
          Uri.parse(endpointFirebaseMessaging),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $serverKey',
          },
          body: jsonEncode(message),
        );

        if (response.statusCode == 200) {
          sent = true;
          print('Notification sent to userId: $userId');
          await sendPushNotificationToFirestore(
              userId, msg, type, memberName, memberEmail, videoDetails);
        } else {
          print(response.body);
          print('Failed to send notification');
          attempts++;
          if (attempts == 3) {
            throw Exception('Failed to send notification after 3 attempts');
          }
          await Future.delayed(
              Duration(seconds: 2 * attempts)); // Exponential backoff
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  static Future<void> sendPushNotificationToFirestore(
      String userId,
      String msg,
      String type,
      String memberName,
      String memberEmail,
      Map<String, String> videoDetails) async {
    try {
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      await Api.userRef.doc(userId).collection('notifications').doc(time).set({
        'senderId': Api.user!.uid,
        'message': msg,
        'type': type,
        'timestamp': time,
        'memberName': memberName,
        'memberEmail': memberEmail,
        "videoId": videoDetails.keys.first,
        "title": videoDetails.values.first
      });
      print('Notification saved to Firestore for userId: $userId');
    } catch (e) {
      print('Error saving notification to Firestore: ${e.toString()}');
    }
  }
}
