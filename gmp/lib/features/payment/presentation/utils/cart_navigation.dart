import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/customer_cart_nav_hook.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../pages/cart_page.dart';

/// Registers the bottom-nav cart opener. Call once from app shell startup.
void registerCustomerCartNavigation() {
  openCustomerCartHook = openCustomerCartPage;
}

/// Opens [CartPage] from bottom nav (skips push if already on cart).
void openCustomerCartPage(BuildContext context) {
  registerCustomerCartNavigation();

  final current = ModalRoute.of(context)?.settings.name;
  if (current == '/cart') return;

  ProfileBloc? profileBloc;
  try {
    profileBloc = context.read<ProfileBloc>();
  } catch (_) {
    profileBloc = ProfileBlocAnchor.current;
  }

  const page = CartPage();
  Navigator.of(context).push(
    MaterialPageRoute(
      settings: const RouteSettings(name: '/cart'),
      builder: (_) {
        if (profileBloc == null || profileBloc.isClosed) return page;
        return BlocProvider.value(value: profileBloc, child: page);
      },
    ),
  );
}
