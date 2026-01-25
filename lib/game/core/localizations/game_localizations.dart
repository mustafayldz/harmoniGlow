/// ============================================================================
/// GAME LOCALIZATIONS - Oyun metinleri için yerelleştirme sınıfı
/// ============================================================================
///
/// Bu sınıf, oyun içi tüm metinleri tutar ve çok dilli destek sağlar.
/// FlameGame BuildContext'e erişemediği için, metinler bu sınıf aracılığıyla
/// oyun instance'ına aktarılır.
///
/// ## Kullanım
///
/// ```dart
/// final localizations = GameLocalizations.fromContext(context);
/// final game = DrumHeroGame(localizations: localizations);
/// ```
/// ============================================================================
class GameLocalizations {
  /// Oyun metinlerini oluşturur.
  const GameLocalizations({
    required this.score,
    required this.gameOver,
    required this.highestCombo,
    required this.record,
    required this.legendary,
    required this.great,
    required this.good,
    required this.tryAgain,
    required this.playAgain,
    required this.mainMenu,
    required this.drumlyGame,
    required this.catchTheBeat,
    required this.highest,
    required this.start,
    required this.difficultyLevel,
    required this.easy,
    required this.medium,
    required this.hard,
    required this.howToPlay,
    required this.exitGame,
    required this.combo,
    required this.miss,
    required this.fever,
    required this.shieldReady,
  });

  /// BuildContext'ten yerelleştirilmiş metinleri oluşturur.
  factory GameLocalizations.fromMap(Map<String, String> texts) => GameLocalizations(
      score: texts['score'] ?? 'Score:',
      gameOver: texts['gameOver'] ?? 'GAME OVER!',
      highestCombo: texts['highestCombo'] ?? 'Highest Combo:',
      record: texts['record'] ?? '🏆 Record:',
      legendary: texts['legendary'] ?? '🏆 LEGENDARY!',
      great: texts['great'] ?? '⭐ GREAT!',
      good: texts['good'] ?? '👍 GOOD!',
      tryAgain: texts['tryAgain'] ?? '💪 Try Again!',
      playAgain: texts['playAgain'] ?? '🔄  PLAY AGAIN',
      mainMenu: texts['mainMenu'] ?? '🏠  MAIN MENU',
      drumlyGame: texts['drumlyGame'] ?? 'DRUMLY GAME',
      catchTheBeat: texts['catchTheBeat'] ?? 'Catch the Beat!',
      highest: texts['highest'] ?? '🏆 Highest:',
      start: texts['start'] ?? '▶  START',
      difficultyLevel: texts['difficultyLevel'] ?? 'Difficulty Level',
      easy: texts['easy'] ?? 'EASY',
      medium: texts['medium'] ?? 'MEDIUM',
      hard: texts['hard'] ?? 'HARD',
      howToPlay: texts['howToPlay'] ?? '🎵 Tap the circles when notes fall!',
      exitGame: texts['exitGame'] ?? '✕  EXIT GAME',
      combo: texts['combo'] ?? 'Combo:',
      miss: texts['miss'] ?? 'MISS!',
      fever: texts['fever'] ?? '🔥 FEVER x2!',
      shieldReady: texts['shieldReady'] ?? '🛡️ SHIELD READY',
    );

  // Oyun metinleri
  final String score;
  final String gameOver;
  final String highestCombo;
  final String record;
  final String legendary;
  final String great;
  final String good;
  final String tryAgain;
  final String playAgain;
  final String mainMenu;
  final String drumlyGame;
  final String catchTheBeat;
  final String highest;
  final String start;
  final String difficultyLevel;
  final String easy;
  final String medium;
  final String hard;
  final String howToPlay;
  final String exitGame;
  final String combo;
  final String miss;
  final String fever;
  final String shieldReady;
}
