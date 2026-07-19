import 'package:flutter/material.dart';
import 'package:front/features/user/closet/models/clothing_item.dart';
import 'package:front/features/user/closet/services/closet_service.dart';

class SaveOutfitPage extends StatefulWidget {
  final List<CanvasItem> items;
  final VoidCallback? onRefresh;
  final bool isAIRecommendedMode;

  const SaveOutfitPage({
    super.key,
    required this.items,
    this.onRefresh,
    this.isAIRecommendedMode = false,
  });

  @override
  State<SaveOutfitPage> createState() => _SaveOutfitPageState();
}

class _SaveOutfitPageState extends State<SaveOutfitPage> {
  String? _selectedCategory;
  bool _saveAsTodayOutfit = false;

  @override
  void initState() {
    super.initState();
    final categories = ClosetService.instance.outfitCategoriesNotifier.value;
    if (widget.isAIRecommendedMode) {
      _selectedCategory = '미니멀';
    } else if (categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }
  }

  void _saveOutfit() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코디 카테고리를 선택하거나 추가해 주세요.')),
      );
      return;
    }

    final clothesList = widget.items.map((i) => i.clothing).toList();

    if (clothesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('캔버스에 등록된 옷이 없습니다.')),
      );
      return;
    }

    final title = widget.isAIRecommendedMode
        ? 'AI 추천 $_selectedCategory 코디 조합'
        : '$_selectedCategory 코디 조합';
    final saveDate = widget.isAIRecommendedMode
        ? DateTime(2026, 6, 6)
        : DateTime.now();

    final newOutfit = SavedOutfit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: _selectedCategory!,
      items: clothesList,
      createdAt: saveDate,
    );

    // Save to ClosetService
    ClosetService.instance.saveOutfit(newOutfit);

    if (_saveAsTodayOutfit) {
      ClosetService.instance.addWornRecord(WornRecord(
        date: saveDate,
        outfit: newOutfit,
        weather: widget.isAIRecommendedMode ? '⛅ 구름조금' : '☀️ 맑음',
        temp: widget.isAIRecommendedMode ? 28 : 25,
      ));
      for (var cloth in clothesList) {
        ClosetService.instance.markAsWorn(cloth);
      }
    }

    widget.onRefresh?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _saveAsTodayOutfit
                    ? '✨ [$title] 저장 및 오늘의 룩으로 등록되었습니다!'
                    : '✨ [$title]이 성공적으로 저장되었습니다!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

    if (widget.isAIRecommendedMode) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      Navigator.pop(context); // Pop SaveOutfitPage
      Navigator.pop(context); // Pop CodiMakerPage
    }
  }

  void _showAddCategoryDialog() {
    String? selectedNewCat;
    final List<String> presetOptions = const [
      '시티보이', '고프코어', '댄디', 'Y2K', '페미닌', '클래식', '빈티지', '오피스룩', '홈웨어'
    ];
    final currentCategories = ClosetService.instance.outfitCategoriesNotifier.value;
    final availableOptions = presetOptions.where((opt) => !currentCategories.contains(opt)).toList();

    if (availableOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 프리셋 카테고리가 이미 추가되었습니다.')),
      );
      return;
    }

    selectedNewCat = availableOptions.first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 카테고리 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableOptions.map((opt) {
                  final isSelected = selectedNewCat == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setDialogState(() {
                          selectedNewCat = opt;
                        });
                      }
                    },
                    selectedColor: const Color(0xFF1A1A1A),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade200),
                    ),
                  );
                }).toList(),
              ),
            );
          }
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedNewCat != null) {
                ClosetService.instance.addOutfitCategory(selectedNewCat!);
                setState(() {
                  _selectedCategory = selectedNewCat;
                });
                Navigator.pop(ctx);
              }
            },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        title: const Text('코디 조합 저장'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('코디 카테고리 선택', style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800)),
                  TextButton.icon(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(Icons.add, size: 14, color: Colors.purple),
                    label: const Text('카테고리 직접 만들기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<List<String>>(
                valueListenable: ClosetService.instance.outfitCategoriesNotifier,
                builder: (context, outfitCategories, child) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: outfitCategories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                        selectedColor: const Color(0xFF1A1A1A),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade200),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),

              const Text('저장할 의류 목록', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.items.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final cloth = widget.items[idx].clothing;
                    return Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: cloth.imageBytes != null
                                ? Image.memory(cloth.imageBytes!, fit: BoxFit.contain)
                                : cloth.assetPath != null
                                    ? Image.asset(cloth.assetPath!, fit: BoxFit.contain)
                                    : Container(
                                        color: cloth.fallbackColor.withValues(alpha: 0.15),
                                        child: Icon(cloth.fallbackIcon, size: 24, color: cloth.fallbackColor),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 60,
                          child: Text(
                            cloth.name,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: CheckboxListTile(
                  title: const Text(
                    '오늘의 룩(착용 기록)으로 바로 등록하기',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                  ),
                  subtitle: const Text(
                    '코디 저장과 동시에 오늘 날짜의 착용 기록에 추가합니다.',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  value: _saveAsTodayOutfit,
                  activeColor: const Color(0xFF1A1A1A),
                  checkColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onChanged: (val) {
                    setState(() {
                      _saveAsTodayOutfit = val ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveOutfit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                  ),
                  child: const Text('코디 조합 저장 완료', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
