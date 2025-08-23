import 'package:flutter/material.dart';
import 'HomePage.dart'; 

class HomeRoute extends StatelessWidget {
  const HomeRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return HomePageView(
      showEmptyState: false,
      emptyImageAsset: 'assets/petfeed.jpg',
      emptyText: "Voops! Couldn't find any PawFeeder.",
      isAuthorizing: false,
      errorMessage: null,
      onRetryAuthorize: null,
      onOpenProfile: () {}, // TODO: hook your profile navigation
      onOpenHistory: () {}, // TODO: hook your history navigation
      onSignOut: () {},     // TODO: implement sign-out
      username: null,
      avatarUrl: null,
      foodWeightGrams: 420,
      catDetected: true,
      onDispense: () {},
      onSchedule: () {},
      onConnectDevice: () {},
    );
  }
}
