import 'package:flutter/material.dart';

class StereoscopicWidget extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color shadowColor;
  final double borderRadius;
  final double depth;
  final bool isPressed;
  final bool showStripes;
  final bool showDots;
  final bool showHighlight;

  const StereoscopicWidget({
    super.key,
    required this.child,
    required this.baseColor,
    required this.shadowColor,
    this.borderRadius = 16.0,
    this.depth = 4.0,
    this.isPressed = false,
    this.showStripes = true,
    this.showDots = false,
    this.showHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 60),
      padding: EdgeInsets.only(
        top: isPressed ? depth : 0,
        bottom: isPressed ? 0 : depth,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            if (!isPressed)
              BoxShadow(
                color: shadowColor,
                offset: Offset(0, depth),
                blurRadius: 0,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              if (showStripes)
                Positioned.fill(
                  child: CustomPaint(
                    painter: StripePainter(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ),
              if (showDots)
                Positioned.fill(
                  child: CustomPaint(
                    painter: DotPatternPainter(
                      dotColor: Colors.black.withOpacity(0.05),
                      dotRadius: 1.0,
                      spacing: 6.0,
                    ),
                  ),
                ),
              if (showHighlight)
                Positioned(
                  top: 2,
                  left: 2,
                  right: 2,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class StereoscopicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color baseColor;
  final Color shadowColor;
  final double borderRadius;
  final double depth;
  final bool showStripes;
  final bool showDots;
  final bool showHighlight;

  const StereoscopicButton({
    super.key,
    required this.child,
    this.onPressed,
    required this.baseColor,
    required this.shadowColor,
    this.borderRadius = 22.0,
    this.depth = 6.0,
    this.showStripes = true,
    this.showDots = false,
    this.showHighlight = true,
  });

  @override
  State<StereoscopicButton> createState() => _StereoscopicButtonState();
}

class _StereoscopicButtonState extends State<StereoscopicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            },
      onTapCancel: widget.onPressed == null
          ? null
          : () => setState(() => _isPressed = false),
      child: StereoscopicWidget(
        baseColor: widget.onPressed == null ? Colors.grey : widget.baseColor,
        shadowColor: widget.onPressed == null
            ? Colors.grey.shade700
            : widget.shadowColor,
        borderRadius: widget.borderRadius,
        depth: widget.depth,
        isPressed: _isPressed,
        showStripes: widget.showStripes,
        showDots: widget.showDots,
        showHighlight: widget.showHighlight,
        child: widget.child,
      ),
    );
  }
}

class StereoscopicContainer extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color shadowColor;
  final double borderRadius;
  final double depth;
  final bool showStripes;
  final bool showDots;
  final bool showHighlight;

  const StereoscopicContainer({
    super.key,
    required this.child,
    required this.baseColor,
    required this.shadowColor,
    this.borderRadius = 8.0,
    this.depth = 4.0,
    this.showStripes = true,
    this.showDots = false,
    this.showHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    return StereoscopicWidget(
      baseColor: baseColor,
      shadowColor: shadowColor,
      borderRadius: borderRadius,
      depth: depth,
      isPressed: false,
      showStripes: showStripes,
      showDots: showDots,
      showHighlight: showHighlight,
      child: child,
    );
  }
}

class StripePainter extends CustomPainter {
  final Color color;
  StripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double step = 8.0;
    for (double i = -size.height; i < size.width; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 背景のドット柄を描画するペインター
class DotPatternPainter extends CustomPainter {
  final Color dotColor;
  final double dotRadius;
  final double spacing;

  DotPatternPainter({
    required this.dotColor,
    this.dotRadius = 1.5,
    this.spacing = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
