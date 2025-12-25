import 'dart:convert';

import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_panel/providers/api_client_provider.dart';
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

  Future<void> _loadApiKeyFromStorage(String apiKeyUuid) async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _response = 'Password required to load API key';
        _isError = true;
      });
      return;
    }

    try {
      final storage = ApiKeyStorage.instance;
      final secretKey = await storage.getApiKey(
        apiKeyUuid,
        _passwordController.text,
      );

      if (secretKey == null) {
        setState(() {
          _response = 'Invalid password or API key not found';
          _isError = true;
        });
        return;
      }

      // Encode to base64 for display
      final base64SecretKey = base64Encode(utf8.encode(secretKey));

      setState(() {
        _secretController.text = base64SecretKey;
        _selectedApiKeyUuid = apiKeyUuid;
        _apiKeyUuidForInvoke = apiKeyUuid;
        _showStoredKeys = false;
        _response = null;
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Failed to load API key: $e';
        _isError = true;
      });
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
        _response = jsonEncode(result);
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
                  if (_storedApiKeyUuids.isNotEmpty) ...[
                    Text(
                      'Password (to load stored API key)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    FTextField(
                      control: .managed(controller: _passwordController),
                      obscureText: true,
                      hint: 'Enter password',
                    ),
                    const SizedBox(height: 8),
                  ],
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
                              child: FButton(
                                onPress: () => _loadApiKeyFromStorage(uuid),
                                style: FButtonStyle.outline(),
                                child: Text(
                                  uuid,
                                  style: const TextStyle(fontSize: 11),
                                ),
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
              Column(
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
                          Clipboard.setData(ClipboardData(text: _response!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.copiedToClipboardSimple,
                              ),
                            ),
                          );
                        },
                        style: FButtonStyle.ghost(),
                        child: Text(AppLocalizations.of(context)!.copy),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isError
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _isError ? Colors.red : Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(_response!),
                  ),
                ],
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
