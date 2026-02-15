import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/forge_api_client.dart';

final forgeApiClientProvider = Provider<ForgeApiClient>((ref) {
  return ForgeApiClient();
});
