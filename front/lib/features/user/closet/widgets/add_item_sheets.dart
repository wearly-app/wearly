import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:front/features/user/closet/models/clothing_item.dart';
import 'package:front/features/user/closet/services/closet_service.dart';
import 'package:front/features/user/closet/pages/wardrobe_page.dart';
import 'package:front/services/api_service.dart';

// ──────────────────────────────────────────────
// Add Item Source Sheet (Acloset style)
// ──────────────────────────────────────────────
class AddItemSourceSheet extends StatelessWidget {
  final VoidCallback onAdded;
  const AddItemSourceSheet({super.key, required this.onAdded});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 22),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            size: 18, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text('아이템 설명',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14)),
                        const Spacer(),
                        Icon(Icons.camera_alt_outlined,
                            size: 18, color: Colors.grey.shade500),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.help_outline, size: 22, color: Colors.grey.shade500),
              ],
            ),
            const SizedBox(height: 12),
            const Text('직접 추가',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _sourceItem(
                    context,
                    Icons.photo_library_outlined,
                    '앨범',
                    onTap: () => _pickImage(context, ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _sourceItem(
                    context,
                    Icons.camera_alt_outlined,
                    '카메라',
                    onTap: () => _pickImage(context, ImageSource.camera),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceItem(BuildContext context, IconData icon, String label,
      {bool filled = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 26,
                color: filled ? Colors.white : const Color(0xFF333333)),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: filled ? Colors.white : const Color(0xFF333333))),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    if (context.mounted) {
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => AddItemProcessSheet(
          imageFile: picked,
          onAdded: onAdded,
        ),
      );
    }
  }
}

// ──────────────────────────────────────────────
// Add Item Process Sheet (rembg / Google Lens sim)
// ──────────────────────────────────────────────
class AddItemProcessSheet extends StatefulWidget {
  final XFile? imageFile;
  final VoidCallback onAdded;
  const AddItemProcessSheet({
    super.key,
    this.imageFile,
    required this.onAdded,
  });

  @override
  State<AddItemProcessSheet> createState() => _AddItemProcessSheetState();
}

class _AddItemProcessSheetState extends State<AddItemProcessSheet> {
  static int _currentIndex = 0; // Simulation counter
  int _step = 1; // 1=loading, 2=done
  double _progress = 0.0;
  String _loadingText = 'AI가 의류 배경을 분리하고 스마트 분석을 준비 중입니다...';

  // Processed results
  Uint8List? _inputBytes;
  Uint8List? _processedBytes;
  String? _analyzedImageKey;
  String? _analyzedImageUrl;
  String _extractedColorHex = '#FFFFFF';
  String? _aiExtractedColorHex;
  bool _isRembgActive = false;
  bool _isLocalServer = false;
  String _serverStatus = '배경 분리 완료';
  bool _isAnalyzingImage = false;
  bool _isSaving = false;

  // Simulated AI tag analysis states
  bool _isAiAnalyzed = false;
  int _setIndex = 0;
  String _extractedMaterial = '';
  double _cloSliderValue = 1.0; // 1.0 to 5.0 discrete slider values

  // Form controllers & fields
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  String _selectedCategory = '상의';
  final List<String> _selectedSeasons = [];
  final List<String> _selectedSituations = ['캐주얼'];
  int _styleLevel = 2; // 1 ~ 5

  final List<String> _categories = const [
    '상의',
    '하의',
    '아우터',
    '원피스',
    '신발',
    '가방',
    '기타'
  ];
  final List<String> _seasons = const ['봄', '여름', '가을', '겨울'];
  final List<String> _styles = const [
    '캐주얼',
    '미니멀',
    '스트릿',
    '아메카지',
    '스포티',
    '격식',
    '데이트'
  ];

  // Standard colors preset for user manual overrides
  final List<Map<String, dynamic>> _presetColors = [
    {'name': '블랙', 'hex': '#000000', 'color': Colors.black},
    {'name': '화이트', 'hex': '#FFFFFF', 'color': Colors.white},
    {'name': '그레이', 'hex': '#808080', 'color': Colors.grey},
    {'name': '레드', 'hex': '#FF3B30', 'color': Colors.red},
    {'name': '블루', 'hex': '#007AFF', 'color': Colors.blue},
    {'name': '그린', 'hex': '#34C759', 'color': Colors.green},
    {'name': '옐로우', 'hex': '#FFCC00', 'color': Colors.yellow},
    {'name': '베이지', 'hex': '#F5F5DC', 'color': const Color(0xFFF5F5DC)},
    {'name': '브라운', 'hex': '#A52A2A', 'color': Colors.brown},
    {'name': '네이비', 'hex': '#000080', 'color': const Color(0xFF000080)},
    {'name': '핑크', 'hex': '#FF2D55', 'color': Colors.pink},
    {'name': '카키', 'hex': '#4B5320', 'color': const Color(0xFF4B5320)},
  ];

  @override
  void initState() {
    super.initState();
    _initImagesAndProcess();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _materialCtrl.dispose();
    super.dispose();
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

  Future<void> _initImagesAndProcess() async {
    if (widget.imageFile != null) {
      final bytes = await widget.imageFile!.readAsBytes();
      if (mounted) {
        setState(() {
          _inputBytes = bytes;
        });
        _processImage(bytes);
      }
    }
  }

  String _getCloStageText(double value) {
    int stage = value.toInt();
    switch (stage) {
      case 1:
        return '매우 시원함 (한여름용)';
      case 2:
        return '가볍고 산뜻함 (늦봄/초여름용)';
      case 3:
        return '적당한 포근함 (봄/가을용)';
      case 4:
        return '따뜻함 (늦가을/초겨울용)';
      case 5:
        return '매우 따뜻함 (한겨울 방한용)';
      default:
        return '';
    }
  }

  double _getCloValueFromSlider(double value) {
    int stage = value.toInt();
    switch (stage) {
      case 1:
        return 0.15;
      case 2:
        return 0.45;
      case 3:
        return 0.65;
      case 4:
        return 1.0;
      case 5:
        return 1.6;
      default:
        return 0.15;
    }
  }

  Future<void> _processImage(Uint8List inputBytes) async {
    if (!mounted) return;
    setState(() {
      _progress = 0.05;
      _loadingText = 'AI가 의류 배경을 분리하고 스마트 분석을 준비 중입니다...';
    });

    // Start a timer to animate progress up to 90% in-flight
    Timer? progressTimer;
    progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_progress < 0.90) {
          _progress += 0.02;
        } else {
          timer.cancel();
        }
      });
    });

    try {
      final apiService = ApiService();
      final result = await apiService.analyzeClothingImage(widget.imageFile!);
      progressTimer.cancel();

      if (result != null && mounted) {
        setState(() {
          _progress = 1.0;
        });

        final imageKey = result['imageKey'] as String?;
        final imageUrl = result['imageUrl'] as String?;

        if (imageKey == null || imageKey.isEmpty) {
          throw StateError('분석 응답에 imageKey가 없습니다.');
        }

        // Map Category
        final mappedCategory = switch (result['category'] as String?) {
          'TOP' => '상의',
          'BOTTOM' => '하의',
          'OUTER' => '아우터',
          'ONEPIECE' => '원피스',
          'SHOES' => '신발',
          'BAG' => '가방',
          _ => '기타',
        };

        // Map Style
        final mappedStyle = switch (result['style'] as String?) {
          'MINIMAL' => '미니멀',
          'STREET' => '스트릿',
          'SPORTY' => '스포티',
          'FORMAL' => '격식',
          'VINTAGE' => '데이트',
          _ => '캐주얼',
        };

        // Convert HSV to Hex Color
        final h = result['colorH'] as int? ?? 0;
        final s = result['colorS'] as int? ?? 0;
        final v = result['colorV'] as int? ?? 100;
        final color = HSVColor.fromAHSV(
                1.0, h.toDouble(), s.toDouble() / 100.0, v.toDouble() / 100.0)
            .toColor();
        final hexColor =
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

        final brand = result['brand'] as String? ?? '';
        final material = result['material'] as String? ?? '';
        final thickness = result['thickness'] as int? ?? 2;

        // Map thickness to CLO Slider value (1.0 to 5.0 discrete)
        double mappedSliderValue = 3.0; // 봄/가을용
        if (thickness == 1) {
          mappedSliderValue = 1.0;
        } else if (thickness == 3) {
          mappedSliderValue = 5.0;
        }

        setState(() {
          _analyzedImageKey = imageKey;
          _analyzedImageUrl = imageUrl;
          _processedBytes = null;
          _isRembgActive = true;
          _isLocalServer = true;
          _serverStatus = 'AI 분석 완료 (배경 제거 & 속성 추출 성공)';

          final name = result['name'] as String? ?? '';
          _brandCtrl.text = brand;
          _nameCtrl.text = name.isNotEmpty
              ? name
              : (brand.isNotEmpty ? '$brand $mappedCategory' : mappedCategory);
          _extractedColorHex = hexColor;
          _selectedCategory = mappedCategory;
          _extractedMaterial = material;
          _materialCtrl.text = material;
          _cloSliderValue = mappedSliderValue;
          _isAiAnalyzed = true;

          // Map Seasons
          _selectedSeasons.clear();
          if (thickness == 1) {
            _selectedSeasons.add('여름');
          } else if (thickness == 3) {
            _selectedSeasons.add('겨울');
          } else {
            _selectedSeasons.addAll(const ['봄', '가을']);
          }

          // Map Situation
          _selectedSituations.clear();
          _selectedSituations.add(mappedStyle);
        });

        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _step = 2;
          });
        }
      } else {
        setState(() {
          _progress = 1.0;
          _processedBytes = inputBytes;
          _serverStatus = 'AI 분석 실패 (기본 설정)';
          _step = 2;
        });
      }
    } catch (e) {
      print('Error during image analysis: $e');
      progressTimer.cancel();
      setState(() {
        _progress = 1.0;
        _processedBytes = inputBytes;
        _serverStatus = 'AI 분석 중 에러 발생';
        _step = 2;
      });
    }
  }

  Future<void> _simulateAiAnalysis() async {
    if (_inputBytes != null) {
      await _processImage(_inputBytes!);
    }
  }

  Future<void> _analyzeImageWithAI() async {
    await _simulateAiAnalysis();
  }

  Future<void> _saveItem() async {
    if (_isSaving) return;

    final imageKey = _analyzedImageKey;
    if (imageKey == null || imageKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('분석된 이미지 키가 없습니다. 이미지를 다시 분석해주세요.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // 1. Prepare data for backend API
    final backendCategory = switch (_selectedCategory) {
      '하의' => 'BOTTOM',
      '아우터' => 'OUTER',
      '원피스' => 'ONEPIECE',
      '신발' => 'SHOES',
      '가방' => 'BAG',
      '기타' => 'ACCESSORY',
      _ => 'TOP',
    };

    String backendStyle = 'CASUAL';
    if (_selectedSituations.isNotEmpty) {
      backendStyle = switch (_selectedSituations.first) {
        '미니멀' => 'MINIMAL',
        '스트릿' => 'STREET',
        '스포티' => 'SPORTY',
        '격식' => 'FORMAL',
        '데이트' => 'VINTAGE',
        _ => 'CASUAL',
      };
    }

    final color = _parseHexColor(_extractedColorHex);
    final hsv = HSVColor.fromColor(color);

    final itemData = {
      'name': _nameCtrl.text.trim(),
      'category': backendCategory,
      'style': backendStyle,
      'imageKey': imageKey,
      'colorH': hsv.hue.toInt(),
      'colorS': (hsv.saturation * 100).toInt(),
      'colorV': (hsv.value * 100).toInt(),
      'brand': _brandCtrl.text.isEmpty ? 'No Brand' : _brandCtrl.text,
      'material': _materialCtrl.text.isEmpty ? '코튼 100%' : _materialCtrl.text,
      'thickness': _cloSliderValue.toInt() <= 2
          ? 1
          : (_cloSliderValue.toInt() == 3 ? 2 : 3),
      'cloValue': _getCloValueFromSlider(_cloSliderValue),
    };

    // 2. Call API to save to DB
    final apiService = ApiService();
    final created = await apiService.createClothingItem(itemData);

    if (!mounted) return;
    if (created == null) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('옷 저장에 실패했습니다. 잠시 후 다시 시도해주세요.'),
        ),
      );
      return;
    }

    final createdImageUrl = created['imageUrl'] as String?;
    final createdName = created['name'] as String?;
    final lastWornAt = created['lastWornAt'] as String?;

    // 3. Save locally to UI State (ClosetService)
    final item = ClothingItem(
      id: created['id'].toString(),
      name: createdName?.isNotEmpty == true
          ? createdName!
          : (_nameCtrl.text.isEmpty ? '새 아이템' : _nameCtrl.text),
      category: _selectedCategory,
      brand: _brandCtrl.text.isEmpty ? 'No Brand' : _brandCtrl.text,
      imageUrl: createdImageUrl,
      fallbackColor: color,
      fallbackIcon: Icons.dry_cleaning,
      seasons: List<String>.from(_selectedSeasons),
      situation: List<String>.from(_selectedSituations),
      thickness: _cloSliderValue.toInt() <= 2
          ? 1
          : (_cloSliderValue.toInt() == 3 ? 2 : 3),
      colorHex: _extractedColorHex,
      styleLevel: _styleLevel,
      lastWornDate: lastWornAt == null ? null : DateTime.tryParse(lastWornAt),
      wearCount: (created['wearCount'] as num?)?.toInt() ?? 0,
      material: _materialCtrl.text.isEmpty ? '코튼 100%' : _materialCtrl.text,
      clo: _getCloValueFromSlider(_cloSliderValue),
    );

    ClosetService.instance.addClothingItem(item);
    widget.onAdded();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                '✨ 스마트 옷장에 성공적으로 추가되었습니다! 내 옷장으로 이동합니다.',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WardrobePage(onRefresh: widget.onAdded)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _step == 1 ? _buildLoading() : _buildDone(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(28),
      child: Column(
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
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_inputBytes != null)
                    Image.memory(_inputBytes!, fit: BoxFit.cover)
                  else
                    const Center(child: CircularProgressIndicator()),
                  Container(
                    color:
                        Colors.white.withValues(alpha: 0.3 * (1 - _progress)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _loadingText,
              key: ValueKey(_loadingText),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF444444),
                  height: 1.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF1A1A1A)),
            ),
          ),
          const SizedBox(height: 6),
          Text('${(_progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('스마트 아이템 등록',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.grey),
              )
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: _parseHexColor(_extractedColorHex)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _analyzedImageUrl?.isNotEmpty == true
                            ? Image.network(
                                _analyzedImageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _inputBytes != null
                                        ? Image.memory(
                                            _inputBytes!,
                                            fit: BoxFit.contain,
                                          )
                                        : const Icon(Icons.broken_image),
                              )
                            : (_processedBytes != null
                                ? Image.memory(
                                    _processedBytes!,
                                    fit: BoxFit.contain,
                                  )
                                : (_inputBytes != null
                                    ? Image.memory(
                                        _inputBytes!,
                                        fit: BoxFit.contain,
                                      )
                                    : const Center(
                                        child: CircularProgressIndicator(),
                                      ))),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isRembgActive
                              ? Colors.green.shade600
                              : (_isLocalServer
                                  ? Colors.blue.shade600
                                  : Colors.orange.shade600),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isRembgActive
                                  ? Icons.check
                                  : (_isLocalServer
                                      ? Icons.color_lens
                                      : Icons.sync_problem),
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _isRembgActive
                                  ? 'AI 누끼 완료'
                                  : (_isLocalServer ? '색상 추출 완료' : '서버 미연결'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _serverStatus,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _analyzeImageWithAI,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.deepPurple.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.center_focus_strong,
                            size: 14, color: Colors.deepPurple),
                        const SizedBox(width: 6),
                        Text(
                          _isAnalyzingImage
                              ? '이미지 분석 검색 중...'
                              : (_isAiAnalyzed
                                  ? 'AI 분석 정보 다시 찾기'
                                  : '이미지로 AI 상품 정보 자동 찾기'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('아이템 이름',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF4F4F4),
              hintText: '아이템 이름을 직접 입력해주세요',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          const Text('카테고리',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final sel = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        sel ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : const Color(0xFF555555),
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('브랜드',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _brandCtrl,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF4F4F4),
              hintText: '브랜드를 직접 입력해주세요',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          if (_brandCtrl.text.isEmpty && _isAiAnalyzed) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '* 브랜드 크롤링 분석이 제한되어 직접 입력이 필요합니다.',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('소재',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _materialCtrl,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF4F4F4),
              hintText: '소재를 직접 입력해주세요 (예: 코튼 100%)',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          if (_materialCtrl.text.isEmpty && _isAiAnalyzed) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '* 소재 크롤링 분석이 제한되어 직접 입력이 필요합니다.',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('기본 단열 지수(CLO)',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getCloStageText(_cloSliderValue),
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.purple.shade200, width: 0.5),
                    ),
                    child: Text(
                      '${_getCloValueFromSlider(_cloSliderValue)} CLO',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTickMarkColor: const Color(0xFF1A1A1A),
              inactiveTickMarkColor: Colors.grey.shade400,
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: _cloSliderValue,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              activeColor: const Color(0xFF1A1A1A),
              inactiveColor: Colors.grey.shade200,
              onChanged: (val) {
                setState(() {
                  _cloSliderValue = val;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('대표 색상 ',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _parseHexColor(_extractedColorHex),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _extractedColorHex.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
              const SizedBox(width: 8),
              if (_isLocalServer)
                const Text(
                  '(AI 추출)',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final List<Map<String, dynamic>> displayColors = [];
            if (_aiExtractedColorHex != null) {
              final isAiColorInPresets = _presetColors.any((preset) =>
                  preset['hex'].toString().toLowerCase() ==
                  _aiExtractedColorHex!.toLowerCase());
              if (!isAiColorInPresets) {
                displayColors.add({
                  'name': 'AI 추출',
                  'hex': _aiExtractedColorHex!,
                  'color': _parseHexColor(_aiExtractedColorHex!),
                });
              }
            }
            displayColors.addAll(_presetColors);

            return SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: displayColors.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final col = displayColors[i];
                  final isSelected = _extractedColorHex.toLowerCase() ==
                      col['hex'].toString().toLowerCase();
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _extractedColorHex = col['hex']),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: col['color'],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A1A1A)
                              : Colors.grey.shade300,
                          width: isSelected ? 3.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                const BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    spreadRadius: 1)
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: col['color'] == Colors.white
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('계절(공동선택)',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '💡 AI 추천 시 해당 계절에도 코디를 제안받고 싶다면 여러 계절을 함께 선택해 주세요.',
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _seasons.map((season) {
              final isSelected = _selectedSeasons.contains(season);
              return FilterChip(
                label: Text(season),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSeasons.add(season);
                    } else {
                      _selectedSeasons.remove(season);
                    }
                  });
                },
                selectedColor: const Color(0xFF1A1A1A),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: const Color(0xFFF4F4F4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('스타일',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '💡 선택하신 스타일 정보는 AI 코디 추천 시 맞춤형 제안을 위해 활용됩니다.',
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _styles.map((style) {
              final isSelected = _selectedSituations.contains(style);
              return ChoiceChip(
                label: Text(style),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSituations.add(style);
                    } else {
                      if (_selectedSituations.length > 1) {
                        _selectedSituations.remove(style);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('최소 하나의 스타일은 선택해야 합니다.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  });
                },
                selectedColor: const Color(0xFF1A1A1A),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF555555),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: const Color(0xFFF4F4F4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '스마트 옷장에 저장',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
