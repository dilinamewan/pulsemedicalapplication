import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  User({
    required this.userId,
  });

  final String userId;
}

class UserService {
   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Example of a method that fetches users
   Future<List<User>> getUsers() async {
    List<User> users = [];

    try {
      // Query 'users' collection
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();

      // Iterate over the results and build 'User' objects
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        users.add(
          User(
            userId: doc.id, // user document ID
          ),
        );
      }
    } catch (e) {
      print('Error fetching users: $e');
    }

    return users;
  }
}