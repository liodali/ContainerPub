import 'dart:convert';

import 'package:cloud_panel/providers/api_client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

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
            _response = 'Invalid JSON: $e';
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
              const Text(
                'Request Body (JSON)',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                  const Text(
                    'Signing (--sign)',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                const Text(
                  'Secret Key (for signed requests)',
                  style: TextStyle(fontSize: 12),
                ),
                FTextField(
                  controller: _secretController,
                  obscureText: true,
                  hint: 'Enter your API secret key',
                ),
              ],
            ],
          ),
          FButton(
            onPress: _isLoading ? null : _invoke,
            child: _isLoading
                ? const Text('Invoking...')
                : const Text('Invoke Function'),
          ),
          if (_response != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Response:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    FButton(
                      onPress: () {
                        Clipboard.setData(ClipboardData(text: _response!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                      style: FButtonStyle.ghost(),
                      child: const Text('Copy'),
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
