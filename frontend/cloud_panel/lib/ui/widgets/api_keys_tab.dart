import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_panel/common/commons.dart';
import 'package:cloud_panel/providers/api_client_provider.dart';
import 'package:cloud_panel/providers/common_provider.dart';
import 'package:cloud_panel/providers/function_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

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
              child: const Text('Generate New API Key'),
            ),
          ),
          keysAsync.when(
            data: (keys) {
              if (keys.isEmpty) {
                return const Center(
                  child: Text('No API keys'),
                );
              }

              return Expanded(
                child: ListView.separated(
                  itemCount: keys.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    final isExpired =
                        key.expiresAt != null &&
                        key.expiresAt!.isBefore(DateTime.now());
                    final expirationText = key.expiresAt != null
                        ? dateFormatter.format(key.expiresAt!)
                        : 'Never';
                    final creationText = dateFormatter.format(key.createdAt);

                    Color getStatusColor() {
                      if (isExpired) return Colors.red;
                      if (key.isActive) return Colors.green;
                      return Colors.orange;
                    }

                    String getStatusText() {
                      if (isExpired) return 'Expired';
                      if (key.isActive) return 'Active';
                      return 'Inactive';
                    }

                    final statusColor = getStatusColor();
                    final statusText = getStatusText();

                    return FCard(
                      title: Text(key.name ?? 'Unnamed Key'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Prefix: ${key.uuid.substring(0, 8)}...',
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  border: Border.all(color: statusColor),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Created: $creationText',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Expires: $expirationText',
                            style: TextStyle(
                              fontSize: 12,
                              color: isExpired ? Colors.red : null,
                              fontWeight: isExpired ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        spacing: 8,
                        children: [
                          FButton(
                            onPress: () => _deleteKey(
                              context,
                              ref,
                              key.uuid,
                              key.name ?? 'Unnamed Key',
                            ),
                            style: FButtonStyle.destructive(),
                            child: const Text('Delete'),
                          ),
                          FButton(
                            onPress: () => _revokeKey(context, ref, key.uuid),
                            child: const Text('Revoke'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: FCircularProgress()),
            error: (e, s) => Center(
              child: FAlert(
                title: const Text('Oppssy!! Cannot load apikey function'),
                subtitle: Text('Something went wrong'),
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
            title: const Text('API Key Generated'),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                const Text(
                  'Please copy your secret key. It will not be shown again.',
                ),
                SelectableText(
                  apiKey.secretKey,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                FButton(
                  onPress: () {
                    Clipboard.setData(ClipboardData(text: apiKey.secretKey));
                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(const SnackBar(content: Text('Copied!')));
                  },
                  child: const Text('Copy to Clipboard'),
                ),
              ],
            ),
            actions: [
              FButton(
                onPress: () => Navigator.pop(ctx),
                style: FButtonStyle.ghost(),
                child: const Text('Skip'),
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
                child: const Text('Save Locally'),
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
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  Future<void> _revokeKey(
    BuildContext context,
    WidgetRef ref,
    String keyUuid,
  ) async {
    try {
      await ref.read(apiClientProvider).revokeApiKey(keyUuid);
      ref.invalidate(functionApiKeysProvider(uuid));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
          title: const Text('API key saved to local storage'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteKey(
    BuildContext context,
    WidgetRef ref,
    String keyUuid,
    String keyName,
  ) async {
    if (!context.mounted) return;

    final nameController = TextEditingController();
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, _) => _DeleteKeyDialog(
        keyName: keyName,
        controller: nameController,
        style: style,
      ),
    );

    nameController.dispose();

    if (confirmed != true) return;

    if (!context.mounted) return;

    try {
      await ref.read(apiClientProvider).revokeApiKey(keyUuid);
      ref.invalidate(functionApiKeysProvider(uuid));
      if (context.mounted) {
        showFToast(
          context: context,
          alignment: FToastAlignment.bottomCenter,
          title: const Text('API key deleted successfully'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
      title: const Text('Generate API Key'),
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
                const Text(
                  'Key Name',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) => FTextField(
                    controller: widget.controller,
                    hint: 'e.g., Production Key',
                    autofocus: true,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                const Text(
                  'Validity',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                          validity.label,
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
          child: const Text('Cancel'),
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
            child: const Text('Generate'),
          ),
        ),
      ],
    );
  }
}

class _DeleteKeyDialog extends StatefulWidget {
  final String keyName;
  final TextEditingController controller;
  final FDialogStyle style;

  const _DeleteKeyDialog({
    required this.keyName,
    required this.controller,
    required this.style,
  });

  @override
  State<_DeleteKeyDialog> createState() => _DeleteKeyDialogState();
}

class _DeleteKeyDialogState extends State<_DeleteKeyDialog> {
  bool get _isValid => widget.controller.text.trim() == widget.keyName;

  @override
  Widget build(BuildContext context) {
    return FDialog(
      style: (_) => widget.style,
      title: const Text('Delete API Key'),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action cannot be undone. To confirm deletion, please enter the API key name:',
              style: TextStyle(fontSize: 13),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Key Name: ${widget.keyName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => FTextField(
                controller: widget.controller,
                hint: 'Enter key name to confirm',
                autofocus: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        FButton(
          onPress: () => Navigator.pop(context, false),
          style: FButtonStyle.secondary(),
          child: const Text('Cancel'),
        ),
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => FButton(
            onPress: _isValid ? () => Navigator.pop(context, true) : null,
            style: FButtonStyle.destructive(),
            child: const Text('Delete'),
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
                controller: widget.passwordController,
                hint: 'Password',
                obscureText: !_showPassword,
                autofocus: true,
              ),
            ),
            ListenableBuilder(
              listenable: widget.confirmPasswordController,
              builder: (context, _) => FTextField(
                controller: widget.confirmPasswordController,
                hint: 'Confirm Password',
                obscureText: !_showConfirmPassword,
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
                controller: widget.controller,
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
