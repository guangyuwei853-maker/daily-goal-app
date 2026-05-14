import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/photo_manager.dart';

class PhotoSection extends StatefulWidget {
  final String dateStr; // YYYY-MM-DD format

  const PhotoSection({super.key, required this.dateStr});

  @override
  State<PhotoSection> createState() => _PhotoSectionState();
}

class _PhotoSectionState extends State<PhotoSection> {
  File? _photoFile;
  List<int>? _photoBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void didUpdateWidget(covariant PhotoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateStr != widget.dateStr) {
      _loadPhoto();
    }
  }

  Future<void> _loadPhoto() async {
    setState(() => _loading = true);
    if (kIsWeb) {
      final bytes = await PhotoManager.getPhotoBytes(widget.dateStr);
      if (mounted) {
        setState(() {
          _photoBytes = bytes;
          _loading = false;
        });
      }
    } else {
      final file = await PhotoManager.getPhoto(widget.dateStr);
      if (mounted) {
        setState(() {
          _photoFile = file;
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      await PhotoManager.savePhotoBytes(widget.dateStr, bytes);
      if (mounted) {
        setState(() {
          _photoBytes = bytes;
        });
      }
    } else {
      final file = File(pickedFile.path);
      await PhotoManager.savePhoto(widget.dateStr, file);
      final saved = await PhotoManager.getPhoto(widget.dateStr);
      if (mounted) {
        setState(() {
          _photoFile = saved;
        });
      }
    }
  }

  bool get _hasPhoto {
    if (kIsWeb) return _photoBytes != null;
    return _photoFile != null;
  }

  void _viewFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenPhoto(
          dateStr: widget.dateStr,
          file: _photoFile,
          bytes: _photoBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _hasPhoto ? _buildPhotoCard() : _buildPlaceholder(),
    );
  }

  Widget _buildPhotoCard() {
    return GestureDetector(
      onTap: _viewFullScreen,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (kIsWeb && _photoBytes != null)
                Image.memory(
                  Uint8List.fromList(_photoBytes!),
                  fit: BoxFit.cover,
                )
              else if (_photoFile != null)
                Image.file(
                  _photoFile!,
                  fit: BoxFit.cover,
                ),
              // Date overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.dateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              '拍照记录今天',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '记录每一天的变化',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenPhoto extends StatelessWidget {
  final String dateStr;
  final File? file;
  final List<int>? bytes;

  const _FullScreenPhoto({
    required this.dateStr,
    this.file,
    this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(dateStr),
      ),
      body: Center(
        child: InteractiveViewer(
          child: kIsWeb && bytes != null
              ? Image.memory(Uint8List.fromList(bytes!), fit: BoxFit.contain)
              : file != null
                  ? Image.file(file!, fit: BoxFit.contain)
                  : const SizedBox(),
        ),
      ),
    );
  }
}
