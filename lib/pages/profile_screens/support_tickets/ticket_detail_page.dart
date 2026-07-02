import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TicketDetailPageWidget extends StatefulWidget {
  final String ticketId;
  const TicketDetailPageWidget({super.key, required this.ticketId});

  static String routeName = 'TicketDetailPage';
  static String routePath = '/support/tickets/:id';

  @override
  State<TicketDetailPageWidget> createState() => _TicketDetailPageWidgetState();
}

class _TicketDetailPageWidgetState extends State<TicketDetailPageWidget> {
  late TicketDetailPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  Future<ApiCallResponse>? _ticketDetailFuture;

  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TicketDetailPageModel());
    _loadTicketDetails(scrollToBottom: true);
  }

  void _loadTicketDetails({bool scrollToBottom = false}) {
    setState(() {
      _ticketDetailFuture = EbookGroup.getSupportTicketDetailApiCall.call(
        ticketId: widget.ticketId,
        token: FFAppState().token,
      );
    });

    if (scrollToBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return const Color(0xFF2ECC71);
      case 'in_progress':
        return const Color(0xFF3498DB);
      case 'resolved':
        return const Color(0xFF95A5A6);
      case 'closed':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String _getStatusText(BuildContext context, String? status) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    switch (status?.toLowerCase()) {
      case 'open':
        return isBn ? 'উন্মুক্ত' : 'Open';
      case 'in_progress':
        return isBn ? 'চলমান' : 'In Progress';
      case 'resolved':
        return isBn ? 'সমাধানকৃত' : 'Resolved';
      case 'closed':
        return isBn ? 'বন্ধ' : 'Closed';
      default:
        return status ?? '';
    }
  }

  String _getCategoryText(BuildContext context, String? category) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    switch (category?.toLowerCase()) {
      case 'payment_issue':
        return isBn ? 'পেমেন্ট সমস্যা' : 'Payment Issue';
      case 'book_access':
        return isBn ? 'বই অ্যাক্সেস' : 'Book Access';
      case 'audiobook_playback':
        return isBn ? 'অডিওবুক প্লেব্যাক' : 'Audiobook Playback';
      case 'subscription':
        return isBn ? 'সাবস্ক্রিপশন' : 'Subscription';
      case 'refund':
        return isBn ? 'রিফান্ড' : 'Refund';
      case 'hardcopy_delivery':
        return isBn ? 'হার্ডকপি ডেলিভারি' : 'Hardcopy Delivery';
      case 'account':
        return isBn ? 'অ্যাকাউন্ট' : 'Account';
      case 'general':
        return isBn ? 'সাধারণ' : 'General';
      case 'other':
        return isBn ? 'অন্যান্য' : 'Other';
      default:
        return category ?? (isBn ? 'সাধারণ' : 'General');
    }
  }

  Future<void> _sendReply() async {
    final msg = _replyController.text.trim();
    if (msg.isEmpty) return;

    setState(() {
      _isReplying = true;
    });

    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    try {
      final response = await EbookGroup.replySupportTicketApiCall.call(
        ticketId: widget.ticketId,
        message: msg,
        token: FFAppState().token,
      );

      if (response.succeeded) {
        _replyController.clear();
        _loadTicketDetails(scrollToBottom: true);
      } else {
        final errMsg = getJsonField(response.jsonBody, r'''$.message''')?.toString() ?? 
                       (isBn ? 'উত্তর পাঠানো সম্ভব হয়নি' : 'Failed to send reply');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBn ? 'একটি ভুল হয়েছে' : 'An unexpected error occurred',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReplying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              wrapWithModel(
                model: _model.customCenterAppbarModel,
                updateCallback: () => safeSetState(() {}),
                child: CustomCenterAppbarWidget(
                  title: isBn ? 'টিকিট বিবরণ' : 'Ticket Detail',
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                ),
              ),
              Expanded(
                child: FutureBuilder<ApiCallResponse>(
                  future: _ticketDetailFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            FlutterFlowTheme.of(context).primary,
                          ),
                        ),
                      );
                    }

                    final response = snapshot.data!;
                    if (!response.succeeded) {
                      // Check for 404
                      if (response.statusCode == 404) {
                        return Center(
                          child: Text(
                            isBn ? 'টিকিট পাওয়া যায়নি' : 'Ticket not found',
                            style: FlutterFlowTheme.of(context).bodyLarge,
                          ),
                        );
                      }
                      return Center(
                        child: Text(
                          isBn
                              ? 'টিকিট বিবরণ লোড করতে সমস্যা হয়েছে'
                              : 'Failed to load ticket details',
                          style: FlutterFlowTheme.of(context).bodyLarge,
                        ),
                      );
                    }

                    final ticket = response.jsonBody;
                    if (ticket == null) {
                      return Center(
                        child: Text(
                          isBn ? 'টিকিট পাওয়া যায়নি' : 'Ticket not found',
                          style: FlutterFlowTheme.of(context).bodyLarge,
                        ),
                      );
                    }

                    final ticketNum = ticket['ticket_number']?.toString() ?? '';
                    final subject = ticket['subject']?.toString() ?? '';
                    final description = ticket['description']?.toString() ?? '';
                    final category = ticket['category']?.toString() ?? '';
                    final status = ticket['status']?.toString() ?? '';
                    final repliesList = ticket['replies'] ?? [];
                    final replies = List.from(repliesList);

                    // Triggers scroll to bottom after layout loads
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return Column(
                      children: [
                        Expanded(
                          child: ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16.0),
                            children: [
                              // Ticket Info Card
                              Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context).accent3,
                                    width: 1.0,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          ticketNum,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'SF Pro Display',
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                              ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status)
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6.0),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 4.0,
                                          ),
                                          child: Text(
                                            _getStatusText(context, status),
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      _getStatusColor(status),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      subject,
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.label_outline,
                                          size: 14,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getCategoryText(context, category),
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall
                                              .override(
                                                fontFamily: 'SF Pro Display',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24, thickness: 0.5),
                                    Text(
                                      description,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24.0),
                              // Chat Thread Divider
                              if (replies.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Expanded(child: Divider(thickness: 0.5)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        isBn ? 'বার্তালাপ' : 'Conversation',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                            ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(thickness: 0.5)),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                              ],
                              // Reply Chat Bubbles
                              ...replies.map((reply) {
                                final isStaff = reply['is_staff'] == true;
                                final message = reply['message']?.toString() ?? '';
                                final createdAt = reply['created_at']?.toString() ?? '';

                                String formattedTime = '';
                                if (createdAt.isNotEmpty) {
                                  try {
                                    final parsedDate =
                                        DateTime.parse(createdAt).toLocal();
                                    formattedTime =
                                        DateFormat('dd MMM, hh:mm a')
                                            .format(parsedDate);
                                  } catch (_) {
                                    formattedTime = createdAt;
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Column(
                                    crossAxisAlignment: isStaff
                                        ? CrossAxisAlignment.start
                                        : CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.75,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isStaff
                                              ? FlutterFlowTheme.of(context)
                                                  .accent4
                                              : FlutterFlowTheme.of(context)
                                                  .primary,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(12),
                                            topRight: const Radius.circular(12),
                                            bottomLeft: isStaff
                                                ? Radius.zero
                                                : const Radius.circular(12),
                                            bottomRight: isStaff
                                                ? const Radius.circular(12)
                                                : Radius.zero,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14.0,
                                          vertical: 10.0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (isStaff) ...[
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.support_agent_rounded,
                                                    size: 14,
                                                    color:
                                                        FlutterFlowTheme.of(context)
                                                            .primary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isBn ? 'স্টাফ' : 'Staff',
                                                    style:
                                                        FlutterFlowTheme.of(context)
                                                            .bodySmall
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              color:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                            ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            Text(
                                              message,
                                              style: FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .override(
                                                    fontFamily: 'SF Pro Display',
                                                    color: isStaff
                                                        ? FlutterFlowTheme.of(
                                                                context)
                                                            .primaryText
                                                        : Colors.white,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedTime,
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 10.0,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        // Input Field Row
                        Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            border: Border(
                              top: BorderSide(
                                color: FlutterFlowTheme.of(context).accent3,
                                width: 1.0,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _replyController,
                                  maxLines: null,
                                  style: FlutterFlowTheme.of(context).bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: isBn
                                        ? 'আপনার উত্তর লিখুন...'
                                        : 'Type your reply...',
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _isReplying
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: _sendReply,
                                      icon: Icon(
                                        Icons.send_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TicketDetailPageModel extends FlutterFlowModel<TicketDetailPageWidget> {
  late CustomCenterAppbarModel customCenterAppbarModel;

  @override
  void initState(BuildContext context) {
    customCenterAppbarModel =
        createModel(context, () => CustomCenterAppbarModel());
  }

  @override
  void dispose() {
    customCenterAppbarModel.dispose();
  }
}
