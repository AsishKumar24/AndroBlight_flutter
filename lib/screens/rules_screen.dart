import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/rules_provider.dart';
import '../models/threat_rule.dart';

/// Custom threat rules — permission combinations (backend).

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RulesProvider>().loadRules();
    });
  }

  Widget _pageBackground(BuildContext context) {
    return Stack(
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
              stops: [0.0, 0.4, 1.0],
            ),
          ),
        ),
        Positioned(
          bottom: AppScale.verticalScale(context, 80),
          right: -AppScale.scale(context, 50),
          child: IgnorePointer(
            child: Container(
              width: AppScale.scale(context, 200),
              height: AppScale.scale(context, 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brand.withAlpha(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final provider = context.watch<RulesProvider>();

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.pageBackground,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Text(
          'Custom rules',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: r.sp(18),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          if (provider.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.brand,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brand,
        foregroundColor: AppTheme.onBrand,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add rule'),
        onPressed: () => _showRuleDialog(context),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _pageBackground(context),
          Positioned.fill(child: _buildBody(context, r, provider)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Responsive r,
    RulesProvider provider,
  ) {
    if (provider.isLoading && provider.rules.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.brand),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: r.screenPadding,
          child: Container(
            padding: EdgeInsets.all(r.spacingLG),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.r20(context)),
              border: Border.all(color: AppTheme.malwareRed.withAlpha(45)),
              boxShadow: UiShadows.card(blur: 18, y: 8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: AppTheme.malwareRed, size: 48),
                SizedBox(height: r.spacingMD),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: r.sp(14),
                  ),
                ),
                SizedBox(height: r.spacingLG),
                ElevatedButton(
                  onPressed: () => provider.loadRules(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand,
                    foregroundColor: AppTheme.onBrand,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.rules.isEmpty) {
      return Center(
        child: Padding(
          padding: r.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withAlpha(24),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rule_folder_rounded,
                  size: 48,
                  color: AppTheme.brand,
                ),
              ),
              SizedBox(height: r.spacingMD),
              Text(
                'No custom rules yet',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: r.sp(17),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: r.spacingSM),
              Text(
                'Tap Add rule to flag permission combinations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: r.sp(14),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(r.wp(4), r.wp(2), r.wp(4), 100),
      itemCount: provider.rules.length,
      separatorBuilder: (_, _) => SizedBox(height: r.spacingSM),
      itemBuilder: (ctx, i) => _RuleCard(
        rule: provider.rules[i],
        onToggle: (active) => provider.toggleRule(provider.rules[i].id, active),
        onDelete: () => _confirmDelete(ctx, provider, provider.rules[i]),
        onEdit: () => _showRuleDialog(ctx, existing: provider.rules[i]),
        r: r,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RulesProvider provider,
    ThreatRule rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete rule',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Delete "${rule.name}"? This cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppTheme.malwareRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final err = await provider.deleteRule(rule.id);
      if (!context.mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppTheme.malwareRed),
        );
      }
    }
  }

  Future<void> _showRuleDialog(
    BuildContext context, {
    ThreatRule? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final threatCtrl = TextEditingController(text: existing?.threat ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final permsCtrl = TextEditingController(
      text: existing?.permissions.join(', ') ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final rulesProvider = context.read<RulesProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          existing == null ? 'Add rule' : 'Edit rule',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Rule name', required: true),
                const SizedBox(height: 12),
                _field(threatCtrl, 'Threat label', required: true),
                const SizedBox(height: 12),
                _field(descCtrl, 'Description', required: true, maxLines: 2),
                const SizedBox(height: 12),
                _field(
                  permsCtrl,
                  'Permissions (comma-separated)',
                  required: true,
                  hint:
                      'e.g. android.permission.CAMERA, android.permission.RECORD_AUDIO',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brand,
              foregroundColor: AppTheme.onBrand,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final permissions = permsCtrl.text
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    String? err;

    if (existing == null) {
      err = await rulesProvider.createRule(
        name: nameCtrl.text.trim(),
        permissions: permissions,
        threat: threatCtrl.text.trim(),
        description: descCtrl.text.trim(),
      );
    } else {
      err = await rulesProvider.updateRule(
        existing.id,
        name: nameCtrl.text.trim(),
        permissions: permissions,
        threat: threatCtrl.text.trim(),
        description: descCtrl.text.trim(),
      );
    }

    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.malwareRed),
      );
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textMuted.withAlpha(140)),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.textMuted.withAlpha(50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.textMuted.withAlpha(50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.malwareRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.malwareRed),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.r,
  });

  final ThreatRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Responsive r;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.r20(context)),
        border: Border.all(color: AppTheme.brand.withAlpha(28)),
        boxShadow: UiShadows.card(blur: 16, y: 6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rule.name,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: r.sp(15),
                    ),
                  ),
                ),
                Switch(
                  value: rule.isActive,
                  onChanged: onToggle,
                  activeThumbColor: AppTheme.onBrand,
                  activeTrackColor: AppTheme.brand,
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppTheme.textSecondary,
                    size: 22,
                  ),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.malwareRed,
                    size: 22,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withAlpha(28),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warningAmber.withAlpha(70)),
              ),
              child: Text(
                rule.threat,
                style: TextStyle(
                  color: AppTheme.warningAmber,
                  fontSize: r.sp(12),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              rule.description,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: r.sp(13),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: rule.permissions.map((p) {
                final short = p.replaceFirst('android.permission.', '');
                return Chip(
                  backgroundColor: AppTheme.brand.withAlpha(22),
                  side: BorderSide(color: AppTheme.brand.withAlpha(50)),
                  label: Text(
                    short,
                    style: TextStyle(
                      color: AppTheme.brandDark,
                      fontSize: r.sp(11),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
