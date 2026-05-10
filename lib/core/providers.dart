import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/forge_api_client.dart';
import 'layout_preferences.dart';

final apiUrlProvider = StateProvider<String>((ref) => LayoutPreferences.getApiUrl());

final forgeApiClientProvider = Provider<ForgeApiClient>((ref) {
  final baseUrl = ref.watch(apiUrlProvider);
  return ForgeApiClient(baseUrl: baseUrl);
});
