import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_client.dart';
import '../../models/session_model.dart';
import '../home/home_screen.dart';

class PathRevealScreen extends StatefulWidget {
  final String userId;
  final String language;
  final String level;
  final String goal;

  const PathRevealScreen({
    super.key,
    required this.userId,
    required this.language,
    required this.level,
    required this.goal,
  });

  @override
  State<PathRevealScreen> createState() => _PathRevealScreenState();
}

class _PathRevealScreenState extends State<PathRevealScreen>
    with SingleTickerProviderStateMixin {
  DashboardData? _data;
  bool _loading = true;
  String? _error;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _loadPlan();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    try {
      final raw = await ApiClient.getDashboard(widget.userId);
      setState(() {
        _data = DashboardData.fromJson(raw);
        _loading = false;
      });
      _animController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Module mix based on goal
  List<Map<String, dynamic>> _getModuleMix() {
    switch (widget.goal) {
      case 'full_literacy':
        return [
          {
            'module': 'Story',
            'pct': '40%',
            'icon': '📖',
            'color': const Color(0xFF534AB7),
          },
          {
            'module': 'Writing',
            'pct': '35%',
            'icon': '✍️',
            'color': const Color(0xFFBA7517),
          },
          {
            'module': 'Speech',
            'pct': '25%',
            'icon': '🎤',
            'color': const Color(0xFF993C1D),
          },
        ];
      case 'script':
        return [
          {
            'module': 'Writing',
            'pct': '60%',
            'icon': '✍️',
            'color': const Color(0xFFBA7517),
          },
          {
            'module': 'Story',
            'pct': '25%',
            'icon': '📖',
            'color': const Color(0xFF534AB7),
          },
          {
            'module': 'Speech',
            'pct': '15%',
            'icon': '🎤',
            'color': const Color(0xFF993C1D),
          },
        ];
      default: // conversational
        return [
          {
            'module': 'Speech',
            'pct': '60%',
            'icon': '🎤',
            'color': const Color(0xFF993C1D),
          },
          {
            'module': 'Story',
            'pct': '30%',
            'icon': '📖',
            'color': const Color(0xFF534AB7),
          },
          {
            'module': 'Writing',
            'pct': '10%',
            'icon': '✍️',
            'color': const Color(0xFFBA7517),
          },
        ];
    }
  }

  String get _levelLabel {
    switch (widget.level) {
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return 'Beginner';
    }
  }

  String get _languageLabel {
    return AppStrings.languages[widget.language] ?? widget.language;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  // ── Loading state ─────────────────────────────────────
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
          SizedBox(height: 24),
          Text(
            'Building your personalised path...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'AI is generating your first week of content',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ───────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white60, size: 52),
            const SizedBox(height: 16),
            Text(
              'Could not load your plan\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadPlan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try again',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main content ──────────────────────────────────────
  Widget _buildContent() {
    final plan = _data?.weekPlan ?? [];
    final mix = _getModuleMix();

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              // ── Trophy icon ──
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text('🎯', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Heading ──
              const Text(
                'Your path is ready!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'AI built a 7-day $_languageLabel plan\nbased on your level and goal',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // ── Level badge ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Level: $_levelLabel  ·  Language: $_languageLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Section label ──
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your learning mix',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Module mix cards ──
              ...mix.map(
                (m) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Module icon circle
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (m['color'] as Color).withOpacity(0.75),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            m['icon'],
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Module name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m['module']} practice',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _moduleDesc(m['module']),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Percentage
                      Text(
                        m['pct'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Week plan preview ──
              if (plan.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'This week',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...plan.take(7).toList().asMap().entries.map(
                      (entry) => _WeekRow(
                        day: entry.value,
                        isToday: entry.key == 0,
                      ),
                    ),
              ],

              const SizedBox(height: 32),

              // ── Start button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(userId: widget.userId),
                      ),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start learning  →',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Skip link ──
              GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(userId: widget.userId),
                    ),
                    (_) => false,
                  );
                },
                child: const Text(
                  'Go to dashboard',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white54,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white38,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _moduleDesc(String module) {
    switch (module) {
      case 'Speech':
        return 'Pronunciation · Listening · Speaking';
      case 'Story':
        return 'Reading · Vocabulary · Comprehension';
      case 'Writing':
        return 'Script · Spelling · Characters';
      default:
        return '';
    }
  }
}

// ── Week row widget ───────────────────────────────────
class _WeekRow extends StatelessWidget {
  final PlanDaySummary day;
  final bool isToday;

  const _WeekRow({required this.day, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isToday
            ? Colors.white.withOpacity(0.22)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Day circle
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.white
                  : Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${day.dayNumber}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isToday ? AppColors.primary : Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Topic name
          Expanded(
            child: Text(
              day.topicDisplay,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isToday ? Colors.white : Colors.white70,
              ),
            ),
          ),

          // Content type pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day.contentType,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white60,
              ),
            ),
          ),

          // Today label
          if (isToday) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}