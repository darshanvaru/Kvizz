class UserModel {
  final String id;
  final String username;
  final String? photo;

  UserModel({
    required this.id,
    required this.username,
    this.photo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      username: json['username'],
      photo: json['photo'],
    );
  }
}
