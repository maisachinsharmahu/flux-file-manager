import 'package:flutter/material.dart';

class BrowserToolbar extends StatelessWidget {
  const BrowserToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Theme.of(context).cardColor,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Path: /sdcard'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.grid_view),
          ),
        ],
      ),
    );
  }
}
