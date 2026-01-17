import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/screens/auth/auth_viewmodel.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  late AuthViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = AuthViewModel();
    viewModel.init();
    viewModel.initializeAgeGate();
  }

  @override
  void dispose() {
    viewModel.disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<AuthViewModel>.value(
        value: viewModel,
        child: const AuthViewBody(),
      );
}

class AuthViewBody extends StatelessWidget {
  const AuthViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final appProvider = context.watch<AppProvider>();

    final isDark = appProvider.isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF212121) : Colors.white;
    final fieldColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF2F2F2);
    final buttonColor = isDark ? Colors.blueAccent : Colors.black;
    final buttonTextColor = Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Card(
            color: backgroundColor,
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => viewModel.toggleMode(true),
                          style: TextButton.styleFrom(
                            backgroundColor: fieldColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'signIn'.tr(),
                            style: TextStyle(
                              color: viewModel.isLoginMode
                                  ? textColor
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () => viewModel.toggleMode(false),
                          style: TextButton.styleFrom(
                            backgroundColor: fieldColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'signUp'.tr(),
                            style: TextStyle(
                              color: !viewModel.isLoginMode
                                  ? textColor
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!viewModel.isLoginMode)
                    TextField(
                      controller: viewModel.nameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'name'.tr(),
                        filled: true,
                        fillColor: fieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  if (!viewModel.isLoginMode) const SizedBox(height: 16),
                  if (viewModel.isAgeRequired) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ageGateTitle'.tr(),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: viewModel.selectedBirthYear,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'ageGateYearLabel'.tr(),
                        filled: true,
                        fillColor: fieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: viewModel.birthYears
                          .map(
                            (year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: viewModel.setBirthYear,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: viewModel.emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'email'.tr(),
                      filled: true,
                      fillColor: fieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: viewModel.passwordController,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'password'.tr(),
                      filled: true,
                      fillColor: fieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          viewModel.isButtonLoading || !viewModel.isFormValid
                              ? null
                              : () async {
                                  if (viewModel.isLoginMode) {
                                    await viewModel.login(context);
                                  } else {
                                    await viewModel.register(context);
                                  }
                                },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: buttonTextColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isButtonLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              viewModel.isLoginMode
                                  ? 'signIn'.tr()
                                  : 'signUp'.tr(),
                            ),
                    ),
                  ),
                  if (viewModel.isLoginMode) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: viewModel.isButtonLoading
                          ? null
                          : () => viewModel.resetPassword(context),
                      child: Text(
                        'forgotPassword'.tr(),
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
