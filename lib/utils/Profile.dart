import 'package:firebase_database/firebase_database.dart';

class Profile {
  String userId;
  String fullName;
  String email;
  String password;
  String phoneNumber;
  AddressData address;
  String preferredLanguage;
  String token;
  String bio;
  int age;
  String profilePicture;
  List<String> skillsOffered;
  List<String> skillsNeeded;
  int credits;
  List<Ad> postedAds;
  List<Ad> savedAds;
  List<Session> scheduledSessions;
  List<Review> receivedReviews;
  String verificationStatus;
  DateTime registrationDate;
  DateTime lastLogin;
  NotificationPreferences notificationPreferences;
  PrivacySettings privacySettings;
  SocialMediaLinks socialMediaLinks;
  List<VerificationDocument> verificationDocuments;



  Profile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.password,
    required this.age,
    required this.phoneNumber,
    required this.address,
    required this.preferredLanguage,
    required this.bio,
    required this.profilePicture,
    required this.skillsOffered,
    required this.skillsNeeded,
    required this.credits,
    required this.postedAds,
    required this.savedAds,
    required this.scheduledSessions,
    required this.receivedReviews,
    required this.verificationStatus,
    required this.registrationDate,
    required this.lastLogin,
    required this.notificationPreferences,
    required this.privacySettings,
    required this.socialMediaLinks,
    required this.verificationDocuments,
    required this.token
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': fullName,
      'age': age,
      'email': email,
      'token': token,
      'password' : password,
      'phoneNumber': phoneNumber,
      'address': address.toJson(),
      'preferredLanguage': preferredLanguage,
      'bio': bio,
      'profilePicture': profilePicture,
      'skillsOffered': skillsOffered,
      'skillsNeeded': skillsNeeded,
      'credits': credits,
      'postedAds': postedAds.map((ad) => ad.toJson()).toList(),
      'savedAds': savedAds.map((ad) => ad.toJson()).toList(),
      'scheduledSessions': scheduledSessions.map((session) => session.toJson()).toList(),
      'receivedReviews': receivedReviews.map((review) => review.toJson()).toList(),
      'verificationStatus': verificationStatus,
      'registrationDate': registrationDate.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'notificationPreferences': notificationPreferences.toJson(),
      'privacySettings': privacySettings.toJson(),
      'socialMediaLinks': socialMediaLinks.toJson(),
      'verificationDocuments': verificationDocuments.map((doc) => doc.toJson()).toList(),
    };
  }
  // Metodo per convertire un oggetto User in una mappa
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': fullName,
      'age': age,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'address': address.toMap(),
      'preferredLanguage': preferredLanguage,
      'bio': bio,
      'profilePicture': profilePicture,
      'skillsOffered': skillsOffered,
      'skillsNeeded': skillsNeeded,
      'credits': credits,
      'token' : token,
      'postedAds': postedAds.map((ad) => ad.toMap()).toList(),
      'savedAds': savedAds.map((ad) => ad.toMap()).toList(),
      'scheduledSessions': scheduledSessions.map((session) => session.toMap()).toList(),
      'receivedReviews': receivedReviews.map((review) => review.toMap()).toList(),
      'verificationStatus': verificationStatus,
      'registrationDate': registrationDate.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'notificationPreferences': notificationPreferences.toMap(),
      'privacySettings': privacySettings.toMap(),
      'socialMediaLinks': socialMediaLinks.toMap(),
    };
  }

  // Metodo per creare un oggetto User da una mappa
  Profile.fromMap(Map<dynamic, dynamic> map)
      : userId = map['userId'],
        fullName = map['name'],
        age = map['age'],
        email = map['email'],
        password = map['password'],
        token = map['token'],
        phoneNumber = map['phoneNumber'],
        address = AddressData.fromMap(map['address']),
        preferredLanguage = map['preferredLanguage'],
        bio = map['bio'],
        profilePicture = map['profilePicture'],
        skillsOffered = List<String>.from(map['skillsOffered']),
        skillsNeeded = List<String>.from(map['skillsNeeded']),
        credits = map['credits'],
        postedAds = (map['postedAds'] as List).map((ad) => Ad.fromMap(ad)).toList(),
        savedAds = (map['savedAds'] as List).map((ad) => Ad.fromMap(ad)).toList(),
        scheduledSessions = (map['scheduledSessions'] as List).map((session) => Session.fromMap(session)).toList(),
        receivedReviews = (map['receivedReviews'] as List).map((review) => Review.fromMap(review)).toList(),
        verificationStatus = map['verificationStatus'],
        registrationDate = DateTime.parse(map['registrationDate']),
        lastLogin = DateTime.parse(map['lastLogin']),
        notificationPreferences = NotificationPreferences.fromMap(map['notificationPreferences']),
        privacySettings = PrivacySettings.fromMap(map['privacySettings']),
        socialMediaLinks = SocialMediaLinks.fromMap(map['socialMediaLinks']),
        verificationDocuments = (map['verificationDocuments'] as List).map((doc) => VerificationDocument.fromMap(doc)).toList();

  // Metodo per salvare l'utente su Firebase
  Future<void> saveToDatabase() async {
    final databaseReference = FirebaseDatabase.instance.ref();
    await databaseReference.child('users').child(userId).set(toMap());
  }

  // Metodo statico per recuperare un utente da Firebase
  static Future<Profile?> getUserFromDatabase(String userId) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    final snapshot = await databaseReference.child('users').child(userId).get();

    if (snapshot.exists) {
      return Profile.fromMap(snapshot.value as Map<dynamic, dynamic>);
    } else {
      return null;
    }
  }
}

class AddressData {
  String street;
  String city;
  String state;
  String postalCode;
  double latitude;  // Aggiunto
  double longitude; // Aggiunto

  AddressData({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.latitude,  // Aggiunto
    required this.longitude, // Aggiunto
  });

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'latitude': latitude,  // Aggiunto
      'longitude': longitude, // Aggiunto
    };
  }

  AddressData.fromMap(Map<dynamic, dynamic> map)
      : street = map['street'],
        city = map['city'],
        state = map['state'],
        postalCode = map['postalCode'],
        latitude = map['latitude'],  // Aggiunto
        longitude = map['longitude']; // Aggiunto
}


class Ad {
  String adId;
  String title;
  String description;

  Ad({
    required this.adId,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'adId': adId,
      'title': title,
      'description': description,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'adId': adId
    };
  }

  Ad.fromMap(Map<dynamic, dynamic> map)
      : adId = map['adId'],
        title = map['title'],
        description = map['description'];
}

class Session {
  String sessionId;
  DateTime date;
  int time;

  Session({
    required this.sessionId,
    required this.date,
    required this.time,
  });
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'date': date.toIso8601String(),
      'time': time,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'date': date.toIso8601String(),
      'time': time,
    };
  }

  Session.fromMap(Map<dynamic, dynamic> map)
      : sessionId = map['sessionId'],
        date = DateTime.parse(map['date']),
        time = map['time'];
}

class Review {
  String reviewId;
  String fromUserId;
  int rating;
  String comment;
  DateTime reviewDate;

  Review({
    required this.reviewId,
    required this.fromUserId,
    required this.rating,
    required this.comment,
    required this.reviewDate
  });

  Map<String, dynamic> toJson() {
    return {
      'reviewerId': fromUserId,
      'reviewId': reviewId,
      'comment': comment,
      'rating': rating,
      'reviewDate': reviewDate.toIso8601String(),
    };
  }
  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'reviewerId': fromUserId,
      'rating': rating,
      'comment': comment,
      'reviewDate': reviewDate.toIso8601String()
    };
  }

  Review.fromMap(Map<dynamic, dynamic> map)
      : reviewId = map['reviewId'],
        fromUserId = map['reviewerId'],
        rating = map['rating'],
        reviewDate = DateTime.parse(map['reviewDate'] as String),
        comment = map['comment'];

}

class NotificationPreferences {
  bool email;
  bool sms;
  bool push;

  NotificationPreferences({
    required this.email,
    required this.sms,
    required this.push,
  });


  Map<String, dynamic> toJson() {
    return {
      'emailNotifications': email,
      'pushNotifications': push,
      'smsNotifications': sms,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'emailNotifications': email,
      'smsNotifications': sms,
      'pushNotifications': push,
    };
  }

  NotificationPreferences.fromMap(Map<dynamic, dynamic> map)
      : email = map['emailNotifications'],
        sms = map['smsNotifications'],
        push = map['pushNotifications'];
}

class PrivacySettings {
  String profileVisibility;
  String reviewVisibility;

  PrivacySettings({
    required this.profileVisibility,
    required this.reviewVisibility,
  });

  Map<String, dynamic> toMap() {
    return {
      'profileVisibility': profileVisibility,
      'reviewVisibility': reviewVisibility,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'profileVisibility': profileVisibility,
      'reviewVisibility' : reviewVisibility
    };
  }

  PrivacySettings.fromMap(Map<dynamic, dynamic> map)
      : profileVisibility = map['profileVisibility'],
        reviewVisibility = map['reviewVisibility'];
}

class SocialMediaLinks {
  String linkedIn;


  SocialMediaLinks({
    required this.linkedIn,
  });

  Map<String, dynamic> toJson() {
    return {
      'linkedin': linkedIn,
    };
  }
  Map<String, dynamic> toMap() {
    return {
      'linkedin': linkedIn,
    };
  }

  SocialMediaLinks.fromMap(Map<dynamic, dynamic> map)
      : linkedIn = map['linkedin'];
}

class VerificationDocument {
  String documentId;
  String type;
  String url;

  VerificationDocument({
    required this.documentId,
    required this.type,
    required this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'documentType': type,
      'documentUrl': url,
      'documentId': documentId,
    };
  }
  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'docuemtnType': type,
      'documentUrl': url,
    };
  }

  VerificationDocument.fromMap(Map<dynamic, dynamic> map)
      : documentId = map['documentId'],
        type = map['documentType'],
        url = map['documentUrl'];
}
