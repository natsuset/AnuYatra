import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';

/// Reusable photo management widget for candidate profiles.
/// Allows adding photos from camera or gallery.
class PhotoManagerWidget extends StatefulWidget {
  /// Initial list of photo paths (can be URLs or local paths)
  final List<String> initialPhotos;

  /// Maximum number of photos allowed
  final int maxPhotos;

  /// Callback when photos list changes
  final ValueChanged<List<String>> onPhotosChanged;

  const PhotoManagerWidget({
    super.key,
    this.initialPhotos = const [],
    this.maxPhotos = 6,
    required this.onPhotosChanged,
  });

  @override
  State<PhotoManagerWidget> createState() => _PhotoManagerWidgetState();
}

class _PhotoManagerWidgetState extends State<PhotoManagerWidget> {
  late List<String> _photos;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
  }

  /// Max bytes per stored photo (PRODUCT_PLAN §1.7 — 3 MB cap after the
  /// `image_picker` long-edge resize). Files larger than this are rejected
  /// with a snackbar; users can retake / pick a different photo.
  static const int _maxBytesPerPhoto = 3 * 1024 * 1024;

  /// Copy a picked [XFile] (a temp path the OS may clean up) into the app's
  /// documents directory so the photo survives restarts. Returns the new
  /// permanent path, or `null` if the file exceeds [_maxBytesPerPhoto].
  Future<String?> _persistPickedImage(XFile picked) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/candidate_photos');
    if (!await dir.exists()) await dir.create(recursive: true);

    final ext = picked.path.contains('.')
        ? picked.path.split('.').last.toLowerCase()
        : 'jpg';
    final ts = DateTime.now().microsecondsSinceEpoch;
    final dest = File('${dir.path}/$ts.$ext');

    // image_picker already resized via maxWidth/maxHeight; here we just
    // copy and enforce the size cap.
    final source = File(picked.path);
    final bytes = await source.length();
    if (bytes > _maxBytesPerPhoto) return null;
    await source.copy(dest.path);
    return dest.path;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_photos.length >= widget.maxPhotos) {
      _showSnack('Maximum ${widget.maxPhotos} photos allowed');
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked == null) return;

      final persisted = await _persistPickedImage(picked);
      if (persisted == null) {
        _showSnack('That image is over 3 MB. Try a smaller / shorter photo.');
        return;
      }

      if (!mounted) return;
      setState(() => _photos.add(persisted));
      widget.onPhotosChanged(_photos);
    } catch (e) {
      _showSnack('Failed to pick image: $e', error: true);
    }
  }

  Future<void> _pickMultiple() async {
    final remaining = widget.maxPhotos - _photos.length;
    if (remaining <= 0) {
      _showSnack('Maximum ${widget.maxPhotos} photos allowed');
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
        limit: remaining,
      );
      if (picked.isEmpty) return;

      var rejected = 0;
      final newPaths = <String>[];
      for (final img in picked.take(remaining)) {
        final p = await _persistPickedImage(img);
        if (p == null) {
          rejected++;
        } else {
          newPaths.add(p);
        }
      }

      if (!mounted) return;
      setState(() => _photos.addAll(newPaths));
      widget.onPhotosChanged(_photos);

      if (rejected > 0) {
        _showSnack(
          '$rejected photo${rejected == 1 ? '' : 's'} skipped (over 3 MB).',
        );
      }
    } catch (e) {
      _showSnack('Failed to pick images: $e', error: true);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? context.palette.error : null,
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
    widget.onPhotosChanged(_photos);
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add Photos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.camera_alt,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  title: const Text('Take a Photo'),
                  subtitle: const Text('Use camera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.palette.info.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.photo_library, color: context.palette.info),
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Pick one photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.palette.success.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.photo_library_outlined,
                        color: context.palette.success),
                  ),
                  title: const Text('Choose Multiple'),
                  subtitle: Text(
                      'Up to ${widget.maxPhotos - _photos.length} more photos'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMultiple();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${_photos.length}/${widget.maxPhotos}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Photo grid
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Existing photos
              ..._photos.asMap().entries.map((entry) {
                final idx = entry.key;
                final path = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildPhotoThumbnail(path, isDark),
                      ),
                      // Remove button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(idx),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: context.palette.error.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // First photo badge
                      if (idx == 0)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Primary',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              // Add photo button
              if (_photos.length < widget.maxPhotos)
                GestureDetector(
                  onTap: _showPickerOptions,
                  child: Container(
                    width: 100,
                    height: 110,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (_photos.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Add photos to make the profile more attractive',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoThumbnail(String path, bool isDark) {
    // Check if it's a local file path
    if (path.startsWith('/') || path.startsWith('file://')) {
      final file = File(path.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 100,
          height: 110,
          fit: BoxFit.cover,
        );
      }
    }

    // Fallback: placeholder
    return Container(
      width: 100,
      height: 110,
      color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 32,
            color: isDark ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            'Photo',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
