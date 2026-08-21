import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../product/presentation/widgets/catalog_section.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/presentation/widgets/profile_header.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth Katalog')),
      body: SafeArea(
        child: Column(
          children: [
            ProfileHeader(onTap: () => context.push(AppRoutes.profile)),
            const Divider(height: 1),
            Expanded(
              child: CatalogSection(
                onAdditionalRefresh: () =>
                    ref.read(profileControllerProvider.notifier).refresh(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
