import 'package:args/args.dart';
import 'package:dart_cloud_cli/common/api_key_validity.dart';

final apiKeyGenerateParser = ArgParser()
  ..addOption(
    'function-id',
    abbr: 'f',
    help: 'Function ID (uses current directory config if not provided)',
  )
  ..addOption(
    'validity',
    abbr: 'v',
    help: 'Key validity: ${ApiKeyValidity.validOptions.join(', ')}',
    defaultsTo: '1d',
  )
  ..addOption(
    'name',
    abbr: 'n',
    help: 'Optional friendly name for the key',
  );

final apiKeyInfoParser = ArgParser()
  ..addOption(
    'function-id',
    abbr: 'f',
    help: 'Function ID (uses current directory config if not provided)',
  );
final apiKeyRevokeParser = ArgParser()
  ..addOption(
    'key-id',
    abbr: 'k',
    help: 'API key UUID to revoke',
  );
final apiKeyListParser = ArgParser()
      ..addOption(
        'function-id',
        abbr: 'f',
        help: 'Function ID (uses current directory config if not provided)',
      );
