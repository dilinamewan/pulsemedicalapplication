import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 16, 
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), 
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
            ),
            child: Text(
              "Emergency",
              style: TextStyle(color: Colors.white, fontSize: 14), 
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications, color: Colors.black, size: 20), 
          ),
        ],
      ),
      toolbarHeight: 48, 
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48); 
}
