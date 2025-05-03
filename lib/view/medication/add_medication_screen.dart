import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Ajout pour le sélecteur de couleur
import '../../core/constants/app_colors.dart';
import '../../viewmodel/medication_viewmodel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddMedicationScreen extends StatefulWidget {
  final String? medicationId;

  AddMedicationScreen(
      {super.key, this.medicationId}); // Utilisation de super.key

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController(); // Nouveau
  final TextEditingController _dosageQuantityController =
      TextEditingController(text: '1'); // Nouveau
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _currentStockController =
      TextEditingController(text: '5'); // Nouveau
  final TextEditingController _lowStockThresholdController =
      TextEditingController(text: '3'); // Nouveau
  final TextEditingController _reminderMinutesBeforeController =
      TextEditingController(text: '5'); // Nouveau

  MedicationType _selectedType = MedicationType.pill;
  FrequencyType _selectedFrequency = FrequencyType.daily;
  MealRelation _selectedMealRelation = MealRelation.no_relation;
  String _selectedDosageUnit = 'mg'; // Nouveau

  List<String> _selectedTimes = ['09:00'];
  List<int> _selectedDays = [];
  File? _imageFile;
  bool _isEditing = false;
  bool _notifyLowStock = true; // Nouveau
  Color _selectedColor = Colors.blue; // Nouveau
  List<Map<String, dynamic>> _existingReminders = [];
  // Ajoute ici :
  bool _remindersHaveChanged() {
    // Si les deux listes sont vides, rien n'a changé
    if (_selectedTimes.isEmpty && _existingReminders.isEmpty) return false;

    // Si les tailles sont différentes, il y a eu un changement
    if (_selectedTimes.length != _existingReminders.length) return true;

    // Compare chaque horaire en tenant compte de l'ordre
    for (int i = 0; i < _selectedTimes.length; i++) {
      String normalizedSelectedTime = _selectedTimes[i].trim();
      String normalizedExistingTime =
          _existingReminders[i]['scheduledTime'].trim();
      if (normalizedSelectedTime != normalizedExistingTime) return true;
    }

    return false;
  }

  // Unités de dosage par type de médicament
  final Map<MedicationType, List<String>> _dosageUnits = {
    MedicationType.pill: ['mg', 'g', 'mcg', 'UI', 'meq', 'comprimé'],
    MedicationType.capsule: ['mg', 'g', 'capsule', 'gélule'],
    MedicationType.injection: ['ml', 'cc', 'mg/ml', 'UI/ml'],
    MedicationType.cream: ['g', '%'],
    MedicationType.syrup: [
      'ml',
      'cuillère à café',
      'cuillère à soupe',
      'gouttes',
      'fl oz'
    ],
  };
  final List<FrequencyType> visibleFrequencies = [
    FrequencyType.daily,
    FrequencyType.weekly,
    FrequencyType.monthly,
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.medicationId != null;

    // Réinitialiser les jours sélectionnés à chaque ouverture
    _selectedDays = [];

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMedicationData();
      });
    }
  }

  Future<void> _loadMedicationData() async {
    final viewModel = Provider.of<MedicationViewModel>(context, listen: false);
    await viewModel.getMedicationById(context, widget.medicationId!);

    final medication = viewModel.selectedMedication;
    if (medication != null) {
      setState(() {
        _nameController.text = medication.name;
        _descriptionController.text = medication.description ?? ''; // Nouveau
        _dosageQuantityController.text =
            medication.dosageQuantity.toString(); // Nouveau
        _selectedDosageUnit = medication.dosageUnit; // Nouveau
        _notesController.text = medication.notes ?? '';
        _currentStockController.text =
            medication.currentStock.toString(); // Nouveau
        _lowStockThresholdController.text =
            medication.lowStockThreshold.toString(); // Nouveau
        _reminderMinutesBeforeController.text =
            medication.reminderMinutesBefore.toString(); // Nouveau
        _notifyLowStock = medication.notifyLowStock; // Nouveau

        // Convertir la couleur hexadécimale en Color
        if (medication.color != null) {
          _selectedColor =
              Color(int.parse(medication.color!.replaceAll('#', '0xFF')));
        }

        // Convert string values to enum values
        _selectedType = MedicationType.values.firstWhere(
          (e) => e.toString().split('.').last == medication.medicationType,
          orElse: () => MedicationType.pill,
        );

        _selectedFrequency = FrequencyType.values.firstWhere(
          (e) => e.toString().split('.').last == medication.frequencyType,
          orElse: () => FrequencyType.daily,
        );

        _selectedMealRelation = MealRelation.values.firstWhere(
          (e) => e.toString().split('.').last == medication.mealRelation,
          orElse: () => MealRelation.no_relation,
        );

        _selectedTimes = medication.timeOfDay;

        if (medication.specificDays != null) {
          _selectedDays = List<int>.from(medication.specificDays!);
        }
        // AJOUTE ICI, à la fin du setState :
        final viewModel =
            Provider.of<MedicationViewModel>(context, listen: false);
// Par exemple, si tu as déjà une liste todayReminders dans le viewModel :
        final reminders = viewModel.todayReminders
            .where((r) => r.medicationId == medication.id)
            .toList();

        // Filtrer pour ne garder qu'un seul reminder par horaire
        final uniqueReminders = <String, Map<String, dynamic>>{};
        for (var r in reminders) {
          uniqueReminders[r.scheduledTime] = {
            'id': r.id,
            'scheduledTime': r.scheduledTime,
          };
        }
        _existingReminders = uniqueReminders.values.toList();
      });
    }
  }

  Future<void> _pickImage() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: isDarkMode ? Colors.white70 : null,
                ),
                title: Text(
                  'Prendre une photo',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile =
                      await ImagePicker().pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: isDarkMode ? Colors.white70 : null,
                ),
                title: Text(
                  'Choisir depuis la galerie',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addTimeSlot() {
    setState(() {
      _selectedTimes.add('12:00');
    });
  }

  void _removeTimeSlot(int index) {
    if (_selectedTimes.length > 1) {
      setState(() {
        _selectedTimes.removeAt(index);
      });
    }
  }

  void _toggleDaySelection(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      // Trier les jours pour qu'ils apparaissent dans l'ordre
      _selectedDays.sort();
    });
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final TimeOfDay initialTime = TimeOfDay(
      hour: int.parse(_selectedTimes[index].split(':')[0]),
      minute: int.parse(_selectedTimes[index].split(':')[1]),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
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
                : ColorScheme.light(
                    primary: AppColors.primaryBlue,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTimes[index] =
            '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      final viewModel =
          Provider.of<MedicationViewModel>(context, listen: false);

      final medicationData = {
        'name': _nameController.text,
        'description': _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        'medicationType': _selectedType.toString().split('.').last,
        'dosageQuantity': int.tryParse(_dosageQuantityController.text) ?? 1,
        'dosageUnit': _selectedDosageUnit,
        'frequencyType': _selectedFrequency.toString().split('.').last,
        'timeOfDay': _selectedTimes, // Toujours inclure les horaires
        'mealRelation': _selectedMealRelation.toString().split('.').last,
        'currentStock': int.tryParse(_currentStockController.text) ?? 5,
        'lowStockThreshold':
            int.tryParse(_lowStockThresholdController.text) ?? 3,
        'notifyLowStock': _notifyLowStock,
        'color':
            '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
        'notes':
            _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      // Gestion des jours spécifiques
      if (_selectedFrequency == FrequencyType.specific_days ||
          _selectedFrequency == FrequencyType.weekly ||
          _selectedFrequency == FrequencyType.monthly) {
        medicationData['specificDays'] = _selectedDays;
      }

      // Debug logs
      print('DEBUG specificDays: $_selectedDays');
      print('DEBUG payload: $medicationData');
      print('_selectedTimes: $_selectedTimes');
      print('_existingReminders: $_existingReminders');

      bool success;
      if (_isEditing) {
        // Forcer la mise à jour des rappels
        medicationData['forceUpdate'] = true;

        // Ajouter les IDs des rappels existants pour éviter la duplication
        if (_existingReminders.isNotEmpty) {
          // Créer une liste d'IDs de rappels existants
          final List<Map<String, dynamic>> reminderUpdates = [];

          // Vérifier si les horaires ont changé
          if (_remindersHaveChanged()) {
            // Si les horaires ont changé, supprimer tous les rappels existants et créer de nouveaux
            medicationData['deleteAllReminders'] = true;

            // Créer de nouveaux rappels pour chaque horaire sélectionné
            for (int i = 0; i < _selectedTimes.length; i++) {
              reminderUpdates.add({
                'scheduledTime': _selectedTimes[i],
              });
            }
          } else {
            // Si les horaires n'ont pas changé, conserver les rappels existants
            for (int i = 0; i < _selectedTimes.length; i++) {
              final String time = _selectedTimes[i];

              // Chercher un rappel existant avec le même horaire
              final existingReminderIndex = _existingReminders
                  .indexWhere((r) => r['scheduledTime'] == time);

              if (existingReminderIndex != -1) {
                // Si un rappel existant a été trouvé, utiliser son ID
                reminderUpdates.add({
                  'id': _existingReminders[existingReminderIndex]['id'],
                  'scheduledTime': time,
                });
              } else {
                // Sinon, créer un nouveau rappel sans ID
                reminderUpdates.add({
                  'scheduledTime': time,
                });
              }
            }
          }

          // Ajouter la liste des mises à jour de rappels aux données du médicament
          medicationData['reminderUpdates'] = reminderUpdates;
        }
        success = await viewModel.updateMedication(
          context,
          widget.medicationId!,
          medicationData,
          imageFile: _imageFile,
        );
      } else {
        success = await viewModel.addMedication(
          context,
          medicationData,
          imageFile: _imageFile,
        );
      }

      if (success && mounted) {
        // Rafraîchir les rappels immédiatement
        await viewModel.fetchTodayReminders(context);
        // Attendre un court instant pour s'assurer que les rappels sont bien mis à jour
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context);
      }
    }
  }

  void _showColorPicker() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            localizations.chooseColor,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() => _selectedColor = color);
              },
              pickerAreaHeightPercent: 0.8,
              labelTypes: const [],
              displayThumbColor: true,
              portraitOnly: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                localizations.ok,
                style: TextStyle(
                  color: AppColors.primaryBlue,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
            _isEditing
                ? localizations.editMedication
                : localizations.addMedication,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: viewModel.isLoading && _isEditing
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medication Image
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppColors.primaryBlue.withOpacity(0.3)
                                : AppColors.primaryBlue.withOpacity(0.2),
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imageFile == null
                              ? Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: isDarkMode
                                      ? AppColors.primaryBlue.withOpacity(0.8)
                                      : AppColors.primaryBlue,
                                )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Medication Name
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: localizations.medicationName,
                        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                        filled: isDarkMode,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDarkMode
                                ? Colors.grey[600]!
                                : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: AppColors.primaryBlue, width: 2.0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDarkMode
                                ? Colors.grey[600]!
                                : Colors.grey.shade300,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                        focusColor: AppColors.primaryBlue,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.pleaseEnterMedicationName;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: localizations.description,
                        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                        filled: isDarkMode,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDarkMode
                                ? Colors.grey[600]!
                                : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: AppColors.primaryBlue, width: 2.0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDarkMode
                                ? Colors.grey[600]!
                                : Colors.grey.shade300,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                        focusColor: AppColors.primaryBlue,
                      ),
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                    ),

                    const SizedBox(height: 16),

                    // Medication Type
                    Text(
                      localizations.medicationType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: MedicationType.values.map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ChoiceChip(
                              label: Text(_getMedicationTypeName(type)),
                              selected: _selectedType == type,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedType = type;
                                    _selectedDosageUnit =
                                        _dosageUnits[type]!.first;
                                  });
                                }
                              },
                              backgroundColor: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              selectedColor: AppColors.primaryBlue,
                              labelStyle: TextStyle(
                                color: _selectedType == type
                                    ? Colors.white
                                    : isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              avatar: _selectedType == type
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Dosage Quantity and Unit (Nouveau)
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _dosageQuantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: localizations.dosageQuantity,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.primaryBlue, width: 2.0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              labelStyle: TextStyle(color: Colors.grey[700]),
                              focusColor: AppColors.primaryBlue,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.required;
                              }
                              if (int.tryParse(value) == null) {
                                return localizations.enterNumber;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _selectedDosageUnit,
                            decoration: InputDecoration(
                              labelText: localizations.unit,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.primaryBlue, width: 2.0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              labelStyle: TextStyle(color: Colors.grey[700]),
                              focusColor: AppColors.primaryBlue,
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            items: _dosageUnits[_selectedType]!.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedDosageUnit = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Frequency
                    Text(
                      localizations.frequency,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: visibleFrequencies.map((frequency) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ChoiceChip(
                              label: Text(_getFrequencyTypeName(frequency)),
                              selected: _selectedFrequency == frequency,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedFrequency = frequency;
                                    _selectedDays
                                        .clear(); // Réinitialise les jours sélectionnés
                                  });
                                }
                              },
                              backgroundColor: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              selectedColor: AppColors.primaryBlue,
                              labelStyle: TextStyle(
                                color: _selectedFrequency == frequency
                                    ? Colors.white
                                    : isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              avatar: _selectedFrequency == frequency
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

// Sélection des jours pour Weekly ou Monthly
                    if (_selectedFrequency == FrequencyType.weekly ||
                        _selectedFrequency == FrequencyType.monthly)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFrequency == FrequencyType.weekly
                                  ? localizations.selectDaysOfWeek
                                  : localizations.selectDaysOfMonth,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_selectedFrequency == FrequencyType.weekly)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(7, (index) {
                                    // index: 0=Sun, 1=Mon, ..., 6=Sat
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 12.0),
                                      child: ChoiceChip(
                                        label: Text([
                                          'Sun',
                                          'Mon',
                                          'Tue',
                                          'Wed',
                                          'Thu',
                                          'Fri',
                                          'Sat'
                                        ][index]),
                                        selected: _selectedDays.contains(index),
                                        onSelected: (selected) {
                                          _toggleDaySelection(index);
                                        },
                                        backgroundColor: isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[200],
                                        selectedColor: AppColors.primaryBlue,
                                        labelStyle: TextStyle(
                                          color: _selectedDays.contains(index)
                                              ? Colors.white
                                              : isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        avatar: _selectedDays.contains(index)
                                            ? const Icon(Icons.check,
                                                color: Colors.white, size: 18)
                                            : null,
                                      ),
                                    );
                                  }),
                                ),
                              )
                            else if (_selectedFrequency ==
                                FrequencyType.monthly)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(31, (index) {
                                  final day = index + 1;
                                  return GestureDetector(
                                    onTap: () => _toggleDaySelection(day),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _selectedDays.contains(day)
                                              ? AppColors.primaryBlue
                                              : Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color:
                                                    _selectedDays.contains(day)
                                                        ? Colors.blue.shade700
                                                        : AppColors.primaryBlue,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(8),
                                                  topRight: Radius.circular(8),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  day.toString(),
                                                  style: TextStyle(
                                                    color: _selectedDays
                                                            .contains(day)
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            if (_selectedDays.isEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text(
                                  localizations.pleaseSelectAtLeastOneDay,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    //
                    Text(
                      localizations.timeOfDay,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedTimes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? Colors.grey[600]!
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedTimes[index],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            _selectTime(context, index),
                                        child: Icon(
                                          Icons.access_time,
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_selectedTimes.length > 1)
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: isDarkMode
                                        ? Colors.red[300]
                                        : Colors.red,
                                  ),
                                  onPressed: () => _removeTimeSlot(index),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Bouton pour ajouter un nouveau time slot
                    TextButton.icon(
                      icon: Icon(
                        Icons.add,
                        color: AppColors.primaryBlue,
                      ),
                      label: Text(
                        localizations.addTime,
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      onPressed: _addTimeSlot,
                    ),

                    const SizedBox(height: 16),

                    // Relation to Meals
                    Text(
                      localizations.mealRelation,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: MealRelation.values.map((relation) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ChoiceChip(
                              label: Text(_getMealRelationName(relation)),
                              selected: _selectedMealRelation == relation,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedMealRelation = relation;
                                  });
                                }
                              },
                              backgroundColor: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              selectedColor: AppColors.primaryBlue,
                              labelStyle: TextStyle(
                                color: _selectedMealRelation == relation
                                    ? Colors.white
                                    : isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              avatar: _selectedMealRelation == relation
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stock Management (Nouveau)
                    Text(
                      localizations.stockManagement,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _currentStockController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: localizations.currentStock,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.primaryBlue, width: 2.0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              labelStyle: TextStyle(color: Colors.grey[700]),
                              focusColor: AppColors.primaryBlue,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.required;
                              }
                              if (int.tryParse(value) == null) {
                                return localizations.enterNumber;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _lowStockThresholdController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: localizations.lowStockAlert,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.primaryBlue, width: 2.0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              labelStyle: TextStyle(color: Colors.grey[700]),
                              focusColor: AppColors.primaryBlue,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.required;
                              }
                              if (int.tryParse(value) == null) {
                                return localizations.enterNumber;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Notify Low Stock (Nouveau)
                    SwitchListTile(
                      title: Text(
                        localizations.notifyWhenStockIsLow,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      value: _notifyLowStock,
                      onChanged: (value) {
                        setState(() {
                          _notifyLowStock = value;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                    ),

                    const SizedBox(height: 16),

                    // Color Picker (Nouveau)
                    ListTile(
                      title: Text(
                        localizations.medicationColor,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        localizations.chooseColor,
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[500] : Colors.grey[700],
                        ),
                      ),
                      trailing: GestureDetector(
                        onTap: _showColorPicker,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ),
                      onTap: _showColorPicker,
                    ),

                    const SizedBox(height: 16),
                    // Notes (Optional)
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: localizations.notes,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: AppColors.primaryBlue, width: 2.0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        focusColor: AppColors.primaryBlue,
                      ),
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isEditing
                              ? localizations.updateMedication
                              : localizations.addMedication,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _getMedicationIcon(MedicationType type) {
    switch (type) {
      case MedicationType.pill:
        return Icons.local_pharmacy;
      case MedicationType.capsule:
        return Icons.medication;
      case MedicationType.injection:
        return Icons.vaccines;
      case MedicationType.cream:
        return Icons.sanitizer;
      case MedicationType.syrup:
        return Icons.local_drink;
    }
  }

  // Supprimer les méthodes non utilisées et garder celles qui sont nécessaires

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getMedicationTypeName(MedicationType type) {
    final localizations = AppLocalizations.of(context)!;

    switch (type) {
      case MedicationType.pill:
        return localizations.pill;
      case MedicationType.capsule:
        return localizations.capsule;
      case MedicationType.injection:
        return localizations.injection;
      case MedicationType.cream:
        return localizations.cream;
      case MedicationType.syrup:
        return localizations.syrup;
    }
  }

  String _getFrequencyTypeName(FrequencyType type) {
    final localizations = AppLocalizations.of(context)!;

    switch (type) {
      case FrequencyType.daily:
        return localizations.daily;
      case FrequencyType.weekly:
        return localizations.weekly;
      case FrequencyType.monthly:
        return localizations.monthly;
      case FrequencyType.specific_days:
        return localizations.specificDays;
    }
  }

  String _getMealRelationName(MealRelation relation) {
    final localizations = AppLocalizations.of(context)!;

    switch (relation) {
      case MealRelation.before_eating:
        return localizations.beforeEating;
      case MealRelation.after_eating:
        return localizations.afterEating;
      case MealRelation.with_food:
        return localizations.withFood;
      case MealRelation.no_relation:
        return localizations.noRelation;
    }
  }
}
