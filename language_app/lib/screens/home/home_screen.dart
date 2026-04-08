import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_client.dart';
import '../../models/session_model.dart';
import '../speech/speech_session_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await ApiClient.getDashboard(widget.userId);
      setState(() {
        _data = DashboardData.fromJson(raw);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _scoreColor(double s) {
    if (s >= 0.8) return AppColors.success;
    if (s >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () { setState(() => _loading = true); _load(); },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final plan = _data!.weekPlan;
    // Today is the first pending day
    final todayPlan = plan.firstWhere(
      (p) => !p.isDone,
      orElse: () => plan.isNotEmpty ? plan.last : PlanDaySummary(
        dayNumber: 0,
        scheduledDate: '',
        module: '',
        topic: '',
        contentType: '',
        status: 'done',
      ),
    );
    final hasTodayTask = !todayPlan.isDone && todayPlan.module.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Header
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Hello, ${_data!.userName} 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          _statPill('🔥 ${_data!.streak} days'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _statPill('⭐ ${_data!.totalXp} XP'),
                          const SizedBox(width: 8),
                          _statPill(
                              '📊 ${_data!.level[0].toUpperCase()}${_data!.level.substring(1)}'),
                          const SizedBox(width: 8),
                          _statPill(
                              '🇮🇳 ${AppStrings.languages[_data!.language] ?? _data!.language}'),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Today's task
                      const Text(
                        "Today's practice",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (hasTodayTask)
                        _TodayCard(
                          plan: todayPlan,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SpeechSessionScreen(
                                  userId: widget.userId,
                                  language: _data!.language,
                                ),
                              ),
                            );
                            _load(); // refresh after session
                          },
                        )
                      else
                        _AllDoneCard(),

                      // Recent scores strip
                      if (_data!.recentScores.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        const Text(
                          'Recent sessions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: _data!.recentScores
                              .take(5)
                              .map((s) => Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.border),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '${(s.score * 100).toInt()}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: _scoreColor(s.score),
                                            ),
                                          ),
                                          Text(
                                            s.module.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textHint),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],

                      // This week plan
                      const SizedBox(height: 28),
                      const Text(
                        'This week',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...plan.map((p) => _WeekRow(plan: p)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statPill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      );
}

class _TodayCard extends StatelessWidget {
  final PlanDaySummary plan;
  final VoidCallback onTap;

  const _TodayCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFAECE7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('🎤', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Speak: ${plan.topicDisplay}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${plan.contentType} practice · Tap to start',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success),
      ),
      child: const Row(
        children: [
          Text('🎉', style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All done for today!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF065F46),
                  ),
                ),
                Text(
                  'Come back tomorrow for your next session',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final PlanDaySummary plan;

  const _WeekRow({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: plan.isDone
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: plan.isDone
                  ? const Icon(Icons.check,
                      size: 14, color: AppColors.success)
                  : Text(
                      '${plan.dayNumber}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.topicDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: plan.isDone
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  plan.contentType,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          if (plan.scheduledDate.isNotEmpty)
            Text(
              plan.scheduledDate,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textHint),
            ),
        ],
      ),
    );
  }
}