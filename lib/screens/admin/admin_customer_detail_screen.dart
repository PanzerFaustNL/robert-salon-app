import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../services/app_store.dart';
import 'admin_appointment_detail_screen.dart';

class AdminCustomerDetailScreen extends StatefulWidget {
  final AppStore store;
  final int customerId;

  const AdminCustomerDetailScreen({
    super.key,
    required this.store,
    required this.customerId,
  });

  @override
  State<AdminCustomerDetailScreen> createState() =>
      _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState
    extends State<AdminCustomerDetailScreen> {
  final picker = ImagePicker();
  late final TextEditingController notes;
  List<CustomerPhoto> photos = [];
  bool loadingPhotos = false;
  bool saving = false;

  Customer? get customer {
    for (final item in widget.store.customers) {
      if (item.id == widget.customerId) return item;
    }
    return null;
  }

  List<Appointment> get history {
    final result = widget.store.appointments
        .where((a) => a.customerId == widget.customerId)
        .toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return result;
  }

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
    notes = TextEditingController(text: customer?.notes ?? '');
    _loadPhotos();
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    notes.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPhotos() async {
    setState(() => loadingPhotos = true);
    try {
      final loaded =
          await widget.store.loadCustomerPhotos(widget.customerId);
      if (mounted) setState(() => photos = loaded);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto’s laden mislukt: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => loadingPhotos = false);
    }
  }

  Future<void> _saveNotes() async {
    setState(() => saving = true);
    try {
      await widget.store.updateCustomerNotes(
        widget.customerId,
        notes.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klantnotities opgeslagen.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opslaan mislukt: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _choosePhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Kies uit fotobibliotheek'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Maak een foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final file = await picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (file == null || !mounted) return;

    await _showUploadDialog(file);
  }

  Future<void> _showUploadDialog(XFile file) async {
    String type = 'result';
    final caption = TextEditingController();
    int? appointmentId = history.isNotEmpty ? history.first.id : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Foto toevoegen'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type foto'),
                  items: const [
                    DropdownMenuItem(
                      value: 'reference',
                      child: Text('Referentie'),
                    ),
                    DropdownMenuItem(
                      value: 'design',
                      child: Text('Ontwerp'),
                    ),
                    DropdownMenuItem(
                      value: 'before',
                      child: Text('Voor'),
                    ),
                    DropdownMenuItem(
                      value: 'result',
                      child: Text('Resultaat'),
                    ),
                    DropdownMenuItem(
                      value: 'healed',
                      child: Text('Genezen'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => type = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  value: appointmentId,
                  decoration: const InputDecoration(
                    labelText: 'Koppel aan afspraak',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Geen specifieke afspraak'),
                    ),
                    ...history.map(
                      (a) => DropdownMenuItem<int?>(
                        value: a.id,
                        child: Text(
                          '${DateFormat('dd-MM-yyyy').format(a.startsAt)} • ${a.service.name}',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => appointmentId = value),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: caption,
                  decoration: const InputDecoration(
                    labelText: 'Bijschrift',
                    hintText: 'Bijvoorbeeld: eindresultaat na sessie 2',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuleren'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Uploaden'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      caption.dispose();
      return;
    }

    setState(() => saving = true);
    try {
      final photo = await widget.store.uploadCustomerPhoto(
        customerId: widget.customerId,
        appointmentId: appointmentId,
        file: file,
        photoType: type,
        caption: caption.text,
      );
      if (mounted) {
        setState(() => photos.insert(0, photo));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaden mislukt: $error')),
        );
      }
    } finally {
      caption.dispose();
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _deletePhoto(CustomerPhoto photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Foto verwijderen?'),
        content: const Text(
          'De foto wordt uit het klantdossier en uit Supabase Storage verwijderd.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.store.deleteCustomerPhoto(photo);
      if (mounted) {
        setState(() => photos.removeWhere((p) => p.id == photo.id));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verwijderen mislukt: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = customer;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Klant')),
        body: const Center(child: Text('Klant niet gevonden.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          IconButton(
            tooltip: 'Foto toevoegen',
            onPressed: saving ? null : _choosePhotoSource,
            icon: const Icon(Icons.add_a_photo_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF24201A),
                    foregroundColor: AppColors.gold,
                    child: Icon(Icons.person_outline),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        SelectableText(c.email),
                        SelectableText(c.phone),
                        if (c.createdAt != null) ...[
                          const SizedBox(height: 7),
                          Text(
                            'Klant sinds ${DateFormat('dd-MM-yyyy').format(c.createdAt!)}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Klantnotities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: notes,
            minLines: 3,
            maxLines: 7,
            decoration: const InputDecoration(
              hintText: 'Voorkeuren, ontwerpinformatie, vervolgafspraken...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: saving ? null : _saveNotes,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Opslaan'),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Foto’s',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: saving ? null : _choosePhotoSource,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Toevoegen'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loadingPhotos)
            const Center(child: CircularProgressIndicator())
          else if (photos.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Nog geen klantfoto’s. Voeg bijvoorbeeld een referentie, ontwerp, resultaat of genezen foto toe.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: .86,
              ),
              itemBuilder: (_, index) {
                final photo = photos[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onLongPress: () => _deletePhoto(photo),
                    onTap: photo.signedUrl == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _PhotoViewer(photo: photo),
                              ),
                            );
                          },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: photo.signedUrl == null
                              ? const Center(
                                  child: Icon(Icons.broken_image_outlined),
                                )
                              : Image.network(
                                  photo.signedUrl!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                photo.photoTypeLabel,
                                style: const TextStyle(
                                  color: AppColors.goldSoft,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              if (photo.caption.isNotEmpty)
                                Text(
                                  photo.caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 26),
          Text(
            'Afspraakgeschiedenis (${history.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Text(
              'Nog geen afspraken.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            ...history.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminAppointmentDetailScreen(
                            store: widget.store,
                            appointmentId: a.id,
                          ),
                        ),
                      );
                    },
                    title: Text(a.service.name),
                    subtitle: Text(
                      '${DateFormat('dd-MM-yyyy • HH:mm').format(a.startsAt)}\n${a.idea}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      a.statusLabel,
                      style: const TextStyle(color: AppColors.goldSoft),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final CustomerPhoto photo;
  const _PhotoViewer({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(photo.photoTypeLabel),
      ),
      body: Center(
        child: photo.signedUrl == null
            ? const Icon(Icons.broken_image_outlined, size: 60)
            : InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.network(
                  photo.signedUrl!,
                  fit: BoxFit.contain,
                ),
              ),
      ),
    );
  }
}
