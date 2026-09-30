import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/hero_stat_card.dart';
import '../../../core/widgets/load_error_view.dart';
import '../../../core/widgets/pastel_data_card.dart';
import '../../../models/models.dart';
import '../../../services/fleet_data_service.dart';
import '../widgets/admin_page_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetDataService>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();
    final week = fleet.weekReport;
    final month = fleet.monthReport;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => fleet.loadReports(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          children: [
            const AdminPageHeader(
              title: 'Reports',
              subtitle: 'Fleet performance',
            ),
            const SizedBox(height: 24),
            if (fleet.adminLoading && week == null && month == null)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (fleet.error != null && week == null && month == null)
              LoadErrorView(
                title: 'Reports unavailable',
                message: fleet.error!,
                onRetry: () => fleet.loadReports(),
              )
            else ...[
              if (fleet.error != null) ...[
                LoadErrorView(
                  title: 'Couldn\'t refresh',
                  message: fleet.error!,
                  onRetry: () => fleet.loadReports(),
                  compact: true,
                ),
                const SizedBox(height: 16),
              ],
              if (week != null) _ReportSection(report: week),
              if (month != null) ...[
                const SizedBox(height: 24),
                _ReportSection(report: month),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.report});

  final PeriodReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(report.label.toUpperCase(), style: AppTextStyles.label()),
        const SizedBox(height: 12),
        HeroStatCard(
          label: 'Net Earnings',
          value: CurrencyFormatter.format(report.net),
          subtitle: '${report.dayCount} driver days · ${report.expenseCount} expenses',
          accentColor: AppColors.lavender,
          icon: Icons.trending_up,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PastelDataCard(
                title: 'Earnings',
                amount: report.totalEarnings,
                color: AppColors.lavender,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PastelDataCard(
                title: 'Expenses',
                amount: report.totalExpenses,
                color: AppColors.peach,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
