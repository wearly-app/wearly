import 'package:flutter/material.dart';
import 'dart:async';
import 'package:front/features/user/closet/models/clothing_item.dart';
import 'package:front/features/user/closet/services/closet_service.dart';
import 'package:front/features/user/closet/pages/codi_maker_page.dart';

// ──────────────────────────────────────────────
// 1. AI Loading Page (Full page transition)
// ──────────────────────────────────────────────
class AiLoadingPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  final String selectedStyle;
  const AiLoadingPage({super.key, this.onRefresh, this.selectedStyle = '미니멀'});

  @override
  State<AiLoadingPage> createState() => _AiLoadingPageState();
}

class _AiLoadingPageState extends State<AiLoadingPage> {
  int _step = 0;
  Timer? _timer;
  final List<String> _loadingTexts = const [
    "실시간 기온 및 날씨 데이터 분석 중...",
    "옷장 속 장기 미착용 의류 스캔 중...",
    "기온 및 스타일 기반 코디 매칭 중...",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_step < 2) {
          setState(() {
            _step++;
          });
        } else {
          timer.cancel();
          _navigateToResult();
        }
      }
    });
  }

  void _navigateToResult() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationResultPage(
          onRefresh: widget.onRefresh,
          selectedStyle: widget.selectedStyle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 3),
                  builder: (context, val, child) {
                    return Transform.rotate(
                      angle: val * 4 * 3.1415,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [Colors.purple, Colors.blue, Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 32,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  '스마트 AI 스타일링 추천',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    _loadingTexts[_step],
                    key: ValueKey(_step),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / 3.0,
                      minHeight: 4,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation(Colors.purple),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 2. Recommendation Result Page (Garment Swap)
// ──────────────────────────────────────────────
class RecommendationResultPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  final String selectedStyle;
  const RecommendationResultPage({super.key, this.onRefresh, this.selectedStyle = '미니멀'});

  @override
  State<RecommendationResultPage> createState() => _RecommendationResultPageState();
}

class _RecommendationResultPageState extends State<RecommendationResultPage> {
  bool _isAlternativeMain = false;
  bool _isSwapped = false;
  bool _isMainLoading = false;
  bool _isBottomLoading = false;

  late final ClothingItem _uniqloCrewneck;
  late final ClothingItem _uniqloNavy;
  late final ClothingItem _uniqloStraight;
  late final ClothingItem _hatchingroomCurved;

  @override
  void initState() {
    super.initState();
    final wardrobe = ClosetService.instance.wardrobeNotifier.value;
    _uniqloCrewneck = wardrobe.firstWhere((i) => i.id == '4', orElse: () => wardrobe[3]);
    _uniqloNavy = wardrobe.firstWhere((i) => i.id == '15', orElse: () => wardrobe[12]);
    _uniqloStraight = wardrobe.firstWhere(
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
    _hatchingroomCurved = wardrobe.firstWhere((i) => i.id == '7', orElse: () => wardrobe[6]);
  }

  void _triggerMainRescueTargetSwap() {
    if (_isMainLoading) return;
    setState(() {
      _isMainLoading = true;
    });

    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isAlternativeMain = !_isAlternativeMain;
          _isMainLoading = false;
          _isSwapped = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _isAlternativeMain
                      ? '✨ 메인 구출 대상이 유니클로 네이비 크루넥 T로 교체되었습니다.'
                      : '✨ 메인 구출 대상이 유니클로 드라이 크루넥T로 복원되었습니다.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            backgroundColor: Colors.purple.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _triggerBottomGarmentSwap() {
    if (_isBottomLoading) return;
    setState(() {
      _isBottomLoading = true;
    });

    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSwapped = !_isSwapped;
          _isBottomLoading = false;
        });
      }
    });
  }

  void _navigateToCanvas() {
    final mainItem = _isAlternativeMain ? _uniqloNavy : _uniqloCrewneck;
    final bottomItem = _isSwapped ? _hatchingroomCurved : _uniqloStraight;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CodiMakerPage(
          onRefresh: widget.onRefresh,
          isAIRecommendedMode: true,
          initialClothes: [mainItem, bottomItem],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMain = _isAlternativeMain ? _uniqloNavy : _uniqloCrewneck;
    final currentBottom = _isSwapped ? _hatchingroomCurved : _uniqloStraight;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        title: const Text('AI 맞춤 구출 코디 제안'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _triggerMainRescueTargetSwap,
            icon: const Icon(Icons.refresh, size: 14, color: Colors.purple),
            label: const Text(
              '다른 옷 구출하기',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '🛡️ 메인 구출 대상',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.auto_awesome, size: 9, color: Colors.amber),
                                    SizedBox(width: 3),
                                    Text(
                                      '옷장 속 숨은 보석',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFFB45309),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '착용: ${currentMain.wearCount}회',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: _isMainLoading
                              ? const CircularProgressIndicator(color: Colors.purple)
                              : _buildGarmentImage(currentMain),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          _isMainLoading ? '새로운 장기 방치 의류 스캔 중...' : currentMain.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D3142),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Center(
                        child: Text(
                          _isMainLoading ? '' : currentMain.brand,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3F0FF), Color(0xFFEBF5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5DEFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.lightbulb_outline, size: 14, color: Colors.indigo),
                        SizedBox(width: 5),
                        Text(
                          '💡 AI 스타일링 리포트',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '6월 6일 기온(28°C ⛅)과 선택하신 [${widget.selectedStyle}] 스타일에 맞춰 통기성이 좋은 소재와 깔끔한 매칭을 진행했습니다.\n최근 5일간 무지 반팔티 위주로 착용하여 가장 방치된 ${_isAlternativeMain ? "유니클로 네이비 크루넥 T(0회)" : "유니클로 드라이 크루넥T(0회)"}와 오늘 새로 등록될 유니클로 연청 데님을 구출하기 위한 매칭입니다.',
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.4,
                        color: Color(0xFF4A5568),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '👖 AI 추천 매칭 하의',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _isSwapped ? '데일리 스트릿 매치' : '추천 캐주얼 매치',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: _isBottomLoading
                              ? const CircularProgressIndicator(color: Colors.purple)
                              : _buildGarmentImage(currentBottom),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          _isBottomLoading ? '새로운 하의 추천 조합 탐색 중...' : currentBottom.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D3142),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Center(
                        child: Text(
                          _isBottomLoading ? '' : currentBottom.brand,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _triggerBottomGarmentSwap,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('다른 하의 추천받기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(color: Colors.purple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _navigateToCanvas,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '이 조합으로 캔버스 배치하기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGarmentImage(ClothingItem item) {
    if (item.imageBytes != null) {
      return Image.memory(item.imageBytes!, fit: BoxFit.contain);
    } else if (item.assetPath != null) {
      return Image.asset(item.assetPath!, fit: BoxFit.contain);
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.fallbackColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(item.fallbackIcon, size: 48, color: item.fallbackColor),
      );
    }
  }
}
