import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/maps/presentation/screens/maps_screen.dart';

class FcMapScreen extends StatelessWidget {
  const FcMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapScreen(
      isFieldCrewMode: true,
      showOptimizedRoute: true,
      showOtherCrews: true,
      showBaseOfOperations: true,
    );
  }
}
