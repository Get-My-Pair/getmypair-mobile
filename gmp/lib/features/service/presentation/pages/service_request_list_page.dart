import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';
import 'service_request_details_page.dart';

class ServiceRequestListPage extends StatefulWidget {
  const ServiceRequestListPage({super.key});

  @override
  State<ServiceRequestListPage> createState() => _ServiceRequestListPageState();
}

class _ServiceRequestListPageState extends State<ServiceRequestListPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        setState(() {
          _loading = false;
          _error = 'Please sign in again';
        });
      },
      (token) async {
        try {
          final res = await sl<DioClient>().get(
            ApiEndpoints.serviceMy,
            accessToken: token,
          );
          final list =
              ((res['data'] as Map<String, dynamic>?)?['requests'] as List?) ??
              const [];
          if (!mounted) return;
          setState(() {
            _requests = list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            _loading = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = e.toString().replaceFirst('Exception: ', '');
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Responsive.horizontalPaddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            )
          : _requests.isEmpty
          ? const Center(
              child: Text(
                'No service requests yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
              itemCount: _requests.length,
              itemBuilder: (_, index) {
                final r = _requests[index];
                final id = (r['_id'] ?? '').toString();
                final serviceType = (r['serviceType'] ?? '').toString();
                final status = (r['status'] ?? '').toString();
                final createdAt = (r['createdAt'] ?? '').toString();
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ServiceRequestDetailsPage(requestId: id),
                      ),
                    );
                    if (!mounted) return;
                    _load();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                serviceType.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _statusChip(status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Request: $id',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: $createdAt',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _statusChip(String value) {
    final v = value.trim().toLowerCase();
    Color bg = AppColors.info.withOpacity(0.12);
    Color fg = AppColors.info;
    if (v == 'completed') {
      bg = AppColors.success.withOpacity(0.12);
      fg = AppColors.success;
    } else if (v == 'cancelled') {
      bg = AppColors.error.withOpacity(0.12);
      fg = AppColors.error;
    } else if (v == 'in_service') {
      bg = AppColors.primary.withOpacity(0.12);
      fg = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
