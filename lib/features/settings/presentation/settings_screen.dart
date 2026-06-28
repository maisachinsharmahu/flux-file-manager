import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: const [
          ListTile(
            title: Text('Thermal Governor Throttling'),
            trailing: Icon(Icons.toggle_on_outlined),
          ),
          ListTile(
            title: Text('Embeddings Generation'),
            trailing: Icon(Icons.toggle_off_outlined),
          ),
        ],
      ),
    );
  }
}
