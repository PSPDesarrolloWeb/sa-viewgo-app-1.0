import 'package:flutter/material.dart';

class SAViewGoApp extends StatelessWidget {
  const SAViewGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporal: el tema (paso 2) y go_router (paso 3) se conectan aquí.
    return const MaterialApp(
      title: 'SAViewGo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('SAViewGo · Firebase listo')),
      ),
    );
  }
}