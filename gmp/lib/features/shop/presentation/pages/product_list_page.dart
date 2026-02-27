import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/product_card.dart';
import '../../data/mock_products.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = mockProducts;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shop'),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final product = items[index];
            return ProductCard(
              product: product,
              onTap: () {
                // TODO: navigate to product detail
              },
            );
          },
        ),
      ),
    );
  }
}

