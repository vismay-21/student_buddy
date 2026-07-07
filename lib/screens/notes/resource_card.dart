import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/dto/notes/notes_dto.dart';

class ResourceCard extends StatelessWidget {
  final NotesResourceDto file;
  final bool isDownloading;
  final VoidCallback onDownload;
  final VoidCallback onEdit;

  const ResourceCard({
    super.key,
    required this.file,
    required this.isDownloading,
    required this.onDownload,
    required this.onEdit,
  });

  String _getFileType(String mime) {
    final m = mime.toLowerCase();
    if (m.contains('pdf')) return 'PDF';
    if (m.contains('presentation') || m.contains('powerpoint') || m.contains('ppt')) return 'PPT';
    if (m.contains('word') || m.contains('document') || m.contains('docx')) return 'DOCX';
    if (m.contains('image')) return 'IMAGE';
    if (m.contains('html') || m.contains('uri') || m.contains('link')) return 'LINK';
    
    // Check file extension as a fallback
    final ext = file.fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'PDF';
    if (ext == 'ppt' || ext == 'pptx') return 'PPT';
    if (ext == 'doc' || ext == 'docx') return 'DOCX';
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) return 'IMAGE';
    
    return 'Other';
  }

  IconData _getFileIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'PPT':
        return Icons.slideshow_rounded;
      case 'DOCX':
        return Icons.description_rounded;
      case 'IMAGE':
        return Icons.image_rounded;
      case 'LINK':
        return Icons.link_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return AppTheme.danger;
      case 'PPT':
        return AppTheme.warning;
      case 'DOCX':
        return AppTheme.primary;
      case 'IMAGE':
        return AppTheme.accent;
      case 'LINK':
        return Colors.teal;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final type = _getFileType(file.mimeType);
    final Color fileColor = _getFileColor(type);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Icon(
        _getFileIcon(type),
        color: fileColor,
        size: 22,
      ),
      title: Text(
        file.resourceName,
        style: TextStyle(
          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '$type • ${_formatFileSize(file.fileSizeLinesOrBytes)}',
        style: TextStyle(
          color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
          fontSize: 11,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit Button (explicitly placed besides download)
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              size: 18,
            ),
            tooltip: 'Edit Resource Details',
            onPressed: onEdit,
          ),
          const SizedBox(width: 4),
          // Download/Progress Indicator
          isDownloading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.download_for_offline_outlined,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    size: 20,
                  ),
                  tooltip: 'Download resource offline',
                  onPressed: onDownload,
                ),
        ],
      ),
    );
  }
}
