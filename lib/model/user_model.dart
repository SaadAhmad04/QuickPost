class UserModel {
  final String email;
  final String joinedOn;
  final String name;
  final String profilePic;
  final String uid;
  String? push_token;

  UserModel({
    required this.email,
    required this.joinedOn,
    required this.name,
    required this.profilePic,
    required this.uid,
    required this.push_token
  });

  // Factory method to create a User from a Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> doc) {
    return UserModel(
      email: doc['email'] ?? '',
      joinedOn: doc['joined_on'] ?? '',
      name: doc['name'] ?? '',
      profilePic: doc['profilePic'] ?? '',
      uid: doc['uid'] ?? '',
      push_token: doc['push_token']
    );
  }

  // Convert User to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'joined_on': joinedOn,
      'name': name,
      'profilePic': profilePic,
      'uid': uid,
      'push_token':push_token
    };
  }

  // Convert the UserModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'joined_on': joinedOn,
      'name': name,
      'profilePic': profilePic,
      'uid': uid,
      'push_token':push_token
    };
  }

  // Convert JSON to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] ?? '',
      joinedOn: json['joined_on'] ?? '',
      name: json['name'] ?? '',
      profilePic: json['profilePic'] ?? '',
      uid: json['uid'] ?? '',
      push_token: json['push_token'] ?? ''
    );
  }
}
