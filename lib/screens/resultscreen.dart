import 'dart:typed_data';

import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.isGenuine,
    required this.image,
  });
  final bool isGenuine;
  final Image image;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        child: Placeholder(),
      ),
    );
  }
}
