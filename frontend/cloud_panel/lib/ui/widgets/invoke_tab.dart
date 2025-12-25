import 'dart:convert';

import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_panel/providers/api_client_provider.dart';
import 'package:cloud_panel/ui/component/password_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';

class InvokeTab extends ConsumerStatefulWidget {
  final String uuid;
  const InvokeTab({required this.uuid, super.key});

  @override
  ConsumerState<InvokeTab> createState() => _InvokeTabState();
}

class _InvokeTabState extends ConsumerState<InvokeTab> {
  final _bodyController = TextEditingController(text: '{}');
  final _secretController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secretFocusNode = FocusNode();
  bool _isLoading = false;
  String? _response;
  bool _isError = false;
  bool _useSigning = true;
  List<String> _storedApiKeyUuids = [];
  String? _selectedApiKeyUuid;
  bool _showStoredKeys = false;
  String? _apiKeyUuidForInvoke;

  @override
  void initState() {
    super.initState();
    _loadStoredApiKeys();
    _secretFocusNode.addListener(() {
      if (_secretFocusNode.hasFocus && _storedApiKeyUuids.isNotEmpty) {
        setState(() => _showStoredKeys = true);
      }
    });
  }

  Future<void> _loadStoredApiKeys() async {
    try {
      final storage = ApiKeyStorage.instance;
      await storage.init();
      final uuids = await storage.getStoredApiKeyUuids();
      if (mounted) {
        setState(() {
          _storedApiKeyUuids = uuids;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _showPasswordDialog(String apiKeyUuid) async {
    final passwordController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PasswordDialog(
        controller: passwordController,
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _loadApiKeyFromStorage(apiKeyUuid, result);
    }
    passwordController.dispose();
  }

  Future<void> _loadApiKeyFromStorage(
    String apiKeyUuid,
    String password,
  ) async {
    try {
      final storage = ApiKeyStorage.instance;
      final secretKey = await storage.getApiKey(
        apiKeyUuid,
        password,
      );

      if (secretKey == null) {
        if (context.mounted) {
          setState(() {
            _response = 'Invalid password or API key not found';
            _isError = true;
          });
        }
        return;
      }

      // Encode to base64 for display
      final base64SecretKey = base64Encode(utf8.encode(secretKey));

      if (context.mounted) {
        setState(() {
          _secretController.text = base64SecretKey;
          _selectedApiKeyUuid = apiKeyUuid;
          _apiKeyUuidForInvoke = apiKeyUuid;
          _showStoredKeys = false;
          _response = null;
          _isError = false;
        });
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _response = 'Failed to load API key: $e';
          _isError = true;
        });
      }
    }
  }

  String? _decodeSecretKey(String input) {
    try {
      // Validate base64
      final decoded = base64Decode(input);
      return utf8.decode(decoded);
    } catch (e) {
      return null;
    }
  }

  Future<void> _invoke() async {
    setState(() {
      _isLoading = true;
      _response = null;
      _isError = false;
    });

    try {
      final client = ref.read(apiClientProvider);
      Map<String, dynamic>? body;

      if (_bodyController.text.isNotEmpty) {
        try {
          body = jsonDecode(_bodyController.text) as Map<String, dynamic>;
        } catch (e) {
          setState(() {
            _response = AppLocalizations.of(context)!.invalidJson(e.toString());
            _isError = true;
            _isLoading = false;
          });
          return;
        }
      }

      String? secretKey;
      String? apiKeyUuid;

      if (_useSigning && _secretController.text.isNotEmpty) {
        // Decode base64 secret key
        final decodedKey = _decodeSecretKey(_secretController.text);
        if (decodedKey == null) {
          setState(() {
            _response = 'Invalid secret key format. Must be base64 encoded.';
            _isError = true;
            _isLoading = false;
          });
          return;
        }

        secretKey = decodedKey;
        apiKeyUuid = _apiKeyUuidForInvoke;

        if (apiKeyUuid == null || apiKeyUuid.isEmpty) {
          setState(() {
            _response = 'API Key UUID is required for signing';
            _isError = true;
            _isLoading = false;
          });
          return;
        }
      }

      final result = await client.invokeFunction(
        widget.uuid,
        body: body,
        secretKey: secretKey,
        apiKeyUuid: apiKeyUuid,
      );

      setState(() {
        // Pretty print JSON with indentation
        _response = const JsonEncoder.withIndent('  ').convert(result);
      });
    } catch (e) {
      setState(() {
        _response = e.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height - 120,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  AppLocalizations.of(context)!.requestBodyJson,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                FTextField(
                  control: .managed(controller: _bodyController),
                  maxLines: 5,
                  hint: '{"key": "value"}',
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.signingLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    FSwitch(
                      value: _useSigning,
                      onChange: (value) {
                        setState(() => _useSigning = value);
                      },
                    ),
                  ],
                ),
                if (_useSigning) ...[
                  Text(
                    'API Key UUID',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_showStoredKeys && _storedApiKeyUuids.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Stored API Keys:',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._storedApiKeyUuids.map(
                            (uuid) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: FButton(
                                      onPress: () => _showPasswordDialog(uuid),
                                      style: FButtonStyle.outline(),
                                      child: Text(
                                        uuid,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  FButton.icon(
                                    onPress: () async {
                                      try {
                                        final storage = ApiKeyStorage.instance;
                                        await storage.deleteApiKey(uuid);
                                        if (context.mounted) {
                                          setState(() {
                                            _storedApiKeyUuids.remove(uuid);
                                            if (_selectedApiKeyUuid == uuid) {
                                              _selectedApiKeyUuid = null;
                                              _secretController.clear();
                                            }
                                          });
                                          showFToast(
                                            context: context,
                                            title: const Text(
                                              'API key deleted',
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          showFToast(
                                            context: context,
                                            title: Text('Failed to delete'),
                                          );
                                        }
                                      }
                                    },
                                    style: FButtonStyle.ghost(),
                                    child: const Icon(FIcons.trash2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          FButton(
                            onPress: () =>
                                setState(() => _showStoredKeys = false),
                            style: FButtonStyle.ghost(),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  if (!_showStoredKeys)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedApiKeyUuid ?? 'No API key selected',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (_storedApiKeyUuids.isNotEmpty)
                          FButton(
                            onPress: () =>
                                setState(() => _showStoredKeys = true),
                            style: FButtonStyle.ghost(),
                            child: const Text('Select'),
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context)!.secretKeyLabel} (base64)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  FTextField(
                    control: .managed(controller: _secretController),
                    focusNode: _secretFocusNode,
                    obscureText: true,
                    hint: 'Base64 encoded secret key',
                  ),
                ],
              ],
            ),
            FButton(
              onPress: _isLoading ? null : _invoke,
              child: _isLoading
                  ? Text(AppLocalizations.of(context)!.invoking)
                  : Text(AppLocalizations.of(context)!.invokeFunction),
            ),
            if (_response != null) ...[
              _ResponseWidget(
                response: jsonDecode(_response!)["result"] ?? _response!,
                isError: _isError,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _secretController.dispose();
    _passwordController.dispose();
    _secretFocusNode.dispose();
    super.dispose();
  }
}

class _ResponseWidget extends StatelessWidget {
  final String response;
  final bool isError;

  const _ResponseWidget({
    required this.response,
    required this.isError,
  });

  List<_JsonToken> _tokenizeJson(String json) {
    final tokens = <_JsonToken>[];
    int i = 0;

    while (i < json.length) {
      final char = json[i];

      if (char == ' ' || char == '\n' || char == '\t' || char == '\r') {
        tokens.add(_JsonToken(char, _TokenType.whitespace));
        i++;
      } else if (char == '{' || char == '}' || char == '[' || char == ']') {
        tokens.add(_JsonToken(char, _TokenType.bracket));
        i++;
      } else if (char == ':') {
        tokens.add(_JsonToken(char, _TokenType.colon));
        i++;
      } else if (char == ',') {
        tokens.add(_JsonToken(char, _TokenType.comma));
        i++;
      } else if (char == '"') {
        int end = i + 1;
        while (end < json.length && json[end] != '"') {
          if (json[end] == '\\') end++;
          end++;
        }
        if (end < json.length) end++;
        final value = json.substring(i, end);
        tokens.add(_JsonToken(value, _TokenType.string));
        i = end;
      } else if (char == '-' ||
          (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57)) {
        int end = i;
        while (end < json.length) {
          final c = json[end];
          if ((c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) ||
              c == '.' ||
              c == '-' ||
              c == '+' ||
              c == 'e' ||
              c == 'E') {
            end++;
          } else {
            break;
          }
        }
        final value = json.substring(i, end);
        tokens.add(_JsonToken(value, _TokenType.number));
        i = end;
      } else if (json.startsWith('true', i)) {
        tokens.add(_JsonToken('true', _TokenType.boolean));
        i += 4;
      } else if (json.startsWith('false', i)) {
        tokens.add(_JsonToken('false', _TokenType.boolean));
        i += 5;
      } else if (json.startsWith('null', i)) {
        tokens.add(_JsonToken('null', _TokenType.nullValue));
        i += 4;
      } else {
        i++;
      }
    }

    return tokens;
  }

  Color _getTokenColor(BuildContext context, _TokenType type) {
    switch (type) {
      case _TokenType.string:
        return Colors.green.shade700;
      case _TokenType.number:
        return Colors.blue.shade700;
      case _TokenType.boolean:
        return Colors.orange.shade700;
      case _TokenType.nullValue:
        return Colors.grey.shade600;
      case _TokenType.bracket:
      case _TokenType.colon:
      case _TokenType.comma:
        return context.theme.colors.foreground;
      case _TokenType.whitespace:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _tokenizeJson(response);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.responseLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            FButton(
              onPress: () {
                Clipboard.setData(ClipboardData(text: response));
                showFToast(
                  context: context,
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!.copiedToClipboardSimple,
                  ),
                );
              },
              style: FButtonStyle.ghost(),
              child: Text(AppLocalizations.of(context)!.copy),
            ),
          ],
        ),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isError
                ? Colors.red.withValues(alpha: 0.05)
                : Colors.green.withValues(alpha: 0.05),
            border: Border.all(
              color: isError
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Wrap(
              children: tokens
                  .map(
                    (token) => Text(
                      token.value,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.5,
                        color: token.type == _TokenType.whitespace
                            ? Colors.transparent
                            : _getTokenColor(context, token.type),
                        fontWeight:
                            token.type == _TokenType.bracket ||
                                token.type == _TokenType.colon ||
                                token.type == _TokenType.comma
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

enum _TokenType {
  string,
  number,
  boolean,
  nullValue,
  bracket,
  colon,
  comma,
  whitespace,
}

class _JsonToken {
  final String value;
  final _TokenType type;

  _JsonToken(this.value, this.type);
}

class _PasswordDialog extends StatelessWidget {
  final TextEditingController controller;

  const _PasswordDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FDialog(
      direction: Axis.horizontal,
      title: const Text('Enter Password'),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          const Text(
            'Enter the password to decrypt your stored API key:',
            style: TextStyle(fontSize: 13),
          ),
          PasswordComponent(
            controller: controller,
            hint: 'Password',
          ),
        ],
      ),
      actions: [
        FButton(
          onPress: () => Navigator.pop(context),
          style: FButtonStyle.secondary(),
          child: const Text('Cancel'),
        ),
        FButton(
          onPress: () => Navigator.pop(
            context,
            controller.text.trim(),
          ),
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
