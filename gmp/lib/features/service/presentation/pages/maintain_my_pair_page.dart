import 'package:flutter/material.dart';
import 'package:gmp/features/service/presentation/pages/repair_my_pair_page.dart';

class MaintainMyPairPage extends StatelessWidget {
  const MaintainMyPairPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepairMyPairPage(
      pageTitle: 'MaintainMyPair',
      allowedServiceTypes: ['maintenance'],
      tagline: '',
      description:
          'MaintainMyPair is a service that keeps your footwear in top condition. Please select the footwear you\'d like to maintain.',
    );
  }
}
