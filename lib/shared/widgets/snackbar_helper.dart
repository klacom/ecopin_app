import 'package:flutter/material.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class SnackbarHelper {

    // TODO: Add more message variants

  static void showMessage(String message){
     messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
   static void showError(String message) {
     messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  static void showValidMessage(String message){
     messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  static void showSemiValidMessage(String message){
     messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black)), 
        backgroundColor: AppColors.warning
      ),
    );
  }

  static void showSuccessMessage(String message){
     messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.info),
    );
  }

}