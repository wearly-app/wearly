import 'package:flutter/material.dart';
import 'package:front/config/app_config.dart';
import 'package:front/features/user/closet/models/clothing_item.dart';
import 'package:front/features/user/closet/services/closet_service.dart';
import 'package:front/services/api_service.dart';

class WardrobePage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const WardrobePage({super.key, this.onRefresh});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  String _cat = '전체';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNext = false;
  int _nextPage = 0;
  String? _deletingClothesId;
  String? _loadError;
  final List<String> _cats = const [
    '전체',
    '상의',
    '하의',
    '아우터',
    '원피스',
    '신발',
    '가방',
    '기타'
  ];

  @override
  void initState() {
    super.initState();
    _loadClothes();
  }

  Future<void> _loadClothes({bool reset = true}) async {
    if (AppConfig.useMockApi) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!reset && (!_hasNext || _isLoadingMore)) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _loadError = null;
        _nextPage = 0;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final response = await ApiService().getClothingItems(
      page: reset ? 0 : _nextPage,
      size: 10,
    );
    if (!mounted) return;

    if (response == null) {
      setState(() {
        if (reset) {
          _isLoading = false;
          _loadError = '옷장 정보를 불러오지 못했습니다.';
        } else {
          _isLoadingMore = false;
        }
      });
      return;
    }

    final items = response.content.map(_clothingItemFromJson).toList();
    if (reset) {
      ClosetService.instance.replaceClothingItems(items);
    } else {
      ClosetService.instance.appendClothingItems(items);
    }

    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
      _hasNext = response.hasNext;
      _nextPage = response.page + 1;
    });
  }

  ClothingItem _clothingItemFromJson(Map<String, dynamic> json) {
    final category = _categoryLabel(json['category'] as String?);
    final style = _styleLabel(json['style'] as String?);
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

  String _categoryLabel(String? category) {
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

  String _styleLabel(String? style) {
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
        return '데이트';
      default:
        return '캐주얼';
    }
  }

  List<String> _seasonsForThickness(int thickness) {
    if (thickness == 1) return const ['여름'];
    if (thickness == 3) return const ['겨울'];
    return const ['봄', '가을'];
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _getStyleLevelText(int level) {
    switch (level) {
      case 1:
        return '아주 편함';
      case 2:
        return '편한 캐주얼';
      case 3:
        return '단정한 출근룩';
      case 4:
        return '화려함';
      case 5:
        return '격식 정장';
      default:
        return '';
    }
  }

  Future<void> _deleteClothingItem(ClothingItem item) async {
    if (_deletingClothesId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('아이템 삭제'),
        content: const Text('정말로 이 옷을 옷장에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingClothesId = item.id;
    });

    final deleted = await ApiService().deleteClothingItem(item.id);
    if (!mounted) return;

    setState(() {
      _deletingClothesId = null;
    });

    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('옷 삭제에 실패했습니다. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    Navigator.pop(context);
    ClosetService.instance.removeClothingItem(item.id);
    widget.onRefresh?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('옷장에서 옷을 삭제했습니다.')),
    );
  }

  void _showItemDetail(ClothingItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: _parseHexColor(item.colorHex)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.imageBytes != null
                            ? Image.memory(item.imageBytes!,
                                fit: BoxFit.contain)
                            : item.imageUrl?.isNotEmpty == true
                                ? Image.network(
                                    item.imageUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Icon(item.fallbackIcon,
                                          size: 60, color: item.fallbackColor),
                                    ),
                                  )
                                : item.assetPath != null
                                    ? Image.asset(item.assetPath!,
                                        fit: BoxFit.contain)
                                    : Center(
                                        child: Icon(item.fallbackIcon,
                                            size: 60,
                                            color: item.fallbackColor)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _detailRow('브랜드', item.brand),
                  _detailRow('카테고리', item.category),
                  _detailRow('추천 계절', item.seasons.join(', ')),
                  _detailRow(
                      '두께감',
                      item.thickness == 1
                          ? '얇음 (여름)'
                          : (item.thickness == 2 ? '보통 (봄/가을)' : '두꺼움 (겨울)')),
                  _detailRow('스타일', item.situation.join(', ')),
                  _detailRow('꾸밈 정도', _getStyleLevelText(item.styleLevel)),
                  _detailRow('대표 색상', item.colorHex.toUpperCase(),
                      isColor: true, hexColor: item.colorHex),
                  _detailRow('착용 횟수', '${item.wearCount}회'),
                  _detailRow(
                      '마지막 착용일',
                      item.lastWornDate != null
                          ? "${item.lastWornDate!.year}-${item.lastWornDate!.month}-${item.lastWornDate!.day}"
                          : "기록 없음"),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setModalState(() {
                              ClosetService.instance.markAsWorn(item);
                            });
                            widget.onRefresh?.call();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('오늘 착용으로 기록되었습니다.')),
                            );
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('오늘 착용'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A1A1A),
                            side: const BorderSide(color: Color(0xFF1A1A1A)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _deletingClothesId == null
                              ? () => _deleteClothingItem(item)
                              : null,
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.white),
                          label: _deletingClothesId == item.id
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('삭제하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool isColor = false, String? hexColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
          Row(
            children: [
              if (isColor && hexColor != null) ...[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _parseHexColor(hexColor),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            const Text('내 옷장', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : () => _loadClothes(),
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildLoadError()
              : ValueListenableBuilder<List<ClothingItem>>(
                  valueListenable: ClosetService.instance.wardrobeNotifier,
                  builder: (context, wardrobe, child) {
                    final items = _cat == '전체'
                        ? wardrobe
                        : wardrobe.where((i) => i.category == _cat).toList();

                    return Column(
                      children: [
                        _buildCategoryChips(),
                        const SizedBox(height: 8),
                        Expanded(
                          child: items.isEmpty
                              ? _buildEmpty()
                              : NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification.metrics.extentAfter <
                                        240) {
                                      _loadClothes(reset: false);
                                    }
                                    return false;
                                  },
                                  child: GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 100),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 0.76,
                                    ),
                                    itemCount:
                                        items.length + (_isLoadingMore ? 1 : 0),
                                    itemBuilder: (_, i) {
                                      if (i == items.length) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      return _itemCard(items[i]);
                                    },
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_loadError!, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _loadClothes(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _cats.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _cats[i];
          final sel = c == _cat;
          return GestureDetector(
            onTap: () => setState(() => _cat = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(c,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? Colors.white : const Color(0xFF666666))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('아직 옷이 없어요',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
          const SizedBox(height: 6),
          Text('+ 버튼으로 첫 아이템을 추가해보세요',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _itemCard(ClothingItem item) {
    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          _parseHexColor(item.colorHex).withValues(alpha: 0.08),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: item.imageBytes != null
                          ? Image.memory(item.imageBytes!, fit: BoxFit.contain)
                          : item.imageUrl?.isNotEmpty == true
                              ? Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Icon(item.fallbackIcon,
                                        size: 32, color: item.fallbackColor),
                                  ),
                                )
                              : item.assetPath != null
                                  ? Image.asset(item.assetPath!,
                                      fit: BoxFit.contain)
                                  : Center(
                                      child: Icon(item.fallbackIcon,
                                          size: 32, color: item.fallbackColor)),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _parseHexColor(item.colorHex),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 2)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.brand,
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
