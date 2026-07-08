import 'package:flutter/material.dart';
import 'package:front/features/user/closet/models/clothing_item.dart';

class ClosetService {
  ClosetService._();
  static final ClosetService instance = ClosetService._();

  final ValueNotifier<List<ClothingItem>> wardrobeNotifier = ValueNotifier<List<ClothingItem>>([]);
  final ValueNotifier<List<CanvasItem>> canvasItemsNotifier = ValueNotifier<List<CanvasItem>>([]);
  final ValueNotifier<List<SavedOutfit>> savedOutfitsNotifier = ValueNotifier<List<SavedOutfit>>([]);
  final ValueNotifier<List<WornRecord>> wornHistoryNotifier = ValueNotifier<List<WornRecord>>([]);

  final ValueNotifier<List<String>> outfitCategoriesNotifier = ValueNotifier<List<String>>([
    '캐주얼', '미니멀', '스트릿', '아메카지', '스포티', '격식', '데이트'
  ]);

  void addOutfitCategory(String category) {
    if (!outfitCategoriesNotifier.value.contains(category)) {
      outfitCategoriesNotifier.value = List.from(outfitCategoriesNotifier.value)..add(category);
    }
  }

  void removeOutfitCategory(String category) {
    outfitCategoriesNotifier.value = outfitCategoriesNotifier.value.where((c) => c != category).toList();
    // Re-map outfits under deleted category to '캐주얼'
    savedOutfitsNotifier.value = savedOutfitsNotifier.value.map((o) {
      if (o.category == category) {
        o.category = '캐주얼';
      }
      return o;
    }).toList();
  }

  void removeOutfit(SavedOutfit outfit) {
    savedOutfitsNotifier.value = savedOutfitsNotifier.value.where((o) => o.id != outfit.id).toList();
  }

  void wearOutfit(SavedOutfit outfit) {
    final now = DateTime.now();
    for (var cloth in outfit.items) {
      cloth.wearCount++;
      cloth.lastWornDate = now;
    }
    // Update wardrobe status
    wardrobeNotifier.value = List.from(wardrobeNotifier.value);
    
    // Insert new worn history record
    wornHistoryNotifier.value = List.from(wornHistoryNotifier.value)
      ..insert(0, WornRecord(
        date: now,
        outfit: outfit,
        weather: '☀️ 맑음',
        temp: 27,
      ));
  }

  void initializeDemoData() {
    if (wardrobeNotifier.value.isNotEmpty) return;

    final List<ClothingItem> demoWardrobe = [
      ClothingItem(
        id: '1',
        name: '98 Knee Pin-Tuck Contrast Cargo Pants',
        category: '하의',
        brand: '아캄',
        assetPath: 'assets/akam_pants.png',
        fallbackColor: const Color(0xFFD2B48C),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '가을'],
        situation: const ['스트릿', '캐주얼'],
        thickness: 2,
        colorHex: '#D2B48C',
        styleLevel: 3,
        wearCount: 5,
      ),
      ClothingItem(
        id: '2',
        name: '빈티지 스트라이프 폴로 티셔츠 다이드 블루',
        category: '상의',
        brand: '해칭룸',
        assetPath: 'assets/hatchingroom_polo.png',
        fallbackColor: const Color(0xFF3F51B5),
        fallbackIcon: Icons.checkroom,
        seasons: const ['여름'],
        situation: const ['캐주얼', '스트릿'],
        thickness: 2,
        colorHex: '#3F51B5',
        styleLevel: 3,
        wearCount: 2,
      ),
      ClothingItem(
        id: '3',
        name: 'UNIFORM SEMI CROP T-SHIRTS',
        category: '상의',
        brand: '다이브인',
        assetPath: 'assets/divein_crop.jpeg',
        fallbackColor: const Color(0xFF808080),
        fallbackIcon: Icons.checkroom,
        seasons: const ['여름'],
        situation: const ['미니멀', '캐주얼'],
        thickness: 2,
        colorHex: '#808080',
        styleLevel: 2,
        wearCount: 0,
      ),
      ClothingItem(
        id: '4',
        name: '드라이컬러크루넥T',
        category: '상의',
        brand: '유니클로',
        assetPath: 'assets/uniqlo_crewneck.png',
        fallbackColor: const Color(0xFFFFFFF0),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '여름', '가을', '겨울'],
        situation: const ['캐주얼', '미니멀'],
        thickness: 2,
        colorHex: '#FFFFF0',
        styleLevel: 1,
        wearCount: 0,
      ),
      ClothingItem(
        id: '5',
        name: 'TWISTED SLASH DENIM DEEP INDIGO',
        category: '하의',
        brand: '서피스에디션',
        assetPath: 'assets/surface_denim.png',
        fallbackColor: const Color(0xFF1A237E),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '여름', '가을', '겨울'],
        situation: const ['스트릿', '캐주얼'],
        thickness: 2,
        colorHex: '#1A237E',
        styleLevel: 3,
        wearCount: 4,
      ),
      ClothingItem(
        id: '6',
        name: '오버핏 반팔 블랙',
        category: '상의',
        brand: '스파오',
        assetPath: 'assets/spao_overfit_black.png',
        fallbackColor: const Color(0xFF1C1C1C),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '여름', '가을'],
        situation: const ['캐주얼', '스포티'],
        thickness: 2,
        colorHex: '#1C1C1C',
        styleLevel: 2,
        wearCount: 3,
      ),
      ClothingItem(
        id: '7',
        name: '해칭룸 커브드 팬츠',
        category: '하의',
        brand: '해칭룸',
        assetPath: 'assets/hatchingroom_curved_pants.png',
        fallbackColor: const Color(0xFF5A5A5A),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '가을', '겨울'],
        situation: const ['미니멀', '스트릿'],
        thickness: 3,
        colorHex: '#5A5A5A',
        styleLevel: 3,
        wearCount: 3,
      ),
      ClothingItem(
        id: '9',
        name: '98 Knee Pin-Tuck Contrast Cargo Pants (그레이)',
        category: '하의',
        brand: '아캄',
        assetPath: 'assets/akam_pants_gray.png',
        fallbackColor: const Color(0xFF808080),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '가을', '겨울'],
        situation: const ['스트릿', '캐주얼'],
        thickness: 2,
        colorHex: '#808080',
        styleLevel: 3,
        wearCount: 2,
      ),
      ClothingItem(
        id: '11',
        name: '더콜디스트모먼트 워크 치노 팬츠',
        category: '하의',
        brand: '더콜디스트모먼트',
        assetPath: 'assets/tcm_chino.png',
        fallbackColor: const Color(0xFF4A4B46),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '가을', '겨울'],
        situation: const ['스트릿', '아메카지'],
        thickness: 2,
        colorHex: '#4A4B46',
        styleLevel: 3,
        wearCount: 0,
      ),
      ClothingItem(
        id: '12',
        name: '데꼬로소 와플 헨리넥 니트',
        category: '상의',
        brand: '데꼬로소',
        assetPath: 'assets/decoroso_henley.png',
        fallbackColor: const Color(0xFF1E1E24),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '가을', '겨울'],
        situation: const ['캐주얼', '아메카지'],
        thickness: 3,
        colorHex: '#1E1E24',
        styleLevel: 3,
        wearCount: 0,
      ),
      ClothingItem(
        id: '13',
        name: '마초 골지 헨리넥 셔츠',
        category: '상의',
        brand: '마초',
        assetPath: 'assets/macho_henley.png',
        fallbackColor: const Color(0xFF4A2F22),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '가을', '겨울'],
        situation: const ['캐주얼', '아메카지'],
        thickness: 2,
        colorHex: '#4A2F22',
        styleLevel: 3,
        wearCount: 0,
      ),
      ClothingItem(
        id: '14',
        name: '무신사 스탠다드 울 크루넥 니트',
        category: '상의',
        brand: '무신사 스탠다드',
        assetPath: 'assets/victoria_wool.png',
        fallbackColor: const Color(0xFF800020),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '가을', '겨울'],
        situation: const ['데이트', '미니멀'],
        thickness: 3,
        colorHex: '#800020',
        styleLevel: 3,
        wearCount: 0,
      ),
      ClothingItem(
        id: '15',
        name: '유니클로 네이비 크루넥 T',
        category: '상의',
        brand: '유니클로',
        assetPath: 'assets/uniqlo_navy.png',
        fallbackColor: const Color(0xFF1B263B),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '여름', '가을'],
        situation: const ['캐주얼', '미니멀'],
        thickness: 2,
        colorHex: '#1B263B',
        styleLevel: 1,
        wearCount: 0,
      ),
      ClothingItem(
        id: '16',
        name: '유니폼 세미 크롭 티셔츠 (블랙)',
        category: '상의',
        brand: '다이브인',
        assetPath: 'assets/divein_crop_black.png',
        fallbackColor: const Color(0xFF1C1C1C),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '여름', '가을'],
        situation: const ['미니멀', '캐주얼'],
        thickness: 2,
        colorHex: '#1C1C1C',
        styleLevel: 2,
        wearCount: 0,
      ),
      ClothingItem(
        id: '8',
        name: '스트레이트 데님 (중청)',
        category: '하의',
        brand: '유니클로',
        assetPath: 'assets/uniqlo_straight_blue.png',
        fallbackColor: const Color(0xFF4682B4),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '가을', '겨울'],
        situation: const ['캐주얼', '미니멀'],
        thickness: 2,
        colorHex: '#4682B4',
        styleLevel: 2,
        wearCount: 3,
      ),
      ClothingItem(
        id: '17',
        name: '베이직 클래식 셔츠 (화이트)',
        category: '상의',
        brand: 'No Brand',
        assetPath: 'assets/white_shirt.png',
        fallbackColor: const Color(0xFFFFFFFF),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '여름', '가을'],
        situation: const ['격식', '미니멀'],
        thickness: 2,
        colorHex: '#FFFFFF',
        styleLevel: 3,
        wearCount: 0,
      ),
      ClothingItem(
        id: '18',
        name: '디키즈 루즈핏 워크팬츠',
        category: '하의',
        brand: '디키즈',
        assetPath: 'assets/dickies_loose_fit.png',
        fallbackColor: const Color(0xFF3E3D32),
        fallbackIcon: Icons.checkroom,
        seasons: const ['봄', '여름', '가을', '겨울'],
        situation: const ['스트릿', '캐주얼'],
        thickness: 2,
        colorHex: '#3E3D32',
        styleLevel: 3,
        wearCount: 0,
      ),
    ];

    wardrobeNotifier.value = demoWardrobe;

    final List<SavedOutfit> demoSavedOutfits = [
      SavedOutfit(
        id: 'o1',
        title: '초여름 캐주얼 조합',
        category: '캐주얼',
        items: [
          demoWardrobe[2], // Divein Crop Top
          demoWardrobe[0], // Akam Pants
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SavedOutfit(
        id: 'o2',
        title: '빈티지 블루 스트릿',
        category: '스트릿',
        items: [
          demoWardrobe[1], // Hatchingroom Polo
          demoWardrobe[4], // Surface Denim
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SavedOutfit(
        id: 'o3',
        title: '미니멀 블랙 & 차콜 매치',
        category: '미니멀',
        items: [
          demoWardrobe[5], // Spao Overfit Black T-shirt
          demoWardrobe[6], // Hatchingroom Curved Pants
        ],
        createdAt: DateTime.now(),
      ),
      SavedOutfit(
        id: 'o4',
        title: '클래식 셔츠 & 디키즈 격식룩',
        category: '격식',
        items: [
          demoWardrobe[15], // Basic Classic Shirt (White)
          demoWardrobe[16], // Dickies Loose Fit Work Pants
        ],
        createdAt: DateTime.now(),
      ),
    ];
    savedOutfitsNotifier.value = demoSavedOutfits;

    final List<WornRecord> demoWornHistory = [
      WornRecord(
        date: DateTime(2026, 6, 1),
        outfit: SavedOutfit(
          id: 'wh_j1',
          title: '다이브인 크롭티 조합',
          category: '데일리',
          items: [demoWardrobe[2], demoWardrobe[0]],
          createdAt: DateTime(2026, 6, 1),
        ),
        weather: '☀️ 맑음',
        temp: 29,
      ),
      WornRecord(
        date: DateTime(2026, 6, 2),
        outfit: SavedOutfit(
          id: 'wh_j2',
          title: '스파오 오버핏 블랙 조합',
          category: '데일리',
          items: [demoWardrobe[5], demoWardrobe[4]],
          createdAt: DateTime(2026, 6, 2),
        ),
        weather: '☀️ 맑음',
        temp: 30,
      ),
      WornRecord(
        date: DateTime(2026, 6, 3),
        outfit: SavedOutfit(
          id: 'wh_j3',
          title: '다이브인 크롭티 조합',
          category: '데일리',
          items: [demoWardrobe[2], demoWardrobe[6]],
          createdAt: DateTime(2026, 6, 3),
        ),
        weather: '☀️ 맑음',
        temp: 31,
      ),
      WornRecord(
        date: DateTime(2026, 6, 4),
        outfit: SavedOutfit(
          id: 'wh_j4',
          title: '다이브인 블랙 크롭티 조합',
          category: '데일리',
          items: [demoWardrobe[13], demoWardrobe[0]],
          createdAt: DateTime(2026, 6, 4),
        ),
        weather: '🌧️ 비',
        temp: 30,
      ),
      WornRecord(
        date: DateTime(2026, 6, 5),
        outfit: SavedOutfit(
          id: 'wh_j5',
          title: '다이브인 크롭티 조합',
          category: '데일리',
          items: [demoWardrobe[2], demoWardrobe[4]],
          createdAt: DateTime(2026, 6, 5),
        ),
        weather: '☀️ 맑음',
        temp: 25,
      ),
    ];
    wornHistoryNotifier.value = demoWornHistory;
  }

  void addClothingItem(ClothingItem item) {
    wardrobeNotifier.value = List.from(wardrobeNotifier.value)..add(item);
  }

  void removeClothingItem(String id) {
    wardrobeNotifier.value = wardrobeNotifier.value.where((w) => w.id != id).toList();
  }

  void markAsWorn(ClothingItem item) {
    item.wearCount++;
    item.lastWornDate = DateTime.now();
    wardrobeNotifier.value = List.from(wardrobeNotifier.value);
  }

  void saveOutfit(SavedOutfit outfit) {
    savedOutfitsNotifier.value = List.from(savedOutfitsNotifier.value)..add(outfit);
  }

  void addWornRecord(WornRecord record) {
    wornHistoryNotifier.value = List.from(wornHistoryNotifier.value)..add(record);
  }

  void clearCanvas() {
    canvasItemsNotifier.value = [];
  }

  void addCanvasItem(CanvasItem item) {
    canvasItemsNotifier.value = List.from(canvasItemsNotifier.value)..add(item);
  }

  void removeCanvasItem(String itemId) {
    canvasItemsNotifier.value = canvasItemsNotifier.value.where((x) => x.id != itemId).toList();
  }

  void updateCanvasItem(CanvasItem updatedItem) {
    canvasItemsNotifier.value = canvasItemsNotifier.value.map((x) => x.id == updatedItem.id ? updatedItem : x).toList();
  }
}
