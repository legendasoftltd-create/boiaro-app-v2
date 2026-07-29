import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
  int _currentSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerFuture = EbookGroup.getActiveBannersCall.call();
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

        final slidesRaw = banner['slides'];
        final List<Map<String, dynamic>> slides = [];
        if (slidesRaw is List) {
          for (final slide in slidesRaw) {
            if (slide is Map) {
              slides.add(Map<String, dynamic>.from(slide));
            }
          }
        }

        // Sort slides by display_order
        slides.sort((a, b) {
          final int orderA = int.tryParse(a['display_order']?.toString() ?? '0') ?? 0;
          final int orderB = int.tryParse(b['display_order']?.toString() ?? '0') ?? 0;
          return orderA.compareTo(orderB);
        });

        // Fallback to legacy fields if slides list is empty
        if (slides.isEmpty && imageUrl.isNotEmpty) {
          slides.add({
            'id': '',
            'image_url': imageUrl,
            'destination_url': destinationUrl,
            'display_order': 0,
          });
        }

        if (slides.isEmpty) {
          return const SizedBox.shrink();
        }

        // Keep _currentSlideIndex in bounds
        if (_currentSlideIndex >= slides.length) {
          _currentSlideIndex = 0;
        }

        // Track impression once per lifecycle when the widget is built/displayed
        if (!_impressionTracked && id.isNotEmpty) {
          _impressionTracked = true;
          final firstSlideId = slides.isNotEmpty ? (slides[0]['id']?.toString() ?? '') : '';
          // Run after current frame to avoid updating state during build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            EbookGroup.postAdImpressionCall.call(
              bannerId: id,
              slideId: firstSlideId.isNotEmpty ? firstSlideId : null,
            ).then((res) {
              debugPrint('[AD BANNER] Impression registered for banner: $id (slide: $firstSlideId), status: ${res.statusCode}');
            }).catchError((err) {
              debugPrint('[AD BANNER] Failed to register impression: $err');
            });
          });
        }

        // Single slide rendering
        if (slides.length == 1) {
          final singleSlide = slides[0];
          final slideId = singleSlide['id']?.toString() ?? '';
          final slideImgUrl = singleSlide['image_url']?.toString() ?? '';
          final destUrl = singleSlide['destination_url']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                  aspectRatio: 343 / 150, // standard banner ratio
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: destUrl.isEmpty
                                ? null
                                : () async {
                                    if (id.isNotEmpty) {
                                      EbookGroup.postAdClickCall.call(
                                        bannerId: id,
                                        slideId: slideId.isNotEmpty ? slideId : null,
                                      ).then((res) {
                                        debugPrint('[AD BANNER] Click registered for banner: $id (slide: $slideId), status: ${res.statusCode}');
                                      }).catchError((err) {
                                        debugPrint('[AD BANNER] Failed to register click: $err');
                                      });
                                    }
                                    if (destUrl.isNotEmpty) {
                                      await launchURL(destUrl);
                                    }
                                  },
                            child: CachedNetworkImage(
                              imageUrl: slideImgUrl,
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
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.98, 0.98));
        }

        // Multiple slides rendering (CarouselSlider)
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                aspectRatio: 343 / 150, // standard banner ratio
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CarouselSlider(
                        options: CarouselOptions(
                          aspectRatio: 343 / 150,
                          viewportFraction: 1.0,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 20),
                          autoPlayAnimationDuration: const Duration(milliseconds: 600),
                          autoPlayCurve: Curves.easeInOut,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentSlideIndex = index;
                            });
                          },
                        ),
                        items: slides.map((slide) {
                          final slideId = slide['id']?.toString() ?? '';
                          final slideImgUrl = slide['image_url']?.toString() ?? '';
                          final destUrl = slide['destination_url']?.toString() ?? '';

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: destUrl.isEmpty
                                  ? null
                                  : () async {
                                      if (id.isNotEmpty) {
                                        EbookGroup.postAdClickCall.call(
                                          bannerId: id,
                                          slideId: slideId.isNotEmpty ? slideId : null,
                                        ).then((res) {
                                          debugPrint('[AD BANNER] Click registered for banner: $id (slide: $slideId), status: ${res.statusCode}');
                                        }).catchError((err) {
                                          debugPrint('[AD BANNER] Failed to register click: $err');
                                        });
                                      }
                                      if (destUrl.isNotEmpty) {
                                        await launchURL(destUrl);
                                      }
                                    },
                              child: SizedBox.expand(
                                child: CachedNetworkImage(
                                  imageUrl: slideImgUrl,
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
                            ),
                          );
                        }).toList(),
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
                    // Positioned(
                    //   bottom: 8,
                    //   left: 0,
                    //   right: 0,
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     children: List.generate(slides.length, (index) {
                    //       final active = index == _currentSlideIndex;
                    //       return AnimatedContainer(
                    //         duration: const Duration(milliseconds: 250),
                    //         margin: const EdgeInsets.symmetric(horizontal: 3),
                    //         width: active ? 12 : 6,
                    //         height: 6,
                    //         decoration: BoxDecoration(
                    //           borderRadius: BorderRadius.circular(3),
                    //           color: active ? theme.primary : Colors.white.withOpacity(0.5),
                    //         ),
                    //       );
                    //     }),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.98, 0.98));
      },
    );
  }
}
