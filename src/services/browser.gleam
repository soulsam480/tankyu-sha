import chrobot
import chrobot/chrome
import chrobot/protocol/page as chropage
import envoy
import gleam/option
import gleam/result

pub fn search_browser() {
  use path <- result.map(chrome.get_system_chrome_path())

  use temp <- result.map(envoy.get("TMPDIR"))

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

  use browser <- result.map(chrome.launch_with_config(config))

  use page <- result.map(chrobot.open(browser, "about:blank", 30_000))

  use _ <- result.then(chrobot.eval(
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
  ))

  let callback = chrobot.page_caller(page)

  // use _ <- result.then(chrobot.eval_async(
  //   page,
  //   "new Promise((resolve, reject) => setTimeout(() => resolve(42), 600000))",
  // ))

  use _ <- result.then(chropage.navigate(
    callback,
    "https://sambitsahoo.com",
    option.None,
    option.None,
    option.None,
  ))

  use _ <- result.map(chrobot.await_load_event(browser, page))
  // use input <- result.map(chrobot.select(page, "textarea"))
  //
  // use _ <- result.then(chrobot.focus(page, input))
  // use _ <- result.then(chrobot.type_text(page, "revenuehero"))
  // use _ <- result.then(chrobot.press_key(page, "Enter"))
  //
  // use _ <- result.then(chrobot.await_load_event(browser, page))

  // use title_results <- result.map(
  //   list.map(page_items, fn(i) { chrobot.get_attribute(page, i, "href") })
  //   |> result.all(),
  // )
  //
  // io.debug(title_results)

  let _ = chrobot.quit(browser)

  Ok(Nil)
}
