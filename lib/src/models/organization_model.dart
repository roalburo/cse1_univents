// models/organization.dart
class Organization {
  final String uid;
  final String banner;
  final String logo;
  final String acronym;
  final String name;
  final String category;
  final String email;
  final String mobile;
  final String facebook;
  final bool status;

  Organization({
    required this.uid,
    required this.banner,
    required this.logo,
    required this.acronym,
    required this.name,
    required this.category,
    required this.email,
    required this.mobile,
    required this.facebook,
    required this.status,
  });

  factory Organization.fromMap(Map<String, dynamic> m) => Organization(
        uid: m['uid'] as String,
        banner: m['banner'] as String,
        logo: m['logo'] as String,
        acronym: m['acronym'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        email: m['email'] as String,
        mobile: m['mobile'] as String,
        facebook: m['facebook'] as String,
        status: m['status'] as bool,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'banner': banner,
        'logo': logo,
        'acronym': acronym,
        'name': name,
        'category': category,
        'email': email,
        'mobile': mobile,
        'facebook': facebook,
        'status': status,
      };
}
