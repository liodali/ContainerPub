import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cloudflare API Client for managing DNS records
class CloudflareClient {
  final String apiToken;
  final String zoneId;
  final String baseUrl = 'https://api.cloudflare.com/client/v4';

  CloudflareClient({
    required this.apiToken,
    required this.zoneId,
  });

  /// Get common headers for API requests
  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      };

  /// Create a new DNS A record
  /// 
  /// [name] - Subdomain name (e.g., 'api' or 'user123.api')
  /// [ipAddress] - Target IP address
  /// [proxied] - Whether to proxy through Cloudflare (default: true)
  /// [ttl] - Time to live in seconds (1 = automatic, default: 1)
  Future<Map<String, dynamic>> createARecord({
    required String name,
    required String ipAddress,
    bool proxied = true,
    int ttl = 1,
    String? comment,
  }) async {
    final url = Uri.parse('$baseUrl/zones/$zoneId/dns_records');

    final body = {
      'type': 'A',
      'name': name,
      'content': ipAddress,
      'ttl': ttl,
      'proxied': proxied,
      if (comment != null) 'comment': comment,
    };

    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data['result'] as Map<String, dynamic>;
    } else {
      throw CloudflareException(
        'Failed to create DNS record: ${data['errors']}',
        statusCode: response.statusCode,
        errors: data['errors'] as List?,
      );
    }
  }

  /// Create a CNAME record
  /// 
  /// [name] - Subdomain name
  /// [target] - Target domain
  /// [proxied] - Whether to proxy through Cloudflare (default: true)
  Future<Map<String, dynamic>> createCNAMERecord({
    required String name,
    required String target,
    bool proxied = true,
    int ttl = 1,
    String? comment,
  }) async {
    final url = Uri.parse('$baseUrl/zones/$zoneId/dns_records');

    final body = {
      'type': 'CNAME',
      'name': name,
      'content': target,
      'ttl': ttl,
      'proxied': proxied,
      if (comment != null) 'comment': comment,
    };

    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data['result'] as Map<String, dynamic>;
    } else {
      throw CloudflareException(
        'Failed to create CNAME record: ${data['errors']}',
        statusCode: response.statusCode,
        errors: data['errors'] as List?,
      );
    }
  }

  /// List all DNS records
  /// 
  /// [type] - Filter by record type (e.g., 'A', 'CNAME')
  /// [name] - Filter by record name
  Future<List<Map<String, dynamic>>> listDNSRecords({
    String? type,
    String? name,
  }) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (name != null) queryParams['name'] = name;

    final url = Uri.parse('$baseUrl/zones/$zoneId/dns_records')
        .replace(queryParameters: queryParams);

    final response = await http.get(url, headers: _headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['result'] as List).cast<Map<String, dynamic>>();
    } else {
      throw CloudflareException(
        'Failed to list DNS records: ${data['errors']}',
        statusCode: response.statusCode,
        errors: data['errors'] as List?,
      );
    }
  }

  /// Get a specific DNS record by ID
  Future<Map<String, dynamic>> getDNSRecord(String recordId) async {
    final url = Uri.parse('$baseUrl/zones/$zoneId/dns_records/$recordId');
    final response = await http.get(url, headers: _headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data['result'] as Map<String, dynamic>;
    } else {
      throw CloudflareException(
        'Failed to get DNS record: ${data['errors']}',
        statusCode: response.statusCode,
        errors: data['errors'] as List?,
      );
    }
  }

  /// Update an existing DNS record
  Future<Map<String, dynamic>> updateDNSRecord({
    required String recordId,
    required String type,
    required String name,
    required String content,
    bool? proxied,
    int? ttl,
    String? comment,
  }) async {
    final url = Uri.parse('$baseUrl/zones/$zoneId/dns_records/$recordId');

    final body = {
      'type': type,
      'name': name,
      'content': content,
      if (proxied != null) 'proxied': proxied,
      if (ttl != null) 'ttl': ttl,
      if (comment != null) 'comment': comment,
    };

    final response = await http.put(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data['result'] as Map<String, dynamic>;
    } else {
      throw CloudflareException(
        'Failed to update DNS record: ${data['errors']}',
        statusCode: response.statusCode,
        errors: data['errors'] as List?,
      );
    }
  }

  /// Delete a DNS record
  Future<bool> deleteDNSRecord(String recordId) async {
    final url = Uri.parse('$baseUrl/zones/$zoneId/dns_records/$recordId');

    final response = await http.delete(url, headers: _headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return true;
    } else {
      throw CloudflareException(
        'Failed to delete DNS record: ${data['errors']}',
        statusCode: response.statusCode,
        errors: data['errors'] as List?,
      );
    }
  }

  /// Check if a subdomain exists
  Future<bool> subdomainExists(String name) async {
    try {
      final records = await listDNSRecords(name: name);
      return records.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Create subdomain for a user (helper method)
  /// 
  /// Creates a subdomain like: username.api.yourdomain.com
  Future<Map<String, dynamic>> createUserSubdomain({
    required String username,
    required String baseSubdomain,
    required String ipAddress,
    bool proxied = true,
  }) async {
    final subdomain = '$username.$baseSubdomain';

    // Check if subdomain already exists
    if (await subdomainExists(subdomain)) {
      throw CloudflareException(
        'Subdomain $subdomain already exists',
        statusCode: 409,
      );
    }

    return await createARecord(
      name: subdomain,
      ipAddress: ipAddress,
      proxied: proxied,
      comment: 'User subdomain for $username',
    );
  }

  /// Get zone details
  Future<Map<String, dynamic>> getZoneDetails() async {
    final url = Uri.parse('$baseUrl/zones/$zoneId');

    final response = await http.get(url, headers: _headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data['result'] as Map<String, dynamic>;
    } else {
      throw CloudflareException(
        'Failed to get zone details: ${data['errors']}',
        statusCode: response.statusCode,
        errors: data['errors'] as List?,
      );
    }
  }
}

/// Custom exception for Cloudflare API errors
class CloudflareException implements Exception {
  final String message;
  final int? statusCode;
  final List? errors;

  CloudflareException(
    this.message, {
    this.statusCode,
    this.errors,
  });

  @override
  String toString() {
    final buffer = StringBuffer('CloudflareException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (errors != null && errors!.isNotEmpty) {
      buffer.write('\nErrors: ${jsonEncode(errors)}');
    }
    return buffer.toString();
  }
}
