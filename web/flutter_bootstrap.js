{{flutter_js}}
{{flutter_build_config}}

// Flutter 3.35.4 uses this base for both its startup Roboto and on-demand Noto
// fallbacks. Preserve the engine's versioned paths and keep fallback enabled.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: new URL('font-fallbacks/', document.baseURI).href,
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
