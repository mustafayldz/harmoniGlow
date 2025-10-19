import 'dart:async';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/models/notes_model.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/screens/player/player_shared.dart';
import 'package:drumly/screens/songs/songs_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/countdown.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SongVisualizer extends StatefulWidget {
  const SongVisualizer({required this.song, super.key});
  final SongModel song;

  @override
  State<SongVisualizer> createState() => _SongVisualizerState();
}

class _SongVisualizerState extends State<SongVisualizer>
    with SingleTickerProviderStateMixin {
  late AppProvider appProvider;
  YoutubePlayerController? _youtubeController;

  int _elapsedMs = 0;
  bool isPlaying = false;
  bool isPaused = false;
  bool hasStarted = false; // UI değişikliği için
  double playerSpeed = 1.0;
  static const int baseLedDuration = 100;
  static const int preDropMs = 5000; // Damla 5 saniye önce düşmeye başlar

  List<Color> _colors = [];
  final Map<int, HitGlow> activeHits = {};
  final Set<int> sentNoteIndices = {};

  bool showSpeedText = false;
  Timer? _speedTextTimer;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    appProvider = Provider.of<AppProvider>(context, listen: false);
    _loadDrumColors();

    // 🎵 YouTube player başlat (ama otomatik başlatma)
    if (widget.song.fileUrl != null && widget.song.fileUrl!.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(widget.song.fileUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            hideControls: true,
            disableDragSeek: true,
          ),
        );
      }
    }

    // 🐛 Debug: Nota bilgilerini yazdır
    print('🎵 Song: ${widget.song.title}');
    print('📝 Total notes: ${widget.song.notes?.length ?? 0}');
    if (widget.song.notes != null && widget.song.notes!.isNotEmpty) {
      final firstNote = widget.song.notes!.first;
      print(
        '📍 First note: i=${firstNote.i}, sM=${firstNote.sM}, led=${firstNote.led}',
      );
      if (widget.song.notes!.length > 1) {
        final secondNote = widget.song.notes![1];
        print(
          '📍 Second note: i=${secondNote.i}, sM=${secondNote.sM}, led=${secondNote.led}',
        );
      }
    }

    // Timer'ı başlatma, sadece play'e basıldığında başlatacağız
  }

  Future<void> _loadDrumColors() async {
    final List<Color> loaded = [];
    for (int i = 1; i <= 9; i++) {
      final drum = await StorageService.getDrumPart(i.toString());
      if (drum?.rgb != null && drum!.rgb!.length >= 3) {
        loaded.add(Color.fromRGBO(drum.rgb![0], drum.rgb![1], drum.rgb![2], 1));
      } else {
        loaded.add(_defaultColor(i));
      }
    }
    if (mounted) setState(() => _colors = loaded);
  }

  Color _defaultColor(int i) {
    const defaults = [
      Color.fromRGBO(220, 0, 0, 1),
      Color.fromRGBO(208, 151, 154, 1),
      Color.fromRGBO(255, 125, 0, 1),
      Color.fromRGBO(7, 219, 2, 1),
      Color.fromRGBO(0, 212, 154, 1),
      Color.fromRGBO(21, 25, 207, 1),
      Color.fromRGBO(235, 0, 255, 1),
      Color.fromRGBO(242, 255, 0, 1),
      Colors.white,
    ];
    return defaults[(i - 1).clamp(0, defaults.length - 1)];
  }

  /// 🎵 Play / Pause davranışı
  Future<void> _togglePlay(BluetoothBloc bloc) async {
    if (isPlaying) {
      // Pause moduna geç
      setState(() {
        isPlaying = false;
        isPaused = true;
      });
      _timer?.cancel();
      _youtubeController?.pause();
      await SendData().sendHexData(bloc, [0]); // LED'leri kapat
      return;
    }

    // İlk başlatma: UI'yi değiştir, sonra countdown göster
    if (!hasStarted) {
      // UI'yi hemen değiştir (drum resmi gelsin)
      setState(() {
        hasStarted = true;
        _elapsedMs =
            -5000; // 5 saniye önceden başlat (countdown sırasında damlalar düşsün)
      });

      // Timer'ı countdown SIRASINDA başlat (damlalar düşmeye başlasın)
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!mounted) return;

        setState(() {
          _elapsedMs += (16 * playerSpeed).round();
        });

        // Countdown bitene kadar bekle, YouTube'u başlatma
        if (_elapsedMs >= 0 && !isPlaying) {
          // Countdown bitti, artık çalmaya hazır
          return;
        }
      });

      // Yeni UI'da countdown göster (5 saniye)
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Countdown(),
      );

      // Countdown bitti, zamanlayıcıyı 0'a ayarla
      setState(() {
        _elapsedMs = 0;
      });
    }

    // Devam et
    setState(() {
      isPlaying = true;
      isPaused = false;
    });

    // YouTube player'ı başlat
    _youtubeController?.play();

    // Timer'ı yeniden başlat - YouTube player ile senkronize
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isPlaying) return;

      // YouTube player'dan gerçek zamanı al (daha doğru senkronizasyon)
      if (_youtubeController != null && _youtubeController!.value.isPlaying) {
        _elapsedMs = _youtubeController!.value.position.inMilliseconds;
      } else {
        // YouTube player yoksa manuel sayaç
        _elapsedMs += (16 * playerSpeed).round();
      }

      setState(() {});
      _handleHitsAtCurrentTime(bloc);
    });
  }

  Future<void> _onSpeedChange(double delta, BluetoothBloc bloc) async {
    playerSpeed = (playerSpeed + delta).clamp(0.5, 1.5);
    final int ledDuration = (baseLedDuration / playerSpeed).round();
    await SendData().sendHexData(bloc, splitToBytes(ledDuration));
    _youtubeController?.setPlaybackRate(playerSpeed);

    setState(() => showSpeedText = true);
    _speedTextTimer?.cancel();
    _speedTextTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => showSpeedText = false);
    });
  }

  Future<void> _handleHitsAtCurrentTime(BluetoothBloc bloc) async {
    final now = _elapsedMs;
    for (final note in widget.song.notes ?? <NoteModel>[]) {
      if (now >= note.sM && !sentNoteIndices.contains(note.i)) {
        final List<int> payload = [];
        for (final drumPart in note.led) {
          if (drumPart < 1 || drumPart > 9) continue;
          final drum = await StorageService.getDrumPart(drumPart.toString());
          if (drum?.led == null || drum?.rgb == null) continue;
          payload.addAll([drum!.led!, ...drum.rgb!]);
          final color = _colors[(drumPart - 1).clamp(0, _colors.length - 1)];
          activeHits[drumPart] = HitGlow(color: color, untilMs: now + 180);
        }
        if (payload.isNotEmpty) await SendData().sendHexData(bloc, payload);
        sentNoteIndices.add(note.i);
      }
    }
    activeHits.removeWhere((_, glow) => glow.untilMs <= now);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speedTextTimer?.cancel();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    final size = MediaQuery.of(context).size;
    final isDark = appProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🎧 Görünmeyen YouTube Player
          if (_youtubeController != null)
            SizedBox(
              width: 1,
              height: 1,
              child: YoutubePlayer(controller: _youtubeController!),
            ),

          // 🎬 İlk ekran: Sadece animasyon
          if (!hasStarted)
            Center(
              child: Lottie.asset(
                'assets/animation/drummer.json',
                fit: BoxFit.fitWidth,
              ),
            ),

          // 🎬 İlk ekran: Ortada büyük play butonu
          if (!hasStarted)
            Center(
              child: GestureDetector(
                onTap: () => _togglePlay(bluetoothBloc),
                child: Container(
                  width: size.width / 4,
                  height: size.width / 4,
                  decoration: BoxDecoration(
                    color:
                        (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: size.width / 8,
                    color:
                        (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                  ),
                ),
              ),
            ),

          // 🥁 Oyun ekranı: Drum görseli
          if (hasStarted)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/newDrum.png',
                fit: BoxFit.fitWidth,
              ),
            ),

          // 💧 Oyun ekranı: Düşen damlalar
          if (hasStarted)
            CustomPaint(
              painter: SongFlowPainter(
                notes: widget.song.notes ?? [],
                elapsedMs: _elapsedMs,
                preDropMs: preDropMs,
                colors: _colors,
                screenSize: size,
                activeHits: activeHits,
              ),
              child: const SizedBox.expand(),
            ),

          // 🏃 Speed indicator
          if (showSpeedText && hasStarted)
            Positioned(
              bottom: size.height * 0.35,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Speed: ${playerSpeed.toStringAsFixed(2)}x',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

          // 🎮 Oyun ekranı: Control butonları
          if (hasStarted)
            Positioned(
              bottom: size.height * 0.10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  controlButton(
                    imagePath: 'assets/images/icons/turtle.png',
                    onPressed: () => _onSpeedChange(-0.25, bluetoothBloc),
                  ),
                  controlButton(
                    icon: isPlaying ? Icons.pause : Icons.play_arrow,
                    onPressed: () => _togglePlay(bluetoothBloc),
                    iconSize: 52,
                  ),
                  controlButton(
                    imagePath: 'assets/images/icons/rabbit.png',
                    onPressed: () => _onSpeedChange(0.25, bluetoothBloc),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SongFlowPainter extends CustomPainter {
  SongFlowPainter({
    required this.notes,
    required this.elapsedMs,
    required this.preDropMs,
    required this.colors,
    required this.screenSize,
    required this.activeHits,
  });
  final List<NoteModel> notes;
  final int elapsedMs;
  final int preDropMs;
  final List<Color> colors;
  final Size screenSize;
  final Map<int, HitGlow> activeHits;

  Map<int, Offset> get targetPos => {
        1: _px(0.10, 0.78), // Hi-Hat - Sol
        2: _px(0.20, 0.73), // Crash - Sol
        3: _px(0.80, 0.70), // Ride - Sağ
        4: _px(0.45, 0.85), // Snare - Orta
        5: _px(0.55, 0.68), // Tom 1 - Orta-Sağ
        6: _px(0.65, 0.72), // Tom 2 - Sağ
        7: _px(0.75, 0.80), // Floor Tom - Sağ
        8: _px(0.50, 0.93), // Kick - Orta-Alt
        9: _px(0.90, 0.88), // Extra - En Sağ
      };

  Offset _px(double rx, double ry) =>
      Offset(screenSize.width * rx, screenSize.height * ry);

  @override
  void paint(Canvas canvas, Size size) {
    final startY = size.height * 0.08; // Damlaların başlangıç Y pozisyonu (üst)
    final dropWidth = size.width * 0.05;
    const dropHeight = 56.0;

    // 💧 Sadece aktif damlaları çiz (performans için)
    // Zaman aralığını daralt: mevcut zamandan 5 saniye önce başlayan ve henüz çarpmamış notalar
    final int timeWindowStart = elapsedMs - 500; // 500ms tolerans
    final int timeWindowEnd =
        elapsedMs + preDropMs; // İleride görünecek notalar

    for (final note in notes) {
      final int dropStartMs = note.sM - preDropMs;
      final int dropEndMs = note.sM;

      // Performans optimizasyonu: zaman penceresi dışındaki notaları atla
      if (note.sM < timeWindowStart || note.sM > timeWindowEnd) continue;

      // Henüz düşme zamanı gelmedi veya çoktan çarptı mı?
      if (elapsedMs < dropStartMs || elapsedMs > dropEndMs) continue;

      // 🎨 İlerleme hesaplama: 0.0 (başlangıç/üst) → 1.0 (hedef/drum)
      // Negatif zamanları da handle ediyoruz
      final double progress =
          ((elapsedMs - dropStartMs) / preDropMs).clamp(0.0, 1.0);

      // 🎵 Bu notanın LED listesindeki HER ELEMAN için ayrı damla çiz
      // Örnek: note.led = [4, 8] → 2 damla çizilecek (yeşil ve sarı)
      for (final led in note.led) {
        // LED numarasını kontrol et (1-9 arası olmalı)
        if (led < 1 || led > 9) continue;

        // LED numarasına göre hedef pozisyonu al
        final pos = targetPos[led];
        if (pos == null) continue;

        // 🎨 LED numarasına göre renk al
        // led = 1 → colors[0], led = 2 → colors[1], ... led = 9 → colors[8]
        final colorIndex = (led - 1).clamp(0, colors.length - 1);
        final color = colors.isNotEmpty && colorIndex < colors.length
            ? colors[colorIndex]
            : Colors.white; // Fallback renk

        // 📍 Damlanın şu anki pozisyonunu hesapla
        final double x = pos.dx; // X sabit (yatay hareket yok)
        final double y = startY + progress * (pos.dy - startY); // Y üstten alta

        // 🎨 Damla şeklini çiz (yuvarlatılmış dikdörtgen)
        final rect = Rect.fromLTWH(
          x - dropWidth / 2,
          y - dropHeight / 2,
          dropWidth,
          dropHeight,
        );
        final paint = Paint()
          ..shader = LinearGradient(
            colors: [
              color.withOpacity(0.0), // Üst kısım şeffaf
              color.withOpacity(0.95), // Alt kısım opak
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(rect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          paint,
        );
      }
    }

    // 🎇 HitGlow (vurma efekti) - drum'a çarpma anında parlama
    for (final entry in activeHits.entries) {
      final pos = targetPos[entry.key];
      if (pos == null) continue;
      final glow = entry.value;

      // İki katmanlı parlama efekti
      for (int i = 0; i < 2; i++) {
        final radius = (i == 0) ? 36.0 : 68.0;
        final alpha = (i == 0) ? 0.35 : 0.18;
        final p = Paint()
          ..color = glow.color.withOpacity(alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(pos, radius, p);
      }

      // Merkez parlak nokta
      final centerPaint = Paint()..color = glow.color.withOpacity(0.9);
      canvas.drawCircle(pos, 16, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SongFlowPainter oldDelegate) =>
      oldDelegate.elapsedMs != elapsedMs ||
      oldDelegate.activeHits.length != activeHits.length;
}

class HitGlow {
  HitGlow({required this.color, required this.untilMs});
  final Color color;
  final int untilMs;
}
