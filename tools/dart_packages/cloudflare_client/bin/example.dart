import 'dart:io';
import 'package:cloudflare_client/cloudflare_client.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  // Load environment variables
  final env = DotEnv();
  final envFile = File('.env');

  if (await envFile.exists()) {
    env.load();
  }

  final apiToken =
      env['CLOUDFLARE_API_TOKEN'] ??
      Platform.environment['CLOUDFLARE_API_TOKEN'];
  final zoneId =
      env['CLOUDFLARE_ZONE_ID'] ?? Platform.environment['CLOUDFLARE_ZONE_ID'];

  if (apiToken == null || zoneId == null) {
    print('Error: CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID must be set');
    exit(1);
  }

  final client = CloudflareClient(apiToken: apiToken, zoneId: zoneId);

  try {
    print('🌐 Cloudflare DNS Management Example\n');

    // Get zone details
    print('📋 Fetching zone details...');
    final zone = await client.getZoneDetails();
    print('Zone: ${zone['name']}');
    print('Status: ${zone['status']}\n');

    // List existing DNS records
    print('📝 Listing existing A records...');
    final records = await client.listDNSRecords(type: 'A');
    print('Found ${records.length} A records:');
    for (final record in records) {
      print(
        '  - ${record['name']} → ${record['content']} (${record['proxied'] ? 'Proxied' : 'DNS only'})',
      );
    }
    print('');

    // Example: Create a new subdomain
    print('➕ Creating new subdomain...');
    final newRecord = await client.createARecord(
      name: 'test-api',
      ipAddress: '192.0.2.1', // Example IP
      proxied: true,
      comment: 'Test subdomain created by Dart client',
    );
    print('✅ Created: ${newRecord['name']} → ${newRecord['content']}');
    print('   Record ID: ${newRecord['id']}\n');

    // Example: Create user-specific subdomain
    print('👤 Creating user subdomain...');
    final userRecord = await client.createUserSubdomain(
      username: 'john',
      baseSubdomain: 'api',
      ipAddress: '192.0.2.1',
    );
    print('✅ Created: ${userRecord['name']} → ${userRecord['content']}\n');

    // Example: Check if subdomain exists
    print('🔍 Checking if subdomain exists...');
    final exists = await client.subdomainExists('test-api');
    print('test-api exists: $exists\n');

    // Example: Update a record
    print('✏️  Updating record...');
    final updated = await client.updateDNSRecord(
      recordId: newRecord['id'] as String,
      type: 'A',
      name: 'test-api',
      content: '192.0.2.2', // New IP
      proxied: true,
      comment: 'Updated by Dart client',
    );
    print('✅ Updated: ${updated['name']} → ${updated['content']}\n');

    // Example: Delete records (cleanup)
    print('🗑️  Cleaning up test records...');
    await client.deleteDNSRecord(newRecord['id'] as String);
    print('✅ Deleted: ${newRecord['name']}');

    await client.deleteDNSRecord(userRecord['id'] as String);
    print('✅ Deleted: ${userRecord['name']}\n');

    print('✨ All operations completed successfully!');
  } on CloudflareException catch (e) {
    print('❌ Cloudflare API Error: $e');
    exit(1);
  } catch (e) {
    print('❌ Unexpected error: $e');
    exit(1);
  }
}
