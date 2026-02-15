import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/forge_api_client.dart';

final apiUrlProvider = StateProvider<String>((ref) => 'http://127.0.0.1:7861');

final forgeApiClientProvider = Provider<ForgeApiClient>((ref) {
  final baseUrl = ref.watch(apiUrlProvider);
  return ForgeApiClient(baseUrl: baseUrl);
});
