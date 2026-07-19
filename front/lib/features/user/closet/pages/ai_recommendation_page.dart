import 'package:flutter/material.dart';
import 'dart:async';
import 'package:front/features/user/closet/models/clothing_item.dart';
import 'package:front/features/user/closet/services/closet_service.dart';
import 'package:front/features/user/closet/services/recommendation_service.dart';
import 'package:front/features/user/closet/pages/codi_maker_page.dart';
import 'package:front/services/api_service.dart';

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
    "실시간 기온 및 날씨 조건 요청 중...",
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
                        colors: [
                          Colors.purple,
                          Colors.blue,
                          Colors.transparent
                        ],
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
  const RecommendationResultPage(
      {super.key, this.onRefresh, this.selectedStyle = '미니멀'});

  @override
  State<RecommendationResultPage> createState() =>
      _RecommendationResultPageState();
}

class _RecommendationResultPageState extends State<RecommendationResultPage> {
  static const double _demoTemperature = 28;
  static const double _demoLatitude = 37.2636;
  static const double _demoLongitude = 127.0286;
  final RecommendationService _recommendationService =
      const RecommendationService();
  final ApiService _apiService = ApiService();
  bool _isMainLoading = false;
  bool _isBottomLoading = false;
  bool _isApiLoading = true;
  bool _usingServerRecommendations = false;
  int _mainIndex = 0;
  int _bottomIndex = 0;
  double _currentTemperature = _demoTemperature;
  String _weatherCondition = '⛅';
  String? _apiErrorMessage;
  late List<ClothingRecommendation> _mainRecommendations;
  late List<ClothingRecommendation> _bottomRecommendations;

  @override
  void initState() {
    super.initState();
    final wardrobe = ClosetService.instance.wardrobeNotifier.value;
    _mainRecommendations = _recommendationService.rank(
      wardrobe: wardrobe,
      category: '상의',
      temperature: _demoTemperature,
      selectedStyle: widget.selectedStyle,
    );
    _bottomRecommendations = _recommendationService.rank(
      wardrobe: wardrobe,
      category: '하의',
      temperature: _demoTemperature,
      selectedStyle: widget.selectedStyle,
    );
    _loadServerRecommendations();
  }

  Future<void> _loadServerRecommendations() async {
    final response = await _apiService.getRecommendations(
      latitude: _demoLatitude,
      longitude: _demoLongitude,
      style: _styleApiValue(widget.selectedStyle),
    );

    if (!mounted) return;
    if (response == null) {
      setState(() {
        _isApiLoading = false;
        _apiErrorMessage = '서버 추천을 불러오지 못해 로컬 추천을 표시합니다.';
      });
      return;
    }
    if (response.recommendations.isEmpty) {
      setState(() {
        _isApiLoading = false;
        _currentTemperature = response.weather.temperature;
        _weatherCondition = _weatherLabel(response.weather.condition);
        _apiErrorMessage = '추천 API 연결은 성공했지만 서버 추천 결과가 아직 비어 있어 '
            '로컬 추천을 표시합니다.';
      });
      return;
    }

    final tops = <String, ClothingRecommendation>{};
    final bottoms = <String, ClothingRecommendation>{};

    for (final outfit in response.recommendations) {
      for (final recommended in outfit.clothes) {
        final item = recommended.toClothingItem();
        final neglectedDays = item.lastWornDate == null
            ? (90 - (item.wearCount * 12)).clamp(30, 90)
            : DateTime.now()
                .difference(item.lastWornDate!)
                .inDays
                .clamp(0, 3650);
        final recommendation = ClothingRecommendation(
          item: item,
          totalScore: outfit.score,
          neglectedDays: neglectedDays,
          neglectScore: 0,
          weatherScore: 0,
          styleScore: 0,
        );
        final target = item.category == '상의'
            ? tops
            : item.category == '하의'
                ? bottoms
                : null;
        if (target != null &&
            (target[item.id] == null ||
                target[item.id]!.totalScore < recommendation.totalScore)) {
          target[item.id] = recommendation;
        }
      }
    }

    final rankedTops = tops.values.toList()
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    final rankedBottoms = bottoms.values.toList()
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    if (rankedTops.isEmpty || rankedBottoms.isEmpty) {
      setState(() {
        _isApiLoading = false;
        _apiErrorMessage = '서버 응답에 상의 또는 하의가 없어 로컬 추천을 표시합니다.';
      });
      return;
    }

    setState(() {
      _mainRecommendations = rankedTops;
      _bottomRecommendations = rankedBottoms;
      _mainIndex = 0;
      _bottomIndex = 0;
      _currentTemperature = response.weather.temperature;
      _weatherCondition = _weatherLabel(response.weather.condition);
      _usingServerRecommendations = true;
      _isApiLoading = false;
      _apiErrorMessage = null;
    });
  }

  String _styleApiValue(String style) {
    const values = {
      '캐주얼': 'CASUAL',
      '미니멀': 'MINIMAL',
      '스트릿': 'STREET',
      '스포티': 'SPORTY',
      '격식': 'FORMAL',
      '아메카지': 'VINTAGE',
      '데이트': 'CASUAL',
    };
    return values[style] ?? 'CASUAL';
  }

  String _weatherLabel(String condition) {
    const labels = {
      'CLEAR': '☀️',
      'CLOUDS': '⛅',
      'RAIN': '🌧️',
      'SNOW': '❄️',
      'THUNDERSTORM': '⛈️',
      'DRIZZLE': '🌦️',
      'MIST': '🌫️',
      'FOG': '🌫️',
    };
    return labels[condition] ?? '🌤️';
  }

  String _recommendationReport(
    ClothingRecommendation main,
    ClothingRecommendation bottom,
  ) {
    if (_usingServerRecommendations) {
      return '서버 실시간 추천 · 현재 기온 '
          '(${_currentTemperature.toStringAsFixed(1)}°C $_weatherCondition)과 '
          '[${widget.selectedStyle}] 스타일을 반영했습니다.\n'
          '${main.item.name}: 방치 약 ${main.neglectedDays}일 · 서버 추천 점수 '
          '${main.totalScore.toStringAsFixed(0)}점\n'
          '${bottom.item.name}: 방치 약 ${bottom.neglectedDays}일 · 서버 추천 점수 '
          '${bottom.totalScore.toStringAsFixed(0)}점';
    }

    return '로컬 시연 추천 · 기온(${_demoTemperature.toInt()}°C ⛅)과 '
        '[${widget.selectedStyle}] 스타일을 반영했습니다.\n'
        '${main.item.name}: 방치 ${main.neglectedDays}일 · 방치 '
        '${main.neglectScore.toStringAsFixed(0)} + 날씨 '
        '${main.weatherScore.toStringAsFixed(0)} + 스타일 '
        '${main.styleScore.toStringAsFixed(0)} = '
        '${main.totalScore.toStringAsFixed(0)}점\n'
        '${bottom.item.name}: 방치 ${bottom.neglectedDays}일 · 총 '
        '${bottom.totalScore.toStringAsFixed(0)}점';
  }

  void _triggerMainRescueTargetSwap() {
    if (_isMainLoading) return;
    setState(() {
      _isMainLoading = true;
    });

    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _mainIndex = (_mainIndex + 1) % _mainRecommendations.length;
          _isMainLoading = false;
          _bottomIndex = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  '✨ 다음 방치 의류 ${_mainRecommendations[_mainIndex].item.name}을(를) 추천합니다.',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            backgroundColor: Colors.purple.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          _bottomIndex = (_bottomIndex + 1) % _bottomRecommendations.length;
          _isBottomLoading = false;
        });
      }
    });
  }

  void _navigateToCanvas() {
    final mainItem = _mainRecommendations[_mainIndex].item;
    final bottomItem = _bottomRecommendations[_bottomIndex].item;

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
    final currentMainRecommendation = _mainRecommendations[_mainIndex];
    final currentBottomRecommendation = _bottomRecommendations[_bottomIndex];
    final currentMain = currentMainRecommendation.item;
    final currentBottom = currentBottomRecommendation.item;

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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        size: 9, color: Colors.amber),
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
                              ? const CircularProgressIndicator(
                                  color: Colors.purple)
                              : _buildGarmentImage(currentMain),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          _isMainLoading
                              ? '새로운 장기 방치 의류 스캔 중...'
                              : currentMain.name,
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
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 14, color: Colors.indigo),
                        const SizedBox(width: 5),
                        const Text(
                          '💡 AI 스타일링 리포트',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.indigo,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _isApiLoading
                              ? '서버 연결 중'
                              : _usingServerRecommendations
                                  ? '서버 추천'
                                  : '로컬 추천',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: _usingServerRecommendations
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isApiLoading
                          ? '서버 추천 API를 요청하고 있습니다. 응답 전까지 로컬 추천을 표시합니다.'
                          : '${_apiErrorMessage == null ? '' : '$_apiErrorMessage\n'}${_recommendationReport(currentMainRecommendation, currentBottomRecommendation)}',
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                            '${widget.selectedStyle} · ${currentBottomRecommendation.totalScore.toStringAsFixed(0)}점',
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
                              ? const CircularProgressIndicator(
                                  color: Colors.purple)
                              : _buildGarmentImage(currentBottom),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          _isBottomLoading
                              ? '새로운 하의 추천 조합 탐색 중...'
                              : currentBottom.name,
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
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
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
    } else if (item.imageUrl?.isNotEmpty == true) {
      return Image.network(
        item.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackGarment(item),
      );
    } else if (item.assetPath != null) {
      return Image.asset(
        item.assetPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackGarment(item),
      );
    } else {
      return _buildFallbackGarment(item);
    }
  }

  Widget _buildFallbackGarment(ClothingItem item) {
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
