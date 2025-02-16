# My Flutter Video App 🎥

This is the first version of my Flutter app using Dart 3, Firebase, and FL Chart for video analytics.

## Features
✅ Upload and store videos in Firebase  
✅ Generate thumbnails  
✅ Video analytics (likes, dislikes, comments, views)  
✅ Interactive UI with a purple theme  
✅ Notifications for likes, dislikes, and comments  

## Installation
1. Clone the repo:  
git clone https://github.com/SaadAhmad04/QuickPost.git
2. Open in IntelliJ IDEA.
3. Run:
flutter pub get
4. Set up Firebase (`google-services.json` for Android, `GoogleService-Info.plist` for iOS).
5. Run the app:
flutter run
6. To get service account json(used in notifications.dart), go to firebase project settings, then go to Service Accounts tab and select NodeJs and generate the private key
Store that key in separate file(Secret.dart) and declare it as static and final

## Contributing
Feel free to submit issues or pull requests.

## License
[MIT](LICENSE)
