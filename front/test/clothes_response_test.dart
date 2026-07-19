import 'package:flutter_test/flutter_test.dart';
import 'package:front/features/user/closet/models/clothes_response.dart';

void main() {
  test('옷 목록 페이지 응답을 프론트 모델로 변환한다', () {
    final page = ClothingPageResponse.fromJson({
      'content': [
        {
          'id': 12,
          'category': 'BOTTOM',
          'style': 'CASUAL',
          'imageUrl': 'https://example.com/bottom.png',
          'colorH': 210,
          'colorS': 50,
          'colorV': 60,
          'brand': '테스트 브랜드',
          'material': '데님',
          'thickness': 2,
          'cloValue': 0.45,
          'wearCount': 3,
          'lastWornAt': '2026-07-01',
        }
      ],
      'page': 0,
      'size': 50,
      'first': true,
      'last': true,
      'hasNext': false,
    });

    expect(page.content, hasLength(1));
    expect(page.hasNext, isFalse);

    final clothing = page.content.single.toClothingItem();
    expect(clothing.id, '12');
    expect(clothing.category, '하의');
    expect(clothing.situation, ['캐주얼']);
    expect(clothing.material, '데님');
    expect(clothing.clo, 0.45);
    expect(clothing.imageUrl, 'https://example.com/bottom.png');
  });

  test('누락된 선택 필드는 안전한 기본값으로 변환한다', () {
    final item = ClothingApiItem.fromJson({
      'id': 1,
      'category': 'TOP',
    }).toClothingItem();

    expect(item.category, '상의');
    expect(item.brand, '브랜드 정보 없음');
    expect(item.thickness, 2);
    expect(item.wearCount, 0);
  });
}
