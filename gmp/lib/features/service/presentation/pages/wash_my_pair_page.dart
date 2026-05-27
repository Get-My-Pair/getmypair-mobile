import 'package:flutter/material.dart';
import 'package:gmp/features/service/presentation/pages/repair_my_pair_page.dart';

class WashMyPairPage extends StatelessWidget {
  const WashMyPairPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepairMyPairPage(
      pageTitle: 'WashMyPair',
      allowedServiceTypes: ['wash'],
      description:
          'WashMyPair gives your footwear a deep clean.\n\nSelect one or more pairs you\'d like to wash.',
    );
  }
}
