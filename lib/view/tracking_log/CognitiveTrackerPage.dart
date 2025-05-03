import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import 'MemoryMatchPage.dart';
import 'MSNQTestPage.dart';
import 'ChartDetailPage.dart';
import 'auditifwordGame.dart';
import 'wordGame.dart';
import 'package:pim/viewmodel/healthTracker_viewmodel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CognitiveTrackerPage extends StatefulWidget {
  const CognitiveTrackerPage({super.key});

  @override
  _CognitiveTrackerPageState createState() => _CognitiveTrackerPageState();
}

class _CognitiveTrackerPageState extends State<CognitiveTrackerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTestAvailability());
  }

  Future<void> _checkTestAvailability() async {
    final viewModel = Provider.of<HealthTrackerViewModel>(context, listen: false);
    try {
      await viewModel.checkQuestionnaireAvailability();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorCheckingTest} ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HealthTrackerViewModel>(context);
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTestSection(viewModel, theme, locale),
              const SizedBox(height: 24),
              _buildGameSection(theme, locale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestSection(HealthTrackerViewModel viewModel, ThemeData theme, AppLocalizations locale) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final unlocked = !viewModel.isTestLocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MS Neuropsychological Questionnaire (MSNQ)',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: unlocked
                ? _buildResponsiveButton(
                    text: locale.takeTestNow,
                    icon: Icons.play_arrow,
                    onPressed: () => _startTest(context),
                    color: theme.colorScheme.primary,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locale.testLockedUntil),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.nextAvailableDate != null
                            ? DateFormat.yMMMMEEEEd(locale.localeName).format(viewModel.nextAvailableDate!)
                            : locale.nextMonday,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildResponsiveButton(
                        text: locale.testLocked,
                        icon: Icons.lock,
                        onPressed: () => _showTestLockedDialog(viewModel, locale),
                        color: theme.disabledColor,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }

  void _startTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MSNQTestPage(),
        settings: RouteSettings(arguments: {
          'onComplete': () async {
            final viewModel = Provider.of<HealthTrackerViewModel>(context, listen: false);
            await viewModel.checkQuestionnaireAvailability();
            if (mounted) setState(() {});
          },
        }),
      ),
    );
  }

  void _showTestLockedDialog(HealthTrackerViewModel viewModel, AppLocalizations locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.testLocked),
        content: Text(
          '${locale.takeTestNow} ${viewModel.nextAvailableDate != null
              ? DateFormat.yMMMMEEEEd(locale.localeName).format(viewModel.nextAvailableDate!)
              : locale.nextMonday}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.ok),
          ),
        ],
      ),
    );
  }

  Widget _buildGameSection(ThemeData theme, AppLocalizations locale) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(locale.cognitiveGames, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildGameCard(theme: theme, title: locale.memoryMatch, imagePath: 'assets/memgame.png', buttonText: locale.playMemoryGame, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryMatchPage())), width: width * 0.45),
              const SizedBox(width: 12),
              _buildGameCard(theme: theme, title: locale.wordGame, imagePath: 'assets/wordgame.png', buttonText: locale.playWordGame, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WordGamePage())), width: width * 0.45),
              const SizedBox(width: 12),
              _buildGameCard(theme: theme, title: locale.shapeGame, imagePath: 'assets/shapegame.png', buttonText: locale.playShapeGame, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuditifWordGame())), width: width * 0.45),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard({
  required ThemeData theme,
  required String title,
  required String imagePath,
  required String buttonText,
  required VoidCallback onPressed,
  required double width,
}) {
  return SizedBox(
    width: width,
    height: 250,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      splashColor: theme.colorScheme.primary.withOpacity(0.2),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryBlue, // ✅ bleu outline
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(imagePath, height: 110, fit: BoxFit.cover),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onPressed,
                        icon: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  
}
