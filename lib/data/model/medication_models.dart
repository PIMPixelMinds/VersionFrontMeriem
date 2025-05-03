// Medication model
class Medication {
  final String id;
  final String name;
  final String? description;
  final String medicationType;
  final String dosage;
  final int dosageQuantity;
  final String dosageUnit;
  final String frequencyType;
  final List<String> timeOfDay;
  final List<int>? specificDays;
  final String mealRelation;
  final int reminderMinutesBefore;
  final int currentStock;
  final int lowStockThreshold;
  final bool notifyLowStock;
  final String? color;
  final String? notes;
  final String? imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    required this.id,
    required this.name,
    this.description,
    required this.medicationType,
    required this.dosage,
    this.dosageQuantity = 1,
    this.dosageUnit = 'dose',
    required this.frequencyType,
    required this.timeOfDay,
    this.specificDays,
    required this.mealRelation,
    this.reminderMinutesBefore = 0,
    this.currentStock = 0,
    this.lowStockThreshold = 0,
    this.notifyLowStock = false,
    this.color,
    this.notes,
    this.imageUrl,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      medicationType: json['medicationType'] ?? 'pill',
      dosage: json['dosageQuantity'] != null && json['dosageUnit'] != null
          ? '${json['dosageQuantity']} ${json['dosageUnit']}'
          : json['dosage'] ?? '',
      dosageQuantity: json['dosageQuantity'] ?? 1,
      dosageUnit: json['dosageUnit'] ?? 'dose',
      frequencyType: json['frequencyType'] ?? 'daily',
      timeOfDay: List<String>.from(json['timeOfDay'] ?? []),
      specificDays: json['specificDays'] != null
          ? List<int>.from(json['specificDays'])
          : null,
      mealRelation: json['mealRelation'] ?? 'no_relation',
      reminderMinutesBefore: json['reminderMinutesBefore'] ?? 0,
      currentStock: json['currentStock'] ?? 0,
      lowStockThreshold: json['lowStockThreshold'] ?? 0,
      notifyLowStock: json['notifyLowStock'] ?? false,
      color: json['color'],
      notes: json['notes'],
      imageUrl: json['imageUrl'],
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'medicationType': medicationType,
      'dosageQuantity': dosageQuantity,
      'dosageUnit': dosageUnit,
      'frequencyType': frequencyType,
      'timeOfDay': timeOfDay,
      'specificDays': specificDays,
      'mealRelation': mealRelation,
      'reminderMinutesBefore': reminderMinutesBefore,
      'currentStock': currentStock,
      'lowStockThreshold': lowStockThreshold,
      'notifyLowStock': notifyLowStock,
      'isActive': isActive,
    };

    if (description != null) data['description'] = description;
    if (specificDays != null) data['specificDays'] = specificDays;
    if (color != null) data['color'] = color;
    if (notes != null) data['notes'] = notes;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (startDate != null) data['startDate'] = startDate!.toIso8601String();
    if (endDate != null) data['endDate'] = endDate!.toIso8601String();

    return data;
  }
}

// Reminder model (for today's reminders)
class MedicationReminder {
  final String id;
  final String medicationId;
  final Medication medication;
  final DateTime scheduledDate;
  final String scheduledTime;
  final bool isCompleted;
  final bool isSkipped;
  final DateTime? completedAt;
  final String message;

  String get status {
    if (isCompleted) return 'completed';
    if (isSkipped) return 'skipped';
    return 'pending';
  }

  MedicationReminder({
    required this.id,
    required this.medicationId,
    required this.medication,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.isCompleted,
    required this.isSkipped,
    this.completedAt,
    this.message = 'Take your medication',
  });

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    // Handle the case where medication might be an ID or a full object
    Medication medicationObj;

    if (json['medicationId'] is Map<String, dynamic>) {
      medicationObj = Medication.fromJson(json['medicationId']);
    } else if (json['medication'] is Map<String, dynamic>) {
      medicationObj = Medication.fromJson(json['medication']);
    } else {
      // Create a placeholder medication if neither is available
      medicationObj = Medication(
        id: json['medicationId']?.toString() ?? '',
        name: 'Unknown Medication',
        dosage: '',
        medicationType: '',
        frequencyType: '',
        timeOfDay: [],
        mealRelation: '',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return MedicationReminder(
      id: json['_id']?.toString() ?? '',
      medicationId: json['medicationId'] is String
          ? json['medicationId']
          : json['medicationId']?['_id']?.toString() ?? '',
      medication: medicationObj,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : DateTime.now(),
      scheduledTime: json['scheduledTime']?.toString() ?? '',
      isCompleted: json['isCompleted'] ?? false,
      isSkipped: json['isSkipped'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      message: json['message']?.toString() ?? 'Take your medication',
    );
  }
}

// Medication History model
class MedicationHistory {
  final String id;
  final String medicationId;
  final Medication medication;
  final DateTime takenAt;
  final int quantityTaken;
  final String? notes;
  final bool skipped;
  final String scheduledTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicationHistory({
    required this.id,
    required this.medicationId,
    required this.medication,
    required this.takenAt,
    this.quantityTaken = 1,
    this.notes,
    this.skipped = false,
    required this.scheduledTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicationHistory.fromJson(Map<String, dynamic> json) {
    return MedicationHistory(
      id: json['_id'] ?? '',
      medicationId: json['medicationId'] ?? '',
      medication: json['medication'] != null
          ? Medication.fromJson(json['medication'])
          : Medication.fromJson({}),
      takenAt: json['takenAt'] != null
          ? DateTime.parse(json['takenAt'])
          : DateTime.now(),
      quantityTaken: json['quantityTaken'] ?? 1,
      notes: json['notes'],
      skipped: json['skipped'] ?? false,
      scheduledTime: json['scheduledTime'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

// Take Medication DTO
class TakeMedicationDto {
  final DateTime takenAt;
  final int? quantityTaken;
  final String? notes;

  TakeMedicationDto({
    required this.takenAt,
    this.quantityTaken,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'takenAt': takenAt.toIso8601String(),
    };

    if (quantityTaken != null) data['quantityTaken'] = quantityTaken;
    if (notes != null) data['notes'] = notes;

    return data;
  }
}

// ModÃ¨le pour l'historique du stock
class StockHistory {
  final String id;
  final String medicationId;
  final int previousStock;
  final int currentStock;
  final int changeAmount;
  final String? notes;
  final String type; // 'add', 'remove', 'take', 'adjustment'
  final String userId;
  final DateTime createdAt;

  StockHistory({
    required this.id,
    required this.medicationId,
    required this.previousStock,
    required this.currentStock,
    required this.changeAmount,
    this.notes,
    required this.type,
    required this.userId,
    required this.createdAt,
  });

  factory StockHistory.fromJson(Map<String, dynamic> json) {
    return StockHistory(
      id: json['_id'],
      medicationId: json['medicationId'],
      previousStock: json['previousStock'],
      currentStock: json['currentStock'],
      changeAmount: json['changeAmount'],
      notes: json['notes'],
      type: json['type'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
