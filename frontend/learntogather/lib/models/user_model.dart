class UserModel {
  final int id;
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String? profilePicture; // Now stores base64 encoded image data
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    this.displayName,
    this.profilePicture,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      email: json['email'],
      displayName: json['display_name'],
      profilePicture: json['profile_picture'], // Base64 data or null
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'display_name': displayName,
      'profile_picture': profilePicture, // Base64 data or null
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? firebaseUid,
    String? email,
    String? displayName,
    String? profilePicture,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper method to get profile image as data URL for display
  String? getProfileImageDataUrl() {
    if (profilePicture == null || profilePicture!.isEmpty) {
      return null;
    }
    
    // If already contains data URL prefix, return as is
    if (profilePicture!.startsWith('data:')) {
      return profilePicture;
    }
    
    // Otherwise, add data URL prefix (assuming JPEG)
    return 'data:image/jpeg;base64,${profilePicture!}';
  }

  // Helper method to check if user has a profile picture
  bool get hasProfilePicture {
    return profilePicture != null && profilePicture!.isNotEmpty;
  }

  // Helper method to get initials from display name or email
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final names = displayName!.trim().split(' ');
      if (names.length >= 2) {
        return '${names.first[0]}${names.last[0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        return names.first.substring(0, 1).toUpperCase();
      }
    }
    
    // Fallback to email initial
    if (email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }
    
    return 'U'; // Default fallback
  }

  @override
  String toString() {
    return 'UserModel{id: $id, firebaseUid: $firebaseUid, email: $email, displayName: $displayName, hasProfilePicture: $hasProfilePicture, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserModel &&
        other.id == id &&
        other.firebaseUid == firebaseUid &&
        other.email == email &&
        other.displayName == displayName &&
        other.profilePicture == profilePicture &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        firebaseUid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        profilePicture.hashCode ^
        createdAt.hashCode;
  }
}
