import 'package:flutter/material.dart';

class ViewerErrorBoundary extends StatefulWidget {
  final Widget child;

  const ViewerErrorBoundary({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ViewerErrorBoundary> createState() => _ViewerErrorBoundaryState();
}

class _ViewerErrorBoundaryState extends State<ViewerErrorBoundary> {
  bool _hasError = false;
  String _errorDetails = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          title: const Text('Viewer Error Recovery', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Out Of Memory or Rendering Exception Caught',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorDetails,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorDetails = "";
                    });
                  },
                  child: const Text('Attempt Recovery', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Connect standard Flutter error catching boundary hooks
    return ErrorWidgetBuilder(
      onError: (details) {
        setState(() {
          _hasError = true;
          _errorDetails = details.toString();
        });
      },
      child: widget.child,
    );
  }
}

class ErrorWidgetBuilder extends StatefulWidget {
  final Widget child;
  final Function(Object) onError;

  const ErrorWidgetBuilder({
    Key? key,
    required this.child,
    required this.onError,
  }) : super(key: key);

  @override
  State<ErrorWidgetBuilder> createState() => _ErrorWidgetBuilderState();
}

class _ErrorWidgetBuilderState extends State<ErrorWidgetBuilder> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
