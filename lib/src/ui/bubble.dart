
import 'package:flutter/material.dart';

class DebugBubble extends StatefulWidget {
  const DebugBubble({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<DebugBubble> createState() => _DebugBubbleState();
}

class _DebugBubbleState extends State<DebugBubble> with TickerProviderStateMixin {
  Offset _offset = const Offset(16, 200);
  bool _dragging = false;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    const size = 60.0;

    return Positioned(
      left: _offset.dx,
      top: _offset.dy.clamp(0, media.size.height - size - 80),
      child: GestureDetector(
        onTap: () {
          if (!_dragging) {
            _scaleController.forward().then((_) {
              _scaleController.reverse();
            });
            widget.onTap();
          }
        },
        onPanStart: (_) {
          setState(() => _dragging = true);
          _scaleController.forward();
        },
        onPanEnd: (_) {
          _scaleController.reverse();
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) setState(() => _dragging = false);
          });
        },
        onPanUpdate: (d) {
          setState(() {
            _offset = Offset(
              (_offset.dx + d.delta.dx).clamp(0, media.size.width - size),
              (_offset.dy + d.delta.dy).clamp(0, media.size.height - size),
            );
          });
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _scaleController]),
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_scaleController.value * 0.1),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse effect
                  Container(
                    width: size + (20 * _pulseController.value),
                    height: size + (20 * _pulseController.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(
                          0.5 * (1 - _pulseController.value),
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                  // Main bubble
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepPurple[400]!,
                          Colors.deepPurple[700]!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bug_report_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'DBG',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Drag indicator when dragging
                  if (_dragging)
                    Positioned(
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Drag to move',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
