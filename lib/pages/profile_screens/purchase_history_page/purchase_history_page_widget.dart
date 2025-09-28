import 'package:a_i_ebook_app/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import 'package:a_i_ebook_app/pages/home_pages/book_detailspage/book_detailspage_widget.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/single_appbar/single_appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'purchase_history_page_model.dart';
export 'purchase_history_page_model.dart';

class PurchaseHistoryPageWidget extends StatefulWidget {
  const PurchaseHistoryPageWidget({super.key});

  static String routeName = 'PurchaseHistoryPage';
  static String routePath = '/purchaseHistoryPage';

  @override
  State<PurchaseHistoryPageWidget> createState() =>
      _PurchaseHistoryPageWidgetState();
}

class _PurchaseHistoryPageWidgetState extends State<PurchaseHistoryPageWidget> {
  late PurchaseHistoryPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PurchaseHistoryPageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: FutureBuilder<ApiCallResponse>(
            future: EbookGroup.userBookPurchaseRecordsApiCall.call(
              userId: FFAppState().userId,
              token: FFAppState().token,
            ),
            builder: (context, snapshot) {
              Widget bodyContent;

              // Customize what your widget displays when the call is in progress,
              // has an error, or is awaiting the results.
              if (!snapshot.hasData) {
                bodyContent = Center(
                  child: CircularProgressIndicator(
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                );
              } else {
                final purchaseHistoryPageUserBookPurchaseRecordsResponse =
                    snapshot.data!;
                if (purchaseHistoryPageUserBookPurchaseRecordsResponse.statusCode != 200) {
                  bodyContent = Center(
                    child: Text(
                      'Error: ${purchaseHistoryPageUserBookPurchaseRecordsResponse.statusCode}',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                  );
                } else {
                  final purchaseDetails = EbookGroup.userBookPurchaseRecordsApiCall
                      .purchaseDetails(
                          purchaseHistoryPageUserBookPurchaseRecordsResponse.jsonBody);
                  if (purchaseDetails == null || purchaseDetails.isEmpty) {
                    bodyContent = Center(
                      child: Text(
                        'No purchase records found.',
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                    );
                  } else {
                    bodyContent = ListView.builder(
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.vertical,
                      itemCount: purchaseDetails.length,
                      itemBuilder: (context, purchaseDetailsIndex) {
                        final purchaseDetailsItem = purchaseDetails[purchaseDetailsIndex];
                        return GestureDetector(
                          onTap: () {
                          context.pushNamed(
                               BookDetailspageWidget.routeName,
                               queryParameters:
                                   {
                                 'name': purchaseDetailsItem['bookDetails']['name']?.toString(),
                                 'price': purchaseDetailsItem['bookDetails']['price']?.toString(),
                                 'image': 'image',
                                 'id': purchaseDetailsItem['bookDetails']['id']?.toString(),
                               }.withoutNulls,
                             );
                          },
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: FlutterFlowTheme.of(context).shadowColor,
                                    offset: Offset(0.0, 2.0),
                                  )
                                ],
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 12.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      getJsonField(
                                        purchaseDetailsItem,
                                        r'''$.bookDetails.name''',
                                      ).toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                                      child: Text(
                                        'Price: ${getJsonField(
                                          purchaseDetailsItem,
                                          r'''$.price''',
                                        ).toString()}',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color: FlutterFlowTheme.of(context).primaryText,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                                      child: Text(
                                        'Payment Mode: ${getJsonField(
                                          purchaseDetailsItem,
                                          r'''$.paymentmode''',
                                        ).toString()}',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color: FlutterFlowTheme.of(context).secondaryText,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                                      child: Text(
                                        'Transaction ID: ${getJsonField(
                                          purchaseDetailsItem,
                                          r'''$.transactionId''',
                                        ).toString()}',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color: FlutterFlowTheme.of(context).secondaryText,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                                      child: Text(
                                        'Payment Status: ${getJsonField(
                                          purchaseDetailsItem,
                                          r'''$.paymentstatus''',
                                        ).toString()}',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color: FlutterFlowTheme.of(context).secondaryText,
                                              letterSpacing: 0.0,
                                            ),
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
                  }
                }
              }

              return Column(
                children: [
                  CustomCenterAppbarWidget(
                    title: 'Purchase History',
                    backIcon: false,
                    addIcon: false,
                    onTapAdd: () async {},
                  ),
                  Expanded(child: bodyContent),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
