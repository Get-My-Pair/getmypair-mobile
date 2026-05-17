import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/gradient_page_shell.dart';
import '../widgets/product_card.dart';
import '../../data/mock_products.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = mockProducts;
    return GradientPageShell(
      appBar: buildGradientAppBar(title: 'Shop', centerTitle: false),
      body: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ColoredBox(
            color: AppColors.surface,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final padding = Responsive.horizontalPaddingOf(context);
                final aspectRatio = MediaQuery.sizeOf(context).width <= Responsive.breakpointSmall ? 0.68 : 0.72;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
                  child: GridView.builder(
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: aspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      final product = items[index];
                      return ProductCard(
                        product: product,
                        onTap: () => showComingSoon(
                          context,
                          feature: 'Product details',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
