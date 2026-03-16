import 'package:flutter/material.dart';
import 'package:gmp/core/theme/app_colors.dart';

/// Module 3 – Edit shoe. Placeholder; full form will use PUT /api/articles/update/:articleId.
class ArticleEditPage extends StatelessWidget {
  final String articleId;

  const ArticleEditPage({super.key, required this.articleId});

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
          'Edit Shoe',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Edit form coming soon',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
