import 'package:database/database.dart' show Entity;

enum Role {
  developer('developer'),
  team('team'),
  subTeamDeveloper('sub_team_developer')
  ;

  const Role(this.value);
  final String value;

  static Role fromString(String value) {
    return Role.values.firstWhere((role) => role.value == value);
  }
}

class UserInformation extends Entity {
  final int? id;
  final String? uuid;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? country;
  final String? city;
  final String? address;
  final String? zipCode;
  final String? avatar;
  final Role role;
  final String userId;

  UserInformation({
    this.id,
    this.uuid,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.country,
    this.city,
    this.address,
    this.zipCode,
    required this.avatar,
    required this.role,
    required this.userId,
  });

  UserInformation.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      uuid = map['uuid'],
      firstName = map['first_name'],
      lastName = map['last_name'],
      phoneNumber = map['phone_number'],
      country = map['country'],
      city = map['city'],
      address = map['address'],
      zipCode = map['zip_code'],
      avatar = map['avatar'],
      role = map['role'] is String ? Role.fromString(map['role']) : map['role'],
      userId = map['user_id'];

  @override
  String get tableName => 'user_information';

  @override
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber ?? '',
      'country': country ?? '',
      'city': city ?? '',
      'address': address ?? '',
      'zip_code': zipCode ?? '',
      'avatar': avatar ?? '',
      'role': role.value,
      'user_id': userId,
    };
  }
}
