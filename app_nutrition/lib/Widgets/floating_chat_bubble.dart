// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Screens/chatbot_repas_screen.dart';
import '../Services/navigation_service.dart';

class FloatingChatBubble extends StatefulWidget {
  const FloatingChatBubble({super.key});

  @override
  State<FloatingChatBubble> createState() => _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends State<FloatingChatBubble> {
  // Absolute position (top-left). Initialized lazily on first build.
  Offset? _position;
  bool _dragging = false;
  static const double _size = 66.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final viewInsets = mq.viewInsets; // keyboard
    final safeBottom =
        (viewInsets.bottom > 0 ? viewInsets.bottom : mq.padding.bottom) + 90;
    final safeTop = mq.padding.top + 12;

    // Initialize position bottom-right on first build
    _position ??= Offset(
      mq.size.width - _size - 16,
      mq.size.height - _size - safeBottom,
    );

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          Positioned(
            top: _position!.dy.clamp(
              safeTop,
              mq.size.height - _size - safeBottom,
            ),
            left: _position!.dx.clamp(8.0, mq.size.width - _size - 8.0),
            child: _buildDraggable(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggable() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => setState(() => _dragging = true),
      onPanUpdate: (details) {
        final mq = MediaQuery.of(context);
        final viewInsets = mq.viewInsets;
        final safeBottom =
            (viewInsets.bottom > 0 ? viewInsets.bottom : mq.padding.bottom) +
            90;
        final safeTop = mq.padding.top + 12;
        final minX = 8.0;
        final maxX = mq.size.width - _size - 8.0;
        final minY = safeTop;
        final maxY = mq.size.height - _size - safeBottom;
        final next = (_position ?? Offset.zero) + details.delta;
        setState(() {
          _position = Offset(
            next.dx.clamp(minX, maxX),
            next.dy.clamp(minY, maxY),
          );
        });
      },
      onPanEnd: (_) {
        final mq = MediaQuery.of(context);
        final centerX = (_position?.dx ?? 0) + _size / 2;
        final snapLeft = centerX < mq.size.width / 2;
        setState(() {
          _dragging = false;
          _position = Offset(
            snapLeft ? 12.0 : mq.size.width - _size - 12.0,
            _position?.dy ?? 100,
          );
        });
      },
      onTap: () async {
        // Déclenche la navigation après la fin de la frame courante pour éviter
        // les conflits de gestes/navigation selon certains appareils.
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          try {
            HapticFeedback.lightImpact();
            await NavigationService.push(
              MaterialPageRoute(builder: (_) => const ChatbotRepasScreen()),
            );
          } catch (e) {
            debugPrint('Error opening chat screen: $e');
          }
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _dragging ? 0.95 : 1.0,
        child: _ProChatBubble(size: _size),
      ),
    );
  }
}

class _ProChatBubble extends StatelessWidget {
  final double size;
  const _ProChatBubble({required this.size});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ouvrir le chat Snacky',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Outer circle with green gradient and soft shadow
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFFB2FF59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.13),
                    offset: const Offset(0, 7),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFB2FF59), Color(0xFF43A047)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_chat_unread_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            // Animated unread badge
            Positioned(
              right: -2,
              top: -2,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.15),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                onEnd: () {},
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
