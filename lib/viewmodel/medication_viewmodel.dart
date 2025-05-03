import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pim/core/utils/medication_notification_helper.dart';
import 'package:pim/viewmodel/healthTracker_viewmodel.dart';
import '../data/model/medication_models.dart';
import '../data/repositories/medication_repository.dart';
import 'package:provider/provider.dart';
import '../data/repositories/shared_prefs_service.dart';

// Enum definitions to match backend
enum MedicationType {
  pill,
  capsule,
  injection,
  cream,
  syrup,
}

enum FrequencyType {
  daily,
  weekly,
  monthly,
  specific_days,
}

enum MealRelation {
  before_eating,
  after_eating,
  with_food,
  no_relation,
}

class MedicationViewModel extends ChangeNotifier {
  final MedicationRepository _repository = MedicationRepository();
  final SharedPrefsService _prefsService = SharedPrefsService();

  bool isLoading = false;
  String errorMessage = '';

  List<Medication> medications = [];
  Medication? selectedMedication;
  List<MedicationReminder> todayReminders = [];
  List<MedicationHistory> medicationHistory = [];

  Future<void> fetchMedications(BuildContext context) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final fetchedMedications = await _repository.getMedications();
      medications = fetchedMedications;
    } catch (e) {
      errorMessage = "Error: $e";
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodayReminders(BuildContext context) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final fetchedReminders = await _repository.getTodayReminders();
      todayReminders = fetchedReminders;

      await MedicationNotificationHelper.flutterLocalNotificationsPlugin.cancelAll();
      await MedicationNotificationHelper.scheduleAllReminders(todayReminders);
    } catch (e) {
      errorMessage = "Error fetching today's reminders: $e";
      todayReminders = [];
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMedication(BuildContext context, Map<String, dynamic> medicationData, {File? imageFile}) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      await _repository.addMedication(medicationData, imageFile: imageFile);
      await fetchMedications(context);
      await fetchTodayReminders(context);
      await fetchRemindersForDate(context, DateTime.now());
      return true;
    } catch (e) {
      errorMessage = "Error: $e";
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMedication(BuildContext context, String medicationId, Map<String, dynamic> medicationData, {File? imageFile}) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      await _repository.updateMedication(medicationId, medicationData, imageFile: imageFile);
      await fetchMedications(context);
      await fetchTodayReminders(context);
      await fetchRemindersForDate(context, DateTime.now());
      return true;
    } catch (e) {
      errorMessage = "Error: $e";
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMedication(BuildContext context, String medicationId) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final success = await _repository.deleteMedication(medicationId);
      if (success) {
        await fetchMedications(context);
        return true;
      }
      return false;
    } catch (e) {
      errorMessage = "Error: $e";
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getMedicationById(BuildContext context, String medicationId) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final medication = await _repository.getMedicationById(medicationId);
      selectedMedication = medication;
    } catch (e) {
      errorMessage = "Error: $e";
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> takeMedication(BuildContext context, String medicationId, DateTime takenAt, {int? quantityTaken, String? notes, File? imageFile}) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final takeMedicationDto = TakeMedicationDto(takenAt: takenAt, quantityTaken: quantityTaken, notes: notes);

      await _repository.takeMedication(medicationId, takeMedicationDto, imageFile: imageFile);
      await MedicationNotificationHelper.cancelNotification(medicationId.hashCode);
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchTodayReminders(context);
      await refreshMedicationStats(context);
      return true;
    } catch (e) {
      errorMessage = "Error: $e";
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> skipMedication(BuildContext context, String medicationId, DateTime scheduledDate, String scheduledTime) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      await _repository.skipMedication(medicationId, scheduledDate, scheduledTime);
      await MedicationNotificationHelper.cancelNotification(medicationId.hashCode);
      await fetchTodayReminders(context);
      await refreshMedicationStats(context);
      return true;
    } catch (e) {
      errorMessage = "Error: $e";
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMedicationHistory(BuildContext context, String medicationId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final history = await _repository.getMedicationHistory(medicationId, startDate: startDate, endDate: endDate);
      medicationHistory = history;
    } catch (e) {
      errorMessage = "Error: $e";
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRemindersForDate(BuildContext context, DateTime date) async {
    final token = await _prefsService.getAccessToken();
    print('📢 Auth token used: $token');
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final fetchedReminders = await _repository.getRemindersForDate(date);
      todayReminders = fetchedReminders;
      print("Successfully fetched ${todayReminders.length} reminders for $date");
    } catch (e) {
      errorMessage = "Error fetching reminders for $date: $e";
      todayReminders = [];
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fixReminders(BuildContext context) async {
    final token = await _prefsService.getAccessToken();
    try {
      await _repository.fixReminders(token!);
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminders corrigés avec succès !')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la correction des reminders : $e')));
      }
    }
  }

  Future<void> refreshMedicationStats(BuildContext context) async {
    try {
      final healthTrackerViewModel = Provider.of<HealthTrackerViewModel>(context, listen: false);
      await healthTrackerViewModel.fetchMedicationStats(context);
    } catch (e) {
      print('Error refreshing medication stats: $e');
    }
  }

  Future<List<StockHistory>> getStockHistory(String medicationId, {String? token, Function(String message)? onError}) async {
    try {
      return await _repository.fetchStockHistory(medicationId);
    } catch (e) {
      if (onError != null) onError('Erreur lors de la récupération du stock');
      rethrow;
    }
  }

  Future<void> updateStock({required String medicationId, required int quantity, int? lowStockThreshold, String? notes, Function(String message)? onSuccess, Function(String message)? onError}) async {
    final token = await _prefsService.getAccessToken();
    try {
      await _repository.updateStock(medicationId: medicationId, quantity: quantity, lowStockThreshold: lowStockThreshold, notes: notes, token: token);
      notifyListeners();
      if (onSuccess != null) onSuccess('Stock mis à jour avec succès');
    } catch (e) {
      if (onError != null) onError('Erreur lors de la mise à jour du stock');
      rethrow;
    }
  }

  Future<void> addStock({required String medicationId, required int quantity, String? notes, Function(String message)? onSuccess, Function(String message)? onError}) async {
    final token = await _prefsService.getAccessToken();
    try {
      await _repository.addStock(medicationId: medicationId, quantity: quantity, notes: notes, token: token);
      notifyListeners();
      if (onSuccess != null) onSuccess('Stock ajouté avec succès');
    } catch (e) {
      if (onError != null) onError('Erreur lors de l\'ajout de stock');
      rethrow;
    }
  }
}
