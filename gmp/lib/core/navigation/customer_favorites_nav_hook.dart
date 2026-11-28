import 'package:flutter/material.dart';

/// Set by favorites navigation so the bottom nav can open Favorites without a
/// circular import on [FavoritesPage].
typedef OpenCustomerFavoritesCallback = void Function(BuildContext context);

OpenCustomerFavoritesCallback? openCustomerFavoritesHook;

/// Returns true when a favorites opener was registered and invoked.
bool invokeOpenCustomerFavorites(BuildContext context) {
  final hook = openCustomerFavoritesHook;
  if (hook == null) return false;
  hook(context);
  return true;
}
