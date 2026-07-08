import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Codi Page (shortcut to CodiMakerPage chooser)
// ──────────────────────────────────────────────
class CodiPage extends StatelessWidget {
  final VoidCallback? onRefresh;
  const CodiPage({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('코디')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('어떤 방법으로 코디를 만들까요?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _codiMethod(context, icon: Icons.open_with, label: '직접 코디 만들기',
                    onTap: () => context.push('/closet/codi-maker')),
                _codiMethod(context, icon: Icons.category_outlined, label: '카테고리별로 고르기', onTap: () {}),
                _codiMethod(context, icon: Icons.layers_outlined, label: '에이클로젯 레이아웃', onTap: () {}),
                _codiMethod(context, icon: Icons.auto_awesome, label: '코디 추천', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _codiMethod(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF333333)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
