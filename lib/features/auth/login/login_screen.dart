import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/hero_stat_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'driver@taxifleet.com');
  final _passwordController = TextEditingController(text: 'password');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.warning(context, 'Please fix the errors below');
      return;
    }

    final auth = context.read<AuthService>();
    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      AppToast.error(context, auth.error ?? 'Sign in failed. Please try again.');
      return;
    }

    AppToast.success(context, 'Welcome back!');

    final user = auth.currentUser!;
    if (user.isAdmin) {
      context.go(AppRouter.adminHome);
    } else if (user.status == UserStatus.approved) {
      context.go(AppRouter.driverHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text('Welcome back', style: AppTextStyles.pageTitle()),
                const SizedBox(height: 8),
                Text(
                  'Sign in to manage your fleet',
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                HeroStatCard(
                  label: AppConstants.appName,
                  value: 'Digital Logbook',
                  subtitle: 'Replace the physical book',
                  accentColor: AppColors.mint,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: FormValidators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: FormValidators.password,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(
                      AppRouter.forgotPassword,
                      extra: _emailController.text.trim(),
                    ),
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.body()
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Sign In',
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : _login,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRouter.signup),
                    child: Text(
                      'New driver? Create account',
                      style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (!AppConstants.isSupabaseConfigured) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.skyBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Demo mode: use driver@taxifleet.com, admin@taxifleet.com, or pending@driver.com',
                      style: AppTextStyles.body().copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
