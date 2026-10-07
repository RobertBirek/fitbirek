import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'push_client.dart';
import 'push_platform.dart';

final pushClientProvider = Provider<PushClient>((ref) => createPushClient());
