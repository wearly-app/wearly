import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:front/features/user/closet/models/clothing_item.dart';
import 'package:front/features/user/closet/services/closet_service.dart';
import 'package:front/features/user/closet/pages/save_outfit_page.dart';

// Codi Maker Page (Free Canvas)
// ──────────────────────────────────────────────
class CodiMakerPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  final bool isAIRecommendedMode;
  final List<ClothingItem>? initialClothes;

  const CodiMakerPage({
    super.key,
    this.onRefresh,
    this.isAIRecommendedMode = false,
    this.initialClothes,
  });

  @override
  State<CodiMakerPage> createState() => _CodiMakerPageState();
}

class _CodiMakerPageState extends State<CodiMakerPage> {
  final List<CanvasItem> _items = [];
  String? _selectedId;
  final bool _isPortrait = true; // 3:4 vs 1:1
  String _selectedCategory = '전체';
  final List<String> _categories = const [
    '전체',
    '상의',
    '하의',
    '아우터',
    '원피스',
    '신발',
    '가방',
    '기타'
  ];

  // AI weather simulation states
  String? _activeRescueDay;
  bool _isAIComputing = false;
  int _scenarioClickCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isAIRecommendedMode) {
      _activeRescueDay = '6/6';
      _scenarioClickCount = 1; // 6/6 completed state simulation
    }

    if (widget.initialClothes != null && widget.initialClothes!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final canvasW = MediaQuery.of(context).size.width - 40;
        final canvasH = _isPortrait ? canvasW * 4 / 3 : canvasW;
        const baseSize = 120.0;

        setState(() {
          for (int i = 0; i < widget.initialClothes!.length; i++) {
            final clothing = widget.initialClothes![i];
            final isTop = clothing.category == '상의' || i == 0;
            const scaleVal = 1.3;
            final itemSize = baseSize * scaleVal + 40;
            final topOffset = isTop
                ? (canvasH - itemSize) / 2 - 100
                : (canvasH - itemSize) / 2 + 15;
            final leftOffset = (canvasW - itemSize) / 2;

            _items.add(CanvasItem(
              id: (DateTime.now().millisecondsSinceEpoch + i).toString(),
              clothing: clothing,
              position: Offset(leftOffset, topOffset),
              scale: scaleVal,
            ));
          }
          if (_items.isNotEmpty) {
            _selectedId = _items.first.id;
          }
        });

        if (widget.isAIRecommendedMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '✨ AI 코디 추천: 선택하신 스마트 구출 코디 조합 2벌이 배치되었습니다!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    } else if (widget.isAIRecommendedMode) {
      final wardrobe = ClosetService.instance.wardrobeNotifier.value;
      final cropItem = wardrobe.firstWhere(
        (i) => i.id == '3',
        orElse: () => wardrobe[0],
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addRescuedItem(cropItem);
      });
    }
  }

  void _addItem(ClothingItem clothing) {
    setState(() {
      _items.add(CanvasItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clothing: clothing,
        position: Offset(80 + _items.length * 20.0, 80 + _items.length * 20.0),
        scale: 1.6,
      ));
    });
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    setState(() {
      _items.removeWhere((i) => i.id == _selectedId);
      _selectedId = null;
    });
  }

  void _flipSelected() {
    if (_selectedId == null) return;
    setState(() {
      final idx = _items.indexWhere((i) => i.id == _selectedId);
      if (idx != -1) _items[idx].isFlipped = !_items[idx].isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canvasW = MediaQuery.of(context).size.width - 40;
    final canvasH = _isPortrait ? canvasW * 4 / 3 : canvasW;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F0F0),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SaveOutfitPage(
                  items: _items,
                  onRefresh: widget.onRefresh,
                  isAIRecommendedMode:
                      widget.isAIRecommendedMode || _activeRescueDay != null,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('다음',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Container(
                width: canvasW,
                height: canvasH,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    if (widget.isAIRecommendedMode)
                      _buildWeatherTimeline(canvasW),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedId = null),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ..._items
                                .where((i) => i.id != _selectedId)
                                .map((item) => _buildCanvasItem(item)),
                            ..._items
                                .where((i) => i.id == _selectedId)
                                .map((item) => _buildCanvasItem(item)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildWardrobePicker(),
        ],
      ),
    );
  }

  Widget _buildCanvasItem(CanvasItem item) {
    final isSelected = item.id == _selectedId;
    const baseSize = 120.0;

    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onTap: () => setState(() => _selectedId = item.id),
        onPanUpdate: (d) {
          setState(() {
            item.position = item.position + d.delta;
            _selectedId = item.id;
          });
        },
        child: SizedBox(
          width: baseSize * item.scale + 40,
          height: baseSize * item.scale + 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 20,
                top: 20,
                child: Transform(
                  alignment: Alignment.center,
                  transform: item.isFlipped
                      ? Matrix4.diagonal3Values(-1.0, 1.0, 1.0)
                      : Matrix4.identity(),
                  child: SizedBox(
                    width: baseSize * item.scale,
                    height: baseSize * item.scale,
                    child: item.clothing.imageBytes != null
                        ? Image.memory(item.clothing.imageBytes!,
                            fit: BoxFit.contain)
                        : item.clothing.imageUrl?.isNotEmpty == true
                            ? Image.network(
                                item.clothing.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  item.clothing.fallbackIcon,
                                  size: baseSize * item.scale * 0.5,
                                  color: item.clothing.fallbackColor,
                                ),
                              )
                            : item.clothing.assetPath != null
                                ? Image.asset(item.clothing.assetPath!,
                                    fit: BoxFit.contain)
                                : Container(
                                    decoration: BoxDecoration(
                                      color: item.clothing.fallbackColor
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(item.clothing.fallbackIcon,
                                        size: baseSize * item.scale * 0.5,
                                        color: item.clothing.fallbackColor),
                                  ),
                  ),
                ),
              ),
              if (isSelected) ...[
                Positioned(
                  left: 0,
                  top: 0,
                  child: _controlBtn(
                    onTap: _flipSelected,
                    child: const Icon(Icons.flip,
                        size: 14, color: Color(0xFF1A1A1A)),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: _controlBtn(
                    onTap: _deleteSelected,
                    child: const Icon(Icons.delete_outline,
                        size: 14, color: Color(0xFF1A1A1A)),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: (d) {
                      setState(() {
                        final delta = (d.delta.dx + d.delta.dy) / 200;
                        item.scale = (item.scale + delta).clamp(0.4, 3.0);
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4)
                        ],
                      ),
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: const Icon(Icons.open_in_full,
                            size: 14, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlBtn({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: child,
      ),
    );
  }

  Widget _buildWardrobePicker() {
    final wardrobe = ClosetService.instance.wardrobeNotifier.value;
    final filteredWardrobe = _selectedCategory == '전체'
        ? wardrobe
        : wardrobe.where((item) => item.category == _selectedCategory).toList();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = _categories[i];
                  final sel = c == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(c,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF666666))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: filteredWardrobe.isEmpty
                  ? Center(
                      child: Text('해당 카테고리에 옷이 없습니다.',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13)),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredWardrobe.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final item = filteredWardrobe[i];
                        return GestureDetector(
                          onTap: () => _addItem(item),
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (item.imageBytes != null ||
                                    item.imageUrl?.isNotEmpty == true ||
                                    item.assetPath != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: item.imageBytes != null
                                          ? Image.memory(item.imageBytes!,
                                              fit: BoxFit.cover)
                                          : item.imageUrl?.isNotEmpty == true
                                              ? Image.network(
                                                  item.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Icon(
                                                    item.fallbackIcon,
                                                    color: item.fallbackColor,
                                                  ),
                                                )
                                              : Image.asset(item.assetPath!,
                                                  fit: BoxFit.cover),
                                    ),
                                  )
                                else
                                  Icon(item.fallbackIcon,
                                      size: 36, color: item.fallbackColor),
                                const SizedBox(height: 4),
                                Text(item.brand,
                                    style: const TextStyle(
                                        fontSize: 9, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis),
                                Text(item.name,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherTimeline(double canvasW) {
    String dateStr = '6/6 (오늘)';
    String tempStr = '28°C ⛅';
    String weatherDesc = '구름조금';

    if (_activeRescueDay == '6/6' || _activeRescueDay == '6/6_28') {
      dateStr = '6/6 (오늘)';
      tempStr = '28°C ⛅';
      weatherDesc = '구름조금';
    } else if (_activeRescueDay == '6/7' || _activeRescueDay == '6/7_21') {
      dateStr = '6/7 (내일)';
      tempStr = '21°C 🌧️';
      weatherDesc = '비/흐림';
    } else if (_activeRescueDay == '6/8' || _activeRescueDay == '6/8_27') {
      dateStr = '6/8 (모레)';
      tempStr = '27°C ☀️';
      weatherDesc = '맑음 (초여름)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  tempStr.contains('☀️')
                      ? Icons.wb_sunny
                      : (tempStr.contains('⛅')
                          ? Icons.wb_cloudy_outlined
                          : Icons.cloudy_snowing),
                  size: 18,
                  color: tempStr.contains('☀️')
                      ? Colors.orange
                      : (tempStr.contains('⛅') ? Colors.amber : Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$dateStr 날씨 정보',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$tempStr · $weatherDesc',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _triggerDayWarpScenario,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF3F51B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 6),
                      const Text(
                        'AI 추천: 날씨 맞춤 방치 의류 구출!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerDayWarpScenario() {
    if (_isAIComputing) return;

    final List<int> tempScenario = const [28, 21, 27];
    final temp = tempScenario[_scenarioClickCount % tempScenario.length];
    final currentStep = _scenarioClickCount % tempScenario.length;

    setState(() {
      _scenarioClickCount++;
    });

    ClothingItem targetItem;
    String statusMsg = '';
    String snackBarMsg = '';
    String dayId = '';

    final wardrobe = ClosetService.instance.wardrobeNotifier.value;

    if (currentStep == 0) {
      targetItem = wardrobe.firstWhere(
        (i) => i.id == '3',
        orElse: () => wardrobe[2],
      );
      dayId = '6/6_28';
      statusMsg = 'AI가 오늘의 기온(28°C) 분석 중';
      snackBarMsg = '✨ AI 구출 완료: 6월 6일(28°C 구름조금) 맞춤 다이브인 크롭티가 구출되었습니다!';
    } else if (currentStep == 1) {
      targetItem = wardrobe.firstWhere(
        (i) => i.id == '5',
        orElse: () => wardrobe[4],
      );
      dayId = '6/7_21';
      statusMsg = 'AI가 내일의 저온 기온(21°C, 비) 분석 중';
      snackBarMsg = '🌧️ AI 구출 완료: 6월 7일(21°C 비/쌀쌀함) 맞춤 서피스 데님이 구출되었습니다!';
    } else {
      targetItem = wardrobe.firstWhere(
        (i) => i.name.contains('연청'),
        orElse: () => ClothingItem(
          id: '8_temp',
          name: '스트레이트 데님 (연청)',
          category: '하의',
          brand: '유니클로',
          assetPath: 'assets/uniqlo_straight.png',
          fallbackColor: const Color(0xFFADD8E6),
          fallbackIcon: Icons.checkroom,
          seasons: const ['봄', '여름', '가을'],
          situation: const ['데일리'],
          thickness: 2,
          colorHex: '#ADD8E6',
          styleLevel: 2,
          wearCount: 0,
        ),
      );
      dayId = '6/8_27';
      statusMsg = 'AI가 모레의 초여름 기온(27°C) 분석 중';
      snackBarMsg = '☀️ AI 구출 완료: 6월 8일(27°C 맑음) 맞춤 유니클로 연청 데님이 구출되었습니다!';
    }

    _showAIStylistDialog(
      dayId: dayId,
      item: targetItem,
      initialStatus: statusMsg,
      successMessage: snackBarMsg,
      temp: temp,
    );
  }

  void _showAIStylistDialog({
    required String dayId,
    required ClothingItem item,
    required String initialStatus,
    required String successMessage,
    required int temp,
  }) {
    setState(() {
      _isAIComputing = true;
    });

    int dotCount = 0;
    Timer? dotTimer;
    String statusText = initialStatus;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            dotTimer ??= Timer.periodic(const Duration(milliseconds: 400), (_) {
              if (ctx.mounted) {
                setDialogState(() {
                  dotCount = (dotCount + 1) % 4;
                });
              }
            });

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 2.0 * math.pi),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                              colors: [Colors.transparent, Color(0xFF1A1A1A)]),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.auto_awesome,
                              size: 22, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('AI 스타일리스트',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('$statusText${'.' * dotCount}',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 700), () {
      statusText = '옷장에서 최저 방치 의류 분석 중';
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      statusText = '방치 의류 구출 완료! 캔버스 팝업 중';
    });

    Future.delayed(const Duration(milliseconds: 2200), () {
      dotTimer?.cancel();
      navigator.pop(); // Close dialog

      setState(() {
        _activeRescueDay = dayId;
        _items.clear();
        _selectedId = null;
        _isAIComputing = false;
      });

      _addRescuedItem(item);

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  successMessage,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _addRescuedItem(ClothingItem clothing) {
    const baseSize = 120.0;
    final canvasW = MediaQuery.of(context).size.width - 40;
    final canvasH = _isPortrait ? canvasW * 4 / 3 : canvasW;
    const scaleVal = 1.3;
    final itemSize = baseSize * scaleVal + 40;
    final centerX = (canvasW - itemSize) / 2;
    final centerY = (canvasH - itemSize) / 2 - 40;

    setState(() {
      _items.add(CanvasItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clothing: clothing,
        position: Offset(centerX, centerY),
        scale: scaleVal,
      ));
      _selectedId = _items.last.id;
    });
  }
}
