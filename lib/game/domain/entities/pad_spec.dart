/// ============================================================================
/// PAD SPEC ENTITY - Daire bazlı pad (vuruş bölgesi) tanımı
/// ============================================================================
///
/// Her pad, drum kit üzerindeki bir enstrümanı temsil eden daire şeklindedir.
/// Normalized koordinatlar kullanılarak farklı ekran boyutlarına uyum sağlar.
///
/// ## Koordinat Sistemi
///
/// ```
/// normCx, normCy: 0.0 - 1.0 arası normalized değerler
/// normCx: Ekran genişliğine göre (0 = sol, 1 = sağ)
/// normCy: Drum kit yüksekliğine göre (0 = üst, 1 = alt)
/// normR: min(screenWidth, drumKitHeight) ile orantılı yarıçap
/// ```
///
/// ## Örnek Kullanım
///
/// ```dart
/// final pad = PadSpec(lane: 0, normCx: 0.5, normCy: 0.5, normR: 0.1);
/// pad.updateWorldCoords(screenWidth: 400, drumKitY: 600, drumKitHeight: 200);
///
/// if (pad.containsPoint(tapX, tapY)) {
///   // Tap bu pad'in içinde!
/// }
/// ```
/// ============================================================================
class PadSpec {
  /// Yeni bir pad tanımı oluşturur.
  ///
  /// [lane] Bu pad'in hangi enstrümana ait olduğu (0-7).
  /// [normCx] Normalized x merkez koordinatı (0.0-1.0).
  /// [normCy] Normalized y merkez koordinatı, drum kit içinde (0.0-1.0).
  /// [normR] Normalized yarıçap.
  PadSpec({
    required this.lane,
    required this.normCx,
    required this.normCy,
    required this.normR,
  });

  /// Bu pad'in ait olduğu lane (enstrüman) numarası.
  ///
  /// | Lane | Enstrüman    |
  /// |------|--------------|
  /// | 0    | Close Hi-Hat |
  /// | 1    | Open Hi-Hat  |
  /// | 2    | Crash        |
  /// | 3    | Ride         |
  /// | 4    | Snare        |
  /// | 5    | Kick         |
  /// | 6    | Tom 1        |
  /// | 7    | Floor Tom    |
  final int lane;

  /// Normalized x merkez koordinatı (0.0 = sol kenar, 1.0 = sağ kenar).
  final double normCx;

  /// Normalized y merkez koordinatı, drum kit alanı içinde.
  ///
  /// 0.0 = drum kit'in üst kenarı, 1.0 = drum kit'in alt kenarı.
  /// Bu değer ekranın tamamına değil, sadece drum kit bölgesine göredir.
  final double normCy;

  /// Normalized yarıçap.
  ///
  /// Gerçek yarıçap = normR * min(screenWidth, drumKitHeight)
  /// Bu sayede hem yatay hem dikey boyuta göre orantılı kalır.
  final double normR;

  // ===========================================================================
  // WORLD KOORDİNATLARI (piksel cinsinden, hesaplanmış)
  // ===========================================================================

  /// Hesaplanmış x merkez koordinatı (piksel).
  double cx = 0;

  /// Hesaplanmış y merkez koordinatı (piksel).
  double cy = 0;

  /// Hesaplanmış yarıçap (piksel).
  double r = 0;

  /// Ekran boyutuna göre world koordinatlarını günceller.
  ///
  /// Bu metod her ekran boyutu değişikliğinde (onGameResize) çağrılmalıdır.
  ///
  /// [screenWidth] Ekranın toplam genişliği (piksel).
  /// [drumKitY] Drum kit'in ekrandaki y başlangıç pozisyonu (piksel).
  /// [drumKitHeight] Drum kit'in yüksekliği (piksel).
  void updateWorldCoords(
      double screenWidth, double drumKitY, double drumKitHeight,) {
    // X koordinatı: ekran genişliğine göre
    cx = normCx * screenWidth;

    // Y koordinatı: drum kit alanı içinde
    cy = drumKitY + normCy * drumKitHeight;

    // Yarıçap: SongV2 kit ölçüsüyle uyumlu (screenWidth tabanlı)
    r = normR * screenWidth;
  }

  /// Verilen noktanın bu pad'in içinde olup olmadığını kontrol eder.
  ///
  /// Daire içi kontrolü için Pisagor teoremi kullanılır:
  /// ```
  /// dx² + dy² <= r² ise nokta daire içinde
  /// ```
  ///
  /// [px] Kontrol edilecek noktanın x koordinatı (piksel).
  /// [py] Kontrol edilecek noktanın y koordinatı (piksel).
  ///
  /// Returns: Nokta dairenin içindeyse `true`, değilse `false`.
  bool containsPoint(double px, double py) {
    final dx = px - cx;
    final dy = py - cy;
    // Karekök almadan karşılaştırma (performans için)
    return dx * dx + dy * dy <= r * r;
  }

  @override
  String toString() => 'PadSpec(lane: $lane, center: ($cx, $cy), r: $r)';
}
