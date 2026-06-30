import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/providers/navigation_provider.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detect visibility changes inside IndexedStack (TrashScreen is at index 5)
    final isActive = ref.watch(activeIndexProvider) == 5;
    if (isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_controller.isAnimating && _controller.value == 0.0) {
          _controller.forward();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.value > 0.0) {
          _controller.reset();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text('Trash'),
      ),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: const Center(
            child: Text('Tombstoned Files (Empty)'),
          ),
        ),
      ),
    );
  }
}
