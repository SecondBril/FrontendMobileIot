import 'package:flutter/material.dart';

class TransparentCard extends StatelessWidget {
  final Widget child;
  const TransparentCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20.0)),
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: Padding(padding: const EdgeInsets.all(10.0), child: child),
    );
  }
}
