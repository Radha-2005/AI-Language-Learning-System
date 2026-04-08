import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/api_client.dart';
import '../../services/tts_service.dart';
import 'path_reveal_screen.dart';

class LevelScreen extends StatefulWidget {
  final String language;
  final String name;

  const LevelScreen({
    super.key,
    required this.language,
    required this.name,
  });

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  String? _level;
  bool _loading = false;

  final List<Map<String, String>> _levels = [
    {
      'id': 'beginner',
      'label': 'Beginner',
      'desc': 'I know very little or nothing',
      'detail': 'Single words · Phonetic guides · Full translations',
      'example': 'e.g.  नमस्ते (na-mas-te) = Hello',
    },
    {
      'id': 'intermediate',
      'label': 'Intermediate',
      'desc': 'I know some basics',
      'detail': 'Phrases and sentences · Key word translations',
      'example': 'e.g.  आप कैसे हैं? = How are you?',
    },
    {
      'id': 'advanced',
      'label': 'Advanced',
      'desc': 'I can hold a conversation',
      'detail': 'Paragraphs · No translations · Cultural context',
      'example': 'e.g.  Full paragraph practice',
    },
  ];

  Future<void> _continue() async {
    if (_level == null) return;
    setState(() => _loading = true);

    try {
      final result = await ApiClient.setupUser(
        name: widget.name,
        language: widget.language,
        level: _level!,
        goal: 'conversational',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', result['user_id']);
      await prefs.setString('user_name', widget.name);
      await prefs.setString('language', widget.language);
      await prefs.setString('level', _level!);

      await TtsService.init(widget.language);

      if (!mounted) return;

      // Goes to PathRevealScreen which shows the 7-day plan
      // PathRevealScreen then has a button that goes to HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PathRevealScreen(
            userId: result['user_id'],
            language: widget.language,
            level: _level!,
            goal: 'conversational',
          ),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // ── Use SingleChildScrollView to fix overflow ──
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32),

              // Personalised greeting
              Text(
                'Hi ${widget.name}!',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "What's your level?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The AI adapts content difficulty to match you',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Level cards
              ..._levels.map(
                (l) => GestureDetector(
                  onTap: () => setState(() => _level = l['id']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _level == l['id']
                          ? AppColors.primaryLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _level == l['id']
                            ? AppColors.primary
                            : AppColors.border,
                        width: _level == l['id'] ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l['label']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _level == l['id']
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l['desc']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l['detail']!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                l['example']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_level == l['id'])
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 22,
                          )
                        else
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.border,
                                width: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Step indicator — step 3 of 3 (all filled)
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_level == null || _loading) ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Build my learning path',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}