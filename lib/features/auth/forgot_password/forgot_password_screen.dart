import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.warning(context, 'Please enter a valid email');
      return;
    }

    final auth = context.read<AuthService>();
    final success = await auth.sendPasswordResetEmail(_emailController.text);

    if (!mounted) return;

    if (!success) {
      AppToast.error(
        context,
        auth.error ?? 'Could not send reset email. Please try again.',
      );
      return;
    }

    setState(() => _sent = true);
    AppToast.success(context, 'Check your email for a reset link');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Forgot password', style: AppTextStyles.pageTitle()),
                const SizedBox(height: 8),
                Text(
                  _sent
                      ? 'If an account exists for this email, Firebase sent a link to set a new password.'
                      : 'Enter the email on your account. We will send a Firebase reset link.',
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !_sent,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: FormValidators.email,
                  onFieldSubmitted: (_) {
                    if (!auth.isLoading && !_sent) _send();
                  },
                ),
                const SizedBox(height: 32),
                if (_sent)
                  PrimaryButton(
                    label: 'Back to Sign In',
                    onPressed: () => context.go(AppRouter.login),
                  )
                else
                  PrimaryButton(
                    label: 'Send Reset Link',
                    isLoading: auth.isLoading,
                    onPressed: auth.isLoading ? null : _send,
                  ),
                if (_sent) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => setState(() => _sent = false),
                      child: Text(
                        'Send again',
                        style: AppTextStyles.body()
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
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
