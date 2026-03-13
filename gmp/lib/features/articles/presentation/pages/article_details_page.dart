import 'package:flutter/material.dart';
import 'package:gmp/core/theme/app_colors.dart';

/// Module 3 – Article details. Placeholder until full details screen is implemented.
/// Navigate from ArticleListPage when user taps a shoe.
class ArticleDetailsPage extends StatelessWidget {
  final String articleId;

  const ArticleDetailsPage({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shoe Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Details screen coming soon',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
