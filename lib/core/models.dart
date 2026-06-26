class AppointmentModel {
  final String id;
  final String userId;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final String category;
  final String? notes;
  final String? repeat;
  final bool notifyEnabled;
  final int? notifyMinutesBefore;
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.startTime,
    this.endTime,
    this.location,
    required this.category,
    this.notes,
    this.repeat,
    this.notifyEnabled = false,
    this.notifyMinutesBefore,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) => AppointmentModel(
    id: json['id'],
    userId: json['user_id'],
    title: json['title'],
    startTime: DateTime.parse(json['start_time']),
    endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
    location: json['location'],
    category: json['category'] ?? 'Pessoal',
    notes: json['notes'],
    repeat: json['repeat'],
    notifyEnabled: json['notify_enabled'] ?? false,
    notifyMinutesBefore: json['notify_minutes_before'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'location': location,
    'category': category,
    'notes': notes,
    'repeat': repeat,
    'notify_enabled': notifyEnabled,
    'notify_minutes_before': notifyMinutesBefore,
  };
}

class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.category,
    this.tags = const [],
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
    id: json['id'],
    userId: json['user_id'],
    title: json['title'],
    content: json['content'] ?? '',
    category: json['category'] ?? 'Pessoal',
    tags: List<String>.from(json['tags'] ?? []),
    isPinned: json['is_pinned'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'content': content,
    'category': category,
    'tags': tags,
    'is_pinned': isPinned,
  };
}

class ReminderModel {
  final String id;
  final String userId;
  final String title;
  final String? notes;
  final DateTime dueDate;
  final bool isDone;
  final bool alarmEnabled;
  final DateTime createdAt;

  const ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    this.notes,
    required this.dueDate,
    this.isDone = false,
    this.alarmEnabled = false,
    required this.createdAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
    id: json['id'],
    userId: json['user_id'],
    title: json['title'],
    notes: json['notes'],
    dueDate: DateTime.parse(json['due_date']),
    isDone: json['is_done'] ?? false,
    alarmEnabled: json['alarm_enabled'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'notes': notes,
    'due_date': dueDate.toIso8601String(),
    'is_done': isDone,
    'alarm_enabled': alarmEnabled,
  };
}

class PersonModel {
  final String id;
  final String userId;
  final String name;
  final String? photoUrl;
  final String? relationship;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? address;
  final String? notes;
  final String? giftIdeas;
  final List<SpecialDateModel> specialDates;
  final DateTime createdAt;

  const PersonModel({
    required this.id,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.relationship,
    this.phone,
    this.whatsapp,
    this.email,
    this.address,
    this.notes,
    this.giftIdeas,
    this.specialDates = const [],
    required this.createdAt,
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) => PersonModel(
    id: json['id'],
    userId: json['user_id'],
    name: json['name'],
    photoUrl: json['photo_url'],
    relationship: json['relationship'],
    phone: json['phone'],
    whatsapp: json['whatsapp'],
    email: json['email'],
    address: json['address'],
    notes: json['notes'],
    giftIdeas: json['gift_ideas'],
    specialDates: (json['special_dates'] as List? ?? [])
        .map((d) => SpecialDateModel.fromJson(d))
        .toList(),
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'photo_url': photoUrl,
    'relationship': relationship,
    'phone': phone,
    'whatsapp': whatsapp,
    'email': email,
    'address': address,
    'notes': notes,
    'gift_ideas': giftIdeas,
  };
}

class SpecialDateModel {
  final String id;
  final String userId;
  final String? personId;
  final String title;
  final String type;
  final int day;
  final int month;
  final int? year;
  final bool alertEnabled;
  final DateTime createdAt;

  const SpecialDateModel({
    required this.id,
    required this.userId,
    this.personId,
    required this.title,
    required this.type,
    required this.day,
    required this.month,
    this.year,
    this.alertEnabled = true,
    required this.createdAt,
  });

  factory SpecialDateModel.fromJson(Map<String, dynamic> json) => SpecialDateModel(
    id: json['id'],
    userId: json['user_id'],
    personId: json['person_id'],
    title: json['title'],
    type: json['type'] ?? 'Aniversário',
    day: json['day'],
    month: json['month'],
    year: json['year'],
    alertEnabled: json['alert_enabled'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'person_id': personId,
    'title': title,
    'type': type,
    'day': day,
    'month': month,
    'year': year,
    'alert_enabled': alertEnabled,
  };

  int daysUntilNext() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, month, day);
    if (next.isBefore(today)) {
      next = DateTime(now.year + 1, month, day);
    }
    return next.difference(today).inDays;
  }
}

class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final String? dosage;
  final List<String> schedules;
  final int stockQuantity;
  final int? stockAlertAt;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  const MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    this.dosage,
    this.schedules = const [],
    this.stockQuantity = 0,
    this.stockAlertAt,
    this.isActive = true,
    this.notes,
    required this.createdAt,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) => MedicationModel(
    id: json['id'],
    userId: json['user_id'],
    name: json['name'],
    dosage: json['dosage'],
    schedules: List<String>.from(json['schedules'] ?? []),
    stockQuantity: json['stock_quantity'] ?? 0,
    stockAlertAt: json['stock_alert_at'],
    isActive: json['is_active'] ?? true,
    notes: json['notes'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'dosage': dosage,
    'schedules': schedules,
    'stock_quantity': stockQuantity,
    'stock_alert_at': stockAlertAt,
    'is_active': isActive,
    'notes': notes,
  };
}

class HealthAppointmentModel {
  final String id;
  final String userId;
  final String title;
  final String? doctorName;
  final String? clinic;
  final String? specialty;
  final DateTime appointmentDate;
  final String coverageType;
  final double? value;
  final DateTime? returnDate;
  final String? notes;
  final List<String> attachmentUrls;
  final DateTime createdAt;

  const HealthAppointmentModel({
    required this.id,
    required this.userId,
    required this.title,
    this.doctorName,
    this.clinic,
    this.specialty,
    required this.appointmentDate,
    this.coverageType = 'Particular',
    this.value,
    this.returnDate,
    this.notes,
    this.attachmentUrls = const [],
    required this.createdAt,
  });

  factory HealthAppointmentModel.fromJson(Map<String, dynamic> json) => HealthAppointmentModel(
    id: json['id'],
    userId: json['user_id'],
    title: json['title'],
    doctorName: json['doctor_name'],
    clinic: json['clinic'],
    specialty: json['specialty'],
    appointmentDate: DateTime.parse(json['appointment_date']),
    coverageType: json['coverage_type'] ?? 'Particular',
    value: json['value']?.toDouble(),
    returnDate: json['return_date'] != null ? DateTime.parse(json['return_date']) : null,
    notes: json['notes'],
    attachmentUrls: List<String>.from(json['attachment_urls'] ?? []),
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'doctor_name': doctorName,
    'clinic': clinic,
    'specialty': specialty,
    'appointment_date': appointmentDate.toIso8601String(),
    'coverage_type': coverageType,
    'value': value,
    'return_date': returnDate?.toIso8601String(),
    'notes': notes,
    'attachment_urls': attachmentUrls,
  };
}

class FinancialEntryModel {
  final String id;
  final String userId;
  final String title;
  final double value;
  final String type;
  final String category;
  final DateTime date;
  final String? creditCardId;
  final int? installments;
  final int? currentInstallment;
  final String? bankName;
  final String? notes;
  final bool isPaid;
  final DateTime createdAt;

  const FinancialEntryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.value,
    required this.type,
    required this.category,
    required this.date,
    this.creditCardId,
    this.installments,
    this.currentInstallment,
    this.bankName,
    this.notes,
    this.isPaid = false,
    required this.createdAt,
  });

  factory FinancialEntryModel.fromJson(Map<String, dynamic> json) => FinancialEntryModel(
    id: json['id'],
    userId: json['user_id'],
    title: json['title'],
    value: (json['value'] as num).toDouble(),
    type: json['type'],
    category: json['category'] ?? 'Outros',
    date: DateTime.parse(json['date']),
    creditCardId: json['credit_card_id'],
    installments: json['installments'],
    currentInstallment: json['current_installment'],
    bankName: json['bank_name'],
    notes: json['notes'],
    isPaid: json['is_paid'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'value': value,
    'type': type,
    'category': category,
    'date': date.toIso8601String(),
    'credit_card_id': creditCardId,
    'installments': installments,
    'current_installment': currentInstallment,
    'bank_name': bankName,
    'notes': notes,
    'is_paid': isPaid,
  };
}

class CreditCardModel {
  final String id;
  final String userId;
  final String name;
  final String bank;
  final String operator;
  final double limit;
  final int closingDay;
  final int dueDay;
  final int bestBuyDay;
  final String? notes;
  final DateTime createdAt;

  const CreditCardModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.bank,
    required this.operator,
    required this.limit,
    required this.closingDay,
    required this.dueDay,
    required this.bestBuyDay,
    this.notes,
    required this.createdAt,
  });

  factory CreditCardModel.fromJson(Map<String, dynamic> json) => CreditCardModel(
    id: json['id'],
    userId: json['user_id'],
    name: json['name'],
    bank: json['bank'],
    operator: json['operator'] ?? '',
    limit: (json['limit'] as num).toDouble(),
    closingDay: json['closing_day'],
    dueDay: json['due_day'],
    bestBuyDay: json['best_buy_day'],
    notes: json['notes'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'bank': bank,
    'operator': operator,
    'limit': limit,
    'closing_day': closingDay,
    'due_day': dueDay,
    'best_buy_day': bestBuyDay,
    'notes': notes,
  };
}

class DocumentModel {
  final String id;
  final String userId;
  final String title;
  final String type;
  final String? fileUrl;
  final String? notes;
  final DateTime createdAt;

  const DocumentModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    this.fileUrl,
    this.notes,
    required this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
    id: json['id'],
    userId: json['user_id'],
    title: json['title'],
    type: json['type'] ?? 'Outros',
    fileUrl: json['file_url'],
    notes: json['notes'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'type': type,
    'file_url': fileUrl,
    'notes': notes,
  };
}
