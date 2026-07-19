import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front/features/user/closet/models/clothing_item.dart';
import 'package:front/features/user/closet/services/recommendation_service.dart';

void main() {
  const service = RecommendationService();
  final now = DateTime(2026, 7, 19);

  ClothingItem item({
    required String id,
    required int daysAgo,
    required List<String> seasons,
    int thickness = 1,
    List<String> styles = const ['캐주얼'],
  }) {
    return ClothingItem(
      id: id,
      name: id,
      category: '상의',
      brand: '테스트',
      fallbackColor: Colors.grey,
      fallbackIcon: Icons.checkroom,
      seasons: seasons,
      situation: styles,
      thickness: thickness,
      colorHex: '#808080',
      lastWornDate: now.subtract(Duration(days: daysAgo)),
      styleLevel: 2,
    );
  }

  test('더운 날에는 여름옷을 우선 추천한다', () {
    final ranked = service.rank(
      wardrobe: [
        item(id: '겨울옷', daysAgo: 60, seasons: ['겨울'], thickness: 3),
        item(id: '여름옷', daysAgo: 60, seasons: ['여름']),
      ],
      category: '상의',
      temperature: 28,
      selectedStyle: '캐주얼',
      now: now,
    );

    expect(ranked.first.item.id, '여름옷');
  });

  test('날씨와 스타일 조건이 같으면 오래 방치된 옷을 우선 추천한다', () {
    final ranked = service.rank(
      wardrobe: [
        item(id: '최근옷', daysAgo: 5, seasons: ['여름']),
        item(id: '방치옷', daysAgo: 80, seasons: ['여름']),
      ],
      category: '상의',
      temperature: 28,
      selectedStyle: '캐주얼',
      now: now,
    );

    expect(ranked.first.item.id, '방치옷');
    expect(ranked.first.neglectedDays, 80);
  });
}
