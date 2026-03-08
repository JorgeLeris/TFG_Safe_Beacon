import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/auth/cubits/register_cubit.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class RegisterAddDataScreen extends StatelessWidget {
  const RegisterAddDataScreen({super.key, this.isGoogleRegister = false});

  final bool isGoogleRegister;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final cubit = context.read<RegisterCubit>();

    return BlocListener<RegisterCubit, RegisterState>(
      listenWhen: (prev, curr) => prev.isLoading && !curr.isLoading,
      listener: (context, state) {
        if (state.errorMessage != null) {
          CustomDialog.show(
            context: context,
            title: l10n.registerErrorTitle,
            content: Text(state.errorMessage!),
            buttonText: l10n.accept,
          );
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: colorScheme.surfaceContainerHigh,
          body: Padding(
            padding: const EdgeInsets.only(right: 32, left: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 75),

                Center(
                  child: Text(
                    l10n.appName,
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      fontSize: textTheme.headlineLarge!.fontSize! * 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Divider(
                  color: colorScheme.onPrimary,
                  thickness: 1.25,
                  height: 0,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        BlocBuilder<RegisterCubit, RegisterState>(
                          buildWhen: (prev, curr) =>
                              prev.nameError != curr.nameError,
                          builder: (context, state) => InputField(
                            hint: l10n.name,
                            initialValue: state.name,
                            onChanged: cubit.onNameChanged,
                            errorText: state.nameError,
                          ),
                        ),

                        const SizedBox(height: 24),

                        BlocBuilder<RegisterCubit, RegisterState>(
                          buildWhen: (prev, curr) =>
                              prev.surnameError != curr.surnameError,
                          builder: (context, state) => InputField(
                            hint: l10n.surname,
                            initialValue: state.surname,
                            onChanged: cubit.onSurnameChanged,
                            errorText: state.surnameError,
                          ),
                        ),

                        const SizedBox(height: 24),

                        BlocBuilder<RegisterCubit, RegisterState>(
                          buildWhen: (prev, curr) =>
                              prev.birthDateError != curr.birthDateError,
                          builder: (context, state) => DateInputField(
                            hint: l10n.birthDate,
                            initialValue: state.birthDate,
                            onChanged: cubit.onBirthDateChanged,
                            errorText: state.birthDateError,
                          ),
                        ),

                        const SizedBox(height: 24),

                        BlocBuilder<RegisterCubit, RegisterState>(
                          buildWhen: (prev, curr) =>
                              prev.genderError != curr.genderError,
                          builder: (context, state) => DropdownInputField(
                            hint: l10n.gender,
                            value: state.gender,
                            onChanged: cubit.onGenderChanged,
                            errorText: state.genderError,
                            items: [
                              DropdownMenuItem(
                                value: Constants.maleFieldKey,
                                child: Text(l10n.male),
                              ),
                              DropdownMenuItem(
                                value: Constants.femaleFieldKey,
                                child: Text(l10n.female),
                              ),
                              DropdownMenuItem(
                                value: Constants.otherFieldKey,
                                child: Text(l10n.other),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        BlocBuilder<RegisterCubit, RegisterState>(
                          buildWhen: (prev, curr) => false,
                          builder: (context, state) => InputField(
                            hint: l10n.descriptionObservation,
                            initialValue: state.description,
                            maxLines: 5,
                            onChanged: cubit.onDescriptionChanged,
                          ),
                        ),

                        const SizedBox(height: 36),

                        BlocBuilder<RegisterCubit, RegisterState>(
                          buildWhen: (prev, curr) =>
                              prev.isLoading != curr.isLoading,
                          builder: (context, state) {
                            if (isGoogleRegister) {
                              return SizedBox(
                                width: double.infinity,
                                child: CustomFilledButton(
                                  text: l10n.finishRegistration,
                                  isLoading: state.isLoading,
                                  onPressed: () => cubit.onSubmit(l10n),
                                  backgroundColor: colorScheme.inversePrimary,
                                  foregroundColor: colorScheme.onPrimary,
                                  colorText: colorScheme.onPrimary,
                                  fontSizeText:
                                      textTheme.labelLarge!.fontSize! * 1.2,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 14,
                                  ),
                                ),
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: CustomFilledButton(
                                    text: l10n.back,
                                    onPressed: state.isLoading
                                        ? () {}
                                        : () {
                                            FocusScope.of(context).unfocus();
                                            context.pop();
                                          },
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    colorText: colorScheme.onPrimary,
                                    fontSizeText:
                                        textTheme.labelLarge!.fontSize! * 1.2,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 14,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 35),

                                Expanded(
                                  child: CustomFilledButton(
                                    text: l10n.createAccount,
                                    isLoading: state.isLoading,
                                    onPressed: () => cubit.onSubmit(l10n),
                                    backgroundColor: colorScheme.inversePrimary,
                                    foregroundColor: colorScheme.onPrimary,
                                    colorText: colorScheme.onPrimary,
                                    fontSizeText:
                                        textTheme.labelLarge!.fontSize! * 1.2,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 14,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
