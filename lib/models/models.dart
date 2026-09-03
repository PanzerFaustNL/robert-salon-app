class SalonService {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final double deposit;

  const SalonService({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.deposit,
  });
}

class Appointment {
  final String id;
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

  Appointment({
    required this.id,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.service,
    required this.startsAt,
    required this.idea,
    required this.placement,
    required this.consentComplete,
    required this.depositPaid,
    this.status = 'Aangevraagd',
  });
}

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;

  const Customer({required this.id, required this.name, required this.email, required this.phone});
}
