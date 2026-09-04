// Warunkowy eksport implementacji połączenia z bazą - w zależności od
// platformy (natywna z dart:ffi vs web z dart:js_interop).
// Zobacz ARCHITECTURE.md - sekcja "Drift na wielu platformach".
library;

export 'unsupported_connection.dart'
    if (dart.library.ffi) 'native_connection.dart'
    if (dart.library.js_interop) 'web_connection.dart';
