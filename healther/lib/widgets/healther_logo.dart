import 'package:flutter/material.dart';

class HealtherLogo extends StatefulWidget {
  final double? size;
  final bool animate;
  final Color? color;
  
  const HealtherLogo({
    super.key,
    this.size,
    this.animate = true,
    this.color,
  });

  @override
  State<HealtherLogo> createState() => _HealtherLogoState();
}

class _HealtherLogoState extends State<HealtherLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _rotateAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 200.0;
    // Utiliser une couleur par défaut si pas fournie, sans dépendre du Theme
    final color = widget.color ?? Colors.blue;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: widget.animate ? _fadeAnimation.value : 1.0,
          child: Transform.scale(
            scale: widget.animate ? _scaleAnimation.value : 1.0,
            child: Transform.rotate(
              angle: widget.animate ? _rotateAnimation.value : 0.0,
              child: CustomPaint(
                size: Size(size, size),
                painter: HealtherLogoPainter(color: color),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HealtherLogoPainter extends CustomPainter {
  final Color color;

  HealtherLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      fontSize: size.height * 0.35, // Plus grand pour Italianno (cursive)
      fontWeight: FontWeight.normal, // Italianno n'a pas de bold, utiliser normal
      color: color,
      fontFamily: 'Italianno',
      fontFamilyFallback: ['serif'], // Fallback si Italianno n'est pas disponible
      letterSpacing: 1,
      shadows: [
        Shadow(
          color: color.withOpacity(0.5),
          blurRadius: 10,
          offset: const Offset(2, 2),
        ),
      ],
    );

    // Dessiner le texte "HEALTHER" avec effet Italianno
    _drawItaliannoText(canvas, size, textStyle, paint);
    
    // Ajouter des effets décoratifs
    _drawDecorativeElements(canvas, size, paint);
  }

  void _drawItaliannoText(Canvas canvas, Size size, TextStyle textStyle, Paint paint) {
    final textSpan = TextSpan(
      text: 'HEALTHER',
      style: textStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final x = (size.width - textPainter.width) / 2;
    final y = (size.height - textPainter.height) / 2;
    
    // Dessiner plusieurs couches pour l'effet Italianno
    final layers = [
      color.withOpacity(0.3),
      color.withOpacity(0.6),
      color,
    ];
    
    for (var i = 0; i < layers.length; i++) {
      final layerTextSpan = TextSpan(
        text: 'HEALTHER',
        style: textStyle.copyWith(
          color: layers[i],
          fontSize: (textStyle.fontSize ?? size.height * 0.35) + (i * 2),
        ),
      );
      
      final layerPainter = TextPainter(
        text: layerTextSpan,
        textDirection: TextDirection.ltr,
      );
      
      layerPainter.layout();
      
      canvas.save();
      canvas.translate(
        x + (i * 1.5),
        y + (i * 1.5),
      );
      layerPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
    
    // Dessiner le texte principal
    canvas.save();
    canvas.translate(x, y);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawDecorativeElements(Canvas canvas, Size size, Paint paint) {
    // Dessiner des croix médicales décoratives
    final crossSize = size.width * 0.08;
    final crossPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Croix en haut à gauche
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.1 + crossSize, size.height * 0.1 + crossSize),
      crossPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.1 + crossSize, size.height * 0.1),
      Offset(size.width * 0.1, size.height * 0.1 + crossSize),
      crossPaint,
    );

    // Croix en bas à droite
    canvas.drawLine(
      Offset(size.width * 0.9 - crossSize, size.height * 0.9 - crossSize),
      Offset(size.width * 0.9, size.height * 0.9),
      crossPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.9, size.height * 0.9 - crossSize),
      Offset(size.width * 0.9 - crossSize, size.height * 0.9),
      crossPaint,
    );

    // Dessiner des cercles décoratifs
    final circlePaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.2),
      size.width * 0.03,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.8),
      size.width * 0.03,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget animé pour le titre HEALTHER avec effet d'écriture
class HealtherAnimatedTitle extends StatefulWidget {
  final double fontSize;
  final Color? color;
  final bool showSubtitle;
  
  const HealtherAnimatedTitle({
    super.key,
    this.fontSize = 48,
    this.color,
    this.showSubtitle = true,
  });

  @override
  State<HealtherAnimatedTitle> createState() => _HealtherAnimatedTitleState();
}

class _HealtherAnimatedTitleState extends State<HealtherAnimatedTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _letterAnimations;
  final String _text = 'HEALTHER';
  final String _subtitle = 'Health & Diagnosis';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Animation pour chaque lettre
    _letterAnimations = List.generate(
      _text.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index / _text.length,
            (index / _text.length) + 0.2,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser une couleur par défaut si pas fournie
    final color = widget.color ?? Colors.blue;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _text.length,
            (index) {
              if (index >= _text.length || index >= _letterAnimations.length) {
                return const SizedBox.shrink();
              }
              return AnimatedBuilder(
                animation: _letterAnimations[index],
                builder: (context, child) {
                  final opacity = _letterAnimations[index].value;
                  final offset = (1 - opacity) * 20;
                  
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: Opacity(
                      opacity: opacity,
                      child: Text(
                        index < _text.length ? _text[index] : '',
                      style: TextStyle(
                        fontSize: widget.fontSize * 1.3, // Plus grand pour Italianno (cursive)
                        fontWeight: FontWeight.normal, // Italianno n'a pas de bold
                        color: color,
                        fontFamily: 'Italianno',
                        fontFamilyFallback: ['serif'], // Fallback si Italianno n'est pas disponible
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                          Shadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(4, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              );
            },
          ),
        ),
        if (widget.showSubtitle)
          AnimatedOpacity(
            opacity: _controller.value > 0.7 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _subtitle,
                style: TextStyle(
                  fontSize: widget.fontSize * 0.3,
                  color: color.withOpacity(0.7),
                  letterSpacing: 2,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
