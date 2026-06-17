import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class AdBannerWidget extends StatefulWidget {
  final String placementKey;

  const AdBannerWidget({
    Key? key,
    required this.placementKey,
  }) : super(key: key);

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  Future<ApiCallResponse>? _bannerFuture;
  bool _impressionTracked = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerFuture = EbookGroup.getActiveBannersCall.call(
      // placement: widget.placementKey,
      // device: 'mobile',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return FutureBuilder<ApiCallResponse>(
      future: _bannerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final response = snapshot.data!;
        if (!response.succeeded || response.jsonBody == null) {
          return const SizedBox.shrink();
        }

        final rawBanners = response.jsonBody['banners'];
        if (rawBanners is! List || rawBanners.isEmpty) {
          return const SizedBox.shrink();
        }

        // Find the banner that matches widget.placementKey
        Map? bannerMap;
        for (final b in rawBanners) {
          if (b is Map && b['placement_key']?.toString().toLowerCase() == widget.placementKey.toLowerCase()) {
            bannerMap = b;
            break;
          }
        }

        if (bannerMap == null) {
          return const SizedBox.shrink();
        }

        final banner = Map<String, dynamic>.from(bannerMap);
        final id = banner['id']?.toString() ?? '';
        final imageUrl = banner['image_url']?.toString() ?? '';
        final destinationUrl = banner['destination_url']?.toString() ?? '';

        if (imageUrl.isEmpty) {
          return const SizedBox.shrink();
        }

        // Track impression once per lifecycle when the widget is built/displayed
        if (!_impressionTracked && id.isNotEmpty) {
          _impressionTracked = true;
          // Run after current frame to avoid updating state during build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            EbookGroup.postAdImpressionCall.call(bannerId: id).then((res) {
              debugPrint('[AD BANNER] Impression registered for banner: $id, status: ${res.statusCode}');
            }).catchError((err) {
              debugPrint('[AD BANNER] Failed to register impression: $err');
            });
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
            onTap: () async {
              if (id.isNotEmpty) {
                EbookGroup.postAdClickCall.call(bannerId: id).then((res) {
                  debugPrint('[AD BANNER] Click registered for banner: $id, status: ${res.statusCode}');
                }).catchError((err) {
                  debugPrint('[AD BANNER] Failed to register click: $err');
                });
              }
              if (destinationUrl.isNotEmpty) {
                await launchURL(destinationUrl);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 343 / 100, // standard banner ratio
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.fill,
                          placeholder: (context, url) => Container(
                            color: theme.secondaryBackground,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.secondaryBackground,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: theme.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'AD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.98, 0.98)),
        );
      },
    );
  }
}
