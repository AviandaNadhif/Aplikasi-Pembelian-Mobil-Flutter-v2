import 'package:flutter/material.dart';

/// Widget komponen kartu umum dengan ikon dan judul text.
class CardWidget extends StatelessWidget {
  final IconData icon;
  final String judul;

  /// Membuat [CardWidget] dengan [icon] dan [judul] tertentu.
  const CardWidget({super.key, required this.icon, required this.judul});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(judul),
      ),
    );
  }
}