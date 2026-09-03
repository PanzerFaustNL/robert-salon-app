import 'package:flutter/foundation.dart';
import '../models/models.dart';

class AppStore extends ChangeNotifier {
  final List<SalonService> services;
  final List<Appointment> appointments;
  final List<Customer> customers;
  bool adminMode = false;

  AppStore({required this.services, required this.appointments, required this.customers});

  factory AppStore.seeded() {
    const tattoo = SalonService(
      id: 'tattoo',
      name: 'Tattoo afspraak',
      description: 'Van ontwerpbespreking tot het zetten van de tattoo.',
      durationMinutes: 180,
      deposit: 75,
    );
    const intake = SalonService(
      id: 'intake',
      name: 'Intake / ontwerpbespreking',
      description: 'Bespreek idee, stijl, plek, formaat en planning.',
      durationMinutes: 45,
      deposit: 0,
    );
    const touchup = SalonService(
      id: 'touchup',
      name: 'Touch-up / controle',
      description: 'Controle of kleine bijwerking van bestaand werk.',
      durationMinutes: 45,
      deposit: 0,
    );

    return AppStore(
      services: const [tattoo, intake, touchup],
      appointments: [
        Appointment(
          id: 'demo-1',
          customerName: 'Sophie de Wit',
          email: 'sophie@example.com',
          phone: '06 12345678',
          service: tattoo,
          startsAt: DateTime.now().add(const Duration(days: 2, hours: 2)),
          idea: 'Black & grey rozen met fijne lijnen',
          placement: 'Onderarm',
          consentComplete: true,
          depositPaid: true,
          status: 'Bevestigd',
        ),
      ],
      customers: const [
        Customer(id: 'c1', name: 'Sophie de Wit', email: 'sophie@example.com', phone: '06 12345678'),
      ],
    );
  }

  void addAppointment(Appointment appointment) {
    appointments.add(appointment);
    if (!customers.any((c) => c.email.toLowerCase() == appointment.email.toLowerCase())) {
      customers.add(Customer(
        id: 'c-${DateTime.now().millisecondsSinceEpoch}',
        name: appointment.customerName,
        email: appointment.email,
        phone: appointment.phone,
      ));
    }
    notifyListeners();
  }

  void setAdminMode(bool value) {
    adminMode = value;
    notifyListeners();
  }
}
