(function () {
  var config = window.MACVITALS_ANALYTICS || {};
  var eventQueue = [];

  function loadCloudflareAnalytics() {
    if (config.provider !== "cloudflare" || !config.cloudflareToken) {
      return;
    }

    var script = document.createElement("script");
    script.defer = true;
    script.src = "https://static.cloudflareinsights.com/beacon.min.js";
    script.setAttribute("data-cf-beacon", JSON.stringify({ token: config.cloudflareToken }));
    document.head.appendChild(script);
  }

  function track(eventName) {
    if (!eventName) {
      return;
    }

    eventQueue.push({
      event: eventName,
      at: new Date().toISOString()
    });

    if (window.zaraz && typeof window.zaraz.track === "function") {
      window.zaraz.track(eventName);
    }

    if (window.gtag && typeof window.gtag === "function") {
      window.gtag("event", eventName);
    }
  }

  document.addEventListener("click", function (event) {
    var target = event.target.closest("[data-analytics-event]");
    if (!target) {
      return;
    }

    track(target.getAttribute("data-analytics-event"));
  });

  loadCloudflareAnalytics();
  window.macVitalsAnalyticsEvents = eventQueue;
})();
