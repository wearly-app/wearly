import 'package:front/features/user/closet/models/clothing_item.dart';

class ClothingRecommendation {
  final ClothingItem item;
  final double totalScore;
  final int neglectedDays;
  final double neglectScore;
  final double weatherScore;
  final double styleScore;

  const ClothingRecommendation({
    required this.item,
    required this.totalScore,
    required this.neglectedDays,
    required this.neglectScore,
    required this.weatherScore,
    required this.styleScore,
  });
}

class RecommendationService {
  const RecommendationService();

  List<ClothingRecommendation> rank({
    required List<ClothingItem> wardrobe,
    required String category,
    required double temperature,
    required String selectedStyle,
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();
    final recommendations = wardrobe
        .where((item) => item.category == category)
        .map(
          (item) => _score(
            item: item,
            temperature: temperature,
            selectedStyle: selectedStyle,
            now: referenceDate,
          ),
        )
        .toList();

    recommendations.sort((a, b) {
      final scoreComparison = b.totalScore.compareTo(a.totalScore);
      if (scoreComparison != 0) return scoreComparison;

      final wornComparison = a.item.wearCount.compareTo(b.item.wearCount);
      if (wornComparison != 0) return wornComparison;
      return a.item.id.compareTo(b.item.id);
    });
    return recommendations;
  }

  ClothingRecommendation _score({
    required ClothingItem item,
    required double temperature,
    required String selectedStyle,
    required DateTime now,
  }) {
    final neglectedDays = _neglectedDays(item, now);
    final dayScore = (neglectedDays.clamp(0, 90) / 90) * 50;
    final lowWearBonus = ((5 - item.wearCount).clamp(0, 5) / 5) * 10;
    final neglectScore = dayScore + lowWearBonus;
    final weatherScore = _weatherScore(item, temperature);
    final styleScore = item.situation.contains(selectedStyle) ? 15.0 : 5.0;

    return ClothingRecommendation(
      item: item,
      totalScore: neglectScore + weatherScore + styleScore,
      neglectedDays: neglectedDays,
      neglectScore: neglectScore,
      weatherScore: weatherScore,
      styleScore: styleScore,
    );
  }

  int _neglectedDays(ClothingItem item, DateTime now) {
    final lastWornDate = item.lastWornDate;
    if (lastWornDate != null) {
      return now.difference(lastWornDate).inDays.clamp(0, 3650);
    }

    // 시연용 더미 데이터에는 마지막 착용일이 없는 경우가 많다.
    // 이때는 착용 횟수가 적을수록 더 오래 방치된 옷으로 추정한다.
    return (90 - (item.wearCount * 12)).clamp(30, 90);
  }

  double _weatherScore(ClothingItem item, double temperature) {
    final targetSeason = _seasonForTemperature(temperature);
    var score = item.seasons.contains(targetSeason) ? 17.0 : 4.0;

    final clo = item.clo;
    if (temperature >= 27) {
      if (item.thickness == 1 || (clo != null && clo <= 0.35)) score += 8;
      if (item.thickness >= 3 || (clo != null && clo >= 0.8)) score -= 6;
    } else if (temperature <= 10) {
      if (item.thickness >= 3 || (clo != null && clo >= 0.8)) score += 8;
      if (item.thickness == 1 || (clo != null && clo <= 0.35)) score -= 6;
    } else if (item.thickness == 2) {
      score += 8;
    }

    return score.clamp(0, 25).toDouble();
  }

  String _seasonForTemperature(double temperature) {
    if (temperature >= 25) return '여름';
    if (temperature <= 10) return '겨울';
    return '봄';
  }
}
