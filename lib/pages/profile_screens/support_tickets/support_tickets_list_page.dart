import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SupportTicketsListPageWidget extends StatefulWidget {
  const SupportTicketsListPageWidget({super.key});

  static String routeName = 'SupportTicketsListPage';
  static String routePath = '/supportTicketsList';

  @override
  State<SupportTicketsListPageWidget> createState() =>
      _SupportTicketsListPageWidgetState();
}

class _SupportTicketsListPageWidgetState
    extends State<SupportTicketsListPageWidget> {
  late SupportTicketsListPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Future<ApiCallResponse>? _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupportTicketsListPageModel());
    _loadTickets();
  }

  void _loadTickets() {
    setState(() {
      _ticketsFuture = EbookGroup.listSupportTicketsApiCall.call(
        token: FFAppState().token,
      );
    });
  }

  @override
  void dispose() {
    _model.dispose();
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
                  title: isBn ? 'সাপোর্ট টিকিট' : 'Support Tickets',
                  backIcon: false,
                  addIcon: true,
                  onTapAdd: () async {
                    await context.pushNamed(CreateTicketPageWidget.routeName);
                    _loadTickets();
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadTickets();
                  },
                  child: FutureBuilder<ApiCallResponse>(
                    future: _ticketsFuture,
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
                        return ListView(
                          children: [
                            SizedBox(height: 100),
                            Center(
                              child: Text(
                                isBn
                                    ? 'টিকিট লোড করতে সমস্যা হয়েছে'
                                    : 'Failed to load tickets',
                                style: FlutterFlowTheme.of(context).bodyLarge,
                              ),
                            ),
                          ],
                        );
                      }

                      final ticketsList = getJsonField(
                        response.jsonBody,
                        r'''$.tickets''',
                      );

                      if (ticketsList == null ||
                          (ticketsList is List && ticketsList.isEmpty)) {
                        return ListView(
                          children: [
                            SizedBox(height: 150),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.support_agent_rounded,
                                    size: 64,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    isBn
                                        ? 'কোনো টিকিট পাওয়া যায়নি'
                                        : 'No tickets found',
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isBn
                                        ? 'নতুন টিকিট তৈরি করতে উপরে "+" চাপুন'
                                        : 'Tap "+" above to create a ticket',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      final tickets = List.from(ticketsList);
                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = tickets[index];
                          final ticketId = ticket['id']?.toString() ?? '';
                          final ticketNum = ticket['ticket_number']?.toString() ?? '';
                          final subject = ticket['subject']?.toString() ?? '';
                          final category = ticket['category']?.toString() ?? '';
                          final status = ticket['status']?.toString() ?? '';
                          final repliesCount =
                              int.tryParse(ticket['replies_count']?.toString() ?? '0') ?? 0;
                          final createdAtStr = ticket['created_at']?.toString() ?? '';

                          String formattedDate = '';
                          if (createdAtStr.isNotEmpty) {
                            try {
                              final parsedDate = DateTime.parse(createdAtStr).toLocal();
                              formattedDate =
                                  DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(parsedDate);
                            } catch (_) {
                              formattedDate = createdAtStr;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () async {
                                await context.pushNamed(
                                  TicketDetailPageWidget.routeName,
                                  pathParameters: {'id': ticketId},
                                );
                                _loadTickets();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 16.0,
                                      color: FlutterFlowTheme.of(context)
                                          .shadowColor,
                                      offset: const Offset(0.0, 4.0),
                                    )
                                  ],
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                    color: _getStatusColor(status),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        subject,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 8.0),
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
                                          const Spacer(),
                                          if (repliesCount > 0) ...[
                                            Icon(
                                              Icons.reply_all_rounded,
                                              size: 14,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isBn
                                                  ? '$repliesCount টি উত্তর'
                                                  : '$repliesCount replies',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    fontFamily: 'SF Pro Display',
                                                    color:
                                                        FlutterFlowTheme.of(context)
                                                            .primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const Divider(height: 24, thickness: 0.5),
                                      Text(
                                        formattedDate,
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
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupportTicketsListPageModel
    extends FlutterFlowModel<SupportTicketsListPageWidget> {
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
