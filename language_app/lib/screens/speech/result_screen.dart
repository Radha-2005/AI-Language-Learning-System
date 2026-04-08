import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/session_model.dart';
import '../home/home_screen.dart';

class ResultScreen extends StatelessWidget {
  final SessionResult result;
  final String language;
  final String userId;

  const ResultScreen({
    super.key,
    required this.result,
    required this.language,
    required this.userId,
  });

  Color get _scoreColor {
    if (result.sessionScore >= 0.8) return AppColors.success;
    if (result.sessionScore >= 0.55) return AppColors.warning;
    return AppColors.error;
  }

  String get _scoreLabel {
    if (result.sessionScore >= 0.8) return 'Excellent!';
    if (result.sessionScore >= 0.55) return 'Good effort!';
    return 'Keep practising!';
  }

  String get _scoreEmoji {
    if (result.sessionScore >= 0.8) return '🏆';
    if (result.sessionScore >= 0.55) return '⭐';
    return '💪';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (result.sessionScore * 100).toInt();
    final level = result.levelUpdate;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // ── Score circle ──
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: result.sessionScore,
                      strokeWidth: 12,
                      backgroundColor: AppColors.border,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_scoreColor),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _scoreEmoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                _scoreLabel,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _scoreColor,
                ),
              ),

              const SizedBox(height: 6),
              Text(
                '+${result.xpEarned} XP earned',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textHint),
              ),

              // ── Level up card ──
              if (level.changed) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level.direction == 'up'
                                  ? 'Level up!'
                                  : 'Content adjusted',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF065F46),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              level.message,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Not enough data message ──
              if (!level.changed &&
                  level.message.contains('more session')) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          level.message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Weak areas ──
              if (result.weakAreas.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Needs more practice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...result.weakAreas.map(
                  (w) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Text('🔁',
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Text(
                          w,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '— will appear in next session',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // ── Action buttons ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(userId: userId),
                      ),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
}