import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/load_error_view.dart';
import '../../../core/widgets/pill_segment.dart';
import '../../../models/models.dart';
import '../../../services/fleet_data_service.dart';
import '../widgets/admin_page_header.dart';

enum FleetTab { vehicles, checkIns, expenses }

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  FleetTab _tab = FleetTab.vehicles;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTabData());
  }

  void _loadTabData() {
    final fleet = context.read<FleetDataService>();
    switch (_tab) {
      case FleetTab.vehicles:
        fleet.loadAllVehicles();
      case FleetTab.checkIns:
        fleet.loadFleetCheckIns();
      case FleetTab.expenses:
        fleet.loadFleetExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: AdminPageHeader(
              title: 'Fleet',
              subtitle: 'Vehicles & activity',
              trailing: _tab == FleetTab.vehicles
                  ? IconButton(
                      onPressed: () => context.push(AppRouter.adminAddVehicle),
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add vehicle',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PillSegment<FleetTab>(
              options: FleetTab.values,
              selected: _tab,
              onChanged: (v) {
                setState(() => _tab = v);
                _loadTabData();
              },
              labelBuilder: (t) => switch (t) {
                FleetTab.vehicles => 'Vehicles',
                FleetTab.checkIns => 'Check-ins',
                FleetTab.expenses => 'Expenses',
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadTabData(),
              child: _tab == FleetTab.vehicles
                  ? _VehiclesList(
                      vehicles: fleet.vehicles,
                      loading: fleet.adminLoading,
                      error: fleet.error,
                      onRetry: _loadTabData,
                    )
                  : _tab == FleetTab.checkIns
                      ? _CheckInsList(
                          checkIns: fleet.fleetCheckIns,
                          loading: fleet.adminLoading,
                          error: fleet.error,
                          onRetry: _loadTabData,
                        )
                      : _ExpensesList(
                          expenses: fleet.fleetExpenses,
                          loading: fleet.adminLoading,
                          error: fleet.error,
                          onRetry: _loadTabData,
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehiclesList extends StatelessWidget {
  const _VehiclesList({
    required this.vehicles,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final List<Vehicle> vehicles;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && vehicles.isEmpty) {
      return ListView(children: [
        SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      ]);
    }
    if (error != null && vehicles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          LoadErrorView(
            title: 'Vehicles unavailable',
            message: error!,
            onRetry: onRetry,
          ),
        ],
      );
    }
    if (vehicles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text('No vehicles yet', style: AppTextStyles.body(color: AppColors.textSecondary)),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return GestureDetector(
          onTap: () => context.push('${AppRouter.adminVehicles}/${vehicle.id}/edit'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_taxi_outlined),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.registrationNumber, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        '${vehicle.make} ${vehicle.model}${vehicle.year != null ? ' (${vehicle.year})' : ''}',
                        style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(fontSize: 13),
                      ),
                      if (vehicle.color != null)
                        Text(vehicle.color!, style: AppTextStyles.label()),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CheckInsList extends StatelessWidget {
  const _CheckInsList({
    required this.checkIns,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final List<AdminDriverDay> checkIns;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && checkIns.isEmpty) {
      return ListView(children: [
        SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      ]);
    }
    if (error != null && checkIns.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          LoadErrorView(
            title: 'Check-ins unavailable',
            message: error!,
            onRetry: onRetry,
          ),
        ],
      );
    }
    if (checkIns.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [Text('No check-ins yet', style: AppTextStyles.body(color: AppColors.textSecondary))],
      );
    }

    final dateFmt = DateFormat('d MMM yyyy');

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: checkIns.length,
      itemBuilder: (context, index) {
        final entry = checkIns[index];
        final day = entry.day;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.driverName, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
                  Text(dateFmt.format(day.date), style: AppTextStyles.label()),
                ],
              ),
              const SizedBox(height: 8),
              Text(entry.vehicleLabel, style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MiniStat(label: 'Earnings', value: CurrencyFormatter.format(day.totalEarnings)),
                  const SizedBox(width: 16),
                  _MiniStat(label: 'Net', value: CurrencyFormatter.format(day.net)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpensesList extends StatelessWidget {
  const _ExpensesList({
    required this.expenses,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final List<AdminExpense> expenses;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && expenses.isEmpty) {
      return ListView(children: [
        SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      ]);
    }
    if (error != null && expenses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          LoadErrorView(
            title: 'Expenses unavailable',
            message: error!,
            onRetry: onRetry,
          ),
        ],
      );
    }
    if (expenses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [Text('No expenses yet', style: AppTextStyles.body(color: AppColors.textSecondary))],
      );
    }

    final dateFmt = DateFormat('d MMM');

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final entry = expenses[index];
        final expense = entry.expense;
        final color = switch (expense.type) {
          ExpenseType.fuel => AppColors.lavender,
          ExpenseType.maintenance => AppColors.peach,
          ExpenseType.repair => AppColors.peach,
          ExpenseType.other => AppColors.skyBlue,
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.driverName, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      '${expense.type.name} · ${dateFmt.format(entry.dayDate)}',
                      style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(fontSize: 13),
                    ),
                    if (expense.description != null)
                      Text(expense.description!, style: AppTextStyles.label()),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(expense.amount),
                style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label()),
        Text(value, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
