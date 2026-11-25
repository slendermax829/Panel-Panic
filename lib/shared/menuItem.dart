import 'package:flutter/material.dart';

class Menuitem extends StatefulWidget {
  final Widget child;

  const new({super.key, required this.child});

  @override
  State<Menuitem> createState() => _MenuitemState();
}

class _MenuitemState extends State<Menuitem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.1 : 1.0, 
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}