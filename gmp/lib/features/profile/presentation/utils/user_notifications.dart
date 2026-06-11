import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/auth/domain/usecases/get_valid_access_token.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user_profile.dart';
import 'profile_notifications.dart';

class UserNotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? serviceRequestId;
  final double? actualCost;
  final double? amount;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.serviceRequestId,
    this.actualCost,
    this.amount,
    this.isRead = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserNotificationItem.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final dataMap = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final actualRaw = dataMap['actualCost'];
    final amountRaw = dataMap['amount'] ?? actualRaw;
    return UserNotificationItem(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      type: '${json['type'] ?? ''}',
      title: '${json['title'] ?? 'Notification'}',
      message: '${json['body'] ?? json['message'] ?? ''}',
      serviceRequestId: dataMap['serviceRequestId']?.toString(),
      actualCost: actualRaw is num ? actualRaw.toDouble() : double.tryParse('$actualRaw'),
      amount: amountRaw is num ? amountRaw.toDouble() : double.tryParse('$amountRaw'),
      isRead: json['readAt'] != null,
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
    );
  }

  bool get isCostApproval => type == 'COST_APPROVAL_PENDING';
  bool get isPaymentSuccess => type == 'PAYMENT_SUCCESS';
  bool get isPaymentFailed => type == 'PAYMENT_FAILED';
  bool get isPaymentRelated => isPaymentSuccess || isPaymentFailed;

  String? get actionLabel {
    if (isCostApproval) return 'Review cost';
    if (isPaymentSuccess) return 'View payment';
    if (isPaymentFailed) return 'Retry payment';
    return null;
  }

  double? get payableAmount => amount ?? actualCost;
}

class UserNotificationsResult {
  final List<UserNotificationItem> items;
  final int unreadCount;

  const UserNotificationsResult({
    required this.items,
    this.unreadCount = 0,
  });
}

Future<UserNotificationsResult> fetchUserNotifications() async {
  final tokenResult = await sl<GetValidAccessToken>().call();
  return tokenResult.fold(
    (_) async => const UserNotificationsResult(items: []),
    (token) async {
      try {
        final res = await sl<DioClient>().get(
          ApiEndpoints.userNotifications,
          accessToken: token,
        );
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final list = (data['items'] as List?) ?? const [];
        final items = list
            .whereType<Map>()
            .map((e) => UserNotificationItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final unreadCount = (data['unreadCount'] as num?)?.toInt() ?? 0;
        return UserNotificationsResult(items: items, unreadCount: unreadCount);
      } catch (_) {
        return const UserNotificationsResult(items: []);
      }
    },
  );
}

Future<void> markUserNotificationRead(String notificationId) async {
  final tokenResult = await sl<GetValidAccessToken>().call();
  await tokenResult.fold(
    (_) async {},
    (token) async {
      try {
        await sl<DioClient>().patch(
          ApiEndpoints.userNotificationRead(notificationId),
          accessToken: token,
        );
      } catch (_) {}
    },
  );
}

int countAllNotifications({
  UserProfile? profile,
  UserNotificationsResult? apiResult,
}) {
  final profileCount = buildProfileNotifications(profile).length;
  final apiUnread = apiResult?.unreadCount ??
      apiResult?.items.where((n) => !n.isRead).length ??
      0;
  return profileCount + apiUnread;
}

List<Object> mergeNotificationItems({
  required UserProfile? profile,
  required List<UserNotificationItem> apiItems,
}) {
  final profileItems = buildProfileNotifications(profile);
  return [...apiItems, ...profileItems];
}
