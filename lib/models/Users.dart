import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse/Globals.dart';


class User {
  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.profileImageUrl,
    required this.gender,


  });

  final String userId;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? gender;
}

class UserService {
   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Example of a method that fetches users
   Future<List<User>> getUsers(String userId) async {
    List<User> users = [];

    try {
      // Query 'users' collection
      QuerySnapshot querySnapshot = await _firestore.collection('users').where("uid",isEqualTo:globalUserId).get();

      // Iterate over the results and build 'User' objects
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        users.add(
          User(
            userId: doc.id,
            name: data['fullName'],
            email: data['email'],
            phoneNumber: data['phoneNumber'],
            profileImageUrl: data['pp_url'],
            gender: data['gender'],


          ),
        );
      }
    } catch (e) {
      print('Error fetching users: $e');
    }

    return users;
  }
}