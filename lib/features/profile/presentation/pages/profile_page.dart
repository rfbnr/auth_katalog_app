import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda perlu login kembali untuk mengakses aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final failure = await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted || failure == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final notifier = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: profile.when(
          loading: () => const _ProfileShimmer(),
          error: (error, _) => _ProfileError(
            message: failureMessage(error, fallback: 'Profil gagal dimuat.'),
            onRetry: notifier.retry,
            onRefresh: notifier.refresh,
          ),
          data: (user) => _ProfileContent(
            user: user,
            onLogout: () => _logout(context, ref),
            onRefresh: notifier.refresh,
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.user,
    required this.onLogout,
    required this.onRefresh,
  });

  final UserEntity user;
  final VoidCallback onLogout;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _ProfileIdentity(user: user),
          const Divider(height: 32),
          _ProfileSection(
            title: 'Akun',
            entries: [
              ('Email', user.email),
              ('Username', user.username),
              ('ID', '${user.id}'),
            ],
          ),
          _ProfileSection(
            title: 'Pribadi',
            entries: [
              ('Umur', user.age?.toString()),
              ('Gender', user.gender),
              ('Tanggal lahir', DateFormatter.longDate(user.birthDate)),
              ('Telepon', user.phone),
            ],
          ),
          _ProfileSection(
            title: 'Pendidikan',
            entries: [('Universitas', user.university)],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: FilledButton.tonalIcon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Keluar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final role = user.role;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: user.image,
              width: 104,
              height: 104,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) =>
                  const CircleAvatar(radius: 52, child: Icon(Icons.person)),
            ),
          ),
          const SizedBox(height: 16),
          Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '@${user.username}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (role != null && role.isNotEmpty) ...[
            const SizedBox(height: 12),
            Chip(label: Text(role), visualDensity: VisualDensity.compact),
          ],
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.entries});

  final String title;
  final List<(String, String?)> entries;

  @override
  Widget build(BuildContext context) {
    final present = entries
        .where((entry) => entry.$2 != null && entry.$2!.trim().isNotEmpty)
        .toList(growable: false);
    if (present.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final (label, value) in present)
          ListTile(
            dense: true,
            title: Text(label, style: Theme.of(context).textTheme.bodySmall),
            subtitle: Text(
              value!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
      ],
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({
    required this.message,
    required this.onRetry,
    required this.onRefresh,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.person_off_outlined, size: 56),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          children: [
            ShimmerBox(width: 104, height: 104, radius: 52),
            SizedBox(height: 16),
            ShimmerBox(width: 180, height: 24),
            SizedBox(height: 8),
            ShimmerBox(width: 110, height: 16),
            SizedBox(height: 32),
            ShimmerBox(height: 48),
            SizedBox(height: 12),
            ShimmerBox(height: 48),
            SizedBox(height: 12),
            ShimmerBox(height: 48),
          ],
        ),
      ),
    );
  }
}
