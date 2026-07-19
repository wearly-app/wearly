import 'package:flutter/material.dart';
import 'package:front/features/user/closet/models/clothing_item.dart';

class ClothingApiItem {
  final int id;
  final String category;
  final String? style;
  final String? imageUrl;
  final int colorH;
  final int colorS;
  final int colorV;
  final String brand;
  final String material;
  final int thickness;
  final double? cloValue;
  final int wearCount;
  final DateTime? lastWornAt;

  const ClothingApiItem({
    required this.id,
    required this.category,
    required this.style,
    required this.imageUrl,
    required this.colorH,
    required this.colorS,
    required this.colorV,
    required this.brand,
    required this.material,
    required this.thickness,
    required this.cloValue,
    required this.wearCount,
    required this.lastWornAt,
  });

  factory ClothingApiItem.fromJson(Map<String, dynamic> json) {
    return ClothingApiItem(
      id: (json['id'] as num).toInt(),
      category: json['category'] as String? ?? 'ACCESSORY',
      style: json['style'] as String?,
      imageUrl: json['imageUrl'] as String?,
      colorH: (json['colorH'] as num?)?.toInt() ?? 0,
      colorS: (json['colorS'] as num?)?.toInt() ?? 0,
      colorV: (json['colorV'] as num?)?.toInt() ?? 55,
      brand: json['brand'] as String? ?? '브랜드 정보 없음',
      material: json['material'] as String? ?? '소재 정보 없음',
      thickness: (json['thickness'] as num?)?.toInt() ?? 2,
      cloValue: (json['cloValue'] as num?)?.toDouble(),
      wearCount: (json['wearCount'] as num?)?.toInt() ?? 0,
      lastWornAt: DateTime.tryParse(json['lastWornAt'] as String? ?? ''),
    );
  }

  ClothingItem toClothingItem() {
    final categoryLabel = _categoryLabel(category);
    final color = HSVColor.fromAHSV(
      1,
      colorH.clamp(0, 360).toDouble(),
      (colorS.clamp(0, 100) / 100),
      (colorV.clamp(0, 100) / 100),
    ).toColor();

    return ClothingItem(
      id: id.toString(),
      name: '$brand $categoryLabel',
      category: categoryLabel,
      brand: brand,
      imageUrl: imageUrl,
      fallbackColor: color,
      fallbackIcon: Icons.checkroom,
      seasons: _seasonsFor(thickness, cloValue),
      situation: [_styleLabel(style)],
      thickness: thickness,
      colorHex: _toHex(color),
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

  static String _styleLabel(String? style) {
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

  static String _toHex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class ClothingPageResponse {
  final List<ClothingApiItem> content;
  final int page;
  final int size;
  final bool first;
  final bool last;
  final bool hasNext;

  const ClothingPageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.first,
    required this.last,
    required this.hasNext,
  });

  factory ClothingPageResponse.fromJson(Map<String, dynamic> json) {
    return ClothingPageResponse(
      content: (json['content'] as List<dynamic>? ?? const [])
          .map((item) => ClothingApiItem.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}
