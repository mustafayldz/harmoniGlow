import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// ParticleSystem - Hit efektleri için particle sistemi.
class HitParticle extends PositionComponent {

  HitParticle({
    required super.position,
    required this.color,
    required this.velocity,
  }) : super(size: Vector2.all(8));
  final ui.Color color;
  final Vector2 velocity;
  double lifetime = 1.0;
  double opacity = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Hareket
    position.add(velocity * dt);
    
    // Yerçekimi
    velocity.y += 300 * dt;
    
    // Yaşam süresi
    lifetime -= dt;
    opacity = (lifetime / 1.0).clamp(0.0, 1.0);
    
    // Ölü particle'ı kaldır
    if (lifetime <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(
      const ui.Offset(4, 4),
      4,
      paint,
    );
  }
}

/// ParticleEmitter - Particle'ları üreten sistem.
class ParticleEmitter extends Component {

  ParticleEmitter({
    required this.emitPosition,
    required this.color,
    this.particleCount = 15,
  });
  final Vector2 emitPosition;
  final ui.Color color;
  final int particleCount;
  final math.Random _random = math.Random();

  @override
  void onMount() {
    super.onMount();
    emit();
  }

  void emit() {
    for (var i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 100 + _random.nextDouble() * 200;
      
      final particle = HitParticle(
        position: emitPosition.clone(),
        color: color,
        velocity: Vector2(
          math.cos(angle) * speed,
          math.sin(angle) * speed - 100, // Yukarı doğru bias
        ),
      );
      
      parent?.add(particle);
    }
    
    // Emitter'ı kaldır (tek seferlik)
    Future.delayed(const Duration(seconds: 2), () {
      removeFromParent();
    });
  }
}

/// ComboTrail - Combo artarken arka planda akan trail efekti.
class ComboTrail extends PositionComponent {

  ComboTrail({required this.screenWidth})
      : super(
          position: Vector2.zero(),
          size: Vector2(screenWidth, 10),
        );
  final double screenWidth;
  double _phase = 0.0;
  int _combo = 0;

  void setCombo(int combo) {
    _combo = combo;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_combo > 10) {
      _phase += dt * 2.0;
      if (_phase > 1.0) _phase -= 1.0;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (_combo <= 10) return;

    final opacity = ((_combo - 10) / 100).clamp(0.0, 0.5);
    
    for (var i = 0; i < 3; i++) {
      final offset = (_phase + i * 0.33) % 1.0;
      final x = offset * size.x;
      
      final gradient = ui.Gradient.radial(
        ui.Offset(x, 5),
        50,
        [
          ui.Color.fromARGB((255 * opacity).toInt(), 255, 215, 0),
          const ui.Color.fromARGB(0, 255, 215, 0),
        ],
      );
      
      final paint = Paint()..shader = gradient;
      canvas.drawCircle(ui.Offset(x, 5), 50, paint);
    }
  }
}

/// RippleEffect - Dokunma feedback'i için dalga efekti.
class RippleEffect extends PositionComponent {

  RippleEffect({
    required super.position,
    required this.color,
    double maxRadius = 100,
  }) : _maxRadius = maxRadius;
  final ui.Color color;
  double _radius = 0;
  final double _maxRadius;
  double _opacity = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    
    _radius += dt * 300; // 300 px/s genişleme
    _opacity = 1.0 - (_radius / _maxRadius);
    
    if (_radius >= _maxRadius) {
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final paint = Paint()
      ..color = color.withValues(alpha: _opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(
      const ui.Offset(0, 0),
      _radius,
      paint,
    );
  }
}

/// StarBurst - Perfect hit için yıldız patlaması.
class StarBurst extends PositionComponent {

  StarBurst({
    required super.position,
    required this.color,
  }) : super(size: Vector2.all(100));
  final ui.Color color;
  double _scale = 0.0;
  double _rotation = 0.0;
  double _opacity = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    
    _scale += dt * 3.0;
    _rotation += dt * 5.0;
    _opacity = math.max(0, 1.0 - _scale / 2.0);
    
    if (_opacity <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    canvas.save();
    canvas.translate(50, 50);
    canvas.rotate(_rotation);
    canvas.scale(_scale);
    
    final paint = Paint()
      ..color = color.withValues(alpha: _opacity)
      ..style = PaintingStyle.fill;
    
    // Çiz 8 köşeli yıldız
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final radius = i.isEven ? 20.0 : 10.0;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}
