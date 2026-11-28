import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gmp/core/errors/failures.dart';
import 'package:gmp/features/articles/data/models/article_model.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_my_articles.dart';
import 'package:gmp/features/articles/domain/usecases/update_article.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/favorites/presentation/pages/favorites_page.dart';

class _FakeToken implements GetValidAccessToken {
  @override
  Future<Either<Failure, String>> call() async => const Right('token');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGetMyArticles implements GetMyArticles {
  _FakeGetMyArticles(this.articles);
  List<Article> articles;

  @override
  Future<List<Article>> call(String accessToken) async => articles;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUpdateArticle implements UpdateArticle {
  final List<Map<String, Object?>> calls = [];
  bool fail = false;

  @override
  Future<Article> call(
    String accessToken,
    String articleId, {
    String? brand,
    String? model,
    String? category,
    String? footwearType,
    String? color,
    int? purchaseYear,
    String? condition,
    List<Map<String, dynamic>>? materials,
    List<String>? imageUrls,
    String? shoeSize,
    bool? isFavorite,
  }) async {
    calls.add({'id': articleId, 'isFavorite': isFavorite, 'color': color});
    if (fail) throw Exception('Network down');
    return _article(articleId, 'x', favorite: isFavorite ?? false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Article _article(String id, String brand,
    {bool favorite = false, String color = '#E53935'}) {
  return ArticleModel(
    id: id,
    ownerId: 'u1',
    brand: brand,
    model: '$brand Model',
    category: 'sneaker',
    color: color,
    condition: 'good',
    createdAt: DateTime(2026, 1, 1),
    shoeSize: 'UK: 08',
    isFavorite: favorite,
  );
}

Future<void> _pumpPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: FavoritesPage()));
  // Skeleton pulses forever, so never pumpAndSettle.
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  late _FakeGetMyArticles list;
  late _FakeUpdateArticle update;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    final sl = GetIt.instance;
    sl.reset();
    list = _FakeGetMyArticles([
      _article('a1', 'Nike', favorite: true),
      _article('a2', 'Adidas', favorite: false),
      _article('a3', 'Puma', favorite: true, color: 'Navy'),
    ]);
    update = _FakeUpdateArticle();
    sl.registerSingleton<GetValidAccessToken>(_FakeToken());
    sl.registerSingleton<GetMyArticles>(list);
    sl.registerSingleton<UpdateArticle>(update);
  });

  tearDown(() => GetIt.instance.reset());

  // google_fonts can't fetch in tests and logs a (harmless) error per style.
  void ignoreFontErrors() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('google_fonts') || msg.contains('GoogleFonts')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  testWidgets('lists only hearted footwear', (tester) async {
    ignoreFontErrors();
    await _pumpPage(tester);
    expect(find.text('Nike'), findsOneWidget);
    expect(find.text('Puma'), findsOneWidget);
    expect(find.text('Adidas'), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
  });

  testWidgets('exact picked hex colour is shown, not a nearest name',
      (tester) async {
    ignoreFontErrors();
    await _pumpPage(tester);
    expect(find.textContaining('#E53935'), findsOneWidget);
    expect(find.textContaining('Navy'), findsOneWidget);
  });

  testWidgets('tapping the heart removes it and saves isFavorite=false',
      (tester) async {
    ignoreFontErrors();
    await _pumpPage(tester);
    await tester.tap(find.byIcon(Icons.favorite_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Nike'), findsNothing);
    expect(find.text('Puma'), findsOneWidget);
    expect(update.calls, [
      {'id': 'a1', 'isFavorite': false, 'color': null},
    ]);
  });

  testWidgets('failed un-favourite puts the card back', (tester) async {
    ignoreFontErrors();
    update.fail = true;
    await _pumpPage(tester);
    await tester.tap(find.byIcon(Icons.favorite_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Nike'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 6)); // let the alert settle
  });

  testWidgets('empty state explains how to add favourites', (tester) async {
    ignoreFontErrors();
    list.articles = [_article('a2', 'Adidas')];
    await _pumpPage(tester);
    expect(find.text('No favorites yet'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);
  });
}
