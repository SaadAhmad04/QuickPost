class CommentsModel{
  String? userId;
  String? userName;
  List? comment;
  String? postedOn;
  CommentsModel({this.userId , this.userName , this.comment , this.postedOn});

  factory CommentsModel.fromJson(Map<String, dynamic> json) {
    return CommentsModel(
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      comment: json['comment'] as List?,
      postedOn: json['postedOn'] as String?,
    );
  }

  // Method to convert the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'postedOn': postedOn,
    };
  }


}