import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/bgtheme.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/usecases/get_valid_access_token.dart';

/// Account Settings → Manage Devices: view and remove sessions on other devices.
class ManageDevicesPage extends StatefulWidget {
  const ManageDevicesPage({super.key});

  @override
  State<ManageDevicesPage> createState() => _ManageDevicesPageState();
}

class _ManageDevicesPageState extends State<ManageDevicesPage> {
  String? _accessToken;
  bool _isLoading = true;
  bool _isRemoving = false;
  String? _currentSessionId;
  final List<_SessionItem> _sessions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAndLoad());
  }

  Future<void> _initAndLoad() async {
    final result = await di.sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await result.fold(
      (failure) async {
        await showAppFeedbackAlert(
          context,
          message: failure.message,
          type: AppFeedbackType.failure,
        );
      },
      (token) async {
        if (!mounted) return;
        setState(() {
          _accessToken = token;
        });
        await _loadSessions(token);
      },
    );
  }

  Future<void> _loadSessions(String token) async {
    setState(() => _isLoading = true);

    try {
      final client = di.sl<DioClient>();
      final response = await client.get(
        ApiEndpoints.authSessions,
        accessToken: token,
      );

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final currentSessionId = data['currentSessionId']?.toString();
      final sessionsJson = data['sessions'] as List? ?? [];

      final sessions = sessionsJson
          .map((e) => _SessionItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      if (!mounted) return;
      setState(() {
        _currentSessionId = currentSessionId;
        _sessions
          ..clear()
          ..addAll(sessions);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await showAppFeedbackAlert(
        context,
        message: e is ServerException ? e.message : e.toString(),
        type: AppFeedbackType.failure,
      );
    }
  }

  String _iconAssetForDeviceInfo(String deviceInfo) {
    final d = deviceInfo.toLowerCase();
    if (d.contains('web')) return 'assets/images/icons/profile/monitor.svg';
    if (d.contains('desktop')) return 'assets/images/icons/profile/monitor.svg';
    if (d.contains('watch')) return 'assets/images/icons/profile/watch.svg';
    return 'assets/images/icons/profile/smartphone.svg';
  }

  Future<void> _removeSession(_SessionItem session) async {
    final token = _accessToken;
    if (token == null || _isRemoving) return;
    if (session.id == _currentSessionId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Remove device'),
        content: const Text(
          'Are you sure you want to sign out from this device?',
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRemoving = true);
    try {
      final client = di.sl<DioClient>();
      await client.delete(
        ApiEndpoints.authSession(session.id),
        accessToken: token,
      );
      await _loadSessions(token);
      if (!mounted) return;
      await showAppFeedbackAlert(
        context,
        message: 'Device removed successfully.',
        type: AppFeedbackType.success,
      );
    } catch (e) {
      if (!mounted) return;
      await showAppFeedbackAlert(
        context,
        message: e is ServerException ? e.message : e.toString(),
        type: AppFeedbackType.failure,
      );
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _SessionItem? currentSession = _sessions
        .where((s) => s.id == _currentSessionId)
        .firstOrNull;

    final otherSessions =
        _sessions.where((s) => s.id != _currentSessionId).toList();

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage(BgTheme.backgroundImageAsset),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFABABAB),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                margin: const EdgeInsets.only(bottom: 14),
                child: SingleChildScrollView(
                  padding:
                      ArticleStyleHeaderInsets.scrollContentPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ChevronScreenBackButton(
                            iconColor: Color(0xFFDFE7E9),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manage Devices',
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFFDFE7E9),
                                    fontSize: 25,
                                    fontWeight: FontWeight.w400,
                                    height: 1.18,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Devices you\'re currently logged in on. Remove one to sign out from it',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 42),
                      Text(
                        'This Device',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Center(child: Padding(
                          padding: EdgeInsets.only(top: 18, bottom: 18),
                          child: CircularProgressIndicator(),
                        ))
                      else
                        _DeviceRow(
                          iconAsset: _iconAssetForDeviceInfo(
                            currentSession?.deviceInfo ?? 'This device',
                          ),
                          label: currentSession?.deviceInfo ?? 'This device',
                          showTopDivider: false,
                          onRemove: null,
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Other Devices',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const SizedBox.shrink()
                      else if (otherSessions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No other devices',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        )
                      else
                        ...otherSessions.map(
                          (s) => _DeviceRow(
                            iconAsset: _iconAssetForDeviceInfo(s.deviceInfo),
                            label: s.deviceInfo,
                            showTopDivider: false,
                            onRemove: _isRemoving
                                ? null
                                : () => _removeSession(s),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const DashboardLinkedBottomNav(selectedTabIndex: 2),
          ],
        ),
      ),
    );
  }
}

class _SessionItem {
  final String id;
  final String deviceInfo;

  const _SessionItem({
    required this.id,
    required this.deviceInfo,
  });

  factory _SessionItem.fromJson(Map<String, dynamic> json) {
    final rawDeviceInfo = json['deviceInfo'];
    final deviceInfo = rawDeviceInfo?.toString().trim();

    return _SessionItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      deviceInfo: (deviceInfo != null && deviceInfo.isNotEmpty)
          ? deviceInfo
          : 'This device',
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}

class _DeviceRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool showTopDivider;
  final VoidCallback? onRemove;

  const _DeviceRow({
    required this.iconAsset,
    required this.label,
    this.showTopDivider = true,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: showTopDivider
              ? BorderSide(
                  color: Colors.white.withValues(alpha: 0.50),
                  width: 1,
                )
              : BorderSide.none,
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.50),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: SvgPicture.asset(
                  'assets/images/icons/profile/trash-2.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
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
