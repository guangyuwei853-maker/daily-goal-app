import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../utils/photo_manager.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<_PhotoEntry> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final dates = await PhotoManager.getAllPhotoDates();
    final entries = <_PhotoEntry>[];

    for (final date in dates) {
      if (kIsWeb) {
        final bytes = await PhotoManager.getPhotoBytes(date);
        if (bytes != null) {
          entries.add(_PhotoEntry(date: date, bytes: bytes));
        }
      } else {
        final file = await PhotoManager.getPhoto(date);
        if (file != null) {
          entries.add(_PhotoEntry(date: date, file: file));
        }
      }
    }

    if (mounted) {
      setState(() {
        _photos = entries;
        _loading = false;
      });
    }
  }

  void _startSlideshow() {
    if (_photos.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SlideshowScreen(photos: _photos),
      ),
    );
  }

  void _viewPhoto(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SinglePhotoView(
          photo: _photos[index],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('成长记录'),
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        actions: [
          if (_photos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_filled),
              tooltip: '播放幻灯片',
              onPressed: _startSlideshow,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? _buildEmptyState()
              : _buildGrid(),
      floatingActionButton: _photos.isNotEmpty
          ? FloatingActionButton(
              onPressed: _startSlideshow,
              backgroundColor: const Color(0xFF667eea),
              child: const Icon(Icons.play_arrow, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '还没有照片',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            '开始记录每一天的变化吧！',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return GestureDetector(
          onTap: () => _viewPhoto(index),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: photo.file != null
                        ? Image.file(photo.file!, fit: BoxFit.cover, width: double.infinity)
                        : Image.memory(
                            Uint8List.fromList(photo.bytes!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateLabel(photo.date),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateLabel(String dateStr) {
    // dateStr is YYYY-MM-DD
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      return '${parts[1]}/${parts[2]}';
    }
    return dateStr;
  }
}

// ====== Slideshow Screen ======

class _SlideshowScreen extends StatefulWidget {
  final List<_PhotoEntry> photos;

  const _SlideshowScreen({required this.photos});

  @override
  State<_SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<_SlideshowScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isPlaying = true;
  Timer? _timer;
  late AnimationController _fadeController;
  late AnimationController _zoomController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _zoomController.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isPlaying) return;
      _nextPhoto();
    });
  }

  void _nextPhoto() {
    if (_currentIndex >= widget.photos.length - 1) {
      _timer?.cancel();
      _showCompletionDialog();
      return;
    }

    _fadeController.reset();
    _zoomController.reset();
    setState(() {
      _currentIndex++;
    });
    _fadeController.forward();
    _zoomController.forward();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('回顾完成', textAlign: TextAlign.center),
        content: Text(
          '共${widget.photos.length}天的坚持！',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('完成'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentIndex = 0;
                _isPlaying = true;
              });
              _fadeController.reset();
              _fadeController.forward();
              _zoomController.reset();
              _zoomController.forward();
              _startTimer();
            },
            child: const Text('再看一次'),
          ),
        ],
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];
    final progress = (widget.photos.length > 1)
        ? _currentIndex / (widget.photos.length - 1)
        : 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo with Ken Burns effect
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: AnimatedBuilder(
                    animation: _zoomController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _zoomAnimation.value,
                        child: child,
                      );
                    },
                    child: child,
                  ),
                );
              },
              child: photo.file != null
                  ? Image.file(photo.file!, fit: BoxFit.cover, key: ValueKey(_currentIndex))
                  : Image.memory(
                      Uint8List.fromList(photo.bytes!),
                      fit: BoxFit.cover,
                      key: ValueKey(_currentIndex),
                    ),
            ),
            // Date overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    photo.date,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // Pause indicator
            if (!_isPlaying)
              const Center(
                child: Icon(
                  Icons.pause_circle_filled,
                  color: Colors.white70,
                  size: 72,
                ),
              ),
            // Counter
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.photos.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
            // Progress bar at bottom
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF667eea)),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Single Photo View ======

class _SinglePhotoView extends StatelessWidget {
  final _PhotoEntry photo;

  const _SinglePhotoView({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(photo.date),
      ),
      body: Center(
        child: InteractiveViewer(
          child: photo.file != null
              ? Image.file(photo.file!, fit: BoxFit.contain)
              : Image.memory(
                  Uint8List.fromList(photo.bytes!),
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}

// ====== Data Model ======

class _PhotoEntry {
  final String date;
  final File? file;
  final List<int>? bytes;

  _PhotoEntry({required this.date, this.file, this.bytes});
}
