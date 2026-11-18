/// The public profile of a logged-in user.

class UserModel {
  final String username;
  final String name;
  final String email;

  const UserModel({
    required this.username,
    required this.name,
    required this.email,
  });

  /// [json] is the stored record: {name, email, password}.
  /// The username is the storage key, so it is passed in separately.
  factory UserModel.fromJson(String username, Map<String, dynamic> json) =>
      UserModel(
        username: username,
        name: json['name'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        'name': name,
        'email': email,
      };

  UserModel copyWith({String? name, String? email}) => UserModel(
        username: username,
        name: name ?? this.name,
        email: email ?? this.email,
      );

  @override
  bool operator ==(Object other) =>
      other is UserModel &&
      other.username == username &&
      other.name == name &&
      other.email == email;

  @override
  int get hashCode => Object.hash(username, name, email);
}
