import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/user/closet/widgets/add_item_sheets.dart';
import 'package:front/features/user/closet/services/closet_service.dart';
import 'package:front/services/api_service.dart';
import 'package:front/features/user/closet/models/recommendation_response.dart';

// Closet Home Page
// ──────────────────────────────────────────────
class ClosetHomePage extends StatefulWidget {
  const ClosetHomePage({super.key});

  @override
  State<ClosetHomePage> createState() => _ClosetHomePageState();
}

class _ClosetHomePageState extends State<ClosetHomePage> {
  final ApiService _apiService = ApiService();
  UserModel? _userProfile;
  RecommendationWeather? _weatherData;
  bool _isWeatherLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    final closetService = ClosetService.instance;
    if (closetService.cachedWeather != null) {
      if (mounted) {
        setState(() {
          _weatherData = closetService.cachedWeather;
          _isWeatherLoading = false;
        });
      }
      return;
    }

    setState(() { _isWeatherLoading = true; });
    // 서울시청 기본 좌표를 통한 추천 날씨 데이터 호출
    final response = await _apiService.getRecommendations(latitude: 37.5665, longitude: 126.9780, style: 'CASUAL', limit: 1);
    if (mounted) {
      setState(() {
        _weatherData = response?.weather;
        closetService.cachedWeather = response?.weather;
        _isWeatherLoading = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await _apiService.getUserProfile();

    if (!mounted) return;

    setState(() {
      _userProfile = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildWeatherSection(context),
              _buildSectionTitle('주요 기능', '전체 보기'),
              _buildMainFeatures(context),
              _buildSectionTitle('스마트 AI 코디 추천', ''),
              _buildAICodiRecommendationFeature(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _userProfile?.name.isNotEmpty == true
                ? '안녕하세요, ${_userProfile!.name}님'
                : '안녕하세요',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 22, color: Colors.grey.shade600),
              const SizedBox(width: 14),
              Icon(Icons.notifications_none_outlined,
                  size: 24, color: Colors.grey.shade600),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => context.push('/home'),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: Icon(Icons.person, size: 18, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection(BuildContext context) {
    if (_isWeatherLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A))),
      );
    }

    if (_weatherData == null) {
      return const SizedBox.shrink();
    }

    final w = _weatherData!;
    Color bgColor1 = const Color(0xFFE3F2FD);
    Color bgColor2 = const Color(0xFFBBDEFB);
    IconData weatherIcon = Icons.wb_sunny_rounded;
    Color iconColor = Colors.orange;
    String weatherText = '맑음';

    if (w.condition.contains('RAIN')) {
      bgColor1 = const Color(0xFFCFD8DC);
      bgColor2 = const Color(0xFF90A4AE);
      weatherIcon = Icons.water_drop_rounded;
      iconColor = Colors.blue.shade700;
      weatherText = '비';
    } else if (w.condition.contains('CLOUDY')) {
      bgColor1 = const Color(0xFFF5F5F5);
      bgColor2 = const Color(0xFFE0E0E0);
      weatherIcon = Icons.cloud_rounded;
      iconColor = Colors.grey.shade600;
      weatherText = '흐림';
    } else if (w.condition.contains('SNOW')) {
      bgColor1 = const Color(0xFFE1F5FE);
      bgColor2 = const Color(0xFFB3E5FC);
      weatherIcon = Icons.ac_unit_rounded;
      iconColor = Colors.lightBlue;
      weatherText = '눈';
    }

    Color dustColor = Colors.green;
    String dustText = '좋음';
    if (w.dustGrade == 'MODERATE') {
      dustColor = Colors.orange;
      dustText = '보통';
    } else if (w.dustGrade == 'BAD') {
      dustColor = Colors.deepOrange;
      dustText = '나쁨';
    } else if (w.dustGrade == 'VERY_BAD') {
      dustColor = Colors.red;
      dustText = '매우 나쁨';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [bgColor1, bgColor2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${w.temperature.toStringAsFixed(1)}°',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D3142),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '체감 ${w.feelsLikeTemperature?.toStringAsFixed(1) ?? w.temperature.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF455A64), // Blue Grey 700
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(weatherIcon, size: 16, color: iconColor),
                          const SizedBox(width: 6),
                          Text(
                            weatherText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 1, height: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text(
                            '미세먼지 $dustText',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: dustColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Icon(
                  weatherIcon,
                  size: 56,
                  color: iconColor.withOpacity(0.8),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherDetailItem(Icons.water_drop_outlined, '습도', '${w.humidity ?? 0}%'),
                  _buildWeatherDetailItem(Icons.air, '풍속', '${w.windSpeed ?? 0}m/s'),
                  _buildWeatherDetailItem(Icons.umbrella_outlined, '강수확률', '${w.maxRainProbability ?? 0}%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          if (action.isNotEmpty)
            Text(
              action,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }

  Widget _buildMainFeatures(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.45,
        children: [
          _featureCard(
            context,
            icon: Icons.add_circle_outline,
            iconColor: const Color(0xFF1E88E5),
            label: '아이템 추가하기',
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => AddItemSourceSheet(onAdded: () {}),
            ),
          ),
          _featureCard(
            context,
            icon: Icons.open_with_rounded,
            iconColor: const Color(0xFFE91E63),
            label: '직접 코디 만들기',
            onTap: () => context.push('/closet/codi-maker'),
          ),
          _featureCard(
            context,
            icon: Icons.style_outlined,
            iconColor: const Color(0xFF8E24AA),
            label: '내 코디',
            onTap: () => context.push('/closet/saved-outfits'),
          ),
          _featureCard(
            context,
            icon: Icons.checkroom_outlined,
            iconColor: const Color(0xFF00ACC1),
            label: '전체 옷관리',
            onTap: () => context.push('/closet/wardrobe'),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(BuildContext context,
      {required IconData icon,
      required Color iconColor,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3142),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAICodiRecommendationFeature(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _showStyleSelectionSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6A1B9A),
                Color(0xFF3F51B5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF6A1B9A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '스마트 AI 코디 추천',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '오늘 날씨와 스타일 취향에 맞춰 내 옷들을 구출해보세요.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStyleSelectionSheet(BuildContext context) {
    String selectedStyle = '캐주얼';
    final List<String> styles = ClosetService.instance.outfitCategoriesNotifier.value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '오늘 어떤 스타일로 입고 싶으세요?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: styles.map((style) {
                        final isSelected = selectedStyle == style;
                        return ChoiceChip(
                          label: Text(style),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() {
                                selectedStyle = style;
                              });
                            }
                          },
                          selectedColor: const Color(0xFF6A1B9A),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: const Color(0xFFF4F4F4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 16, color: Colors.purple.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '💡 선택한 스타일과 오늘 날씨(계절/기온)에 어울리는 옷장 속 방치 의류를 AI가 구출하여 제안합니다.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: Colors.purple.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/closet/ai-recommendation?style=$selectedStyle');
                        },
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
                          '스타일 맞춤 코디 추천받기',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
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
}
