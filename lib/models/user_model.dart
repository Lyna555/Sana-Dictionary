class SanaUser {
  final int? id;
  final String? username;
  final String? email;
  final String? password;
  final String? type;
  final String? level;
  final String? field;
  final String? photoUrl;
  final String? deviceId;
  final String? createdAt;
  final String? updatedAt;

  SanaUser(
      {required this.id,
      required this.username,
      required this.email,
      required this.password,
      required this.type,
      required this.level,
      required this.field,
      required this.photoUrl,
      required this.deviceId,
      required this.createdAt,
      required this.updatedAt});

  factory SanaUser.fromJson(Map<String, dynamic> json) {
    return SanaUser(
        id: json['id'],
        username: json['username'],
        email: json['email'],
        password: json['password'],
        type: json['type'],
        level: json['level'],
        field: json['field'],
        photoUrl: json['photo_url'],
        deviceId: json['device_id'],
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'type': type,
      'level': level,
      'field': field,
      'photo_url': photoUrl,
      'device_id': deviceId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
