import chrobot
import chrobot/chrome
import envoy
import gleam/erlang/process
import gleam/result
import lib/error
import snag

pub fn load(
  url url: String,
  with fun: fn(process.Subject(chrome.Message), chrobot.Page) ->
    Result(a, snag.Snag),
) -> Result(a, snag.Snag) {
  use path <- result.try(
    chrome.get_system_chrome_path()
    |> error.map_to_snag("Unable to get chrome path"),
  )

  use temp <- result.try(
    envoy.get("TMPDIR") |> error.map_to_snag("Unable to get temp dir"),
  )

  let args = [
    "--disable-field-trial-config",
    "--disable-background-networking",
    "--disable-background-timer-throttling",
    "--disable-backgrounding-occluded-windows",
    "--disable-back-forward-cache",
    "--disable-breakpad",
    "--disable-client-side-phishing-detection",
    "--disable-component-extensions-with-background-pages",
    "--disable-component-update",
    "--no-default-browser-check",
    "--disable-default-apps",
    "--disable-dev-shm-usage",
    "--disable-extensions",
    "--disable-features=AcceptCHFrame,AutoExpandDetailsElement,AvoidUnnecessaryBeforeUnloadCheckSync,CertificateTransparencyComponentUpdater,DeferRendererTasksAfterInput,DestroyProfileOnBrowserClose,DialMediaRouteProvider,ExtensionManifestV2Disabled,GlobalMediaControls,HttpsUpgrades,ImprovedCookieControls,LazyFrameLoading,LensOverlay,MediaRouter,PaintHolding,ThirdPartyStoragePartitioning,Translate",
    "--allow-pre-commit-input",
    "--disable-hang-monitor",
    "--disable-ipc-flooding-protection",
    "--disable-popup-blocking",
    "--disable-prompt-on-repost",
    "--disable-renderer-backgrounding",
    "--force-color-profile=srgb",
    "--metrics-recording-only",
    "--no-first-run",
    "--enable-automation",
    "--password-store=basic",
    "--use-mock-keychain",
    "--no-service-autorun",
    "--export-tagged-pdf",
    "--disable-search-engine-choice-screen",
    "--unsafely-disable-devtools-self-xss-warnings",
    "--enable-use-zoom-for-dsf=false",
    // "--no-sandbox",
    "--user-data-dir=" <> temp <> "chrome-profile",
    "--remote-debugging-pipe",
    "--no-startup-window",
  ]

  let config =
    chrome.BrowserConfig(
      path:,
      args:,
      log_level: chrome.LogLevelWarnings,
      start_timeout: chrome.default_timeout,
    )

  use browser <- result.try(
    chrome.launch_with_config(config)
    |> error.map_to_snag("Launch unsuccessful!"),
  )

  use page <- result.try(
    chrobot.open(browser, url, 30_000)
    |> error.map_to_snag("Unable to open page"),
  )

  use _ <- result.try(
    chrobot.eval(
      page,
      "
      Object.defineProperty(navigator, 'webdriver', {
        get: () => false,
      });
      Object.defineProperty(navigator, 'plugins', {
        get: () => [
          { name: 'Chrome PDF Plugin', filename: 'internal-pdf-viewer', description: 'Portable Document Format' },
          { name: 'Chrome PDF Viewer', filename: 'mhjfbmdgcfjbbpaeojofohoefgiehjai', description: 'Portable Document Format' },
          { name: 'Native Client', filename: 'internal-nacl-plugin', description: 'Native Client' }
        ],
      });
      window.chrome = {
        runtime: {},
        loadTimes: function() {},
        csi: function() {},
        app: {}
      };
      
      // Random mouse movements simulation
      const originalQuery = window.navigator.permissions.query;
      window.navigator.permissions.query = (parameters) => (
        parameters.name === 'notifications' ?
          Promise.resolve({ state: Notification.permission }) :
          originalQuery(parameters)
      );
",
    )
    |> error.map_to_snag("Unable to run init scrpt"),
  )

  let res = fun(browser, page)

  let _ = chrobot.quit(browser) |> error.map_to_snag("Shutdown unsuccessful!")

  res
}
