import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/update_service.dart';
import '../theme/app_theme.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDownloading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryStart, AppColors.primaryEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.rocket_launch, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              '发现新版本 v${widget.updateInfo.version}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Changelog
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '新版本特性：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildChangelog(widget.updateInfo.changelog),
            ),
            const SizedBox(height: 16),
            // Progress indicator when downloading
            if (_isDownloading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
        actions: [
          // "稍后再说" button
          TextButton(
            onPressed: _isDownloading ? null : () => Navigator.of(context).pop(),
            child: Text(
              '稍后再说',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          // "立即更新" button with gradient
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryStart, AppColors.primaryEnd],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: MaterialButton(
              onPressed: _isDownloading ? null : _handleUpdate,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: const Text(
                '立即更新',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangelog(String changelog) {
    final lines = changelog.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        // Remove leading number/bullet markers for display
        final text = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('  •  ', style: TextStyle(color: AppColors.primaryStart)),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleUpdate() async {
    setState(() => _isDownloading = true);

    try {
      final url = Uri.parse(widget.updateInfo.downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开下载链接，请稍后重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
        Navigator.of(context).pop();
      }
    }
  }
}
