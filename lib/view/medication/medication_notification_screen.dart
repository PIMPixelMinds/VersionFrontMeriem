import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../data/model/medication_models.dart';
import '../../viewmodel/medication_viewmodel.dart';

class MedicationNotificationScreen extends StatefulWidget {
  const MedicationNotificationScreen({super.key});

  @override
  State<MedicationNotificationScreen> createState() =>
      _MedicationNotificationScreenState();
}

class _MedicationNotificationScreenState
    extends State<MedicationNotificationScreen> {
  late List<MedicationReminder> _visibleReminders = [];
  late List<MedicationReminder> _allReminders = [];
  String _searchQuery = '';
  String _sortCriteria = 'time'; // Options: 'name', 'time', 'type'

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel =
          Provider.of<MedicationViewModel>(context, listen: false);
      await viewModel.fetchTodayReminders(context);
      setState(() {
        _allReminders = List.from(viewModel.todayReminders);
        _filterAndSortReminders();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAndSortReminders() {
    setState(() {
      // Filtrer par recherche
      if (_searchQuery.isEmpty) {
        _visibleReminders = List.from(_allReminders);
      } else {
        _visibleReminders = _allReminders
            .where((reminder) => reminder.medication.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
      }

      // Trier selon le critÃ¨re sÃ©lectionnÃ©
      switch (_sortCriteria) {
        case 'name':
          _visibleReminders.sort((a, b) => a.medication.name
              .toLowerCase()
              .compareTo(b.medication.name.toLowerCase()));
          break;
        case 'time':
          _visibleReminders
              .sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
          break;
        case 'type':
          _visibleReminders.sort((a, b) => a.medication.medicationType
              .compareTo(b.medication.medicationType));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MedicationViewModel>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Center(
          child: Text(
            localizations.medicationReminders,
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
      ),
      body: viewModel.isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: localizations.searchMedications,
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDarkMode ? Colors.grey[400] : null,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filterAndSortReminders();
                      });
                    },
                  ),
                ),

                // Options de tri
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        localizations.sortBy,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildSortChip(localizations.name, 'name', isDarkMode),
                      const SizedBox(width: 8),
                      _buildSortChip(
                          localizations.timeOfDay, 'time', isDarkMode),
                      const SizedBox(width: 8),
                      _buildSortChip(localizations.type, 'type', isDarkMode),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Liste des rappels
                Expanded(
                  child: _visibleReminders.isEmpty
                      ? Center(
                          child: Text(
                            localizations.noMedicationRemindersFound,
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.grey[400] : Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _visibleReminders.length,
                          itemBuilder: (context, index) {
                            final reminder = _visibleReminders[index];
                            return _buildReminderCard(
                                context, reminder, viewModel, isDarkMode);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSortChip(String label, String criteria, bool isDarkMode) {
    final isSelected = _sortCriteria == criteria;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _sortCriteria = criteria;
          _filterAndSortReminders();
        });
      },
      backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey.shade200,
      selectedColor: AppColors.primaryBlue.withOpacity(0.2),
      checkmarkColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.primaryBlue
            : isDarkMode
                ? Colors.white
                : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, MedicationReminder reminder,
      MedicationViewModel viewModel, bool isDarkMode) {
    final medication = reminder.medication;
    final bool isTaken = reminder.isCompleted;
    final bool isSkipped = reminder.isSkipped;
    final localizations = AppLocalizations.of(context)!;

    // Animation controllers
    final slideController = ValueNotifier<Offset>(Offset.zero);
    final colorController = ValueNotifier<Color>(Colors.transparent);

    // Fonction d'animation pour faire disparaÃ®tre la carte
    Future<void> animateCard({required bool isTake}) async {
      for (double dx = 0; dx <= 1.0; dx += 0.05) {
        slideController.value = Offset(isTake ? dx : -dx, 0);
        colorController.value = isTake
            ? Colors.green.withOpacity(dx * 0.3)
            : Colors.red.withOpacity(dx * 0.3);
        await Future.delayed(const Duration(milliseconds: 5));
      }

      // Trouver l'index de ce rappel dans la liste visible
      final index = _visibleReminders.indexWhere((r) =>
          r.medication.id == reminder.medication.id &&
          r.scheduledTime == reminder.scheduledTime);

      // Trouver l'index dans le ViewModel
      final vmIndex = viewModel.todayReminders.indexWhere((r) =>
          r.medication.id == reminder.medication.id &&
          r.scheduledTime == reminder.scheduledTime);

      if (index != -1) {
        // Mettre Ã  jour l'Ã©tat local
        setState(() {
          // Supprimer l'Ã©lÃ©ment de la liste visible
          _visibleReminders.removeAt(index);

          // Supprimer Ã©galement de la liste complÃ¨te si nÃ©cessaire
          final allIndex = _allReminders.indexWhere((r) =>
              r.medication.id == reminder.medication.id &&
              r.scheduledTime == reminder.scheduledTime);
          if (allIndex != -1) {
            _allReminders.removeAt(allIndex);
          }
        });

        // Mettre Ã  jour le ViewModel en dehors de setState
        if (vmIndex != -1) {
          // Utiliser Future.microtask pour s'assurer que cela se produit aprÃ¨s le cycle de rendu actuel
          Future.microtask(() {
            viewModel.todayReminders.removeAt(vmIndex);
            viewModel.notifyListeners();
          });
        }
      }
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isDarkMode
                      ? Colors.grey[850]
                      : Colors.white, // ChangÃ© Ã  blanc/gris foncÃ©
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.primaryBlue, // Ajout d'une bordure bleue
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors
                                    .primaryBlue, // IcÃ´ne sur fond bleu
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  _getMedicationIconData(
                                      medication.medicationType),
                                  color: Colors.white, // IcÃ´ne en blanc
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
                                    medication.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors
                                          .primaryBlue, // Titre en bleu
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${medication.dosage} - ${reminder.scheduledTime}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors
                                              .black87, // Heure en noir/blanc
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getMealRelationText(
                                        context, medication.mealRelation),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors
                                              .black87, // Instructions en noir/blanc
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!isTaken && !isSkipped)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check,
                                      color: Colors.white, size: 16),
                                  label: Text(
                                    localizations.take,
                                    style: const TextStyle(color: Colors.white),
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
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  label: Text(
                                    localizations.skip,
                                    style: const TextStyle(color: Colors.white),
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
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[200], // Fond gris
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isTaken
                                      ? Icons.check_circle
                                      : Icons.skip_next,
                                  color: isTaken
                                      ? Colors.green
                                      : Colors.orange, // IcÃ´ne en vert/orange
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isTaken
                                      ? localizations.taken
                                      : localizations.skipped,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black, // Texte en noir/blanc
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isTaken && reminder.completedAt != null)
                                  Text(
                                    ' at ${DateFormat('HH:mm').format(reminder.completedAt!)}',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors
                                              .black87, // Heure en noir/blanc
                                    ),
                                  ),
                              ],
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
        return Colors.orange;
      case 'capsule':
        return Colors.blue;
      case 'injection':
        return Colors.green;
      case 'cream':
        return Colors.purple;
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

  String _getMealRelationText(BuildContext context, String relation) {
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
        return '';
    }
  }
}
