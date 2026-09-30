import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';

class OnboardingReviewScreen extends StatefulWidget {
  const OnboardingReviewScreen({super.key});

  @override
  State<OnboardingReviewScreen> createState() => _OnboardingReviewScreenState();
}

class _OnboardingReviewScreenState extends State<OnboardingReviewScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDocuments());
  }

  Future<void> _ensureDocuments() async {
    final driverId = context.read<AuthService>().currentUser?.id;
    if (driverId == null) return;

    final fleet = context.read<FleetDataService>();
    await fleet.loadDriverDocuments(driverId);
    if (!mounted) return;

    if (!fleet.hasRequiredDocuments(driverId)) {
      context.go(AppRouter.onboardingDocuments);
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    final driverId = auth.currentUser?.id;
    if (driverId == null) return;

    final fleet = context.read<FleetDataService>();
    if (!fleet.hasRequiredDocuments(driverId)) {
      AppToast.warning(context, 'Upload both your ID and PDP before submitting');
      context.go(AppRouter.onboardingDocuments);
      return;
    }

    setState(() => _isSubmitting = true);
    AppToast.success(context, 'Application submitted — awaiting admin approval');
    auth.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final fleet = context.watch<FleetDataService>();
    final docs = user != null ? fleet.documentsForDriver(user.id) : const <DriverDocument>[];

    bool hasType(DocumentType type) =>
        docs.any((d) => d.documentType == type);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting
              ? null
              : () => context.go(AppRouter.onboardingDocuments),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review application', style: AppTextStyles.pageTitle()),
              const SizedBox(height: 8),
              Text(
                'Step 3 of 3 — Confirm and submit',
                style: AppTextStyles.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _ReviewCard(
                      title: 'Personal information',
                      children: [
                        _ReviewRow(label: 'Name', value: user?.fullName ?? '—'),
                        _ReviewRow(label: 'Phone', value: user?.phone ?? '—'),
                        _ReviewRow(label: 'Email', value: user?.email ?? '—'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ReviewCard(
                      title: 'Documents',
                      children: [
                        _DocumentStatusRow(
                          label: 'ID Document',
                          uploaded: hasType(DocumentType.id),
                        ),
                        _DocumentStatusRow(
                          label: 'PDP',
                          uploaded: hasType(DocumentType.pdp),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lavender,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Submitting sends your application to the fleet administrator. You\'ll see a pending status until they review your documents.',
                        style: AppTextStyles.body().copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              PrimaryButton(
                label: 'Submit application',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.label()),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: AppTextStyles.body(color: AppColors.textSecondary)
                  .copyWith(fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentStatusRow extends StatelessWidget {
  const _DocumentStatusRow({required this.label, required this.uploaded});

  final String label;
  final bool uploaded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            uploaded ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 20,
            color: uploaded ? AppColors.accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            uploaded ? 'Uploaded' : 'Missing',
            style: AppTextStyles.body(
              color: uploaded ? AppColors.textPrimary : AppColors.error,
            ).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
