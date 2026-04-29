
abstract class FFAppConstants {
  static const String webUrl = 'https://boiaro.com';

  /// BoiAro REST API for mobile clients.
  static const String mobileApiBaseUrl =
      'https://boiaro.com/api/v1';

  /// Legacy key kept so older edge-function code paths can remain no-op safe.
  static const String supabaseAnonApiKey = '';

  static const String baseApiUrl = mobileApiBaseUrl;

  /// v2 APIs return full `https://` URLs; keep these empty so `${bookImagesUrl}${image}` resolves to the full URL.
  static const String imageUrl = webUrl;
  static const String bookImagesUrl = webUrl;
  static const String sliderImagesUrl = webUrl;
  static const String audiobookAudioUrl = webUrl;
  static const String audiobookPreviewAudioUrl = webUrl;
  static const String audiobookAudioPreviewUrl = webUrl;
  static const String previewPdfUrl = webUrl;
  static const String pdfUrl = webUrl;
}
