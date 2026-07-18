import 'package:flutter/material.dart';
import 'dart:async';

class AILoadingDialog extends StatefulWidget {
  const AILoadingDialog({super.key});

  @override
  State<AILoadingDialog> createState() => _AILoadingDialogState();
}

class _AILoadingDialogState extends State<AILoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _dotCount = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      setState(() => _dotCount = (_dotCount + 1) % 4);
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _dotTimer?.cancel();
      Navigator.of(context).pop();
      showDialog(context: context, builder: (_) => const AIResultDialog());
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _ctrl,
              child: Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [Colors.transparent, Color(0xFF1A1A1A)]),
                ),
                child: Container(
                  margin: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, size: 22, color: Color(0xFF1A1A1A)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('AI 스타일리스트',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('오늘의 코디 분석 중${'.' * _dotCount}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class AIResultDialog extends StatelessWidget {
  const AIResultDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI 코디 추천',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        Text('격식 레벨 3 · 18°C 흐린 날',
                            style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _row(Icons.dry_cleaning, '상의', '크림 린넨 셔츠', 'ZARA', '가볍고 포멀한 느낌'),
                  const Divider(height: 18, color: Color(0xFFF0F0F0)),
                  _row(Icons.straighten, '하의', '블랙 슬랙스', 'COS', '격식감을 높여주는 핏'),
                  const Divider(height: 18, color: Color(0xFFF0F0F0)),
                  _row(Icons.checkroom, '아우터', '카키 트렌치코트', 'MANGO', '흐린 날씨 대비'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('다시 추천',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A1A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: const Text('캔버스 적용',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String name, String brand, String note) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: const Color(0xFF555555)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Text('$brand · $note',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
          child: Text('✓ 보유',
              style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
