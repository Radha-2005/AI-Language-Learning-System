import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6C47FF);
  static const primaryLight = Color(0xFFF0EBFF);
  static const accent = Color(0xFFFF6B35);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const dark = Color(0xFF1A1A2E);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const background = Color(0xFFF8F4FF);
  static const surface = Colors.white;
}

class AppStrings {
  static const appName = 'BhashaSikho';

  static const languages = {
    'hindi': 'Hindi',
    'marathi': 'Marathi',
    'english': 'English',
  };

  static const languageNative = {
    'hindi': 'हिंदी',
    'marathi': 'मराठी',
    'english': 'English',
  };

  static const languageSpeakers = {
    'hindi': '600M+ speakers',
    'marathi': '83M+ speakers',
    'english': 'Global language',
  };

  static const levels = {
    'beginner': 'Beginner',
    'intermediate': 'Intermediate',
    'advanced': 'Advanced',
  };

  static const levelDesc = {
    'beginner': 'I know very little or nothing',
    'intermediate': 'I know some basics',
    'advanced': 'I can hold a conversation',
  };

  static const levelDetail = {
    'beginner': 'Single words, phonetic guides, full translations',
    'intermediate': 'Phrases and sentences, key word translations',
    'advanced': 'Paragraphs, no translations, cultural context',
  };

  static const goals = {
    'conversational': 'I want to speak it',
    'full_literacy': 'Full literacy',
    'script': 'Learn the script',
  };

  static const goalDesc = {
    'conversational': 'Focus on pronunciation and conversation',
    'full_literacy': 'Read, write and speak fluently',
    'script': 'Master Devanagari letters and spelling',
  };

  static String hintText(String language) {
    switch (language) {
      case 'hindi':
        return 'हिंदी में जवाब दें...';
      case 'marathi':
        return 'मराठीत उत्तर द्या...';
      default:
        return 'Reply in English...';
    }
  }
}