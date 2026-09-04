import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class AppStore extends ChangeNotifier {
  final SupabaseClient? _database;

  final List<SalonService> services = [];
  final List<Appointment> appointments = [];
  final List<Customer> customers = [];

  bool adminMode = false;
  bool loading = false;
  String? databaseError;

  AppStore({SupabaseClient? database}) : _database = database;

  bool get databaseConfigured => _database != null;
  bool get databaseConnected => databaseConfigured && databaseError == null;

  Future<void> initialize() async {
    if (_database == null) return;
    await refreshAll();
  }

  Future<void> refreshAll() async {
    if (_database == null) return;

    loading = true;
    databaseError = null;
    notifyListeners();

    try {
      await _loadServices();
      await _tryLoadAdminData();
    } catch (error, stackTrace) {
      databaseError = _cleanError(error);
      debugPrint('Supabase load error: $error\n$stackTrace');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadServices() async {
    final rows = await _database!
        .from('services')
        .select(
          'id,name,description,category,duration_minutes,price_from,deposit_amount,active,bookable',
        )
        .order('name');

    services
      ..clear()
      ..addAll(
        (rows as List)
            .map((row) => SalonService.fromMap(Map<String, dynamic>.from(row)))
            .where((service) => service.active),
      );
  }

  /// During the prototype this tries to load the management data directly.
  /// If RLS blocks it (recommended for anonymous users), bookings still work
  /// through the secure RPC and the management screens simply show session data.
  Future<void> _tryLoadAdminData() async {
    try {
      final customerRows = await _database!
          .from('customers')
          .select('id,name,email,phone')
          .order('name');

      final remoteCustomers = (customerRows as List)
          .map((row) => Customer.fromMap(Map<String, dynamic>.from(row)))
          .toList();

      final appointmentRows = await _database!
          .from('appointments')
          .select(
            'id,customer_id,service_id,starts_at,idea,placement,consent_complete,deposit_paid,status',
          )
          .order('starts_at');

      final customerById = {for (final c in remoteCustomers) c.id: c};
      final serviceById = {for (final s in services) s.id: s};
      final remoteAppointments = <Appointment>[];

      for (final raw in appointmentRows as List) {
        final row = Map<String, dynamic>.from(raw);
        final customerId = _asInt(row['customer_id']);
        final serviceId = _asInt(row['service_id']);
        final customer = customerById[customerId];
        final service = serviceById[serviceId];
        if (customer == null || service == null) continue;

        remoteAppointments.add(
          Appointment(
            id: _asInt(row['id']),
            customerId: customerId,
            customerName: customer.name,
            email: customer.email,
            phone: customer.phone,
            service: service,
            startsAt: DateTime.parse(row['starts_at'].toString()).toLocal(),
            idea: (row['idea'] ?? '').toString(),
            placement: (row['placement'] ?? '').toString(),
            consentComplete: row['consent_complete'] as bool? ?? false,
            depositPaid: row['deposit_paid'] as bool? ?? false,
            status: (row['status'] ?? 'requested').toString(),
          ),
        );
      }

      customers
        ..clear()
        ..addAll(remoteCustomers);
      appointments
        ..clear()
        ..addAll(remoteAppointments);
    } catch (error) {
      // This is expected when RLS protects customer and appointment data.
      debugPrint('Admin data not available for current database role: $error');
    }
  }

  Future<Appointment> createAppointment({
    required String customerName,
    required String email,
    required String phone,
    required SalonService service,
    required DateTime startsAt,
    required String idea,
    required String placement,
    required bool consentComplete,
  }) async {
    if (_database == null) {
      throw StateError(
        'Supabase is nog niet ingesteld. Vul config/supabase.json in en start met --dart-define-from-file=config/supabase.json.',
      );
    }

    final cleanName = customerName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim();

    try {
      final rpcResult = await _database!.rpc(
        'create_appointment_request',
        params: {
          'p_name': cleanName,
          'p_email': cleanEmail,
          'p_phone': cleanPhone,
          'p_service_id': service.id,
          'p_starts_at': startsAt.toUtc().toIso8601String(),
          'p_idea': idea.trim(),
          'p_placement': placement.trim(),
          'p_consent_complete': consentComplete,
        },
      );

      final row = _firstMap(rpcResult);
      if (row != null) {
        return _addToSession(
          appointmentId: _asInt(row['appointment_id']),
          customerId: _asInt(row['customer_id']),
          customerName: cleanName,
          email: cleanEmail,
          phone: cleanPhone,
          service: service,
          startsAt: startsAt,
          idea: idea.trim(),
          placement: placement.trim(),
          consentComplete: consentComplete,
        );
      }
    } on PostgrestException catch (error) {
      if (!_functionMissing(error)) rethrow;
      debugPrint(
        'create_appointment_request RPC ontbreekt; probeer directe prototype-insert.',
      );
    }

    // Prototype fallback. This works only while the tables allow direct access.
    // Run supabase/setup.sql to switch to the safer RPC/RLS setup.
    final existingRows = await _database!
        .from('customers')
        .select('id,name,email,phone')
        .eq('email', cleanEmail)
        .limit(1);

    late final Map<String, dynamic> customerRow;
    if ((existingRows as List).isEmpty) {
      customerRow = Map<String, dynamic>.from(
        await _database!
            .from('customers')
            .insert({
              'name': cleanName,
              'email': cleanEmail,
              'phone': cleanPhone,
            })
            .select('id,name,email,phone')
            .single(),
      );
    } else {
      final id = _asInt((existingRows as List).first['id']);
      customerRow = Map<String, dynamic>.from(
        await _database!
            .from('customers')
            .update({'name': cleanName, 'phone': cleanPhone})
            .eq('id', id)
            .select('id,name,email,phone')
            .single(),
      );
    }

    final customerId = _asInt(customerRow['id']);

    final appointmentRow = await _database!
        .from('appointments')
        .insert({
          'customer_id': customerId,
          'service_id': service.id,
          'starts_at': startsAt.toUtc().toIso8601String(),
          'idea': idea.trim(),
          'placement': placement.trim(),
          'consent_complete': consentComplete,
          'deposit_paid': false,
          'status': 'requested',
        })
        .select('id')
        .single();

    return _addToSession(
      appointmentId: _asInt(appointmentRow['id']),
      customerId: customerId,
      customerName: cleanName,
      email: cleanEmail,
      phone: cleanPhone,
      service: service,
      startsAt: startsAt,
      idea: idea.trim(),
      placement: placement.trim(),
      consentComplete: consentComplete,
    );
  }

  Appointment _addToSession({
    required int appointmentId,
    required int customerId,
    required String customerName,
    required String email,
    required String phone,
    required SalonService service,
    required DateTime startsAt,
    required String idea,
    required String placement,
    required bool consentComplete,
  }) {
    final appointment = Appointment(
      id: appointmentId,
      customerId: customerId,
      customerName: customerName,
      email: email,
      phone: phone,
      service: service,
      startsAt: startsAt,
      idea: idea,
      placement: placement,
      consentComplete: consentComplete,
      depositPaid: false,
      status: 'requested',
    );

    appointments.removeWhere((item) => item.id == appointmentId);
    appointments.add(appointment);

    final existingIndex = customers.indexWhere((item) => item.id == customerId);
    final customer = Customer(
      id: customerId,
      name: customerName,
      email: email,
      phone: phone,
    );
    if (existingIndex >= 0) {
      customers[existingIndex] = customer;
    } else {
      customers.add(customer);
    }

    notifyListeners();
    return appointment;
  }

  void setAdminMode(bool value) {
    adminMode = value;
    notifyListeners();
  }

  static bool _functionMissing(PostgrestException error) {
    final text = '${error.code} ${error.message} ${error.details}'.toLowerCase();
    return text.contains('pgrst202') ||
        text.contains('could not find the function') ||
        (text.contains('create_appointment_request') &&
            text.contains('does not exist'));
  }

  static Map<String, dynamic>? _firstMap(dynamic value) {
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _cleanError(Object error) {
    if (error is PostgrestException) return error.message;
    return error.toString();
  }
}
