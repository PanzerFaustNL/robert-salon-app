import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/external_links.dart';
import '../services/wordpress_gallery_service.dart';
import '../widgets/section_title.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _service = WordPressGalleryService();
  final Map<String, List<String>> _images = {};
  bool _loading = true;
  int _selectedIndex = 0;

  WordPressGalleryDefinition get _selectedGallery =>
      WordPressGalleryService.galleries[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    final result = <String, List<String>>{};

    await Future.wait(
      WordPressGalleryService.galleries.map((gallery) async {
        result[gallery.slug] = await _service.loadImages(gallery);
      }),
    );

    if (!mounted) return;

    setState(() {
      _images
        ..clear()
        ..addAll(result);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gallery = _selectedGallery;
    final images = _images[gallery.slug] ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            tooltip: 'Galerijen vernieuwen',
            onPressed: _loading ? null : _loadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            const SectionTitle(
              eyebrow: 'Werk van Robert',
              title: 'Portfolio',
              subtitle:
                  'De galerijen worden rechtstreeks vanuit Roberts WordPress-site geladen.',
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: WordPressGalleryService.galleries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final item = WordPressGalleryService.galleries[index];
                  final selected = index == _selectedIndex;
                  return ChoiceChip(
                    label: Text(_shortTitle(item.title)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedIndex = index);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    gallery.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final ok = await ExternalLinks.openWebsite(gallery.pageUrl);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('De WordPress-galerij kon niet worden geopend.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Website'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading && images.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (images.isEmpty)
              _EmptyGallery(onRetry: _loadAll)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 950
                      ? 4
                      : constraints.maxWidth >= 650
                          ? 3
                          : 2;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: images.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: .82,
                    ),
                    itemBuilder: (_, index) {
                      final imageUrl = images[index];
                      return _PortfolioTile(
                        imageUrl: imageUrl,
                        heroTag: '${gallery.slug}-$index',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _GalleryViewer(
                                title: gallery.title,
                                images: images,
                                initialIndex: index,
                                tagPrefix: gallery.slug,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _shortTitle(String value) {
    switch (value) {
      case 'Tattoos Black & Grey':
        return 'Black & Grey';
      case 'Tattoos Color & Realism':
        return 'Color & Realism';
      case 'Schilderijen Olieverf':
        return 'Olieverf';
      default:
        return 'Acryl & Mixed';
    }
  }
}

class _PortfolioTile extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final VoidCallback onTap;

  const _PortfolioTile({
    required this.imageUrl,
    required this.heroTag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161618),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Hero(
          tag: heroTag,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.muted,
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  final String title;
  final List<String> images;
  final int initialIndex;
  final String tagPrefix;

  const _GalleryViewer({
    required this.title,
    required this.images,
    required this.initialIndex,
    required this.tagPrefix,
  });

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${widget.title}  ${_currentIndex + 1}/${widget.images.length}',
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (_, index) {
          return Center(
            child: Hero(
              tag: '${widget.tagPrefix}-$index',
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 50,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _EmptyGallery({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 42,
              color: AppColors.gold,
            ),
            const SizedBox(height: 12),
            const Text(
              'De galerij kon niet worden geladen.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Controleer de internetverbinding of probeer de WordPress-galerij opnieuw te laden.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      ),
    );
  }
}
