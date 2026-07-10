import 'package:flutter/material.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';

class SnackbarHelper {

    // TODO: Add more message variants

  static void showMessage(String message){
     messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
   static void showError(String message) {
     messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  static void showValidMessage(String message){
     messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  static void showSemiValidMessage(String message){
     messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.black),), backgroundColor: Colors.yellow,),
    );
  }

}