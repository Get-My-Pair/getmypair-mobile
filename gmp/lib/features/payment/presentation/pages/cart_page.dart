import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/navigation/customer_dashboard_tab_index.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/article_rack_shoe_image.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../../../features/auth/domain/usecases/get_valid_access_token.dart';
import '../../../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../../../features/profile/presentation/pages/profile_page.dart';
import '../../../../features/service/presentation/utils/care_active_job.dart';
import '../../../../features/service/presentation/widgets/service_request_bg_layer.dart';
import '../../../../injection_container.dart';
import '../bloc/payment_bloc.dart';
import '../utils/cart_navigation.dart';
import '../utils/payment_amount_formatter.dart';
import 'payment_request_page.dart';

/// Cart (4th nav): same light panel + card look as Active Progress / History,
/// with **Pay Now** only.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _loading = true;
  String? _error;
  List<_CartPayableItem> _items = const [];

  @override
  void initState() {
    super.initState();
    registerCustomerCartNavigation();
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
          final items = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .map(_CartPayableItem.tryFrom)
              .whereType<_CartPayableItem>()
              .toList(growable: false);
          if (!mounted) return;
          setState(() {
            _items = items;
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

  Future<void> _openPurchaseSummary(_CartPayableItem item) async {
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<PaymentBloc>(),
          child: PaymentRequestPage(
            serviceRequestId: item.id,
            amount: item.amount,
            serviceType: item.serviceType,
            requestLabel: item.requestLabel,
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (paid == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          ...ServiceRequestBgLayer.stackBehind(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 30, 10, 0),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: ServiceRequestBgLayer.panelFill,
                  shape: const RoundedRectangleBorder(
                    borderRadius: CartPage._panelRadius,
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: CartPage._panelRadius,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.maybePop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 26,
                                height: 26,
                              ),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF062F35),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Cart',
                                style: GoogleFonts.boldonse(
                                  color: const Color(0xFF062F35),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _loading ? null : _load,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF062F35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _loading
                            ? const AppSkeletonList(itemCount: 3)
                            : _error != null
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _error!,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              color: const Color(0xFFB00020),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          FilledButton(
                                            onPressed: _load,
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF11999E),
                                            ),
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : _items.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No pending payments',
                                          style: GoogleFonts.montserrat(
                                            color: const Color(0xFF9AA4A6),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    : RefreshIndicator(
                                        color: const Color(0xFF11999E),
                                        onRefresh: _load,
                                        child: ListView.separated(
                                          padding: EdgeInsets.fromLTRB(
                                            16,
                                            8,
                                            16,
                                            120 + bottomSafe,
                                          ),
                                          itemCount: _items.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 14),
                                          itemBuilder: (_, i) {
                                            final item = _items[i];
                                            return _CartProgressStyleCard(
                                              item: item,
                                              onPayNow: () =>
                                                  _openPurchaseSummary(item),
                                            );
                                          },
                                        ),
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: dashboardBottomNavOuterInsets(context),
              child: FloatingGradientBottomNav(
                currentIndex: -1,
                highlightCart: true,
                onCartTap: () {},
                onChanged: (i) {
                  final tab = i.clamp(0, 2);
                  customerDashboardTabIndex.value = tab;
                  final nav = Navigator.of(context);
                  if (tab == 2) {
                    ProfileBloc? resolved;
                    try {
                      resolved = context.read<ProfileBloc>();
                    } catch (_) {
                      resolved = ProfileBlocAnchor.current;
                    }
                    if (resolved == null || resolved.isClosed) return;
                    nav.push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: resolved!,
                          child: const ProfilePage(),
                        ),
                      ),
                    );
                    return;
                  }
                  nav.popUntil((route) => route.isFirst);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Same card chrome as Service History / Active Progress list cards.
class _CartProgressStyleCard extends StatelessWidget {
  const _CartProgressStyleCard({
    required this.item,
    required this.onPayNow,
  });

  final _CartPayableItem item;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    final badgeAsset = CareActiveJob.serviceBadgeAsset(item.serviceType);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0F6876), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF12899B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF8A9496),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.option,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF062F35),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF062F35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                badgeAsset,
                                width: 14,
                                height: 14,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF0CADC5),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.serviceTitle,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      PaymentAmountFormatter.formatGrouped(item.amount),
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF12899B),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 56,
                  child: item.imageUrl.isEmpty
                      ? Container(
                          color: const Color(0xFFE8EEEE),
                          child: const Icon(
                            Icons.directions_walk_rounded,
                            color: Color(0xFF12899B),
                          ),
                        )
                      : ArticleRackShoeImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPayNow,
              borderRadius: BorderRadius.circular(100),
              child: Ink(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0xFF0CADC5), Color(0xFF063239)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Pay Now',
                    style: GoogleFonts.boldonse(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartPayableItem {
  final String id;
  final String serviceType;
  final String serviceTitle;
  final String requestLabel;
  final String brand;
  final String model;
  final String option;
  final String imageUrl;
  final double amount;

  const _CartPayableItem({
    required this.id,
    required this.serviceType,
    required this.serviceTitle,
    required this.requestLabel,
    required this.brand,
    required this.model,
    required this.option,
    required this.imageUrl,
    required this.amount,
  });

  static _CartPayableItem? tryFrom(Map<String, dynamic> r) {
    final id = (r['_id'] ?? r['id'] ?? '').toString().trim();
    if (id.isEmpty) return null;

    final paymentState =
        (r['paymentState'] ?? r['workflowStatus'] ?? '').toString().toUpperCase();
    final isPaid = r['isPaid'] == true ||
        r['paymentCompleted'] == true ||
        paymentState == 'PAYMENT_SUCCESS' ||
        paymentState == 'PAID' ||
        paymentState == 'PAYMENT_REFUNDED';
    if (isPaid) return null;

    final amount = _payableAmount(r);
    if (amount <= 0) return null;

    final needsPay = paymentState.isEmpty ||
        paymentState == 'PAYMENT_PENDING' ||
        paymentState == 'PAYMENT_INITIATED' ||
        paymentState == 'PAYMENT_FAILED' ||
        paymentState == 'COST_APPROVAL_PENDING';
    if (!needsPay) return null;

    final serviceType = (r['serviceType'] ?? '').toString();
    final publicId = (r['publicId'] ?? '').toString().trim();
    final requestLabel = publicId.isNotEmpty
        ? 'Request #$publicId'
        : (id.length <= 10
            ? 'Request #$id'
            : 'Request #${id.substring(0, 8)}…');

    return _CartPayableItem(
      id: id,
      serviceType: serviceType,
      serviceTitle: CareActiveJob.serviceLabel(serviceType),
      requestLabel: requestLabel,
      brand: CareActiveJob.brand(r),
      model: CareActiveJob.modelLine(r),
      option: CareActiveJob.serviceOptionLabel(r),
      imageUrl: CareActiveJob.articleImageUrl(r),
      amount: amount,
    );
  }

  static double _payableAmount(Map<String, dynamic> r) {
    final actual = r['actualCost'];
    if (actual is num && actual > 0) return actual.toDouble();
    final actualParsed = double.tryParse('$actual');
    if (actualParsed != null && actualParsed > 0) return actualParsed;
    final estimated = r['estimatedCost'];
    if (estimated is num && estimated > 0) return estimated.toDouble();
    return double.tryParse('$estimated') ?? 0;
  }
}
