import 'package:flutter/material.dart';
Image logoWidget(String imageName) {
  return Image.asset(
    imageName,
    fit: BoxFit.fitWidth,
    width: 240,
    height: 240,
    alignment: Alignment.center,

  );
}
/*TextField reusableTextField(String text,IconData icon,bool isPasswordType,
TextEditingController controller){
  reusableTextField (controller: controller,
      obscureText: isPasswordType,
      enableSuggestions: !isPasswordType,
      autocorrect: !isPasswordType,
      cursorColor: Colors.white,
      style:TextStyle(color:Colors.white.withOpacity(0.9)),
  decoration:InputDecoration()
}*/