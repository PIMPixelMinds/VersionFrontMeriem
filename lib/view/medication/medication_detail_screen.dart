import 'package:flutter/material.dart';
import 'package:pim/core/constants/api_constants.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../data/model/medication_models.dart';
import '../../viewmodel/medication_viewmodel.dart';
import 'add_medication_screen.dart';
import 'stock_progress_card.dart';

class MedicationDetailScreen extends StatefulWidget {
  final String medicationId;

  const MedicationDetailScreen(
      {super.key, required this.medicationId}); // Utilisation de super.key

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel =
          Provider.of<MedicationViewModel>(context, listen: false);
      viewModel.getMedicationById(context, widget.medicationId);
      viewModel.fetchMedicationHistory(context, widget.medicationId,
          startDate: _startDate, endDate: _endDate);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final viewModel = Provider.of<MedicationViewModel>(context, listen: false);
    final String id = widget.medicationId;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDarkMode
                ? ColorScheme.dark(
                    primary: AppColors.primaryBlue,
                    onPrimary: Colors.white,
                    surface: Colors.grey[850]!,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primaryBlue,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      viewModel.fetchMedicationHistory(context, id,
          startDate: _startDate, endDate: _endDate);
    }
  }

  void _showDeleteConfirmation() {
    final BuildContext currentContext = context;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          localizations.deleteMedication,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          localizations.deleteMedicationConfirmation,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              localizations.cancel,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final viewModel = Provider.of<MedicationViewModel>(currentContext,
                  listen: false);
              final String id = widget.medicationId;

              Navigator.pop(dialogContext);
              final success =
                  await viewModel.deleteMedication(currentContext, id);

              if (success && mounted) {
                Navigator.pop(currentContext);
              }
            },
            child: Text(localizations.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String getMedicationImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    // Corrige les Ã©ventuels / en double
    return '${ApiConstants.baseUrl}/${imageUrl.replaceFirst(RegExp(r'^/+'), '')}';
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.blue; // couleur fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MedicationViewModel>(context);
    final medication = viewModel.selectedMedication;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Center(
          child: Text(
            localizations.medicationDetails,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddMedicationScreen(medicationId: widget.medicationId),
                ),
              ).then((_) {
                viewModel.getMedicationById(context, widget.medicationId);
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: viewModel.isLoading
          ? Center(child: CircularProgressIndicator())
          : medication == null
              ? Center(
                  child: Text(
                    'Medication not found',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Medication Info Card
                    Container(
                      padding:
                          const EdgeInsets.all(0), // plus de padding externe
                      margin: const EdgeInsets.all(
                          16), // tu peux ajuster le margin si besoin
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.08),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        // PAS de color ici !
                      ),
                      clipBehavior: Clip
                          .antiAlias, // pour respecter le borderRadius sur l'image
                      child: Stack(
                        children: [
                          // Image en fond (arriÃ¨re-plan)
                          if (medication.imageUrl != null &&
                              medication.imageUrl!.isNotEmpty)
                            Positioned.fill(
                              child: Opacity(
                                opacity:
                                    0.15, // transparence image (plus faible = plus visible)
                                child: Image.network(
                                  getMedicationImageUrl(medication.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          // DÃ©gradÃ© couleur PAR-DESSUS l'image
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: medication.color != null &&
                                        medication.color!.isNotEmpty
                                    ? LinearGradient(
                                        colors: [
                                          _parseColor(medication.color!)
                                              .withOpacity(
                                                  0.40), // moins transparent
                                          _parseColor(medication.color!)
                                              .withOpacity(
                                                  0.15), // moins transparent
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          // Contenu de la card (inchangÃ©)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: _getMedicationColor(
                                            medication.medicationType),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: _getMedicationIcon(
                                            medication.medicationType),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            medication.name,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            medication.dosage,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Divider(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[300],
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                    localizations.type,
                                    _getMedicationTypeName(
                                        medication.medicationType),
                                    isDarkMode),
                                _buildInfoRow(localizations.frequency,
                                    _getFrequencyText(medication), isDarkMode),
                                _buildInfoRow(
                                    localizations.timeOfDay,
                                    medication.timeOfDay.join(', '),
                                    isDarkMode),
                                _buildInfoRow(
                                    localizations.mealRelation,
                                    _getMealRelationName(
                                        medication.mealRelation),
                                    isDarkMode),
                                if (medication.notes != null &&
                                    medication.notes!.isNotEmpty)
                                  _buildInfoRow(localizations.notes,
                                      medication.notes!, isDarkMode),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tabs
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primaryBlue,
                      unselectedLabelColor:
                          isDarkMode ? Colors.grey[400] : Colors.grey,
                      indicatorColor: AppColors.primaryBlue,
                      tabs: [
                        Tab(text: localizations.history),
                        Tab(text: localizations.statistics),
                      ],
                    ),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildHistoryTab(viewModel, isDarkMode),
                          _buildStatisticsTab(
                              viewModel, medication, isDarkMode),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(MedicationViewModel viewModel, bool isDarkMode) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Date range selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          // Vous pouvez ajouter ici un sÃ©lecteur de plage de dates si nÃ©cessaire
        ),

        // History list
        Expanded(
          child: viewModel.medicationHistory.isEmpty
              ? Center(
                  child: Text(
                    'No history found for the selected date range',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: viewModel.medicationHistory.length,
                  itemBuilder: (context, index) {
                    final history = viewModel.medicationHistory[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                              history.skipped ? 'skipped' : 'completed'),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: _getStatusIcon(
                              history.skipped ? 'skipped' : 'completed'),
                        ),
                      ),
                      title: Text(
                        DateFormat('EEEE, MMMM d').format(history.takenAt),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        'Scheduled: ${history.scheduledTime} | Taken: ${DateFormat('HH:mm').format(history.takenAt.toLocal())}',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      trailing: Text(
                        _getStatusText(
                            history.skipped ? 'skipped' : 'completed'),
                        style: TextStyle(
                          color: _getStatusColor(
                              history.skipped ? 'skipped' : 'completed'),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab(
      MedicationViewModel viewModel, Medication medication, bool isDarkMode) {
    final localizations = AppLocalizations.of(context)!;
    int total = viewModel.medicationHistory.length;
    int taken = viewModel.medicationHistory.where((h) => !h.skipped).length;
    double adherenceRate = total > 0 ? (taken / total) * 100 : 0;

    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Les deux cards sur la mÃªme ligne
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        localizations.adherenceRate,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: Stack(
                          children: [
                            Center(
                              child: SizedBox(
                                height: 120,
                                width: 120,
                                child: CircularProgressIndicator(
                                  value: adherenceRate / 100,
                                  strokeWidth: 12,
                                  backgroundColor: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    adherenceRate >= 80
                                        ? Colors.green
                                        : adherenceRate >= 50
                                            ? Colors.orange
                                            : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${adherenceRate.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '$taken/$total',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StockProgressCard(medication: medication),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary
          Text(
            localizations.summary,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Summary cards
          Row(
            children: [
              _buildSummaryCard(
                localizations.taken,
                taken.toString(),
                Icons.check_circle,
                Colors.green,
                isDarkMode,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                localizations.missed,
                (total - taken).toString(),
                Icons.cancel,
                Colors.red,
                isDarkMode,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              // Calcul du nombre "On Time" et "Late"
              ...(() {
                int onTimeCount = 0;
                int lateCount = 0;
                for (final h
                    in viewModel.medicationHistory.where((h) => !h.skipped)) {
                  // scheduledTime est une String "HH:mm", takenAt est DateTime
                  final scheduledParts = h.scheduledTime.split(':');
                  final scheduledHour = int.parse(scheduledParts[0]);
                  final scheduledMinute = int.parse(scheduledParts[1]);
                  final scheduledDateTime = DateTime(
                    h.takenAt.year,
                    h.takenAt.month,
                    h.takenAt.day,
                    scheduledHour,
                    scheduledMinute,
                  );
                  final diff =
                      h.takenAt.difference(scheduledDateTime).inMinutes;
                  if (diff.abs() <= 5) {
                    onTimeCount++;
                  } else if (diff > 5) {
                    lateCount++;
                  }
                }
                return [
                  _buildSummaryCard(
                    localizations.onTime,
                    onTimeCount.toString(),
                    Icons.timer,
                    Colors.blue,
                    isDarkMode,
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    localizations.late,
                    lateCount.toString(),
                    Icons.timer_off,
                    Colors.orange,
                    isDarkMode,
                  ),
                ];
              })(),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color, bool isDarkMode) {
    final size = MediaQuery.of(context).size;

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(size.width * 0.03), // Taille adaptative
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon,
                color: color, size: size.width * 0.06), // Taille adaptative
            SizedBox(height: size.height * 0.01), // Taille adaptative
            Text(
              value,
              style: TextStyle(
                fontSize: size.width * 0.05, // Taille adaptative
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: size.width * 0.035, // Taille adaptative
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMedicationColor(String type) {
    switch (type) {
      case 'pill':
        return Colors.blue;
      case 'capsule':
        return Colors.green;
      case 'injection':
        return Colors.purple;
      case 'cream':
        return Colors.orange;
      case 'syrup':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _getMedicationIcon(String type) {
    IconData iconData;
    switch (type) {
      case 'pill':
        iconData = Icons.local_pharmacy;
        break;
      case 'capsule':
        iconData = Icons.medication;
        break;
      case 'injection':
        iconData = Icons.vaccines;
        break;
      case 'cream':
        iconData = Icons.sanitizer;
        break;
      case 'syrup':
        iconData = Icons.local_drink;
        break;
      default:
        iconData = Icons.medication;
    }
    return Icon(iconData, color: Colors.white, size: 30);
  }

  String _getMedicationTypeName(String type) {
    final localizations = AppLocalizations.of(context)!;

    switch (type) {
      case 'pill':
        return localizations.pill;
      case 'capsule':
        return localizations.capsule;
      case 'injection':
        return localizations.injection;
      case 'cream':
        return localizations.cream;
      case 'syrup':
        return localizations.syrup;
      default:
        return localizations.medications;
    }
  }

  String _getFrequencyText(Medication medication) {
    final localizations = AppLocalizations.of(context)!;

    switch (medication.frequencyType) {
      case 'weekly':
        if (medication.specificDays != null &&
            medication.specificDays!.isNotEmpty) {
          final days = medication.specificDays!
              .map((day) {
                if (day >= 1 && day <= 7) {
                  // Ces chaÃ®nes devraient Ã©galement Ãªtre traduites
                  final weekDays = [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday'
                  ];
                  return weekDays[day - 1];
                }
                return '';
              })
              .where((name) => name.isNotEmpty)
              .join(', ');
          return '${localizations.weekly} on $days';
        }
        return localizations.weekly;
      case 'monthly':
        if (medication.specificDays != null &&
            medication.specificDays!.isNotEmpty) {
          return '${localizations.monthly} on day ${medication.specificDays!.join(', ')}';
        }
        return localizations.monthly;
      case 'specific_days':
        if (medication.specificDays != null &&
            medication.specificDays!.isNotEmpty) {
          final days = medication.specificDays!
              .map((day) {
                if (day >= 1 && day <= 7) {
                  final weekDays = [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday'
                  ];
                  return weekDays[day - 1];
                }
                return '';
              })
              .where((name) => name.isNotEmpty)
              .join(', ');
          return '${localizations.specificDays}: $days';
        }
        return localizations.specificDays;
      default:
        if (medication.frequencyType == 'daily') {
          return localizations.daily;
        }
        return medication.frequencyType[0].toUpperCase() +
            medication.frequencyType.substring(1);
    }
  }

  String _getMealRelationName(String relation) {
    final localizations = AppLocalizations.of(context)!;

    switch (relation) {
      case 'before_eating':
        return localizations.beforeEating;
      case 'after_eating':
        return localizations.afterEating;
      case 'with_food':
        return localizations.withFood;
      case 'no_relation':
        return localizations.noRelation;
      default:
        return localizations.noRelation;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'skipped':
        return Colors.orange;
      case 'missed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusIcon(String status) {
    IconData iconData;
    switch (status) {
      case 'completed':
        iconData = Icons.check;
        break;
      case 'skipped':
        iconData = Icons.skip_next;
        break;
      case 'missed':
        iconData = Icons.close;
        break;
      default:
        iconData = Icons.schedule;
    }
    return Icon(iconData, color: Colors.white, size: 20);
  }

  String _getStatusText(String status) {
    final localizations = AppLocalizations.of(context)!;

    switch (status) {
      case 'completed':
        return localizations.taken;
      case 'skipped':
        return localizations.skipped;
      case 'missed':
        return localizations.missed;
      default:
        return localizations.pending;
    }
  }
}
