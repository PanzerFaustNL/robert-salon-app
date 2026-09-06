import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class AppStore extends ChangeNotifier {
  final SupabaseClient? _database;
  StreamSubscription<AuthState>? _authSubscription;

  final List<SalonService> services = [];
  final List<Appointment> appointments = [];
  final List<Customer> customers = [];
  final List<Payment> payments = [];

  bool loading = false;
  bool adminLoading = false;
  bool isOwner = false;
  String? databaseError;
  String? adminError;
  User? currentUser;

  AppStore({SupabaseClient? database}) : _database = database;

  bool get databaseConfigured => _database != null;
  bool get databaseConnected => databaseConfigured && databaseError == null;
  String? get ownerEmail => currentUser?.email;

  Future<void> initialize() async {
    if (_database == null) return;

    _authSubscription = _database.auth.onAuthStateChange.listen((state) {
      _syncAuthState();
    });

    await refreshAll();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> refreshAll() async {
    if (_database == null) return;

    loading = true;
    databaseError = null;
    notifyListeners();

    try {
      await _syncAuthState(notify: false);
      await _loadServices();
      if (isOwner) {
        await loadAdminData(notify: false);
      } else {
        appointments.clear();
        customers.clear();
        payments.clear();
      }
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
        (rows as List).map(
          (row) => SalonService.fromMap(Map<String, dynamic>.from(row)),
        ),
      );
  }

  Future<void> _syncAuthState({bool notify = true}) async {
    if (_database == null) return;

    currentUser = _database.auth.currentUser;
    isOwner = false;

    final user = currentUser;
    if (user != null) {
      try {
        final rows = await _database
            .from('user_roles')
            .select('role')
            .eq('user_id', user.id)
            .limit(1);

        if ((rows as List).isNotEmpty) {
          final role = (rows.first['role'] ?? '').toString();
          isOwner = role == 'owner';
        }
      } catch (error) {
        debugPrint('Owner role lookup failed: $error');
      }
    }

    if (notify) notifyListeners();
  }

  Future<void> signInOwner({
    required String email,
    required String password,
  }) async {
    if (_database == null) {
      throw StateError('Supabase is niet ingesteld.');
    }

    adminError = null;
    adminLoading = true;
    notifyListeners();

    try {
      await _database.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      await _syncAuthState(notify: false);

      if (!isOwner) {
        await _database.auth.signOut();
        currentUser = null;
        throw StateError(
          'Dit account heeft geen owner-rol voor Roberts salon.',
        );
      }

      await loadAdminData(notify: false);
    } catch (error) {
      adminError = _cleanError(error);
      rethrow;
    } finally {
      adminLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOutOwner() async {
    if (_database == null) return;
    await _database.auth.signOut();
    currentUser = null;
    isOwner = false;
    customers.clear();
    appointments.clear();
    payments.clear();
    notifyListeners();
  }

  Future<void> loadAdminData({bool notify = true}) async {
    if (_database == null || !isOwner) return;

    adminLoading = true;
    adminError = null;
    if (notify) notifyListeners();

    try {
      // Owner policy allows all services, including inactive historical ones.
      await _loadServices();

      final customerRows = await _database
          .from('customers')
          .select('id,name,email,phone,notes,created_at')
          .order('name');

      final remoteCustomers = (customerRows as List)
          .map((row) => Customer.fromMap(Map<String, dynamic>.from(row)))
          .toList();

      final appointmentRows = await _database
          .from('appointments')
          .select(
            'id,customer_id,service_id,starts_at,idea,placement,consent_complete,consent_received,deposit_paid,status,internal_notes',
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
            consentReceived: row['consent_received'] as bool? ?? false,
            depositPaid: row['deposit_paid'] as bool? ?? false,
            status: (row['status'] ?? 'requested').toString(),
            internalNotes: (row['internal_notes'] ?? '').toString(),
          ),
        );
      }

      final paymentRows = await _database
          .from('payments')
          .select(
            'id,appointment_id,amount,kind,status,provider,provider_payment_id,paid_at,created_at',
          )
          .order('created_at', ascending: false);

      customers
        ..clear()
        ..addAll(remoteCustomers);
      appointments
        ..clear()
        ..addAll(remoteAppointments);
      payments
        ..clear()
        ..addAll(
          (paymentRows as List)
              .map((row) => Payment.fromMap(Map<String, dynamic>.from(row))),
        );
    } catch (error, stackTrace) {
      adminError = _cleanError(error);
      debugPrint('Admin load error: $error\n$stackTrace');
    } finally {
      adminLoading = false;
      if (notify) notifyListeners();
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
        'Supabase is nog niet ingesteld. Controleer lib/config/supabase_config.dart.',
      );
    }

    final cleanName = customerName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim();

    final rpcResult = await _database.rpc(
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
    if (row == null) {
      throw StateError('De afspraak is opgeslagen, maar het resultaat ontbreekt.');
    }

    final appointment = Appointment(
      id: _asInt(row['appointment_id']),
      customerId: _asInt(row['customer_id']),
      customerName: cleanName,
      email: cleanEmail,
      phone: cleanPhone,
      service: service,
      startsAt: startsAt,
      idea: idea.trim(),
      placement: placement.trim(),
      consentComplete: consentComplete,
      consentReceived: false,
      depositPaid: false,
      status: 'requested',
      internalNotes: '',
    );

    appointments.removeWhere((item) => item.id == appointment.id);
    appointments.add(appointment);
    notifyListeners();
    return appointment;
  }

  Future<void> updateAppointmentStatus(
    int appointmentId,
    String status,
  ) async {
    _requireOwner();

    await _database!
        .from('appointments')
        .update({'status': status})
        .eq('id', appointmentId);

    final index = appointments.indexWhere((a) => a.id == appointmentId);
    if (index >= 0) {
      appointments[index] = appointments[index].copyWith(status: status);
    }
    notifyListeners();
  }

  Future<void> setConsentReceived(
    int appointmentId,
    bool value,
  ) async {
    _requireOwner();

    await _database!
        .from('appointments')
        .update({'consent_received': value})
        .eq('id', appointmentId);

    final index = appointments.indexWhere((a) => a.id == appointmentId);
    if (index >= 0) {
      appointments[index] =
          appointments[index].copyWith(consentReceived: value);
    }
    notifyListeners();
  }

  Future<void> updateAppointmentNotes(
    int appointmentId,
    String notes,
  ) async {
    _requireOwner();

    await _database!
        .from('appointments')
        .update({'internal_notes': notes.trim()})
        .eq('id', appointmentId);

    final index = appointments.indexWhere((a) => a.id == appointmentId);
    if (index >= 0) {
      appointments[index] =
          appointments[index].copyWith(internalNotes: notes.trim());
    }
    notifyListeners();
  }

  Future<void> updateCustomerNotes(int customerId, String notes) async {
    _requireOwner();

    await _database!
        .from('customers')
        .update({'notes': notes.trim()})
        .eq('id', customerId);

    final index = customers.indexWhere((c) => c.id == customerId);
    if (index >= 0) {
      customers[index] = customers[index].copyWith(notes: notes.trim());
    }
    notifyListeners();
  }

  Future<Payment> recordPayment({
    required Appointment appointment,
    required double amount,
    required String kind,
  }) async {
    _requireOwner();

    final row = await _database!
        .from('payments')
        .insert({
          'appointment_id': appointment.id,
          'amount': amount,
          'kind': kind,
          'status': 'paid',
          'provider': 'manual',
          'paid_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select(
          'id,appointment_id,amount,kind,status,provider,provider_payment_id,paid_at,created_at',
        )
        .single();

    final payment = Payment.fromMap(Map<String, dynamic>.from(row));
    payments.insert(0, payment);

    if (kind == 'deposit' && !appointment.depositPaid) {
      await _database!
          .from('appointments')
          .update({'deposit_paid': true})
          .eq('id', appointment.id);

      final index = appointments.indexWhere((a) => a.id == appointment.id);
      if (index >= 0) {
        appointments[index] =
            appointments[index].copyWith(depositPaid: true);
      }
    }

    notifyListeners();
    return payment;
  }

  Future<List<CustomerPhoto>> loadCustomerPhotos(int customerId) async {
    _requireOwner();

    final rows = await _database!
        .from('customer_photos')
        .select(
          'id,customer_id,appointment_id,storage_path,photo_type,caption,created_at',
        )
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    final result = <CustomerPhoto>[];

    for (final raw in rows as List) {
      final map = Map<String, dynamic>.from(raw);
      final path = (map['storage_path'] ?? '').toString();
      String? signedUrl;

      if (path.isNotEmpty) {
        try {
          signedUrl = await _database!.storage
              .from('customer-photos')
              .createSignedUrl(path, 60 * 60);
        } catch (error) {
          debugPrint('Signed URL failed for $path: $error');
        }
      }

      result.add(CustomerPhoto.fromMap(map, signedUrl: signedUrl));
    }

    return result;
  }

  Future<CustomerPhoto> uploadCustomerPhoto({
    required int customerId,
    int? appointmentId,
    required XFile file,
    required String photoType,
    required String caption,
  }) async {
    _requireOwner();

    final bytes = await file.readAsBytes();
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '$customerId/${DateTime.now().microsecondsSinceEpoch}_$safeName';

    await _database!.storage.from('customer-photos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentType(file.name),
            upsert: false,
          ),
        );

    try {
      final row = await _database!
          .from('customer_photos')
          .insert({
            'customer_id': customerId,
            'appointment_id': appointmentId,
            'storage_path': path,
            'photo_type': photoType,
            'caption': caption.trim(),
          })
          .select(
            'id,customer_id,appointment_id,storage_path,photo_type,caption,created_at',
          )
          .single();

      final signedUrl = await _database!.storage
          .from('customer-photos')
          .createSignedUrl(path, 60 * 60);

      return CustomerPhoto.fromMap(
        Map<String, dynamic>.from(row),
        signedUrl: signedUrl,
      );
    } catch (_) {
      await _database!.storage.from('customer-photos').remove([path]);
      rethrow;
    }
  }

  Future<void> deleteCustomerPhoto(CustomerPhoto photo) async {
    _requireOwner();

    await _database!.storage
        .from('customer-photos')
        .remove([photo.storagePath]);
    await _database!
        .from('customer_photos')
        .delete()
        .eq('id', photo.id);
  }

  void _requireOwner() {
    if (_database == null) {
      throw StateError('Supabase is niet ingesteld.');
    }
    if (!isOwner) {
      throw StateError('Alleen het owner-account mag dit uitvoeren.');
    }
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

  static String _contentType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  static String _cleanError(Object error) {
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return error.message;
    if (error is StorageException) return error.message;
    return error.toString();
  }
}
