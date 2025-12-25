import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_panel/common/commons.dart';
import 'package:cloud_panel/providers/api_client_provider.dart';
import 'package:cloud_panel/providers/common_provider.dart';
import 'package:cloud_panel/providers/function_details_provider.dart';
import 'package:cloud_panel/ui/widgets/api_key_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';

class ApiKeysTab extends ConsumerWidget {
  final String uuid;
  const ApiKeysTab({required this.uuid, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(functionApiKeysProvider(uuid));

    return SizedBox(
      height: MediaQuery.sizeOf(context).height - 120,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FButton(
              onPress: () => _generateKey(context, ref),
              child: Text(AppLocalizations.of(context)!.generateNewApiKey),
            ),
          ),
          keysAsync.when(
            data: (keys) {
              if (keys.isEmpty) {
                return Center(
                  child: Text(AppLocalizations.of(context)!.noApiKeys),
                );
              }

              final sortedKeys = List<ApiKey>.from(keys);
              sortedKeys.sort((a, b) {
                int getPriority(ApiKey key) {
                  final isExpired =
                      key.expiresAt != null &&
                      key.expiresAt!.isBefore(DateTime.now());
                  if (isExpired) return 2;
                  if (key.isActive) return 0;
                  return 1;
                }

                final priorityA = getPriority(a);
                final priorityB = getPriority(b);

                if (priorityA != priorityB) {
                  return priorityA.compareTo(priorityB);
                }

                final dateA = a.createdAt;
                final dateB = b.createdAt;
                return dateB.compareTo(dateA);
              });

              return Expanded(
                child: ListView.separated(
                  itemCount: sortedKeys.length + 1,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (_, index) {
                    if (index == sortedKeys.length)
                      return const SizedBox.shrink();
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    if (index == sortedKeys.length) {
                      return _StoredApiKeysSection(uuid: uuid);
                    }

                    final key = sortedKeys[index];

                    return ApiKeyItemWidget(
                      key: UniqueKey(),
                      apiKeyModel: key,
                      uuid: uuid,
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: FCircularProgress()),
            error: (e, s) => Center(
              child: FAlert(
                title: Text(AppLocalizations.of(context)!.oppsErrorLoadApiKey),
                subtitle: Text(
                  AppLocalizations.of(context)!.somethingWentWrong,
                ),
                style: FAlertStyle.destructive(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateKey(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;

    final nameController = TextEditingController();
    final result = await showFDialog<_KeyGenerationResult?>(
      context: context,
      builder: (ctx, style, _) => _KeyNameDialog(
        controller: nameController,
        style: style,
      ),
    );

    nameController.dispose();

    if (result == null || result.name.isEmpty) return;

    if (!context.mounted) return;

    final client = ref.read(apiClientProvider);
    try {
      final apiKey = await client.generateApiKey(
        uuid,
        name: result.name,
        validity: result.validity.value,
      );
      if (context.mounted) {
        showFDialog(
          context: context,
          builder: (ctx, style, _) => FDialog(
            style: (_) => style,
            title: Text(AppLocalizations.of(context)!.apiKeyGenerated),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                Text(
                  AppLocalizations.of(context)!.copySecretKeyWarning,
                ),
                SelectableText(
                  apiKey.secretKey,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                FButton(
                  onPress: () {
                    Clipboard.setData(ClipboardData(text: apiKey.secretKey));
                    showFToast(
                      context: context,
                      title: Text(AppLocalizations.of(context)!.copied),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.copyToClipboard),
                ),
              ],
            ),
            actions: [
              FButton(
                onPress: () => Navigator.pop(ctx),
                style: FButtonStyle.ghost(),
                child: Text(AppLocalizations.of(context)!.skip),
              ),
              FButton(
                onPress: () {
                  Navigator.pop(ctx);
                  _saveKeyToLocalStorage(
                    context,
                    ref,
                    apiKey.uuid,
                    apiKey.secretKey,
                  );
                },
                style: FButtonStyle.secondary(),
                child: Text(AppLocalizations.of(context)!.saveLocally),
              ),
            ],
          ),
        );
      }
      ref.invalidate(functionApiKeysProvider(uuid));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorWithPlaceholder(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveKeyToLocalStorage(
    BuildContext context,
    WidgetRef ref,
    String keyUuid,
    String secretKey,
  ) async {
    if (!context.mounted) return;

    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final password = await showFDialog<String?>(
      context: context,
      builder: (ctx, style, _) => _PasswordDialog(
        passwordController: passwordController,
        confirmPasswordController: confirmPasswordController,
        style: style,
      ),
    );

    passwordController.dispose();
    confirmPasswordController.dispose();

    if (password == null || password.isEmpty) return;

    if (!context.mounted) return;

    try {
      final apiKeyStorage = ref.read(apiKeyStorageProvider);
      await apiKeyStorage.storeApiKey(keyUuid, secretKey, password);

      if (context.mounted) {
        showFToast(
          context: context,
          alignment: FToastAlignment.bottomCenter,
          title: Text(AppLocalizations.of(context)!.apiKeySavedLocally),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorWithPlaceholder(e.toString()),
            ),
          ),
        );
      }
    }
  }
}

class _KeyGenerationResult {
  final String name;
  final ApiKeyValidity validity;

  _KeyGenerationResult({
    required this.name,
    required this.validity,
  });
}

class _KeyNameDialog extends StatefulWidget {
  final TextEditingController controller;
  final FDialogStyle style;

  const _KeyNameDialog({
    required this.controller,
    required this.style,
  });

  @override
  State<_KeyNameDialog> createState() => _KeyNameDialogState();
}

class _KeyNameDialogState extends State<_KeyNameDialog> {
  ApiKeyValidity _selectedValidity = ApiKeyValidity.forever;

  bool get _isValid => widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return FDialog(
      style: (_) => widget.style,
      title: Text(AppLocalizations.of(context)!.generateApiKey),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  AppLocalizations.of(context)!.keyName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) => FTextField(
                    control: .managed(controller: widget.controller),
                    hint: AppLocalizations.of(context)!.keyNameHint,
                    autofocus: true,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  AppLocalizations.of(context)!.validity,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ApiKeyValidity.values.map((validity) {
                    final isSelected = _selectedValidity == validity;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedValidity = validity);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.theme.colors.primary
                              : context.theme.colors.background,
                          border: Border.all(
                            color: isSelected
                                ? context.theme.colors.primary
                                : context.theme.colors.border,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          validity.localized(context),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? context.theme.colors.primaryForeground
                                : context.theme.colors.foreground,
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        FButton(
          onPress: () => Navigator.pop(context),
          style: FButtonStyle.secondary(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => FButton(
            onPress: _isValid
                ? () => Navigator.pop(
                    context,
                    _KeyGenerationResult(
                      name: widget.controller.text.trim(),
                      validity: _selectedValidity,
                    ),
                  )
                : null,
            child: Text(AppLocalizations.of(context)!.generate),
          ),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final FDialogStyle style;

  const _PasswordDialog({
    required this.passwordController,
    required this.confirmPasswordController,
    required this.style,
  });

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  bool get _isValid =>
      widget.passwordController.text.isNotEmpty &&
      widget.confirmPasswordController.text.isNotEmpty &&
      widget.passwordController.text == widget.confirmPasswordController.text;

  @override
  Widget build(BuildContext context) {
    return FDialog(
      style: (_) => widget.style,
      title: const Text('Set Password for API Key'),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a password to encrypt and store this API key locally. You will need to enter this password to use the key for signing.',
              style: TextStyle(fontSize: 13),
            ),
            ListenableBuilder(
              listenable: widget.passwordController,
              builder: (context, _) => FTextField(
                control: .managed(controller: widget.passwordController),
                hint: 'Password',
                obscureText: !_showPassword,
                autofocus: true,
                suffixBuilder: (context, _, _) => FTappable(
                  onPress: () => setState(() => _showPassword = !_showPassword),
                  child: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: context.theme.colors.foreground,
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.confirmPasswordController,
              builder: (context, _) => FTextField(
                control: .managed(controller: widget.confirmPasswordController),
                hint: 'Confirm Password',
                obscureText: !_showConfirmPassword,
                suffixBuilder: (context, _, _) => FTappable(
                  onPress: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                  child: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: context.theme.colors.foreground,
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: Listenable.merge([
                widget.passwordController,
                widget.confirmPasswordController,
              ]),
              builder: (context, _) {
                final passwordsMatch =
                    widget.passwordController.text ==
                    widget.confirmPasswordController.text;
                final isEmpty = widget.passwordController.text.isEmpty;

                return Text(
                  isEmpty
                      ? 'Enter a password'
                      : passwordsMatch
                      ? 'Passwords match ✓'
                      : 'Passwords do not match',
                  style: TextStyle(
                    fontSize: 12,
                    color: isEmpty
                        ? Colors.grey
                        : passwordsMatch
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        FButton(
          onPress: () => Navigator.pop(context),
          style: FButtonStyle.secondary(),
          child: const Text('Cancel'),
        ),
        ListenableBuilder(
          listenable: Listenable.merge([
            widget.passwordController,
            widget.confirmPasswordController,
          ]),
          builder: (context, _) => FButton(
            onPress: _isValid
                ? () => Navigator.pop(context, widget.passwordController.text)
                : null,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}

class _SecretKeyDialog extends StatefulWidget {
  final TextEditingController controller;
  final FDialogStyle style;

  const _SecretKeyDialog({
    required this.controller,
    required this.style,
  });

  @override
  State<_SecretKeyDialog> createState() => _SecretKeyDialogState();
}

class _SecretKeyDialogState extends State<_SecretKeyDialog> {
  bool _showSecret = false;

  bool get _isValid => widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return FDialog(
      style: (_) => widget.style,
      title: const Text('Enter API Key Secret'),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste the secret key that was shown when you generated the API key:',
              style: TextStyle(fontSize: 13),
            ),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => FTextField(
                control: .managed(controller: widget.controller),
                hint: 'Paste secret key here',
                obscureText: !_showSecret,
                autofocus: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        FButton(
          onPress: () => Navigator.pop(context),
          style: FButtonStyle.secondary(),
          child: const Text('Cancel'),
        ),
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => FButton(
            onPress: _isValid
                ? () => Navigator.pop(context, widget.controller.text.trim())
                : null,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}

class _StoredApiKeysSection extends ConsumerStatefulWidget {
  final String uuid;

  const _StoredApiKeysSection({required this.uuid});

  @override
  ConsumerState<_StoredApiKeysSection> createState() =>
      _StoredApiKeysSectionState();
}

class _StoredApiKeysSectionState extends ConsumerState<_StoredApiKeysSection> {
  List<String> _storedApiKeyUuids = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoredApiKeys();
  }

  Future<void> _loadStoredApiKeys() async {
    try {
      final storage = ApiKeyStorage.instance;
      await storage.init();
      final uuids = await storage.getStoredApiKeyUuids();
      if (mounted) {
        setState(() {
          _storedApiKeyUuids = uuids;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteStoredKey(String apiKeyUuid) async {
    try {
      final storage = ApiKeyStorage.instance;
      await storage.deleteApiKey(apiKeyUuid);
      if (mounted) {
        setState(() {
          _storedApiKeyUuids.remove(apiKeyUuid);
        });
        showFToast(
          context: context,
          title: const Text('Stored API key deleted'),
        );
      }
    } catch (e) {
      showFToast(
        context: context,
        title: Text('Failed to delete: $e'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: FCircularProgress(),
      );
    }

    if (_storedApiKeyUuids.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                children: [
                  Icon(
                    FIcons.info,
                    color: Colors.orange.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Locally Stored API Keys',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'These API keys are stored locally on your device. They cannot be used in the dashboard anymore and should be deleted after you\'re done using them.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        ..._storedApiKeyUuids.map(
          (uuid) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        'Stored Key',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SelectableText(
                        uuid,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FButton.icon(
                  onPress: () => _deleteStoredKey(uuid),
                  style: FButtonStyle.ghost(),
                  child: const Icon(FIcons.trash2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
