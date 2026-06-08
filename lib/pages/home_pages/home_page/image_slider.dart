import 'package:a_i_ebook_app/flutter_flow/flutter_flow_util.dart';
import 'package:a_i_ebook_app/pages/home_pages/home_page/webview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/internationalization.dart';

/// Homepage hero carousel: dark panel, title/author/category, format CTAs, cover.
class BannerSlider extends StatefulWidget {
  const BannerSlider({
    super.key,
    required this.sliderItems,
    required this.onOpenBook,
  });

  final List<dynamic> sliderItems;
  final void Function(dynamic legacyBook) onOpenBook;

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  int _currentIndex = 0;

  static const _listenBlue = Color(0xFF2563EB);

  void _openFromItem(dynamic item) {
    final legacy = getJsonField(item, r'''$.legacy_book''');
    final id = getJsonField(legacy, r'''$._id''').toString().trim();
    if (id.isNotEmpty) {
      widget.onOpenBook(legacy);
      return;
    }
    final url = getJsonField(item, r'''$.button_url''').toString().trim();
    if (url.isNotEmpty && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => WebViewScreen(url: url),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final loc = FFLocalizations.of(context);
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            viewportFraction: 0.94,
            enlargeCenterPage: false,
            padEnds: true,
            autoPlay: widget.sliderItems.length > 1,
            autoPlayInterval: const Duration(seconds: 8),
            onPageChanged: (index, _) {
              setState(() => _currentIndex = index);
            },
          ),
          items: List.generate(widget.sliderItems.length, (index) {
            final item = widget.sliderItems[index];
            final title =
                getJsonField(item, r'''$.title''').toString().trim();
            final author =
                getJsonField(item, r'''$.author_name''').toString().trim();
            final category =
                getJsonField(item, r'''$.category_name''').toString().trim();
            final imageUrl =
                getJsonField(item, r'''$.image''').toString().trim();
            final showBadge =
                getJsonField(item, r'''$.show_editors_badge''') == true;
            final hasEbook =
                getJsonField(item, r'''$.has_ebook''') == true;
            final hasAudio =
                getJsonField(item, r'''$.has_audiobook''') == true;
            final hasHard =
                getJsonField(item, r'''$.has_hardcopy''') == true;

            final metaParts = <String>[];
            if (author.isNotEmpty) {
              metaParts.add(author);
            }
            if (category.isNotEmpty) {
              metaParts.add(category);
            }
            final metaLine = metaParts.join(' · ');

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openFromItem(item),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: theme.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 12,0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (showBadge)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.95,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          loc.getText('slider_editors_choice'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(
                                              alpha: 0.95,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Text(
                                  title.isEmpty ? ' ' : title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: isBn
                                      ? TextStyle(
                                          fontFamily: 'NotoSerifBengali',
                                          fontSize: 18,
                                          height: 1.2,
                                          fontWeight: FontWeight.w600,
                                          color: theme.primaryText,
                                        )
                                      : theme.titleMedium.override(
                                          fontFamily: theme.titleMediumFamily,
                                          fontSize: 18.0,
                                          lineHeight: 1.2,
                                          fontWeight: FontWeight.w600,
                                          color: theme.primaryText,
                                        ),
                                ),
                                if (metaLine.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    metaLine,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.35,
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (hasEbook)
                                      _SliderCta(
                                        label: loc.getText('slider_read_ebook'),
                                        background: theme.primary,
                                        foreground: Colors.white,
                                        icon: Icons.menu_book_outlined,
                                        onTap: () => _openFromItem(item),
                                      ),
                                    if (hasAudio)
                                      _SliderCta(
                                        label:
                                            loc.getText('slider_listen_now'),
                                        background: _listenBlue,
                                        foreground: Colors.white,
                                        icon: Icons.headphones_rounded,
                                        onTap: () => _openFromItem(item),
                                      ),
                                    if (hasHard)
                                      _SliderCta(
                                        label:
                                            loc.getText('slider_order_copy'),
                                        background: theme.alternate,
                                        foreground: theme.success,
                                        icon: Icons.inventory_2_outlined,
                                        borderColor: theme.success,
                                        onTap: () => _openFromItem(item),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _openFromItem(item),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 110,
                                height: 160,
                                child: imageUrl.isEmpty
                                    ? ColoredBox(
                                        color: theme.gray200,
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: theme.secondaryText
                                              .withValues(alpha: 0.5),
                                        ),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.fill,
                                        placeholder: (_, __) => ColoredBox(
                                          color: theme.gray200,
                                          child: Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: theme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) =>
                                            ColoredBox(
                                          color: theme.gray200,
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: theme.secondaryText
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (widget.sliderItems.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.sliderItems.length, (i) {
                final active = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: active ? theme.primary : theme.gray300,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _SliderCta extends StatelessWidget {
  const _SliderCta({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.onTap,
    this.borderColor,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
  final VoidCallback onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1.2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
