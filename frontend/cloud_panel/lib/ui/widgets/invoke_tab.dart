import 'dart:convert';

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
  bool _isLoading = false;
  String? _response;
  bool _isError = false;
  bool _useSigning = true;

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

      final secretKey = _useSigning
          ? (_secretController.text.isNotEmpty ? _secretController.text : null)
          : null;

      final result = await client.invokeFunction(
        widget.uuid,
        body: body,
        secretKey: secretKey,
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
    return SingleChildScrollView(
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
                controller: _bodyController,
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
                  AppLocalizations.of(context)!.secretKeyLabel,
                  style: const TextStyle(fontSize: 12),
                ),
                FTextField(
                  controller: _secretController,
                  obscureText: true,
                  hint: AppLocalizations.of(context)!.enterSecretKeyHint,
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
    );
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _secretController.dispose();
    super.dispose();
  }
}
