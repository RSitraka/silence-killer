import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sound_service.dart';
import '../theme.dart';

/// Gros bouton arrondi façon « bonbon », qui s'enfonce quand on appuie.
class BigButton extends StatefulWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.pink,
    this.textColor = Colors.white,
    this.emoji,
    this.fontSize = 24,
    this.sound = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final String? emoji;
  final double fontSize;

  /// Joue le petit « pop » à l'appui.
  final bool sound;

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final color = _enabled ? widget.color : AppColors.dead;
    final shadow = Color.lerp(color, Colors.black, 0.22)!;
    const depth = 6.0;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: _enabled
            ? () {
                if (widget.sound) context.read<SoundService>().play(Sfx.tap);
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          margin: EdgeInsets.only(top: _pressed ? depth : 0, bottom: _pressed ? 0 : depth),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: shadow, offset: Offset(0, _pressed ? 0 : depth)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.emoji != null) ...[
                Text(widget.emoji!, style: TextStyle(fontSize: widget.fontSize + 2)),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w700,
                    color: widget.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fait apparaître son enfant avec un petit rebond élastique.
class BounceIn extends StatelessWidget {
  const BounceIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900) + delay,
      curve: Interval(
        delay.inMilliseconds / (900 + delay.inMilliseconds),
        1,
        curve: Curves.elasticOut,
      ),
      builder: (context, t, child) => Transform.scale(scale: 0.4 + 0.6 * t, child: Opacity(opacity: t.clamp(0.0, 1.0).toDouble(), child: child)),
      child: child,
    );
  }
}

/// Fait doucement flotter / se dandiner son enfant en boucle.
class Wiggle extends StatefulWidget {
  const Wiggle({super.key, required this.child, this.angle = 0.06, this.offset = 6, this.phase = 0});

  final Widget child;
  final double angle;
  final double offset;
  final double phase;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value * 2 * pi + widget.phase;
        return Transform.translate(
          offset: Offset(0, sin(t) * widget.offset),
          child: Transform.rotate(angle: sin(t + pi / 2) * widget.angle, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Bouton rond pour couper / remettre le son.
class MuteButton extends StatelessWidget {
  const MuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final sounds = context.watch<SoundService>();
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: IconButton(
          tooltip: sounds.muted ? 'Activer le son' : 'Couper le son',
          icon: Icon(
            sounds.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: AppColors.ink,
          ),
          onPressed: sounds.toggleMute,
        ),
      ),
    );
  }
}

/// Carte blanche très arrondie.
class RoundCard extends StatelessWidget {
  const RoundCard({super.key, required this.child, this.color = Colors.white, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: child,
    );
  }
}

/// Sélecteur « − nombre + » avec gros boutons ronds.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.color = AppColors.lavender,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget roundButton(IconData icon, String tooltip, VoidCallback? onTap) => Material(
          color: onTap == null ? AppColors.dead : color,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: tooltip,
            iconSize: 32,
            color: Colors.white,
            icon: Icon(icon),
            onPressed: onTap == null
                ? null
                : () {
                    context.read<SoundService>().play(Sfx.tap);
                    onTap();
                  },
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        roundButton(Icons.remove_rounded, 'Moins', value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 90,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text(
              '$value',
              key: ValueKey(value),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        roundButton(Icons.add_rounded, 'Plus', value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

/// Pluie de confettis infinie (dessinée à la main).
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.count = 90});

  final int count;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final r = Random();
    const colors = [
      AppColors.pink,
      AppColors.yellow,
      AppColors.mint,
      AppColors.sky,
      AppColors.lavender,
      AppColors.peach,
      AppColors.coral,
    ];
    _particles = List.generate(
      widget.count,
      (_) => _Particle(
        x: r.nextDouble(),
        phase: r.nextDouble(),
        speed: 0.6 + r.nextDouble() * 0.8,
        sway: 10 + r.nextDouble() * 25,
        spin: (r.nextDouble() - 0.5) * 12,
        size: 7 + r.nextDouble() * 8,
        color: colors[r.nextInt(colors.length)],
        round: r.nextBool(),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _c),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.phase,
    required this.speed,
    required this.sway,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });

  final double x, phase, speed, sway, spin, size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.animation) : super(repaint: animation);

  final List<_Particle> particles;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    for (final p in particles) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final y = progress * (size.height + 40) - 20;
      final x = p.x * size.width + sin((progress + p.phase) * 2 * pi * 2) * p.sway;
      final paint = Paint()..color = p.color;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.spin);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2.4, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => false;
}

/// Boîte de dialogue « Quitter la partie ? ». Renvoie `true` si confirmé.
Future<bool> confirmQuit(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Quitter la partie ?', textAlign: TextAlign.center),
      content: const Text(
        'La partie en cours sera perdue.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Rester', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Quitter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return result ?? false;
}
