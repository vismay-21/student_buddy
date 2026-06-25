import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dummy_data.dart';

class ResourceCard extends StatelessWidget {
  final NotesFileMock file;
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fileColor = _getFileColor(file.type);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Icon(
        _getFileIcon(file.type),
        color: fileColor,
        size: 22,
      ),
      title: Text(
        file.name,
        style: TextStyle(
          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${file.type} • ${file.size}',
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
