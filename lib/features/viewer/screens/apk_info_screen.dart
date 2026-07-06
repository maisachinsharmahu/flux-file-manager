import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../bridge/flux_bridge.dart';

class ApkInfoScreen extends StatefulWidget {
  final String path;
  final String title;

  const ApkInfoScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<ApkInfoScreen> createState() => _ApkInfoScreenState();
}

class _ApkInfoScreenState extends State<ApkInfoScreen> {
  Map<String, dynamic> _metadata = {};
  bool _isLoading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _loadApkMetadata();
  }

  Future<void> _loadApkMetadata() async {
    try {
      final jsonStr = await FluxBridge.getApkMetadata(widget.path);
      final meta = json.decode(jsonStr) as Map<String, dynamic>;
      setState(() {
        _metadata = meta;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to load APK details: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appName = _metadata['appName'] as String? ?? widget.title;
    final packageName = _metadata['packageName'] as String? ?? "";
    final versionName = _metadata['versionName'] as String? ?? "";
    final versionCode = _metadata['versionCode'] as int? ?? 0;
    final activities = (_metadata['activities'] as List? ?? []).cast<String>();
    final permissions = (_metadata['permissions'] as List? ?? []).cast<String>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appName,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4))))
          : _errorMsg.isNotEmpty
              ? Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.white54)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // App icon logo header card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.android_rounded, color: Color(0xFF00BCD4), size: 56),
                          const SizedBox(height: 16),
                          Text(
                            appName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            packageName,
                            style: const TextStyle(color: Colors.white30, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Version Name', style: TextStyle(color: Colors.white30, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(versionName, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('Version Code', style: TextStyle(color: Colors.white30, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text('$versionCode', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Permissions list segment
                    _buildExpandableList('Permissions (${permissions.length})', permissions, Icons.lock_open_rounded),
                    const SizedBox(height: 16),
                    // Activities list segment
                    _buildExpandableList('Activities (${activities.length})', activities, Icons.explore_outlined),
                  ],
                ),
    );
  }

  Widget _buildExpandableList(String title, List<String> items, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: const Color(0xFF00BCD4), size: 20),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          children: items.isEmpty
              ? [const Center(child: Text('None', style: TextStyle(color: Colors.white30, fontSize: 12)))]
              : items.map<Widget>((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 13)),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(color: Colors.white60, fontSize: 13, fontFamily: 'Courier'),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }
}
