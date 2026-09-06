class SalonService {
  final int id;
  final String name;
  final String description;
  final String category;
  final int durationMinutes;
  final double? priceFrom;
  final double deposit;
  final bool active;
  final bool bookable;

  const SalonService({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.durationMinutes,
    required this.priceFrom,
    required this.deposit,
    required this.active,
    required this.bookable,
  });

  factory SalonService.fromMap(Map<String, dynamic> map) {
    return SalonService(
      id: _asInt(map['id']),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      category: (map['category'] ?? 'other').toString(),
      durationMinutes: _asInt(map['duration_minutes']),
      priceFrom: _asNullableDouble(map['price_from']),
      deposit: _asDouble(map['deposit_amount']),
      active: map['active'] as bool? ?? true,
      bookable: map['bookable'] as bool? ?? true,
    );
  }
}

class Appointment {
  final int id;
  final int customerId;
  final String customerName;
  final String email;
  final String phone;
  final SalonService service;
  final DateTime startsAt;
  final String idea;
  final String placement;
  final bool consentComplete;
  final bool consentReceived;
  final bool depositPaid;
  final String status;
  final String internalNotes;

  const Appointment({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.service,
    required this.startsAt,
    required this.idea,
    required this.placement,
    required this.consentComplete,
    required this.consentReceived,
    required this.depositPaid,
    required this.status,
    required this.internalNotes,
  });

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Bevestigd';
      case 'completed':
        return 'Afgerond';
      case 'cancelled':
        return 'Geannuleerd';
      case 'no_show':
        return 'Niet verschenen';
      case 'requested':
      default:
        return 'Aangevraagd';
    }
  }

  Appointment copyWith({
    bool? consentComplete,
    bool? consentReceived,
    bool? depositPaid,
    String? status,
    String? internalNotes,
  }) {
    return Appointment(
      id: id,
      customerId: customerId,
      customerName: customerName,
      email: email,
      phone: phone,
      service: service,
      startsAt: startsAt,
      idea: idea,
      placement: placement,
      consentComplete: consentComplete ?? this.consentComplete,
      consentReceived: consentReceived ?? this.consentReceived,
      depositPaid: depositPaid ?? this.depositPaid,
      status: status ?? this.status,
      internalNotes: internalNotes ?? this.internalNotes,
    );
  }
}

class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String notes;
  final DateTime? createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.notes,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: _asInt(map['id']),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
      createdAt: _asDateTime(map['created_at']),
    );
  }

  Customer copyWith({String? notes}) {
    return Customer(
      id: id,
      name: name,
      email: email,
      phone: phone,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}

class Payment {
  final int id;
  final int appointmentId;
  final double amount;
  final String kind;
  final String status;
  final String provider;
  final String? providerPaymentId;
  final DateTime? paidAt;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.appointmentId,
    required this.amount,
    required this.kind,
    required this.status,
    required this.provider,
    required this.providerPaymentId,
    required this.paidAt,
    required this.createdAt,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: _asInt(map['id']),
      appointmentId: _asInt(map['appointment_id']),
      amount: _asDouble(map['amount']),
      kind: (map['kind'] ?? 'other').toString(),
      status: (map['status'] ?? 'pending').toString(),
      provider: (map['provider'] ?? 'manual').toString(),
      providerPaymentId: map['provider_payment_id']?.toString(),
      paidAt: _asDateTime(map['paid_at']),
      createdAt: _asDateTime(map['created_at']) ?? DateTime.now(),
    );
  }

  String get kindLabel {
    switch (kind) {
      case 'deposit':
        return 'Aanbetaling';
      case 'final':
        return 'Eindbetaling';
      default:
        return 'Overige betaling';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'Betaald';
      case 'failed':
        return 'Mislukt';
      case 'refunded':
        return 'Terugbetaald';
      case 'cancelled':
        return 'Geannuleerd';
      default:
        return 'Openstaand';
    }
  }
}

class CustomerPhoto {
  final int id;
  final int customerId;
  final int? appointmentId;
  final String storagePath;
  final String photoType;
  final String caption;
  final DateTime createdAt;
  final String? signedUrl;

  const CustomerPhoto({
    required this.id,
    required this.customerId,
    required this.appointmentId,
    required this.storagePath,
    required this.photoType,
    required this.caption,
    required this.createdAt,
    this.signedUrl,
  });

  factory CustomerPhoto.fromMap(
    Map<String, dynamic> map, {
    String? signedUrl,
  }) {
    return CustomerPhoto(
      id: _asInt(map['id']),
      customerId: _asInt(map['customer_id']),
      appointmentId:
          map['appointment_id'] == null ? null : _asInt(map['appointment_id']),
      storagePath: (map['storage_path'] ?? '').toString(),
      photoType: (map['photo_type'] ?? 'result').toString(),
      caption: (map['caption'] ?? '').toString(),
      createdAt: _asDateTime(map['created_at']) ?? DateTime.now(),
      signedUrl: signedUrl,
    );
  }

  String get photoTypeLabel {
    switch (photoType) {
      case 'reference':
        return 'Referentie';
      case 'design':
        return 'Ontwerp';
      case 'before':
        return 'Voor';
      case 'healed':
        return 'Genezen';
      case 'result':
      default:
        return 'Resultaat';
    }
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}
