import 'package:flutter/material.dart';

/// Set by payment cart navigation so bottom nav can open Cart without a
/// circular import on [CartPage].
typedef OpenCustomerCartCallback = void Function(BuildContext context);

OpenCustomerCartCallback? openCustomerCartHook;

void invokeOpenCustomerCart(BuildContext context) {
  openCustomerCartHook?.call(context);
}
