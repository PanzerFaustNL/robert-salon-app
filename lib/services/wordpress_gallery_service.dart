import 'dart:convert';

import 'package:http/http.dart' as http;

class WordPressGalleryDefinition {
  final String title;
  final String slug;
  final String pageUrl;
  final List<String> fallbackImages;

  const WordPressGalleryDefinition({
    required this.title,
    required this.slug,
    required this.pageUrl,
    required this.fallbackImages,
  });
}

class WordPressGalleryService {
  static const _host = 'www.robertveldmantattoo.nl';

  static const galleries = <WordPressGalleryDefinition>[
    WordPressGalleryDefinition(
      title: 'Tattoos Black & Grey',
      slug: 'tattoos-black-grey',
      pageUrl: 'https://www.robertveldmantattoo.nl/tattoos-black-grey/',
      fallbackImages: [
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/Tattoo-Nathalie-scaled.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC01935-1.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/IMG_5902-2.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC01712-2.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC01926-2.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC02188-2.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC01125-2.jpeg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC01934-2.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC02180-3.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC02323-1.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC02363-2.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC01872-1.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC01837-2.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC01912-2.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC01778-1.jpeg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2025/07/DSC01793-1.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2014/06/Robert-Veldman-Tattoo-Alkmaar12.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/WhatsApp-Image-2026-08-15-at-12.35.35.jpeg',
      ],
    ),
    WordPressGalleryDefinition(
      title: 'Tattoos Color & Realism',
      slug: 'tattoos-color-realism',
      pageUrl: 'https://www.robertveldmantattoo.nl/tattoos-color-realism/',
      fallbackImages: [
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/DSC01888-1.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/DSC00392-1.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/IMG_2877-Edit.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/IMG_2853.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/DSC02359.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/DSC01930.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/DSC01920-scaled.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/DSC01888.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/DSC01785.jpeg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/DSC01742-2.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/DSC00398.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/DSC00392.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/de-vos.jpeg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/WhatsApp-Image-2026-08-15-at-12.40.38.jpeg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/08/WhatsApp-Image-2026-08-15-at-12.36.24.jpeg',
      ],
    ),
    WordPressGalleryDefinition(
      title: 'Schilderijen Olieverf',
      slug: 'schilderijen-olieverf',
      pageUrl: 'https://www.robertveldmantattoo.nl/schilderijen-olieverf/',
      fallbackImages: [
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2014/06/cropped-Robert-Veldman-Tattoo-Alkmaar-olie-schilderij-paard.jpg',
      ],
    ),
    WordPressGalleryDefinition(
      title: 'Acryl & Mixed Media',
      slug: 'schilderijen-acryl-mixed-media',
      pageUrl: 'https://www.robertveldmantattoo.nl/schilderijen-acryl-mixed-media/',
      fallbackImages: [
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2018/10/John-Connery-4.jpg',
        'https://www.robertveldmantattoo.nl/wp-content/uploads/2026/07/welcome-lion.jpg',
      ],
    ),
  ];

  Future<List<String>> loadImages(WordPressGalleryDefinition gallery) async {
    try {
      final uri = Uri.https(
        _host,
        '/wp-json/wp/v2/pages',
        {
          'slug': gallery.slug,
          '_fields': 'content',
        },
      );

      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is Map<String, dynamic>) {
            final content = first['content'];
            if (content is Map<String, dynamic>) {
              final rendered = content['rendered'];
              if (rendered is String) {
                final images = _extractImageUrls(rendered);
                if (images.isNotEmpty) {
                  return images;
                }
              }
            }
          }
        }
      }
    } catch (_) {
      // De vaste WordPress-URLs hieronder blijven als veilige fallback werken.
    }

    return List<String>.from(gallery.fallbackImages);
  }

  List<String> _extractImageUrls(String html) {
    final found = <String>{};

    // WordPress/Envira zet doorgaans de grote afbeelding in href en daarnaast
    // een thumbnail in src. Daarom verwerken we href vóór src.
    final patterns = <RegExp>[
      RegExp(
        r'''href\s*=\s*["']([^"']+\.(?:jpe?g|png|webp)(?:\?[^"']*)?)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''(?:src|data-src|data-lazy-src)\s*=\s*["']([^"']+\.(?:jpe?g|png|webp)(?:\?[^"']*)?)["']''',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(html)) {
        final raw = match.group(1);
        if (raw == null || raw.isEmpty) continue;

        var value = raw
            .replaceAll('&amp;', '&')
            .replaceAll('&#038;', '&')
            .replaceAll(r'\/', '/');

        final parsed = Uri.tryParse(value);
        if (parsed == null) continue;

        final absolute = parsed.hasScheme
            ? parsed
            : Uri.parse('https://$_host').resolveUri(parsed);

        if (!absolute.path.contains('/wp-content/uploads/')) continue;

        final path = absolute.path.toLowerCase();
        if (!(path.endsWith('.jpg') ||
            path.endsWith('.jpeg') ||
            path.endsWith('.png') ||
            path.endsWith('.webp'))) {
          continue;
        }

        found.add(absolute.toString());
      }
    }

    return found.toList(growable: false);
  }
}
