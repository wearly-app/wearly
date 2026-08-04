import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/user/closet/models/clothing_item.dart';
import 'package:front/features/user/closet/services/closet_service.dart';

class CodiCalendarPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const CodiCalendarPage({super.key, this.onRefresh});

  @override
  State<CodiCalendarPage> createState() => _CodiCalendarPageState();
}

class _CodiCalendarPageState extends State<CodiCalendarPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDay = DateTime(year, month, 1);
    final totalDays = DateTime(year, month + 1, 0).day;
    final offset = firstDay.weekday % 7; // Sunday is 0, Monday is 1...
    final totalGridItems = totalDays + offset;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        title: const Text('코디 캘린더'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
            onPressed: () => setState(() {}),
          )
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<WornRecord>>(
          valueListenable: ClosetService.instance.wornHistoryNotifier,
          builder: (context, wornHistory, child) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar Card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              onPressed: () {
                                setState(() {
                                  if (_currentMonth.month == 1) {
                                    _currentMonth =
                                        DateTime(_currentMonth.year - 1, 12);
                                  } else {
                                    _currentMonth = DateTime(_currentMonth.year,
                                        _currentMonth.month - 1);
                                  }
                                });
                              },
                            ),
                            Text(
                              '${_currentMonth.year}년 ${_currentMonth.month}월',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20),
                              onPressed: () {
                                setState(() {
                                  if (_currentMonth.month == 12) {
                                    _currentMonth =
                                        DateTime(_currentMonth.year + 1, 1);
                                  } else {
                                    _currentMonth = DateTime(_currentMonth.year,
                                        _currentMonth.month + 1);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const ['일', '월', '화', '수', '목', '금', '토']
                              .map((day) {
                            final isWeekend = day == '일' || day == '토';
                            return SizedBox(
                              width: 32,
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isWeekend
                                      ? (day == '일'
                                          ? const Color(0xFFEF5350)
                                          : const Color(0xFF42A5F5))
                                      : const Color(0xFF9E9E9E),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 6),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: totalGridItems,
                          itemBuilder: (context, index) {
                            final dayNum = index - offset + 1;
                            if (dayNum < 1 || dayNum > totalDays) {
                              return const SizedBox();
                            }

                            final currentDate = DateTime(year, month, dayNum);
                            final isSelected = _selectedDate.day == dayNum &&
                                _selectedDate.month == month &&
                                _selectedDate.year == year;

                            final hasRecord = wornHistory.any((r) =>
                                r.date.year == year &&
                                r.date.month == month &&
                                r.date.day == dayNum);

                            final hasRescue = wornHistory.any((r) =>
                                r.date.year == year &&
                                r.date.month == month &&
                                r.date.day == dayNum &&
                                r.outfit.title.contains('AI'));

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = currentDate;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1A1A1A)
                                      : (hasRescue
                                          ? const Color(0xFFE8EAF6)
                                          : (hasRecord
                                              ? const Color(0xFFF3E5F5)
                                              : Colors.transparent)),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: const Color(0xFF1A1A1A))
                                      : (hasRescue
                                          ? Border.all(
                                              color: const Color(0xFFC5CAE9),
                                              width: 1.5)
                                          : (hasRecord
                                              ? Border.all(
                                                  color:
                                                      const Color(0xFFE1BEE7),
                                                  width: 1.5)
                                              : null)),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dayNum.toString(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : (hasRescue
                                                  ? const Color(0xFF1A237E)
                                                  : (hasRecord
                                                      ? const Color(0xFF4A148C)
                                                      : const Color(
                                                          0xFF333333))),
                                        ),
                                      ),
                                      if (hasRecord && !isSelected)
                                        Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            color: hasRescue
                                                ? Colors.indigo
                                                : Colors.purple,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.timeline,
                            size: 20, color: Color(0xFF1A1A1A)),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedDate.month}월 ${_selectedDate.day}일 착용 코디',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A)),
                        ),
                      ],
                    ),
                  ),

                  _buildTimelineContent(wornHistory),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimelineContent(List<WornRecord> wornHistory) {
    final records = wornHistory
        .where((r) =>
            r.date.year == _selectedDate.year &&
            r.date.month == _selectedDate.month &&
            r.date.day == _selectedDate.day)
        .toList();

    if (records.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Icon(Icons.edit_calendar_outlined,
                  size: 24, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 8),
            Text(
              '이 날짜에 기록된 코디가 없습니다.',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => context.push('/closet/codi-maker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 12),
              label: const Text('코디 만들고 착용 기록하기',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: records.map((record) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: record.outfit.title.contains('AI')
                          ? Colors.indigo
                          : Colors.purple,
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
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
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      record.outfit.category,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                  ),
                                  if (record.outfit.title.contains('AI')) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8EAF6),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.indigo.shade200,
                                            width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.auto_awesome,
                                              size: 10, color: Colors.indigo),
                                          const SizedBox(width: 3),
                                          Text(
                                            'AI 구출',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigo.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    record.weather,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${record.temp}°C',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: record.temp >= 25
                                          ? Colors.orange.shade700
                                          : Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: record.outfit.items.map((cloth) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey.shade200),
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: cloth.imageBytes != null
                                              ? Image.memory(cloth.imageBytes!,
                                                  fit: BoxFit.contain)
                                              : cloth.imageUrl != null
                                                  ? Image.network(
                                                      cloth.imageUrl!,
                                                      fit: BoxFit.contain)
                                                  : cloth.assetPath != null
                                                      ? Image.asset(
                                                          cloth.assetPath!,
                                                          fit: BoxFit.contain)
                                                      : Container(
                                                      color: cloth.fallbackColor
                                                          .withValues(
                                                              alpha: 0.15),
                                                      child: Icon(
                                                          cloth.fallbackIcon,
                                                          size: 14,
                                                          color: cloth
                                                              .fallbackColor),
                                                    ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cloth.brand,
                                            style: const TextStyle(
                                                fontSize: 8,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(
                                            width: 80,
                                            child: Text(
                                              cloth.name,
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      const Color(0xFF333333)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
