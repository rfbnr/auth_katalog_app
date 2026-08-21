import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../controllers/profile_controller.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    return profile.when(
      loading: () => const AppShimmer(
        child: ListTile(
          leading: CircleAvatar(radius: 26),
          title: ShimmerBox(height: 16),
          subtitle: ShimmerBox(height: 12),
        ),
      ),
      error: (error, _) => ListTile(
        leading: const Icon(Icons.account_circle_outlined, size: 48),
        title: Text(
          failureMessage(error, fallback: 'Profil gagal dimuat.'),
          maxLines: 2,
        ),
        trailing: TextButton(
          onPressed: () => ref.read(profileControllerProvider.notifier).retry(),
          child: const Text('Coba Lagi'),
        ),
      ),
      data: (user) => ListTile(
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right),
        leading: ClipOval(
          child: CachedNetworkImage(
            imageUrl: user.image,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) =>
                const CircleAvatar(radius: 26, child: Icon(Icons.person)),
          ),
        ),
        title: Text(
          'Halo, ${user.fullName}!',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(user.email),
      ),
    );
  }
}
