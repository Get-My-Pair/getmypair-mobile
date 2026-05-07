import 'package:flutter/material.dart';

import 'repair_my_pair_page.dart';

/// Donate flow entry — same pattern as [MaintainMyPairPage] / [WashMyPairPage]:
/// article grid on [RepairMyPairPage], then multi-step UI from [donate_my_pair_flow.dart].
class DonateMyPairPage extends StatelessWidget {
  const DonateMyPairPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepairMyPairPage(
      pageTitle: 'DonateMyPair',
      allowedServiceTypes: ['donate'],
      description:
          'DonateMyPair helps you give your footwear a second life.\n\n'
          'Please select the footwear you\'d like to donate.',
    );
  }
}
