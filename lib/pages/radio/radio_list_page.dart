import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/radio/radio_station.dart';
import '../../models/radio/live_session.dart';
import '../../models/radio/radio_chat.dart';
import '../../services/radio/radio_api_service.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/internationalization.dart';
import 'boiaro_on_air_main_page.dart';
import 'station_player_page.dart';

class RadioListPageWidget extends StatefulWidget {
  static const String routeName = 'RadioListPage';
  static const String routePath = '/radioList';

  const RadioListPageWidget({Key? key}) : super(key: key);

  @override
  State<RadioListPageWidget> createState() => _RadioListPageWidgetState();
}

class _RadioListPageWidgetState extends State<RadioListPageWidget> {
  final RadioApiService _apiService = RadioApiService();
  
  bool _isLoading = true;
  LiveSession? _liveSession;
  List<RadioStation> _stations = [];
  List<ShowSchedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final live = await _apiService.getLiveSession();
      final stations = await _apiService.getStations();
      final schedules = await _apiService.getSchedules();

      if (mounted) {
        setState(() {
          _liveSession = live;
          _stations = stations;
          _schedules = schedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching radio list data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        elevation: 0,
        title: Text(
          FFLocalizations.of(context).getVariableText(
            enText: 'Boiaro On Air',
            bnText: 'বই আরো অন এয়ার',
          ),
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FlutterFlowTheme.of(context).primaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: FlutterFlowTheme.of(context).primaryText),
            onPressed: _fetchData,
            tooltip: FFLocalizations.of(context).getVariableText(
              enText: 'Refresh',
              bnText: 'রিফ্রেশ',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: FlutterFlowTheme.of(context).primary,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: FlutterFlowTheme.of(context).primary,
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: LIVE ON AIR CARD
                      _buildLiveSection(),
                      const SizedBox(height: 24),

                      // SECTION 2: 24/7 STATIONS
                      _buildStationsSection(),
                      const SizedBox(height: 24),

                      // SECTION 3: UPCOMING SCHEDULE
                      _buildScheduleSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLiveSection() {
    final hasLive = _liveSession != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FFLocalizations.of(context).getVariableText(
            enText: 'Live Radio',
            bnText: 'লাইভ রেডিও',
          ),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: FlutterFlowTheme.of(context).primaryText,
          ),
        ),
        const SizedBox(height: 12),
        if (hasLive)
          GestureDetector(
            onTap: () {
              context.pushNamed(BoiAroOnAirMainPage.routeName);
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3F2B96), Color(0xFFA8C0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3F2B96).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Dynamic background visuals
                    Positioned(
                      right: -30,
                      bottom: -30,
                      child: Icon(
                        Icons.podcasts,
                        size: 150,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4757),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                                     .scaleXY(begin: 0.8, end: 1.4),
                                    const SizedBox(width: 6),
                                    Text(
                                      FFLocalizations.of(context).getVariableText(
                                        enText: 'LIVE NOW',
                                        bnText: 'চলতি লাইভ',
                                      ),
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_liveSession!.listenerCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.people_outline,
                                        size: 12,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_liveSession!.listenerCount}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _liveSession!.showTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage: _liveSession!.rjProfile?.avatarUrl != null
                                    ? NetworkImage(_liveSession!.rjProfile!.avatarUrl!)
                                    : null,
                                backgroundColor: Colors.white24,
                                child: _liveSession!.rjProfile?.avatarUrl == null
                                    ? const Icon(Icons.person, size: 14, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _liveSession!.rjProfile?.stageName ?? 'RJ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                FFLocalizations.of(context).getVariableText(
                                  enText: 'Join Chat & Call-In →',
                                  bnText: 'আড্ডা ও কলে অংশ নিন →',
                                ),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFF3F2B96),
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fade().scale(curve: Curves.easeOutBack, duration: 400.ms)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FlutterFlowTheme.of(context).alternate),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.radio_outlined,
                  size: 48,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
                const SizedBox(height: 12),
                Text(
                  FFLocalizations.of(context).getVariableText(
                    enText: 'No Live Show Right Now',
                    bnText: 'এই মুহূর্তে কোনো লাইভ শো নেই',
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  FFLocalizations.of(context).getVariableText(
                    enText: 'Check the schedule below or play standard stations.',
                    bnText: 'নিচের সময়সূচী দেখুন অথবা সাধারণ স্টেশন শুনুন।',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fade(duration: 300.ms),
      ],
    );
  }

  Widget _buildStationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FFLocalizations.of(context).getVariableText(
            enText: 'Radio Stations',
            bnText: 'রেডিও স্টেশনসমূহ',
          ),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: FlutterFlowTheme.of(context).primaryText,
          ),
        ),
        const SizedBox(height: 12),
        if (_stations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No radio stations available.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stations.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final station = _stations[index];
              return GestureDetector(
                onTap: () {
                  context.pushNamed(
                    StationPlayerPageWidget.routeName,
                    extra: {'station': station},
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -15,
                          top: -15,
                          child: Icon(
                            Icons.radio,
                            size: 80,
                            color: FlutterFlowTheme.of(context).primaryText.withValues(alpha: 0.03),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Station logo / avatar
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: station.artworkUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            station.artworkUrl!,
                                            width: 42,
                                            height: 42,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => Icon(
                                              Icons.radio,
                                              color: FlutterFlowTheme.of(context).primary,
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.radio,
                                          color: FlutterFlowTheme.of(context).primary,
                                          size: 20,
                                        ),
                                ),
                              ),
                              
                              // Station info
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: FlutterFlowTheme.of(context).primaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    station.description ?? '24/7 stream',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Small play indicator button on bottom right
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ).animate().fade().slideY(begin: 0.1, duration: 300.ms),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FFLocalizations.of(context).getVariableText(
            enText: 'Upcoming Shows',
            bnText: 'আসন্ন সময়সূচী',
          ),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: FlutterFlowTheme.of(context).primaryText,
          ),
        ),
        const SizedBox(height: 12),
        if (_schedules.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No show schedules listed today.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _schedules.length,
            itemBuilder: (context, index) {
              final schedule = _schedules[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      image: schedule.coverImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(schedule.coverImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: schedule.coverImageUrl == null
                        ? const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.purpleAccent,
                            size: 20,
                          )
                        : null,
                  ),
                  title: Text(
                    schedule.showTitle,
                    style: GoogleFonts.outfit(
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'RJ ${schedule.rjStageName} • ${schedule.startTime} - ${schedule.endTime}',
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getDayLabel(schedule.dayOfWeek),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ).animate().fade().slideY(begin: 0.1, duration: 400.ms),
      ],
    );
  }

  String _getDayLabel(int? day) {
    if (day == null) return 'Scheduled';
    final days = {
      0: 'Sunday',
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
    };
    return days[day] ?? 'Scheduled';
  }
}
