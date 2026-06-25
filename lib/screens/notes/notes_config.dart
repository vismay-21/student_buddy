/// Configuration and Architecture Placeholders for the Notes/Resource Repository.
class NotesConfig {
  /// Default download path in local storage.
  /// Used when the user explicitly triggers a download action.
  static const String defaultDownloadLocation = 'Downloads/StudentBuddy/';

  // =========================================================================
  // FUTURE STORAGE ARCHITECTURE DESIGN NOTES (UI Only Phase)
  // =========================================================================
  //
  // 1. Cloud Storage Layer (Supabase Storage):
  //    - Resources (PDFs, PPTs, DOCX, Images, ZIP files) will be uploaded to a
  //      public/authenticated bucket in Supabase.
  //    - The database (notes_metadata table) will store metadata:
  //        * id (UUID)
  //        * semester (String)
  //        * subject (String)
  //        * subsection (String)
  //        * name (String)
  //        * type (String: 'PDF', 'PPT', etc.)
  //        * size (String: '2.4 MB')
  //        * fileUrl (String/URI pointing to Supabase bucket object)
  //        * createdBy (String/UUID of uploading user)
  //
  // 2. Local Storage & Lazy Caching Layer:
  //    - No files will be downloaded automatically upon screen loading.
  //    - Caching logic:
  //        * Check if the file already exists locally at:
  //          `{localDocumentsDirectory}/{defaultDownloadLocation}/{fileName}`.
  //        * If yes, display the "Open File" action.
  //        * If no, display the "Download" icon. Clicking it initiates a stream
  //          download from `fileUrl` to the local path, showing progress.
  //
  // =========================================================================
}
