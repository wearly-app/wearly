import 'package:flutter/material.dart';
import 'package:front/features/user/closet/models/clothing_item.dart';
import 'package:front/features/user/closet/services/closet_service.dart';

class WardrobePage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const WardrobePage({super.key, this.onRefresh});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  String _cat = '전체';
  final List<String> _cats = const ['전체', '상의', '하의', '아우터', '원피스', '신발', '가방', '기타'];

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
      case 1: return '아주 편함';
      case 2: return '편한 캐주얼';
      case 3: return '단정한 출근룩';
      case 4: return '화려함';
      case 5: return '격식 정장';
      default: return '';
    }
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
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        color: _parseHexColor(item.colorHex).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.imageBytes != null
                            ? Image.memory(item.imageBytes!, fit: BoxFit.contain)
                            : item.assetPath != null
                                ? Image.asset(item.assetPath!, fit: BoxFit.contain)
                                : Center(child: Icon(item.fallbackIcon, size: 60, color: item.fallbackColor)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _detailRow('브랜드', item.brand),
                  _detailRow('카테고리', item.category),
                  _detailRow('추천 계절', item.seasons.join(', ')),
                  _detailRow('두께감', item.thickness == 1 ? '얇음 (여름)' : (item.thickness == 2 ? '보통 (봄/가을)' : '두꺼움 (겨울)')),
                  _detailRow('스타일', item.situation.join(', ')),
                  _detailRow('꾸밈 정도', _getStyleLevelText(item.styleLevel)),
                  _detailRow('대표 색상', item.colorHex.toUpperCase(), isColor: true, hexColor: item.colorHex),
                  _detailRow('착용 횟수', '${item.wearCount}회'),
                  _detailRow('마지막 착용일', item.lastWornDate != null ? "${item.lastWornDate!.year}-${item.lastWornDate!.month}-${item.lastWornDate!.day}" : "기록 없음"),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('아이템 삭제'),
                                content: const Text('정말로 이 옷을 옷장에서 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('취소', style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.pop(context);
                                      ClosetService.instance.removeClothingItem(item.id);
                                      widget.onRefresh?.call();
                                    },
                                    child: const Text('삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                          label: const Text('삭제하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _detailRow(String label, String value, {bool isColor = false, String? hexColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
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
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
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
        title: const Text('내 옷장', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ValueListenableBuilder<List<ClothingItem>>(
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
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.76,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _itemCard(items[i]),
                      ),
              ),
            ],
          );
        },
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
          Text('아직 옷이 없어요', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
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
                      color: _parseHexColor(item.colorHex).withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: item.imageBytes != null
                          ? Image.memory(item.imageBytes!, fit: BoxFit.contain)
                          : item.assetPath != null
                              ? Image.asset(item.assetPath!, fit: BoxFit.contain)
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
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
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
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item.name,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
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
