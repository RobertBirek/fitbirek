{{flutter_js}}
{{flutter_build_config}}

// A legacy Flutter worker serves index online-first but unversioned scripts
// cache-first. Never let new HTML execute its stale cached entrypoint while an
// update installs (including the loader's timeout/fallback path).
const fitShellId = document.querySelector('meta[name="fit-offline-shell"]')?.content;
if (fitShellId) {
  for (const build of _flutter.buildConfig.builds) {
    if (build.compileTarget === 'dart2js') {
      build.mainJsPath = `${build.mainJsPath || 'main.dart.js'}?fit-shell=${fitShellId}`;
    }
  }
}

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
