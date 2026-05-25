import 'package:flutter/material.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';

class ShareProfileSheet extends StatelessWidget {
  const ShareProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Text(context.l10n.shareProfileWithClientsButton),
    );
  }
}
