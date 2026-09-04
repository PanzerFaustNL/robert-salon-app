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
  final bool depositPaid;
  final String status;

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
    required this.depositPaid,
    this.status = 'requested',
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
}

class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: _asInt(map['id']),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
    );
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
