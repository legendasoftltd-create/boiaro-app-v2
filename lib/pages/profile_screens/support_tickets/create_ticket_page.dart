import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateTicketPageWidget extends StatefulWidget {
  const CreateTicketPageWidget({super.key});

  static String routeName = 'CreateTicketPage';
  static String routePath = '/createTicket';

  @override
  State<CreateTicketPageWidget> createState() => _CreateTicketPageWidgetState();
}

class _CreateTicketPageWidgetState extends State<CreateTicketPageWidget> {
  late CreateTicketPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'general';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateTicketPageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    try {
      final response = await EbookGroup.createSupportTicketApiCall.call(
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        token: FFAppState().token,
      );

      if (response.succeeded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBn
                    ? 'টিকিট সফলভাবে তৈরি হয়েছে'
                    : 'Ticket created successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        final errMsg = getJsonField(response.jsonBody, r'''$.message''')?.toString() ?? 
                       (isBn ? 'টিকিট তৈরি করতে সমস্যা হয়েছে' : 'Failed to create ticket');
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    final categories = [
      {'value': 'general', 'en': 'General', 'bn': 'সাধারণ'},
      {'value': 'payment_issue', 'en': 'Payment Issue', 'bn': 'পেমেন্ট সমস্যা'},
      {'value': 'book_access', 'en': 'Book Access', 'bn': 'বই অ্যাক্সেস'},
      {'value': 'audiobook_playback', 'en': 'Audiobook Playback', 'bn': 'অডিওবুক প্লেব্যাক'},
      {'value': 'subscription', 'en': 'Subscription', 'bn': 'সাবস্ক্রিপশন'},
      {'value': 'refund', 'en': 'Refund', 'bn': 'রিফান্ড'},
      {'value': 'hardcopy_delivery', 'en': 'Hardcopy Delivery', 'bn': 'হার্ডকপি ডেলিভারি'},
      {'value': 'account', 'en': 'Account', 'bn': 'অ্যাকাউন্ট'},
      {'value': 'other', 'en': 'Other', 'bn': 'অন্যান্য'},
    ];

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
                  title: isBn ? 'টিকিট তৈরি করুন' : 'Create Ticket',
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                        isBn ? 'বিষয়' : 'Subject',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _subjectController,
                        style: FlutterFlowTheme.of(context).bodyMedium,
                        decoration: InputDecoration(
                          hintText: isBn
                              ? 'আপনার সমস্যার বিষয় সংক্ষেপে লিখুন'
                              : 'Brief subject of the issue',
                          hintStyle: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context)
                                    .secondaryText,
                              ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).accent3,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).primary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          filled: true,
                          fillColor: FlutterFlowTheme.of(context)
                              .secondaryBackground,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isBn ? 'বিষয় আবশ্যক' : 'Subject is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        isBn ? 'ক্যাটাগরি' : 'Category',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8.0),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        style: FlutterFlowTheme.of(context).bodyMedium,
                        dropdownColor: FlutterFlowTheme.of(context)
                            .secondaryBackground,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).accent3,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).primary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          filled: true,
                          fillColor: FlutterFlowTheme.of(context)
                              .secondaryBackground,
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['value'],
                            child: Text(isBn ? cat['bn']! : cat['en']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        isBn ? 'বর্ণনা' : 'Description',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _descriptionController,
                        style: FlutterFlowTheme.of(context).bodyMedium,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: isBn
                              ? 'আপনার সমস্যার বিস্তারিত লিখুন'
                              : 'Describe your issue in detail',
                          hintStyle: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context)
                                    .secondaryText,
                              ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).accent3,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).primary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          filled: true,
                          fillColor: FlutterFlowTheme.of(context)
                              .secondaryBackground,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isBn
                                ? 'বর্ণনা আবশ্যক'
                                : 'Description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32.0),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              FlutterFlowTheme.of(context).primary,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isBn ? 'জমা দিন' : 'Submit Ticket',
                                style: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      fontFamily: 'SF Pro Display',
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                      ),
                    ],
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

class CreateTicketPageModel extends FlutterFlowModel<CreateTicketPageWidget> {
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
