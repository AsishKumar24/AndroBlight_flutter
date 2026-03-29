import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/developer_profile.dart';

/// Full-screen profile for one developer (opened from Home → Developers).
class DeveloperDetailScreen extends StatelessWidget {
  final DeveloperProfile profile;

  const DeveloperDetailScreen({super.key, required this.profile});

  Future<void> _openUrl(BuildContext context, String raw) async {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid link')),
        );
      }
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final bio = profile.bio.trim();
    final photo = profile.photoAssetPath?.trim();

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F7FF),
                  AppTheme.primaryLight,
                  AppTheme.pageBackground,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -AppScale.verticalScale(context, 40),
            right: -AppScale.scale(context, 30),
            child: IgnorePointer(
              child: Container(
                width: AppScale.scale(context, 180),
                height: AppScale.scale(context, 180),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brand.withAlpha(14),
                ),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.pageBackground.withAlpha(242),
                foregroundColor: AppTheme.textPrimary,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Developer',
                  style: TextStyle(
                    fontSize: r.sp(17),
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              SliverPadding(
                padding: r.screenPadding,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Center(child: _buildAvatar(context, r, photo)),
                    SizedBox(height: r.spacingMD),
                    Text(
                      profile.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: r.sp(24),
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: r.spacingSM),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.brand.withAlpha(28),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.brand.withAlpha(55),
                          ),
                        ),
                        child: Text(
                          profile.role,
                          style: TextStyle(
                            fontSize: r.sp(13),
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandDark,
                          ),
                        ),
                      ),
                    ),
                    if (profile.hasKiitRollNo) ...[
                      SizedBox(height: r.spacingSM),
                      Text(
                        'KIIT University · Roll no. ${profile.kiitRollNo}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                    SizedBox(height: r.spacingXL),
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: r.sp(12),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    SizedBox(height: r.spacingSM),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(r.spacingMD),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppRadius.r20(context)),
                        border: Border.all(
                          color: AppTheme.brand.withAlpha(28),
                        ),
                        boxShadow: UiShadows.card(blur: 16, y: 6),
                      ),
                      child: Text(
                        bio.isEmpty
                            ? 'Add your bio in home_screen.dart (_kDevelopers → bio). '
                                'Add a photo under assets/developers/ and set photoAssetPath.'
                            : bio,
                        style: TextStyle(
                          fontSize: r.sp(14),
                          height: 1.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (profile.hasGithub || profile.hasLinkedin) ...[
                      SizedBox(height: r.spacingXL),
                      Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      SizedBox(height: r.spacingSM),
                      if (profile.hasGithub)
                        _socialTile(
                          context,
                          r,
                          label: 'GitHub',
                          subtitle: profile.githubUrl!,
                          icon: Icons.code_rounded,
                          onTap: () =>
                              _openUrl(context, profile.githubUrl!),
                        ),
                      if (profile.hasGithub && profile.hasLinkedin)
                        SizedBox(height: r.spacingSM),
                      if (profile.hasLinkedin)
                        _socialTile(
                          context,
                          r,
                          label: 'LinkedIn',
                          subtitle: profile.linkedinUrl!,
                          icon: Icons.work_outline_rounded,
                          onTap: () =>
                              _openUrl(context, profile.linkedinUrl!),
                        ),
                    ],
                    SizedBox(height: r.spacingXL),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    Responsive r,
    String? photoAsset,
  ) {
    final size = r.adaptive(small: 96.0, medium: 104.0);
    final initials = _initialsBox(r, size);

    if (photoAsset == null || photoAsset.isEmpty) {
      return initials;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withAlpha(80),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          photoAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => initials,
        ),
      ),
    );
  }

  Widget _initialsBox(Responsive r, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.brand, AppTheme.brandDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withAlpha(80),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        profile.initials,
        style: TextStyle(
          fontSize: r.sp(28),
          fontWeight: FontWeight.w800,
          color: AppTheme.onBrand,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _socialTile(
    BuildContext context,
    Responsive r, {
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r17(context)),
        child: Ink(
          padding: EdgeInsets.all(r.spacingMD),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.r17(context)),
            border: Border.all(color: AppTheme.brand.withAlpha(32)),
            boxShadow: UiShadows.card(blur: 12, y: 4),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.brandDark, size: 22),
              ),
              SizedBox(width: r.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: r.sp(15),
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: r.sp(11),
                        color: AppTheme.textMuted,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
