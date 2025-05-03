import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodel/healthTracker_viewmodel.dart';
import 'CognitiveTrackerPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'health_grouped_page.dart';
import 'health_page.dart'; // Don't forget to import the intl package for date formatting

class HealthTrackerPage extends StatefulWidget {
  const HealthTrackerPage({super.key});

  @override
  _HealthTrackerPageState createState() => _HealthTrackerPageState();
}

class _HealthTrackerPageState extends State<HealthTrackerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HealthTrackerViewModel>(context, listen: false)
          .fetchActivities(context);
      Provider.of<HealthTrackerViewModel>(context, listen: false)
          .fetchUpcomingAppointmentsCount(context);
      Provider.of<HealthTrackerViewModel>(context, listen: false)
          .fetchCompletedAppointments(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HealthTrackerViewModel>(context);
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          locale.trackingLog,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorPadding: const EdgeInsets.all(2),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white70 : Colors.black87,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: locale.tabCognitive),
                Tab(text: locale.tabOverall),
                Tab(text: locale.tabHealth),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CognitiveTrackerPage(),
          _buildOverallTab(viewModel),
          HealthGroupedPage(),
        ],
      ),
    );
  }

  Widget _buildOverallTab(HealthTrackerViewModel viewModel) {
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localeCode = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.suggestedActivities,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (viewModel.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (viewModel.errorMessage.isNotEmpty)
            Center(
              child: Text(
                viewModel.errorMessage,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            )
          else if (viewModel.activities.isEmpty)
            Center(
              child:
                  Text(locale.noActivities, style: theme.textTheme.bodyMedium),
            )
          else
         Column(
  children: viewModel.activities.map((activity) {
    final title = activity['activity']?.toString().trim() ?? locale.unknownActivity;
    final description = activity['description']?.toString().trim() ?? locale.noDescription;
    return activityCard(title, description);
  }).toList(),
),
          const SizedBox(height: 24),

          // Medication Overview
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        locale.medicationOverview,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 1.3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              color: AppColors.primaryBlue,
                              value: 70,
                              title: '70%',
                              radius: 25,
                              titleStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            PieChartSectionData(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[400]!,
                              value: 30,
                              title: '30%',
                              radius: 25,
                              titleStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        legendCircle(AppColors.primaryBlue),
                        const SizedBox(width: 5),
                        Text(locale.taken),
                        const SizedBox(width: 15),
                        legendCircle(
                            isDark ? Colors.grey[700]! : Colors.grey[400]!),
                        const SizedBox(width: 5),
                        Text(locale.pending),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Appointments
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        locale.upcomingAppointments,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${viewModel.upcomingAppointmentsCount}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Completed appointments
          Text(
            locale.completedAppointments,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildCompletedAppointments(viewModel),
        ],
      ),
    );
  }

  Widget _buildCompletedAppointments(HealthTrackerViewModel viewModel) {
    final theme = Theme.of(context);

    if (viewModel.completedAppointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          AppLocalizations.of(context)!.noCompletedAppointments,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.hintColor,
          ),
        ),
      );
    }

    return Column(
      children: viewModel.completedAppointments.map((appointment) {
        final doctor = appointment['fullName'] ?? "Unknown Doctor";
        final date = appointment['date'] ?? "Unknown Date";
        final formattedTime = _formatDate(date);

        return appointmentCard(doctor, formattedTime, true);
      }).toList(),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      final formatter = DateFormat('yyyy-MM-dd HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      print('Error formatting date: $e');
      return dateStr;
    }
  }

  Widget activityCard(String title, String description) {
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center,
                  color: AppColors.primaryBlue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description.length > 100
                        ? '${description.substring(0, 100)}...'
                        : description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          _showDescriptionDialog(title, description),
                      label: Text(
                        locale.readMore,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDescriptionDialog(String title, String description) {
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          description,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              locale.close,
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget appointmentCard(String doctor, String time,
      [bool isCompleted = false]) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
        title: Text(
          doctor,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          time,
          style: const TextStyle(fontSize: 14),
        ),
        trailing: isCompleted
            ? const Icon(Icons.check_circle,
                color: AppColors.primaryBlue, size: 24)
            : const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget legendCircle(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
