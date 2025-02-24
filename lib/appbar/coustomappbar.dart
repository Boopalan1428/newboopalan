// custom_app_bar.dart

import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final Color backgroundColor; // Added backgroundColor parameter

  // Constructor for customizing the app bar with a solid color
  CustomAppBar({
    required this.title,
    this.actions = const [],
    this.backgroundColor = Colors.blueAccent, // Default color set to blueAccent
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      backgroundColor: backgroundColor, // Set solid background color
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight); // Set the height of the app bar
}
