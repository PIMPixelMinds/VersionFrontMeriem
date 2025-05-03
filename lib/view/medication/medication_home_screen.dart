import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/model/medication_models.dart';
import '../../viewmodel/medication_viewmodel.dart';
import 'add_medication_screen.dart';
import 'medication_detail_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MedicationHomeScreen extends StatefulWidget {
  const MedicationHomeScreen({super.key});

  @override
  State<MedicationHomeScreen> createState() => _MedicationHomeScreenState();
}

class _MedicationHomeScreenState extends State<MedicationHomeScreen> {
  DateTime selectedDate = DateTime.now();
  final List<String> weekDays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  Future<void> _loadRemindersForDate(DateTime date) async {
    final viewModel = Provider.of<MedicationViewModel>(context, listen: false);
    await viewModel.fetchRemindersForDate(context, date);
    setState(() {
      _visibleReminders = List.from(viewModel.todayReminders);
    });
  }

  late List<MedicationReminder> _visibleReminders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      final viewModel =
          Provider.of<MedicationViewModel>(context, listen: false);
      setState(() {
        _visibleReminders = List.from(viewModel.todayReminders);
      });
    });
  }

  Future<void> _loadData() async {
    try {
      final viewModel =
          Provider.of<MedicationViewModel>(context, listen: false);
      await viewModel.fetchMedications(context);
      await viewModel.fetchRemindersForDate(context, selectedDate);
      await viewModel.fetchTodayReminders(context);

      if (mounted) {
        setState(() {
          _visibleReminders = List.from(viewModel.todayReminders);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MedicationViewModel>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Center(
          child: Text(
            localizations.medications,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
      body: viewModel.isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: AppColors.primaryBlue,
            ))
          : RefreshIndicator(
              onRefresh: () async {
                await viewModel.fetchMedications(context);
                await viewModel.fetchTodayReminders(context);
                setState(() {
                  _visibleReminders = List.from(viewModel.todayReminders);
                });
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month and Year
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(selectedDate),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  size: 16,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                onPressed: () async {
                                  final newDate = selectedDate
                                      .subtract(const Duration(days: 1));
                                  setState(() {
                                    selectedDate = newDate;
                                  });
                                  await _loadRemindersForDate(newDate);
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                onPressed: () async {
                                  final newDate =
                                      selectedDate.add(const Duration(days: 1));
                                  setState(() {
                                    selectedDate = newDate;
                                  });
                                  await _loadRemindersForDate(newDate);
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.calendar_today,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: isDarkMode
                                              ? ColorScheme.dark(
                                                  primary:
                                                      AppColors.primaryBlue,
                                                  onPrimary: Colors.white,
                                                  surface: Colors.grey[850]!,
                                                  onSurface: Colors.white,
                                                )
                                              : ColorScheme.light(
                                                  primary:
                                                      AppColors.primaryBlue,
                                                  onPrimary: Colors.white,
                                                  onSurface: Colors.black,
                                                ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null &&
                                      picked != selectedDate) {
                                    setState(() {
                                      selectedDate = picked;
                                    });
                                  }
                                },
                              ),
                              // IcÃ´ne avec compteur de notifications
                              Stack(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.library_books_outlined,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, '/medication_notifications');
                                    },
                                  ),
                                  if (viewModel.todayReminders.isNotEmpty)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          '+${viewModel.todayReminders.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Date selector
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            final date =
                                DateTime.now().add(Duration(days: index - 3));
                            final isSelected =
                                DateUtils.isSameDay(date, selectedDate);

                            return GestureDetector(
                              onTap: () async {
                                setState(() {
                                  selectedDate = date;
                                });
                                await _loadRemindersForDate(date);
                              },
                              child: Container(
                                width: 60,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : isDarkMode
                                          ? Colors.grey.shade800
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryBlue
                                        : isDarkMode
                                            ? Colors.grey.shade600
                                            : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      date.day.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      weekDays[date.weekday % 7],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : isDarkMode
                                                ? Colors.white70
                                                : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // My medications section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizations.myMedications,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Medication list
                      viewModel.medications.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: SizedBox(
                                height: 150,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    AddMedicationCard(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AddMedicationScreen(),
                                          ),
                                        ).then((_) => _loadData());
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: viewModel.medications.length +
                                    1, // +1 pour la carte d'ajout
                                itemBuilder: (context, index) {
                                  // Si c'est le dernier Ã©lÃ©ment, montrer la carte d'ajout
                                  if (index == viewModel.medications.length) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 16.0),
                                      child: AddMedicationCard(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddMedicationScreen(),
                                            ),
                                          ).then((_) => _loadData());
                                        },
                                      ),
                                    );
                                  }

                                  // Sinon afficher la mÃ©dication normale
                                  final medication =
                                      viewModel.medications[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: SizedBox(
                                      width: 150,
                                      child: MedicationCard(
                                        medication: medication,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MedicationDetailScreen(
                                                medicationId: medication.id,
                                              ),
                                            ),
                                          ).then((_) => _loadData());
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                      const SizedBox(height: 24),

                      // To take section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            localizations.toTake,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Medication reminders
                      viewModel.todayReminders.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  localizations.noMedicationsScheduled,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _visibleReminders.length,
                              itemBuilder: (context, index) {
                                final reminder = _visibleReminders[index];
                                return _buildReminderCard(
                                    context, reminder, viewModel, index);
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildReminderCard(BuildContext context, MedicationReminder reminder,
      MedicationViewModel viewModel, int index) {
    final medication = reminder.medication;
    final bool isTaken = reminder.isCompleted;
    final bool isSkipped = reminder.isSkipped;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    // Animation controllers locaux Ã  la card
    final slideController = ValueNotifier<Offset>(Offset.zero);
    final colorController = ValueNotifier<Color>(Colors.transparent);

    Future<void> animateCard({required bool isTake}) async {
      for (double dx = 0; dx <= 1.0; dx += 0.05) {
        slideController.value = Offset(isTake ? dx : -dx, 0);
        colorController.value = isTake
            ? Colors.green.withOpacity(dx * 0.3)
            : Colors.red.withOpacity(dx * 0.3);
        await Future.delayed(const Duration(milliseconds: 5));
      }
      setState(() {
        _visibleReminders.removeAt(index);
      });
    }

    return ValueListenableBuilder<Offset>(
      valueListenable: slideController,
      builder: (context, offset, child) {
        return ValueListenableBuilder<Color>(
          valueListenable: colorController,
          builder: (context, bgColor, child) {
            return Transform.translate(
              offset: Offset(offset.dx * 400, 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                color: bgColor,
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  _getMedicationIconData(
                                      medication.medicationType),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getDosageText(medication.dosage)} ${medication.name}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    reminder.scheduledTime,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getMealRelationText(
                                        medication.mealRelation),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isTaken && !isSkipped)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check,
                                        color: Colors.white, size: 16),
                                    label: Text(
                                      localizations.take,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () async {
                                      await viewModel.takeMedication(
                                        context,
                                        medication.id,
                                        DateTime.now(),
                                      );
                                      await animateCard(isTake: true);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                    label: Text(
                                      localizations.skip,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () async {
                                      await viewModel.skipMedication(
                                        context,
                                        medication.id,
                                        reminder.scheduledDate,
                                        reminder.scheduledTime,
                                      );
                                      await animateCard(isTake: false);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isTaken
                                        ? Icons.check_circle
                                        : Icons.skip_next,
                                    color:
                                        isTaken ? Colors.green : Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isTaken
                                        ? localizations.taken
                                        : localizations.skipped,
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Nouvelle mÃ©thode pour obtenir uniquement l'IconData sans crÃ©er l'icÃ´ne
  IconData _getMedicationIconData(String type) {
    switch (type) {
      case 'pill':
        return Icons.local_pharmacy;
      case 'capsule':
        return Icons.medication;
      case 'injection':
        return Icons.vaccines;
      case 'cream':
        return Icons.sanitizer;
      case 'syrup':
        return Icons.local_drink;
      default:
        return Icons.medication;
    }
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
    return Icon(iconData, color: Colors.white, size: 24);
  }

  String _getMealRelationText(String relation) {
    final localizations = AppLocalizations.of(context)!;

    switch (relation) {
      case 'before_eating':
        return localizations.beforeEating;
      case 'after_eating':
        return localizations.afterEating;
      case 'with_food':
        return localizations.withFood;
      case 'no_relation':
        return localizations.noSpecialInstructions;
      default:
        return '';
    }
  }

// Correction: ImplÃ©menter correctement la mÃ©thode _getDosageText
  String _getDosageText(String dosage) {
    return dosage;
  }
}

// DÃ©placer la classe MedicationCard au niveau supÃ©rieur (en dehors de _MedicationHomeScreenState)
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onTap;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getMedicationTypeColor(medication.medicationType),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _getMedicationTypeIcon(medication.medicationType),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    medication.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              medication.dosage,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getMedicationScheduleText(medication),
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getMedicationTypeColor(String type) {
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

  Widget _getMedicationTypeIcon(String type) {
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
    return Icon(iconData, color: Colors.white, size: 20);
  }

  String _getMedicationScheduleText(Medication medication) {
    return '${medication.timeOfDay.length} times a day';
  }
}

// Nouvelle classe pour la carte d'ajout de mÃ©dicament
class AddMedicationCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddMedicationCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primaryBlue,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.addItem,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
