import 'package:flutter/material.dart';
import 'package:front/features/user/closet/models/clothing_item.dart';
import 'package:front/features/user/closet/models/recommendation_response.dart';
import 'package:front/services/api_service.dart';


class ClosetService {
  ClosetService._();
  static final ClosetService instance = ClosetService._();

  RecommendationWeather? cachedWeather;


  final ValueNotifier<List<ClothingItem>> wardrobeNotifier =
      ValueNotifier<List<ClothingItem>>([]);
  final ValueNotifier<List<CanvasItem>> canvasItemsNotifier =
      ValueNotifier<List<CanvasItem>>([]);
  final ValueNotifier<List<SavedOutfit>> savedOutfitsNotifier =
      ValueNotifier<List<SavedOutfit>>([]);
  final ValueNotifier<List<WornRecord>> wornHistoryNotifier =
      ValueNotifier<List<WornRecord>>([]);

  final ValueNotifier<List<String>> outfitCategoriesNotifier =
      ValueNotifier<List<String>>(
          ['캐주얼', '미니멀', '스트릿', '아메카지', '스포티', '격식', '데이트']);

  void addOutfitCategory(String category) {
    if (!outfitCategoriesNotifier.value.contains(category)) {
      outfitCategoriesNotifier.value = List.from(outfitCategoriesNotifier.value)
        ..add(category);
    }
  }

  void removeOutfitCategory(String category) {
    outfitCategoriesNotifier.value =
        outfitCategoriesNotifier.value.where((c) => c != category).toList();
    // Re-map outfits under deleted category to '캐주얼'
    savedOutfitsNotifier.value = savedOutfitsNotifier.value.map((o) {
      if (o.category == category) {
        o.category = '캐주얼';
      }
      return o;
    }).toList();
  }

  void removeOutfit(SavedOutfit outfit) {
    savedOutfitsNotifier.value =
        savedOutfitsNotifier.value.where((o) => o.id != outfit.id).toList();
  }

  Future<void> wearOutfit(SavedOutfit outfit) async {
    final now = DateTime.now();
    for (var cloth in outfit.items) {
      cloth.wearCount++;
      cloth.lastWornDate = now;
    }
    // Update wardrobe status
    wardrobeNotifier.value = List.from(wardrobeNotifier.value);

    // Insert new worn history record
    wornHistoryNotifier.value = List.from(wornHistoryNotifier.value)
      ..insert(
          0,
          WornRecord(
            date: now,
            outfit: outfit,
          ));

    // Send it to the server so the calendar keeps the record.
    await ApiService().wearOutfit(outfit.id);
  }

  /// Replace the calendar records with the server data for the given month.
  Future<void> loadWornHistoryFromServer(int year, int month) async {
    final api = ApiService();

    final days = await api.getMonthlyWearHistory(year, month);
    if (days.isEmpty) {
      wornHistoryNotifier.value = [];
      return;
    }

    final records = <WornRecord>[];

    for (final day in days) {
      final dateText = day['wornDate'] as String?;
      if (dateText == null) continue;

      final date = DateTime.parse(dateText);
      final histories = await api.getDailyWearHistory(date);

      for (final history in histories) {
        final clothesJson = history['clothes'] as List<dynamic>? ?? [];
        final items = clothesJson
            .map((e) => _clothingFromServer(e as Map<String, dynamic>))
            .toList();

        records.add(WornRecord(
          date: date,
          outfit: SavedOutfit(
            id: '${history['outfitId']}',
            title: history['outfitName'] as String? ?? '코디',
            category: _styleToKorean(history['style'] as String?),
            items: items,
            createdAt: date,
          ),
        ));
      }
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    wornHistoryNotifier.value = records;
  }

  ClothingItem _clothingFromServer(Map<String, dynamic> json) {
    return ClothingItem(
      id: '${json['id']}',
      name: json['name'] as String? ?? '이름 없음',
      category: _categoryToKorean(json['category'] as String?),
      brand: json['brand'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      fallbackColor: Colors.grey.shade200,
      fallbackIcon: Icons.checkroom,
      seasons: const [],
      situation: const [],
      thickness: 2,
      colorHex: '#FFFFFF',
      styleLevel: 3,
    );
  }

  String _styleToKorean(String? style) {
    switch (style) {
      case 'MINIMAL':
        return '미니멀';
      case 'STREET':
        return '스트릿';
      case 'SPORTY':
        return '스포티';
      case 'FORMAL':
        return '격식';
      case 'VINTAGE':
        return '빈티지';
      default:
        return '캐주얼';
    }
  }

  String _categoryToKorean(String? category) {
    switch (category) {
      case 'TOP':
        return '상의';
      case 'BOTTOM':
        return '하의';
      case 'OUTER':
        return '아우터';
      case 'ONEPIECE':
        return '원피스';
      case 'SHOES':
        return '신발';
      case 'BAG':
        return '가방';
      default:
        return '기타';
    }
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

  void replaceClothingItems(List<ClothingItem> items) {
    wardrobeNotifier.value = List.from(items);
  }

  /// Load the wardrobe from the server.
  /// The wardrobe page fills this list on its own, but other pages
  /// (코디 만들기 등) need the clothes too, so they can call this directly.
  /// The server allows at most 50 items per page, so read the pages in order.
  Future<void> loadWardrobeFromServer() async {
    final items = <ClothingItem>[];
    var page = 0;

    while (true) {
      final response = await ApiService().getClothingItems(page: page, size: 50);
      if (response == null) break;

      items.addAll(response.content.map(_wardrobeItemFromServer));

      if (!response.hasNext) break;
      page = response.page + 1;
    }

    if (items.isEmpty) return;

    wardrobeNotifier.value = items;
  }

  ClothingItem _wardrobeItemFromServer(Map<String, dynamic> json) {
    final category = _categoryToKorean(json['category'] as String?);
    final style = _styleToKorean(json['style'] as String?);
    final thickness = (json['thickness'] as num?)?.toInt() ?? 2;
    final brand = json['brand'] as String? ?? '';
    final name = json['name'] as String?;
    final lastWornAt = json['lastWornAt'] as String?;
    final h = (json['colorH'] as num?)?.toDouble() ?? 0;
    final s = (json['colorS'] as num?)?.toDouble() ?? 0;
    final v = (json['colorV'] as num?)?.toDouble() ?? 100;
    final color = HSVColor.fromAHSV(1, h, s / 100, v / 100).toColor();
    final colorHex =
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return ClothingItem(
      id: json['id'].toString(),
      name: name?.isNotEmpty == true
          ? name!
          : (brand.isEmpty ? category : '$brand $category'),
      category: category,
      brand: brand.isEmpty ? 'No Brand' : brand,
      imageUrl: json['imageUrl'] as String?,
      fallbackColor: color,
      fallbackIcon: Icons.dry_cleaning,
      seasons: _seasonsForThickness(thickness),
      situation: [style],
      thickness: thickness,
      colorHex: colorHex,
      lastWornDate: lastWornAt == null ? null : DateTime.tryParse(lastWornAt),
      wearCount: (json['wearCount'] as num?)?.toInt() ?? 0,
      styleLevel: 2,
      material: json['material'] as String?,
      clo: (json['cloValue'] as num?)?.toDouble(),
    );
  }

  List<String> _seasonsForThickness(int thickness) {
    if (thickness == 1) return const ['여름'];
    if (thickness == 3) return const ['겨울'];
    return const ['봄', '가을'];
  }

  void appendClothingItems(List<ClothingItem> items) {
    final merged = <String, ClothingItem>{
      for (final item in wardrobeNotifier.value) item.id: item,
      for (final item in items) item.id: item,
    };
    wardrobeNotifier.value = merged.values.toList();
  }

  void removeClothingItem(String id) {
    wardrobeNotifier.value =
        wardrobeNotifier.value.where((w) => w.id != id).toList();
  }

  Future<void> markAsWorn(ClothingItem item) async {
    item.wearCount++;
    item.lastWornDate = DateTime.now();
    wardrobeNotifier.value = List.from(wardrobeNotifier.value);

    // Send it to the server so the wear count and last worn date are kept.
    // This is a single item, not an outfit, so it does not create a
    // calendar record.
    await ApiService().wearClothingItem(item.id);
  }

  void saveOutfit(SavedOutfit outfit) {
    savedOutfitsNotifier.value = List.from(savedOutfitsNotifier.value)
      ..add(outfit);
  }

  void replaceSavedOutfits(List<SavedOutfit> outfits) {
    savedOutfitsNotifier.value = List.from(outfits);
  }

  void appendSavedOutfits(List<SavedOutfit> outfits) {
    final merged = <String, SavedOutfit>{
      for (final outfit in savedOutfitsNotifier.value) outfit.id: outfit,
      for (final outfit in outfits) outfit.id: outfit,
    };
    savedOutfitsNotifier.value = merged.values.toList();
  }

  void addWornRecord(WornRecord record) {
    wornHistoryNotifier.value = List.from(wornHistoryNotifier.value)
      ..add(record);
  }

  void clearCanvas() {
    canvasItemsNotifier.value = [];
  }

  void addCanvasItem(CanvasItem item) {
    canvasItemsNotifier.value = List.from(canvasItemsNotifier.value)..add(item);
  }

  void removeCanvasItem(String itemId) {
    canvasItemsNotifier.value =
        canvasItemsNotifier.value.where((x) => x.id != itemId).toList();
  }

  void updateCanvasItem(CanvasItem updatedItem) {
    canvasItemsNotifier.value = canvasItemsNotifier.value
        .map((x) => x.id == updatedItem.id ? updatedItem : x)
        .toList();
  }
}
