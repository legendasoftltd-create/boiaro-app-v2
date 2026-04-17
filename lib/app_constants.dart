
abstract class FFAppConstants {
  static const String webUrl = '';

  /// BoiAro REST API v2 (Supabase Edge Function). All mobile clients must send [supabaseAnonApiKey] as `apikey`.
  static const String mobileApiBaseUrl =
      'https://kxpqejmjfnzhqcefyued.supabase.co/functions/v1/mobile-api';

  static const String supabaseAnonApiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4cHFlam1qZm56aHFjZWZ5dWVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMzA0NjUsImV4cCI6MjA4OTkwNjQ2NX0.PSM2xT9QPzJmBU5yP7uKnQxVAvbpevAGF8wFw43i9to';

  static const String baseApiUrl = mobileApiBaseUrl;

  /// v2 APIs return full `https://` URLs; keep these empty so `${bookImagesUrl}${image}` resolves to the full URL.
  static const String imageUrl = '';
  static const String bookImagesUrl = '';
  static const String sliderImagesUrl = '';
  static const String audiobookAudioUrl = '';
  static const String audiobookPreviewAudioUrl = '';
  static const String audiobookAudioPreviewUrl = '';
  static const String previewPdfUrl = '';
  static const String pdfUrl = '';
}
