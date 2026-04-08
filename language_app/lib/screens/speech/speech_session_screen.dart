import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants.dart';
import '../../core/api_client.dart';
import '../../models/plan_model.dart';
import '../../models/session_model.dart';
import '../../services/tts_service.dart';
import 'result_screen.dart';

class SpeechSessionScreen extends StatefulWidget {
  final String userId;
  final String language;

  const SpeechSessionScreen({
    super.key,
    required this.userId,
    required this.language,
  });

  @override
  State<SpeechSessionScreen> createState() => _SpeechSessionScreenState();
}

class _SpeechSessionScreenState extends State<SpeechSessionScreen> {
  // flutter_sound recorder
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderReady = false;

  // Session state
  List<PracticeItem> _items = [];
  String _planId = '';
  String _topic = '';
  String _contentType = '';
  int _currentIndex = 0;
  bool _loadingSession = true;
  bool _recording = false;
  bool _scoring = false;
  String? _recordingPath;
  WordScore? _lastScore;
  List<Map<String, dynamic>> _sessionScores = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadSession();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    TtsService.stop();
    super.dispose();
  }

  // ── Initialise recorder once ──────────────────────────
  Future<void> _initRecorder() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _errorMessage =
            'Microphone permission is required to record your voice.';
        _loadingSession = false;
      });
      return;
    }

    await _recorder.openRecorder();
    setState(() => _recorderReady = true);
  }

  // ── Load today's content from backend ────────────────
  Future<void> _loadSession() async {
    try {
      final data = await ApiClient.getTodaySession(widget.userId);

      if (data['items'] == null || (data['items'] as List).isEmpty) {
        setState(() {
          _loadingSession = false;
          _errorMessage = data['message'] ?? 'No content available today.';
        });
        return;
      }

      final items = (data['items'] as List)
          .map((i) => PracticeItem.fromJson(i))
          .toList();

      setState(() {
        _items = items;
        _planId = data['plan_id'] ?? '';
        _topic = data['topic'] ?? '';
        _contentType = data['content_type'] ?? 'word';
        _loadingSession = false;
      });

      // Auto-play first item after short delay
      await Future.delayed(const Duration(milliseconds: 700));
      _playCurrentItem();
    } catch (e) {
      setState(() {
        _loadingSession = false;
        _errorMessage = 'Could not connect to server. Is the backend running?';
      });
    }
  }

  // ── Play current item via TTS ─────────────────────────
  void _playCurrentItem() {
    if (_currentIndex < _items.length) {
      TtsService.speak(_items[_currentIndex].text);
    }
  }

  // ── Start recording ───────────────────────────────────
  Future<void> _startRecording() async {
    if (!_recorderReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recorder not ready. Please wait.')),
      );
      return;
    }

    // Stop TTS before recording so it doesn't interfere
    await TtsService.stop();

    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/speech_$_currentIndex.aac';

    await _recorder.startRecorder(toFile: _recordingPath, codec: Codec.aacADTS);

    setState(() => _recording = true);
  }

  // ── Stop recording and send to Whisper for scoring ───
  Future<void> _stopAndScore() async {
    if (!_recording) return;

    await _recorder.stopRecorder();
    setState(() {
      _recording = false;
      _scoring = true;
    });

    if (_recordingPath == null) {
      setState(() => _scoring = false);
      return;
    }

    try {
      final result = await ApiClient.scoreWord(
        userId: widget.userId,
        planId: _planId,
        language: widget.language,
        targetText: _items[_currentIndex].text,
        audioPath: _recordingPath!,
      );

      final score = WordScore.fromJson(result);
      setState(() {
        _lastScore = score;
        _scoring = false;
      });

      // Save this word's score for session summary
      _sessionScores.add({
        'text': _items[_currentIndex].text,
        'score': score.score,
      });
    } catch (e) {
      setState(() => _scoring = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Scoring error: $e')));
    }
  }

  // ── Move to next item or finish session ───────────────
  Future<void> _next() async {
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
        _lastScore = null;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      _playCurrentItem();
    } else {
      await _finishSession();
    }
  }

  Future<void> _finishSession() async {
    try {
      final result = await ApiClient.completeSession(
        userId: widget.userId,
        planId: _planId,
        language: widget.language,
        topic: _topic,
        wordScores: _sessionScores,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            result: SessionResult.fromJson(result),
            language: widget.language,
            userId: widget.userId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save session: $e')));
    }
  }

  // ── Retry — remove last score and try again ───────────
  void _retry() {
    if (_sessionScores.isNotEmpty) {
      _sessionScores.removeLast();
    }
    setState(() => _lastScore = null);
    _playCurrentItem();
  }

  // ── Score colour helpers ──────────────────────────────
  Color _scoreColor(double s) {
    if (s >= 0.80) return AppColors.success;
    if (s >= 0.55) return AppColors.warning;
    return AppColors.error;
  }

  String _scoreEmoji(double s) {
    if (s >= 0.80) return '⭐';
    if (s >= 0.55) return '👍';
    return '💪';
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loadingSession) return _buildLoading();
    if (_errorMessage != null) return _buildError();

    final item = _items[_currentIndex];
    final completedProgress = _sessionScores.length / _items.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _showExitDialog,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _topic.replaceAll('_', ' '),
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${widget.language[0].toUpperCase()}${widget.language.substring(1)}'
              ' · ${_currentIndex + 1} of ${_items.length}',
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_sessionScores.length / _items.length * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: completedProgress,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),

          Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            '${_sessionScores.length} of ${_items.length} completed',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // ── Word / phrase / sentence card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Topic badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _topic.replaceAll('_', ' '),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Main Hindi/Marathi text
                        Text(
                          item.text,
                          style: const TextStyle(
                            fontSize: 40,
                            color: AppColors.textPrimary,
                            height: 1.3,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Transliteration
                        if (item.transliteration.isNotEmpty)
                          Text(
                            item.transliteration,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                        // Translation
                        if (item.translation.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.translation,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Listen again button
                        GestureDetector(
                          onTap: _playCurrentItem,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.volume_up,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Tap to hear again',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
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

                  // ── Score result card ──
                  if (_lastScore != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _scoreColor(
                            _lastScore!.score,
                          ).withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(_lastScore!.score * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: _scoreColor(_lastScore!.score),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _scoreEmoji(_lastScore!.score),
                                style: const TextStyle(fontSize: 26),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _lastScore!.feedback,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          if (_lastScore!.heard.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'You said: "${_lastScore!.heard}"',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  const Spacer(),

                  // ── Bottom action area ──
                  if (_scoring)
                    const Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 10),
                        Text(
                          'Analysing your pronunciation...',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  else if (_lastScore == null)
                    _MicButton(
                      recording: _recording,
                      onTap: _recording ? _stopAndScore : _startRecording,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _retry,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '🔄 Try again',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _currentIndex < _items.length - 1
                                  ? 'Next →'
                                  : 'Finish ✓',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Exit confirmation dialog ──────────────────────────
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave session?'),
        content: const Text('Your progress in this session will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading screen ────────────────────────────────────
  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 20),
            Text(
              'Preparing your practice...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              'AI is generating personalised content',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error screen ──────────────────────────────────────
  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Practice', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loadingSession = true;
                    _errorMessage = null;
                  });
                  _initRecorder();
                  _loadSession();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mic button widget ─────────────────────────────────
class _MicButton extends StatelessWidget {
  final bool recording;
  final VoidCallback onTap;

  const _MicButton({required this.recording, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          recording ? 'Recording... tap to stop' : 'Tap the mic and speak',
          style: const TextStyle(fontSize: 13, color: AppColors.textHint),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: recording ? 84 : 76,
            height: recording ? 84 : 76,
            decoration: BoxDecoration(
              color: recording ? AppColors.error : AppColors.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (recording ? AppColors.error : AppColors.accent)
                      .withOpacity(0.4),
                  blurRadius: recording ? 24 : 14,
                  spreadRadius: recording ? 6 : 0,
                ),
              ],
            ),
            child: Icon(
              recording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ],
    );
  }
}
