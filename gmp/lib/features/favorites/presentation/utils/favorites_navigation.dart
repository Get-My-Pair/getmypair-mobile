import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gmp/core/navigation/customer_favorites_nav_hook.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_bloc.dart';

import '../pages/favorites_page.dart';

/// Registers the bottom-nav Favorites opener. Call once from the app shell.
void registerCustomerFavoritesNavigation() {
  openCustomerFavoritesHook = openCustomerFavoritesPage;
}

/// Opens [FavoritesPage] from the bottom nav (no-op if it is already open).
void openCustomerFavoritesPage(BuildContext context) {
  registerCustomerFavoritesNavigation();

  final current = ModalRoute.of(context)?.settings.name;
  if (current == FavoritesPage.routeName) return;

  ProfileBloc? profileBloc;
  try {
    profileBloc = context.read<ProfileBloc>();
  } catch (_) {
    profileBloc = ProfileBlocAnchor.current;
  }

  const page = FavoritesPage();
  Navigator.of(context).push(
    MaterialPageRoute(
      settings: const RouteSettings(name: FavoritesPage.routeName),
      builder: (_) {
        if (profileBloc == null || profileBloc.isClosed) return page;
        return BlocProvider.value(value: profileBloc, child: page);
      },
    ),
  );
}
