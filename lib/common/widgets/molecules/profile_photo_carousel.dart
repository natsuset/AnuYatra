import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Horizontally swipeable photo strip for a candidate profile.
///
/// - Takes a list of photo paths (URLs or local file paths — auto-detected).
/// - Renders a `PageView.builder` so only the visible page is decoded.
/// - Shows a small dot-indicator overlay when there's more than one photo.
/// - Falls back to a tinted-letter placeholder when [photos] is empty.
///
/// Caller controls the height. The widget always fills the parent's width.
class ProfilePhotoCarousel extends StatefulWidget {
  final List<String> photos;

  /// Initial letter shown when [photos] is empty (typically the profile name).
  final String fallbackInitial;

  /// Height of the carousel. Caller decides the aspect.
  final double height;

  /// Corner radius applied to the carousel surface.
  final BorderRadiusGeometry borderRadius;

  const ProfilePhotoCarousel({
    super.key,
    required this.photos,
    required this.fallbackInitial,
    this.height = 220,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  State<ProfilePhotoCarousel> createState() => _ProfilePhotoCarouselState();
}

class _ProfilePhotoCarouselState extends State<ProfilePhotoCarousel> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(ProfilePhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.photos, widget.photos)) {
      _index = 0;
      // jumpToPage needs the controller to be attached to a live PageView,
      // so defer to the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (widget.photos.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Container(
            color: colors.primary.withValues(alpha: 0.08),
            alignment: Alignment.center,
            child: Text(
              widget.fallbackInitial.isNotEmpty
                  ? widget.fallbackInitial[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _FullScreenGallery.open(context, widget.photos, i),
                child: _PhotoTile(path: widget.photos[i]),
              ),
            ),
            if (widget.photos.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: _DotIndicator(
                  count: widget.photos.length,
                  active: _index,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  const _PhotoTile({required this.path});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.broken_image_outlined,
            color: colors.onSurfaceVariant, size: 32),
      ),
    );

    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(
            color: colors.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    // Local file path (slice 9: photo upload writes to app sandbox).
    final file = File(path);
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int active;

  const _DotIndicator({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.55),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Full-screen gallery overlay ───────────────────────────────────────────────

class _FullScreenGallery extends StatefulWidget {
  const _FullScreenGallery({required this.photos, required this.initialIndex});
  final List<String> photos;
  final int initialIndex;

  static void open(BuildContext context, List<String> photos, int index) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenGallery(
          photos: photos,
          initialIndex: index,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _ctrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _prev() {
    if (_index > 0) _ctrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _next() {
    if (_index < widget.photos.length - 1) _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Photo pager ───────────────────────────────────────────────────
          PageView.builder(
            controller: _ctrl,
            itemCount: total,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(child: _PhotoTile(path: widget.photos[i])),
            ),
          ),

          // ── Top bar: page counter + close button ──────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_index + 1} / $total',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),

          // ── Left arrow ────────────────────────────────────────────────────
          if (_index > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: _prev,
                ),
              ),
            ),

          // ── Right arrow ───────────────────────────────────────────────────
          if (_index < total - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: _next,
                ),
              ),
            ),

          // ── Dot indicator ─────────────────────────────────────────────────
          if (total > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: _DotIndicator(count: total, active: _index),
            ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
