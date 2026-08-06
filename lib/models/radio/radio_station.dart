class RadioStation {
  final String id;
  final String name;
  final String? streamUrl;
  final String? streamUrlMedium;
  final String? streamUrlLow;
  final String? artworkUrl;
  final String? description;

  RadioStation({
    required this.id,
    required this.name,
    this.streamUrl,
    this.streamUrlMedium,
    this.streamUrlLow,
    this.artworkUrl,
    this.description,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      streamUrl: json['stream_url']?.toString(),
      streamUrlMedium: json['stream_url_medium']?.toString(),
      streamUrlLow: json['stream_url_low']?.toString(),
      artworkUrl: json['artwork_url']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stream_url': streamUrl,
      'stream_url_medium': streamUrlMedium,
      'stream_url_low': streamUrlLow,
      'artwork_url': artworkUrl,
      'description': description,
    };
  }

  bool get hasQualityOptions =>
      (streamUrlMedium != null && streamUrlMedium!.isNotEmpty) ||
      (streamUrlLow != null && streamUrlLow!.isNotEmpty);
}
