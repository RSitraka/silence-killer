import 'dart:math';

import 'package:flutter/material.dart';

import '../models/player.dart';
import '../theme.dart';

/// Toutes les illustrations sont dessinées à la main avec CustomPainter :
/// aucune image externe, aucun droit d'auteur.
///
/// Les deux icônes de rôle sont volontairement très différentes :
///   • CITOYEN  : forme RONDE, bleu ciel / vert, visage souriant + cœur ;
///   • ASSASSIN : forme d'ÉTOILE POINTUE, violet / rouge, ninja qui fait un clin d'œil.
/// Même sans distinguer les couleurs (daltonisme), la silhouette suffit.

/// Icône du rôle demandé.
class RoleIcon extends StatelessWidget {
  const RoleIcon({super.key, required this.role, this.size = 120});

  final Role role;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: role == Role.citizen ? 'Icône citoyen' : 'Icône assassin',
      child: CustomPaint(
        size: Size.square(size),
        painter: role == Role.citizen ? CitizenPainter() : AssassinPainter(),
      ),
    );
  }
}

/// Dessine un petit cœur centré sur [c], de largeur ~[w].
Path heartPath(Offset c, double w) {
  final x = c.dx, y = c.dy;
  return Path()
    ..moveTo(x, y + 0.38 * w)
    ..cubicTo(x - 0.95 * w, y - 0.2 * w, x - 0.4 * w, y - 0.85 * w, x, y - 0.28 * w)
    ..cubicTo(x + 0.4 * w, y - 0.85 * w, x + 0.95 * w, y - 0.2 * w, x, y + 0.38 * w)
    ..close();
}

/// CITOYEN : rond, bleu ciel / vert, souriant, avec un cœur.
class CitizenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final center = p(0.5, 0.5);

    // Disque de fond en dégradé bleu ciel → vert.
    final disc = Rect.fromCircle(center: center, radius: 0.47 * s);
    canvas.drawCircle(
      center,
      0.47 * s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.citizenBlue, AppColors.citizenGreen],
        ).createShader(disc),
    );
    canvas.drawCircle(
      center,
      0.47 * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.035 * s
        ..color = Colors.white,
    );

    // Visage rond.
    canvas.drawCircle(p(0.5, 0.52), 0.29 * s, Paint()..color = const Color(0xFFFFE8C4));
    // Petite mèche de cheveux.
    canvas.drawPath(
      Path()
        ..moveTo(0.42 * s, 0.26 * s)
        ..quadraticBezierTo(0.5 * s, 0.17 * s, 0.56 * s, 0.25 * s)
        ..quadraticBezierTo(0.5 * s, 0.22 * s, 0.47 * s, 0.28 * s)
        ..close(),
      Paint()..color = const Color(0xFF8B5A2B),
    );

    final ink = Paint()..color = AppColors.ink;
    // Deux yeux ouverts avec un reflet.
    for (final x in [0.40, 0.60]) {
      canvas.drawCircle(p(x, 0.48), 0.038 * s, ink);
      canvas.drawCircle(p(x + 0.012, 0.468), 0.012 * s, Paint()..color = Colors.white);
    }
    // Joues roses.
    final cheek = Paint()..color = const Color(0xFFFF9CB5).withValues(alpha: 0.8);
    canvas.drawOval(Rect.fromCenter(center: p(0.33, 0.58), width: 0.09 * s, height: 0.055 * s), cheek);
    canvas.drawOval(Rect.fromCenter(center: p(0.67, 0.58), width: 0.09 * s, height: 0.055 * s), cheek);
    // Grand sourire.
    canvas.drawArc(
      Rect.fromCenter(center: p(0.5, 0.56), width: 0.22 * s, height: 0.18 * s),
      0.15 * pi,
      0.7 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.035 * s
        ..color = AppColors.ink,
    );

    // Badge cœur en bas à droite.
    final badge = p(0.78, 0.78);
    canvas.drawCircle(badge, 0.15 * s, Paint()..color = Colors.white);
    canvas.drawCircle(badge, 0.12 * s, Paint()..color = AppColors.citizenGreen);
    canvas.drawPath(heartPath(badge.translate(0, 0.01 * s), 0.13 * s), Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ASSASSIN : étoile pointue violet / rouge, ninja rigolo qui fait un clin d'œil.
class AssassinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final center = p(0.5, 0.5);

    // Étoile à 8 branches pointues.
    const points = 8;
    final star = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = (i.isEven ? 0.49 : 0.36) * s;
      final a = -pi / 2 + i * pi / points;
      final pt = center + Offset(cos(a) * r, sin(a) * r);
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AssassinColors.lightPurple, AppColors.assassinPurple, AppColors.assassinRed],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 0.03 * s
        ..color = Colors.white,
    );

    // Tête de ninja (cagoule violet foncé).
    final headCenter = p(0.5, 0.52);
    final headRadius = 0.25 * s;
    // Rubans du bandeau qui flottent derrière la tête.
    final ribbon = Paint()..color = AssassinColors.band;
    canvas.drawPath(
      Path()
        ..moveTo(0.70 * s, 0.38 * s)
        ..quadraticBezierTo(0.82 * s, 0.30 * s, 0.90 * s, 0.24 * s)
        ..quadraticBezierTo(0.86 * s, 0.34 * s, 0.74 * s, 0.44 * s)
        ..close(),
      ribbon,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0.72 * s, 0.42 * s)
        ..quadraticBezierTo(0.86 * s, 0.42 * s, 0.93 * s, 0.38 * s)
        ..quadraticBezierTo(0.86 * s, 0.48 * s, 0.72 * s, 0.47 * s)
        ..close(),
      ribbon,
    );

    canvas.drawCircle(headCenter, headRadius, Paint()..color = AssassinColors.hood);

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: headCenter, radius: headRadius)));
    // Bandeau rouge sur le front.
    canvas.drawRect(Rect.fromLTRB(0, 0.36 * s, s, 0.41 * s), ribbon);
    canvas.restore();

    // Ouverture de la cagoule (où l'on voit les yeux).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p(0.5, 0.50), width: 0.40 * s, height: 0.13 * s),
        Radius.circular(0.065 * s),
      ),
      Paint()..color = const Color(0xFFFFE1C2),
    );

    // Œil gauche ouvert, avec sourcil malicieux.
    canvas.drawCircle(p(0.42, 0.50), 0.034 * s, Paint()..color = AppColors.ink);
    canvas.drawCircle(p(0.43, 0.49), 0.011 * s, Paint()..color = Colors.white);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.03 * s
      ..color = AppColors.ink;
    // Œil droit qui fait un CLIN D'ŒIL (arc fermé).
    canvas.drawPath(
      Path()
        ..moveTo(0.54 * s, 0.495 * s)
        ..quadraticBezierTo(0.585 * s, 0.535 * s, 0.63 * s, 0.495 * s),
      stroke,
    );
    // Petit sourire espiègle dessiné sur la cagoule.
    canvas.drawArc(
      Rect.fromCenter(center: p(0.52, 0.62), width: 0.14 * s, height: 0.08 * s),
      0.1 * pi,
      0.8 * pi,
      false,
      stroke..color = const Color(0xFFFFB3C7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AssassinColors {
  static const lightPurple = Color(0xFFA78BFA);
  static const hood = Color(0xFF2E1A55);
  static const band = Color(0xFFF43F5E);
}

/// Petit fantôme (joueur mort).
class GhostPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(0.12 * w, 0.92 * h)
      ..lineTo(0.12 * w, 0.45 * h)
      ..arcToPoint(Offset(0.88 * w, 0.45 * h), radius: Radius.circular(0.38 * w))
      ..lineTo(0.88 * w, 0.92 * h);
    // Bas ondulé.
    const waves = 3;
    final step = 0.76 * w / waves;
    for (var i = 0; i < waves; i++) {
      final x0 = 0.88 * w - i * step;
      body.quadraticBezierTo(x0 - step / 4, 0.78 * h, x0 - step / 2, 0.92 * h);
      body.quadraticBezierTo(x0 - 3 * step / 4, 1.04 * h, x0 - step, 0.92 * h);
    }
    body.close();

    canvas.drawShadow(body, Colors.black26, 2, false);
    canvas.drawPath(body, Paint()..color = Colors.white);
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05 * w
        ..color = const Color(0xFFD9D3E6),
    );
    final eye = Paint()..color = AppColors.ink;
    canvas.drawOval(Rect.fromCenter(center: Offset(0.38 * w, 0.45 * h), width: 0.12 * w, height: 0.17 * h), eye);
    canvas.drawOval(Rect.fromCenter(center: Offset(0.62 * w, 0.45 * h), width: 0.12 * w, height: 0.17 * h), eye);
    canvas.drawOval(Rect.fromCenter(center: Offset(0.5 * w, 0.64 * h), width: 0.1 * w, height: 0.1 * h), eye);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Avatar NEUTRE d'un joueur pendant la partie (ne révèle jamais le rôle).
/// Vivant : rond coloré et souriant. Mort : grisé, yeux en croix + fantôme.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.colorIndex, this.alive = true, this.size = 72});

  final int colorIndex;
  final bool alive;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _FacePainter(
              color: alive ? AppColors.avatar(colorIndex) : AppColors.dead,
              alive: alive,
            ),
          ),
          if (!alive)
            Positioned(
              right: -size * 0.12,
              top: -size * 0.14,
              child: CustomPaint(size: Size(size * 0.48, size * 0.52), painter: GhostPainter()),
            ),
        ],
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter({required this.color, required this.alive});

  final Color color;
  final bool alive;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    canvas.drawCircle(p(0.5, 0.5), 0.48 * s, Paint()..color = color);
    canvas.drawCircle(
      p(0.5, 0.5),
      0.48 * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.04 * s
        ..color = Colors.white,
    );
    final ink = alive ? AppColors.ink : const Color(0xFF6F6880);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.055 * s
      ..color = ink;

    if (alive) {
      canvas.drawCircle(p(0.36, 0.44), 0.055 * s, Paint()..color = ink);
      canvas.drawCircle(p(0.64, 0.44), 0.055 * s, Paint()..color = ink);
      final cheek = Paint()..color = Colors.white.withValues(alpha: 0.45);
      canvas.drawCircle(p(0.25, 0.58), 0.06 * s, cheek);
      canvas.drawCircle(p(0.75, 0.58), 0.06 * s, cheek);
      canvas.drawArc(
        Rect.fromCenter(center: p(0.5, 0.56), width: 0.34 * s, height: 0.26 * s),
        0.1 * pi,
        0.8 * pi,
        false,
        stroke,
      );
    } else {
      // Yeux en croix.
      for (final cx in [0.36, 0.64]) {
        const d = 0.06;
        canvas.drawLine(p(cx - d, 0.44 - d), p(cx + d, 0.44 + d), stroke);
        canvas.drawLine(p(cx + d, 0.44 - d), p(cx - d, 0.44 + d), stroke);
      }
      // Bouche ondulée.
      canvas.drawPath(
        Path()
          ..moveTo(0.34 * s, 0.68 * s)
          ..quadraticBezierTo(0.42 * s, 0.62 * s, 0.5 * s, 0.68 * s)
          ..quadraticBezierTo(0.58 * s, 0.74 * s, 0.66 * s, 0.68 * s),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) => old.color != color || old.alive != alive;
}
