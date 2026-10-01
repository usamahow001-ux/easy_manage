import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isFirstTime;

  const LanguageSelectionScreen({super.key, this.isFirstTime = false});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late AppLanguage _selectedLanguage;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppStateProvider>();
    _selectedLanguage = provider.language;
  }

  void _onLanguageSelected(AppLanguage lang) {
    setState(() {
      _selectedLanguage = lang;
    });
    // Dynamically update provider so user can see immediate preview
    context.read<AppStateProvider>().setLanguage(lang);
  }

  Future<void> _onContinue() async {
    final provider = context.read<AppStateProvider>();
    await provider.setLanguage(_selectedLanguage);
    await provider.setLanguageSelected(true);

    if (!mounted) return;

    if (widget.isFirstTime) {
      const nextScreen = HomeScreen();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final loc = provider.loc;
    final isDark = provider.isDarkMode;

    String getContinueButtonText() {
      switch (_selectedLanguage) {
        case AppLanguage.urdu:
          return 'آگے بڑھیں  ←';
        case AppLanguage.romanUrdu:
          return 'Aage Barhein  →';
        case AppLanguage.english:
          return 'Continue  →';
      }
    }

    return Scaffold(
      appBar: widget.isFirstTime
          ? null
          : AppBar(
              title: Text(
                loc.tr('select_language'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isFirstTime) const SizedBox(height: 12),
                    // Header Branding
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryGreen, AppTheme.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.translate_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        widget.isFirstTime ? loc.tr('welcome_title') : loc.tr('select_language'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        loc.tr('choose_language_desc'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Language Option 1: English
                    _buildLanguageCard(
                      lang: AppLanguage.english,
                      title: 'English',
                      subtitle: 'English (Default)',
                      sampleTerms: "You'll Give • You'll Get • Cashbook",
                      badgeText: 'English',
                      icon: Icons.language_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),

                    // Language Option 2: Urdu (اردو)
                    _buildLanguageCard(
                      lang: AppLanguage.urdu,
                      title: 'اردو (Urdu)',
                      subtitle: 'اردو رسم الخط',
                      sampleTerms: 'دینے ہیں • لینے ہیں • کیش بک',
                      badgeText: 'اردو',
                      icon: Icons.auto_stories_rounded,
                      isDark: isDark,
                      isUrduFont: true,
                    ),
                    const SizedBox(height: 14),

                    // Language Option 3: Hinglish (Maine Dena Hai)
                    _buildLanguageCard(
                      lang: AppLanguage.romanUrdu,
                      title: 'Hinglish (Maine Dena Hai)',
                      subtitle: 'Maine Dena Hai • Maine Lena Hai',
                      sampleTerms: 'Grahak • Dukandar • Rokad',
                      badgeText: 'Maine Dena Hai',
                      icon: Icons.chat_bubble_outline_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _onContinue,
                  child: Text(
                    getContinueButtonText(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required AppLanguage lang,
    required String title,
    required String subtitle,
    required String sampleTerms,
    required String badgeText,
    required IconData icon,
    required bool isDark,
    bool isUrduFont = false,
  }) {
    final isSelected = _selectedLanguage == lang;

    return GestureDetector(
      onTap: () => _onLanguageSelected(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : (isDark ? AppTheme.darkCardElevated : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.primaryGreen : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sampleTerms,
                      style: isUrduFont
                          ? GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)
                          : GoogleFonts.inter(
                              fontSize: 11,
                              color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
