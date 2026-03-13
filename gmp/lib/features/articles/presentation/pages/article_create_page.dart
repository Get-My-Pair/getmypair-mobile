import 'package:flutter/material.dart';
import 'package:gmp/core/theme/app_colors.dart';

/// Module 3 – Add new shoe. Placeholder until full create form is implemented.
/// Navigate from ArticleListPage when user taps "Add Shoe".
class ArticleCreatePage extends StatelessWidget {
  const ArticleCreatePage({super.key});

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
          'Add Shoe',
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
          'Add shoe form coming soon',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
