import 'package:flutter/material.dart';
import 'package:front/features/user/closet/models/clothing_item.dart';
import 'package:front/features/user/closet/services/closet_service.dart';
import 'package:front/features/user/closet/pages/codi_maker_page.dart';

class SavedOutfitsPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const SavedOutfitsPage({super.key, this.onRefresh});

  @override
  State<SavedOutfitsPage> createState() => _SavedOutfitsPageState();
}

class _SavedOutfitsPageState extends State<SavedOutfitsPage> {
  String _selectedCategory = '전체';
  final _newCategoryCtrl = TextEditingController();

  @override
  void dispose() {
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  void _addNewCategory() {
    final newCat = _newCategoryCtrl.text.trim();
    if (newCat.isEmpty) return;

    final categories = ClosetService.instance.outfitCategoriesNotifier.value;
    if (categories.contains(newCat)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 존재하는 카테고리입니다.')),
      );
      return;
    }

    ClosetService.instance.addOutfitCategory(newCat);
    setState(() {
      _selectedCategory = newCat;
    });
    _newCategoryCtrl.clear();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✨ "$newCat" 카테고리가 추가되었습니다.')),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 코디 카테고리 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: _newCategoryCtrl,
          decoration: InputDecoration(
            hintText: '예: 비즈니스 캐주얼, 휴가룩',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _addNewCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('카테고리 삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('"$cat" 카테고리를 삭제하시겠습니까?\n이 카테고리의 코디 조합은 "캐주얼" 카테고리로 변경됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ClosetService.instance.removeOutfitCategory(cat);
              setState(() {
                _selectedCategory = '전체';
              });
              Navigator.pop(ctx);
              widget.onRefresh?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🗑️ "$cat" 카테고리가 삭제되었습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _deleteOutfit(SavedOutfit outfit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('코디 조합 삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('이 코디 조합을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ClosetService.instance.removeOutfit(outfit);
              Navigator.pop(ctx);
              widget.onRefresh?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🗑️ 코디 조합이 삭제되었습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _wearOutfit(SavedOutfit outfit) {
    ClosetService.instance.wearOutfit(outfit);
    widget.onRefresh?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🎉 [${outfit.category}] 조합을 오늘 착용으로 기록했습니다. (의류 누적 착용 횟수 증가)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: ClosetService.instance.outfitCategoriesNotifier,
      builder: (context, outfitCategories, child) {
        return ValueListenableBuilder<List<SavedOutfit>>(
          valueListenable: ClosetService.instance.savedOutfitsNotifier,
          builder: (context, savedOutfits, child) {
            final outfits = _selectedCategory == '전체'
                ? savedOutfits
                : savedOutfits.where((o) => o.category == _selectedCategory).toList();

            return Scaffold(
              backgroundColor: const Color(0xFFF9FAFB),
              appBar: AppBar(
                backgroundColor: const Color(0xFFF9FAFB),
                title: const Text('코디 조합 관리'),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.create_new_folder_outlined, color: Color(0xFF1A1A1A)),
                    onPressed: _showAddCategoryDialog,
                    tooltip: '카테고리 추가',
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _categoryTab('전체', outfitCategories),
                          ...outfitCategories.map((cat) => _categoryTab(cat, outfitCategories)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: outfits.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.76,
                              ),
                              itemCount: outfits.length,
                              itemBuilder: (context, index) {
                                final outfit = outfits[index];
                                return _buildOutfitCard(outfit);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _categoryTab(String cat, List<String> outfitCategories) {
    final isSelected = _selectedCategory == cat;
    final isDefault = cat == '전체' || const ['캐주얼', '미니멀', '스트릿', '아메카지', '스포티', '격식', '데이트'].contains(cat);

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: EdgeInsets.only(
          left: 16,
          right: isDefault ? 16 : 8,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade200),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cat,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            if (!isDefault) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _deleteCategory(cat),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: isSelected ? Colors.white70 : Colors.grey.shade400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade100)),
            child: Icon(Icons.style_outlined, size: 48, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 16),
          Text(
            '등록된 코디 조합이 없습니다',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            '직접 코디 만들기 화면에서 완성된 코디를 저장해보세요.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(SavedOutfit outfit) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: outfit.items.map((item) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.imageBytes != null
                            ? Image.memory(item.imageBytes!, fit: BoxFit.contain)
                            : item.assetPath != null
                                ? Image.asset(item.assetPath!, fit: BoxFit.contain)
                                : Container(
                                    color: item.fallbackColor.withValues(alpha: 0.15),
                                    child: Icon(item.fallbackIcon, size: 24, color: item.fallbackColor),
                                  ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outfit.title.isNotEmpty ? outfit.title : outfit.category,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _wearOutfit(outfit),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '오늘 입기',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CodiMakerPage(
                              onRefresh: widget.onRefresh,
                              isAIRecommendedMode: outfit.category == 'AI 추천',
                              initialClothes: outfit.items,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit, size: 13, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _deleteOutfit(outfit),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.delete_outline, size: 13, color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
