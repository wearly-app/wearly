import 'package:flutter/material.dart';
import 'package:front/features/user/closet/models/clothing_item.dart';

class RecommendationWeather {
  final double temperature;
  final String condition;

  const RecommendationWeather({
    required this.temperature,
    required this.condition,
  });

  factory RecommendationWeather.fromJson(Map<String, dynamic> json) {
    return RecommendationWeather(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      condition: json['weather'] as String? ?? 'UNKNOWN',
    );
  }
}

class RecommendedClothing {
  final int id;
  final String category;
  final String style;
  final String? name;
  final String? imageUrl;
  final String brand;
  final String material;
  final int thickness;
  final double? cloValue;
  final int wearCount;
  final DateTime? lastWornAt;

  const RecommendedClothing({
    required this.id,
    required this.category,
    required this.style,
    required this.name,
    required this.imageUrl,
    required this.brand,
    required this.material,
    required this.thickness,
    required this.cloValue,
    required this.wearCount,
    required this.lastWornAt,
  });

  factory RecommendedClothing.fromJson(Map<String, dynamic> json) {
    return RecommendedClothing(
      id: (json['id'] as num).toInt(),
      category: json['category'] as String? ?? 'ACCESSORY',
      style: json['style'] as String? ?? 'CASUAL',
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
      brand: json['brand'] as String? ?? '브랜드 정보 없음',
      material: json['material'] as String? ?? '소재 정보 없음',
      thickness: (json['thickness'] as num?)?.toInt() ?? 2,
      cloValue: (json['cloValue'] as num?)?.toDouble(),
      wearCount: (json['wearCount'] as num?)?.toInt() ?? 0,
      lastWornAt: DateTime.tryParse(json['lastWornAt'] as String? ?? ''),
    );
  }

  ClothingItem toClothingItem() {
    return ClothingItem(
      id: id.toString(),
      name: name?.trim().isNotEmpty == true
          ? name!.trim()
          : '$brand ${_categoryLabel(category)}',
      category: _categoryLabel(category),
      brand: brand,
      imageUrl: imageUrl,
      fallbackColor: const Color(0xFF8C8C8C),
      fallbackIcon: Icons.checkroom,
      seasons: _seasonsFor(thickness, cloValue),
      situation: [_styleLabel(style)],
      thickness: thickness,
      colorHex: '#8C8C8C',
      lastWornDate: lastWornAt,
      wearCount: wearCount,
      styleLevel: 2,
      material: material,
      clo: cloValue,
    );
  }

  static String _categoryLabel(String category) {
    const labels = {
      'TOP': '상의',
      'BOTTOM': '하의',
      'OUTER': '아우터',
      'ONEPIECE': '원피스',
      'SHOES': '신발',
      'BAG': '가방',
      'ACCESSORY': '기타',
    };
    return labels[category] ?? '기타';
  }

  static String _styleLabel(String style) {
    const labels = {
      'CASUAL': '캐주얼',
      'MINIMAL': '미니멀',
      'STREET': '스트릿',
      'SPORTY': '스포티',
      'FORMAL': '격식',
      'VINTAGE': '아메카지',
    };
    return labels[style] ?? '캐주얼';
  }

  static List<String> _seasonsFor(int thickness, double? cloValue) {
    if (thickness >= 3 || (cloValue != null && cloValue >= 0.8)) {
      return const ['가을', '겨울'];
    }
    if (thickness <= 1 || (cloValue != null && cloValue <= 0.35)) {
      return const ['여름'];
    }
    return const ['봄', '여름', '가을'];
  }
}

class RecommendedOutfit {
  final double totalClo;
  final double score;
  final List<RecommendedClothing> clothes;

  const RecommendedOutfit({
    required this.totalClo,
    required this.score,
    required this.clothes,
  });

  factory RecommendedOutfit.fromJson(Map<String, dynamic> json) {
    return RecommendedOutfit(
      totalClo: (json['totalClo'] as num?)?.toDouble() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      clothes: (json['clothes'] as List<dynamic>? ?? const [])
          .map((item) => RecommendedClothing.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
    );
  }
}

class RecommendationApiResponse {
  final RecommendationWeather weather;
  final List<RecommendedOutfit> recommendations;

  const RecommendationApiResponse({
    required this.weather,
    required this.recommendations,
  });

  factory RecommendationApiResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationApiResponse(
      weather: RecommendationWeather.fromJson(
        json['weather'] as Map<String, dynamic>? ?? const {},
      ),
      recommendations: (json['recommendations'] as List<dynamic>? ?? const [])
          .map((item) => RecommendedOutfit.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
    );
  }
}
