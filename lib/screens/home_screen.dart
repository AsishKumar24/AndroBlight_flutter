import 'package:flutter/material.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import 'scan_apk_screen.dart';
import 'scan_playstore_screen.dart';
import 'history_screen.dart';
import 'installed_apps_screen.dart';
import 'rules_screen.dart';
import 'two_fa_setup_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../providers/totp_provider.dart';
import '../models/developer_profile.dart';
import 'developer_detail_screen.dart';
import 'login_screen.dart';

// Group 47 — tap a row to open [DeveloperDetailScreen]; edit bios here.
const List<DeveloperProfile> _kDevelopers = [
  DeveloperProfile(
    name: 'Akash Kumar',
    role: 'ML & Backend Engineer',
    photoAssetPath: 'assets/developers/akashkumar.jpeg',
    githubUrl: 'https://github.com/88-akash',
    linkedinUrl: 'https://www.linkedin.com/in/88-akashkumar/',
    kiitRollNo: '2230008',
    bio:
        'ML and deep learning engineer who builds intelligent systems that actually ship — from model design and training loops to the APIs and backends that serve predictions at scale.\n\n'
        'Strong across the classic ML/DL stack; comfortable on mobile with React Native when the product needs a sharp client. Day-to-day focus: ML quality, experimentation discipline, and backend reliability — not slide-deck demos.\n\n'
        'On AndroBlight: the model story — features, risk signals, and the pipeline that turns raw APK signals into verdicts users can trust.',
  ),
  DeveloperProfile(
    name: 'Ashmit Dutta',
    role: 'Flutter & IoT Developer',
    photoAssetPath: 'assets/developers/ashmitdutta.jpeg',
    githubUrl: 'https://github.com/ashmitdutta',
    linkedinUrl: 'https://www.linkedin.com/in/ashmit-dutta/',
    kiitRollNo: '2230156',
    bio:
        'Electronics-minded builder who loves the path from bits to boards — Flutter and Dart on the frontend for fluid, modern UIs, plus Arduino and IoT when the product has to talk to sensors and the real world.\n\n'
        'Comfortable straddling hardware bring-up and polished mobile experiences: prototype fast, iterate cleanly, ship something people actually want to use.\n\n'
        'On AndroBlight: the client app — navigation, screens, and the Dart layer that keeps scans and results feel instant and clear.',
  ),
  DeveloperProfile(
    name: 'Asish Kumar',
    role: 'Full-stack Developer',
    photoAssetPath: 'assets/developers/asishkumar.jpeg',
    githubUrl: 'https://github.com/AsishKumar24',
    linkedinUrl: 'https://www.linkedin.com/in/k-asish-kumar-b38ab0215/',
    kiitRollNo: '2230240',
    bio:
        'Full-stack engineer who ships web and mobile apps end-to-end — React.js, React Native, Node.js, and MongoDB where users meet data, plus Flask and battle-tested REST APIs when the server has to be right.\n\n'
        'Sharp on DSA, API design, and turning fuzzy requirements into production-ready, user-centric products — not demos that fall over under load.\n\n'
        'On AndroBlight: backend architecture, secure integrations, and the pipelines that keep scans fast, honest, and scalable.',
  ),
];

/// Home — main hub (lavender shell, brand cards, grouped actions).

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _logoAsset = 'assets/app_logo.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanProvider>().checkDeviceSecurity();
    });
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text(
          'You will need to sign in again to use your account.\n\n'
          'Scan history saved on this device is not removed — only your session ends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
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
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -AppScale.verticalScale(context, 60),
            right: -AppScale.scale(context, 50),
            child: _glowOrb(
              AppScale.scale(context, 240),
              AppTheme.brand.withAlpha(22),
            ),
          ),
          Positioned(
            bottom: AppScale.verticalScale(context, 180),
            left: -AppScale.scale(context, 70),
            child: _glowOrb(
              AppScale.scale(context, 200),
              AppTheme.brandDark.withAlpha(16),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: r.screenPadding,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(r),
                      SizedBox(height: r.spacingLG + 4),
                      _buildHero(r),
                      SizedBox(height: r.spacingLG),
                      _SectionLabel(text: 'Scan & analyse', r: r),
                      SizedBox(height: r.spacingSM),
                      _ActionCard(
                        icon: Icons.android_rounded,
                        title: 'Scan APK file',
                        description: 'Upload and analyse a local APK',
                        accent: AppTheme.brand,
                        responsive: r,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ScanApkScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: r.spacingMD),
                      _ActionCard(
                        icon: Icons.storefront_rounded,
                        title: 'Play Store app',
                        description: 'URL or package — metadata & permissions',
                        accent: AppTheme.brandDark,
                        responsive: r,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ScanPlaystoreScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: r.spacingMD),
                      _ActionCard(
                        icon: Icons.smartphone_rounded,
                        title: 'Scan my phone',
                        description: 'Review installed apps for risk signals',
                        accent: const Color(0xFF6366F1),
                        responsive: r,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const InstalledAppsScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: r.spacingLG + 8),
                      _SectionLabel(text: 'Security & rules', r: r),
                      SizedBox(height: r.spacingSM),
                      _ActionCard(
                        icon: Icons.rule_folder_rounded,
                        title: 'Custom rules',
                        description: 'Permission-based rules you define',
                        accent: AppTheme.brand,
                        responsive: r,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RulesScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: r.spacingMD),
                      Consumer<TotpProvider>(
                        builder: (context, totp, _) {
                          return _ActionCard(
                            icon: totp.twoFaEnabled
                                ? Icons.verified_user_rounded
                                : Icons.phonelink_lock_rounded,
                            title: 'Two-factor auth',
                            description: totp.twoFaEnabled
                                ? 'Extra sign-in protection is on'
                                : 'Add an authenticator for your account',
                            accent: totp.twoFaEnabled
                                ? AppTheme.benignGreen
                                : AppTheme.warningAmber,
                            responsive: r,
                            onTap: () {
                              context.read<TotpProvider>().loadStatus();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TwoFaSetupScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      SizedBox(height: r.spacingXL),
                      _buildFooter(r),
                      SizedBox(height: r.spacingMD),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  Widget _buildHeader(Responsive r) {
    return Container(
      padding: EdgeInsets.all(r.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.r28(context)),
        boxShadow: UiShadows.card(blur: 22, y: 10),
        border: Border.all(color: AppTheme.brand.withAlpha(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: r.adaptive(small: 48.0, medium: 52.0, large: 54.0),
            height: r.adaptive(small: 48.0, medium: 52.0, large: 54.0),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.brand.withAlpha(35)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brand.withAlpha(35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                _logoAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.brand, AppTheme.brandDark],
                    ),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: AppTheme.onBrand,
                    size: r.adaptive(small: 22.0, medium: 26.0),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: r.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AndroBlight',
                  style: TextStyle(
                    fontSize: r.sp(21),
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Consumer<ScanProvider>(
                      builder: (context, provider, _) {
                        final online = provider.isBackendOnline;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: online
                                    ? AppTheme.benignGreen
                                    : AppTheme.malwareRed,
                                boxShadow: [
                                  BoxShadow(
                                    color: (online
                                            ? AppTheme.benignGreen
                                            : AppTheme.malwareRed)
                                        .withAlpha(90),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              online ? 'Live' : 'Offline',
                              style: TextStyle(
                                fontSize: r.sp(11),
                                fontWeight: FontWeight.w600,
                                color: online
                                    ? AppTheme.benignGreen
                                    : AppTheme.malwareRed,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    Consumer<ScanProvider>(
                      builder: (context, provider, _) {
                        if (!provider.deviceSecurityChecked) {
                          return const SizedBox.shrink();
                        }
                        final rooted = provider.isDeviceRooted;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: rooted
                                ? AppTheme.malwareRed.withAlpha(26)
                                : AppTheme.benignGreen.withAlpha(26),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: rooted
                                  ? AppTheme.malwareRed.withAlpha(70)
                                  : AppTheme.benignGreen.withAlpha(70),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                rooted
                                    ? Icons.warning_amber_rounded
                                    : Icons.verified_rounded,
                                size: 13,
                                color: rooted
                                    ? AppTheme.malwareRed
                                    : AppTheme.benignGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rooted ? 'Rooted' : 'Device OK',
                                style: TextStyle(
                                  fontSize: r.sp(10),
                                  fontWeight: FontWeight.w700,
                                  color: rooted
                                      ? AppTheme.malwareRed
                                      : AppTheme.benignGreen,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Scan history',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppTheme.textMuted,
                ),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: () => _confirmAndLogout(context),
                icon: Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppTheme.textMuted.withAlpha(200),
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHero(Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like\nto scan today?',
          style: TextStyle(
            fontSize: r.sp(26),
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: r.spacingSM),
        Text(
          'Pick a method — we score risk from APKs, Play listings, or your device.',
          style: TextStyle(
            fontSize: r.sp(14),
            color: AppTheme.textSecondary,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: r.spacingMD),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.brand.withAlpha(24),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.brand.withAlpha(45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 18,
                color: AppTheme.brandDark,
              ),
              const SizedBox(width: 8),
              Text(
                'Scan · Analyse · Protect',
                style: TextStyle(
                  fontSize: r.sp(12),
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandDark,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(Responsive r) {
    return Column(
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: AppTheme.textMuted.withAlpha(40),
        ),
        SizedBox(height: r.spacingMD),
        Text(
          'AndroBlight · Malware detection',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: r.sp(12),
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Powered by AndroBlight Group - 47',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: r.sp(10),
            color: AppTheme.textMuted.withAlpha(180),
          ),
        ),
        if (_kDevelopers.isNotEmpty) ...[
          SizedBox(height: r.spacingLG),
          _buildDevelopersSection(context, r),
        ],
      ],
    );
  }

  Widget _buildDevelopersSection(BuildContext context, Responsive r) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: r.spacingMD,
        vertical: r.spacingSM + 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.brand.withAlpha(12),
        borderRadius: BorderRadius.circular(AppRadius.r20(context)),
        border: Border.all(color: AppTheme.brand.withAlpha(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'DEVELOPERS',
            style: TextStyle(
              fontSize: r.sp(10),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: AppTheme.textMuted,
            ),
          ),
          SizedBox(height: r.spacingSM),
          ..._kDevelopers.map((d) => _buildDeveloperRow(context, r, d)),
        ],
      ),
    );
  }

  Widget _buildDeveloperRow(
    BuildContext context,
    Responsive r,
    DeveloperProfile d,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DeveloperDetailScreen(profile: d),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: AppTheme.brand.withAlpha(200),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: r.sp(12),
                        height: 1.35,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: d.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' · ${d.role}',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.textMuted.withAlpha(160),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Responsive r;

  const _SectionLabel({required this.text, required this.r});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: r.sp(11),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Responsive responsive;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.responsive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = responsive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r28(context)),
        splashColor: accent.withAlpha(35),
        highlightColor: accent.withAlpha(18),
        child: Ink(
          padding: EdgeInsets.all(r.spacingMD + 2),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.r28(context)),
            boxShadow: UiShadows.card(blur: 20, y: 8),
            border: Border.all(color: accent.withAlpha(36)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: r.adaptive(small: 56.0, medium: 62.0, large: 66.0),
                height: r.adaptive(small: 56.0, medium: 62.0, large: 66.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withAlpha(48),
                      accent.withAlpha(22),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.r17(context)),
                  border: Border.all(color: accent.withAlpha(55)),
                ),
                child: Icon(
                  icon,
                  size: r.adaptive(small: 28.0, medium: 32.0, large: 34.0),
                  color: accent,
                ),
              ),
              SizedBox(width: r.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: r.sp(17),
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: r.sp(12),
                        color: AppTheme.textSecondary,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
                size: r.adaptive(small: 26.0, medium: 28.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
