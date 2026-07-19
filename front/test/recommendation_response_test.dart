import 'package:flutter_test/flutter_test.dart';
import 'package:front/features/user/closet/models/recommendation_response.dart';

void main() {
  test('추천 API 응답을 프론트 모델로 변환한다', () {
    final response = RecommendationApiResponse.fromJson({
      'weather': {
        'temperature': 28.4,
        'weather': 'CLOUDS',
      },
      'recommendations': [
        {
          'totalClo': 0.7,
          'score': 91.5,
          'clothes': [
            {
              'id': 7,
              'category': 'TOP',
              'style': 'CASUAL',
              'imageUrl': 'https://example.com/top.png',
              'brand': '테스트 브랜드',
              'material': '면 100%',
              'thickness': 1,
              'cloValue': 0.3,
              'wearCount': 0,
              'lastWornAt': '2026-06-01',
            }
          ],
        }
      ],
    });

    expect(response.weather.temperature, 28.4);
    expect(response.weather.condition, 'CLOUDS');
    expect(response.recommendations.single.score, 91.5);

    final clothing = response.recommendations.single.clothes.single;
    expect(clothing.id, 7);
    expect(clothing.toClothingItem().category, '상의');
    expect(clothing.toClothingItem().name, '테스트 브랜드 상의');
    expect(clothing.toClothingItem().imageUrl, 'https://example.com/top.png');
  });

  test('백엔드에 name 필드가 추가되면 해당 이름을 우선 사용한다', () {
    final clothing = RecommendedClothing.fromJson({
      'id': 8,
      'name': '에어리즘 티셔츠',
      'category': 'TOP',
      'style': 'MINIMAL',
      'brand': '유니클로',
      'thickness': 1,
    });

    expect(clothing.toClothingItem().name, '에어리즘 티셔츠');
  });
}
