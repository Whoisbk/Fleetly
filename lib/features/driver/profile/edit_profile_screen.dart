import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser!;
    _firstNameController = TextEditingController(text: user.firstName);
    _lastNameController = TextEditingController(text: user.lastName);
    _phoneController = TextEditingController(text: user.phone);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.warning(context, 'Please fix the errors below');
      return;
    }

    final auth = context.read<AuthService>();
    final success = await auth.updateProfile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
    );

    if (!mounted) return;

    if (!success) {
      AppToast.error(context, auth.error ?? 'Could not update profile');
      return;
    }

    context.pop();
    AppToast.success(context, 'Profile updated');
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
        title: Text('Edit Profile', style: AppTextStyles.sectionTitle()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.lavender,
                        child: Text(
                          _firstNameController.text.isNotEmpty ? _firstNameController.text[0] : '?',
                          style: AppTextStyles.metric().copyWith(fontSize: 36),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Change photo', style: AppTextStyles.body(color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => FormValidators.required(v, field: 'First name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (v) => FormValidators.required(v, field: 'Last name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  validator: FormValidators.phone,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Save Changes',
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
