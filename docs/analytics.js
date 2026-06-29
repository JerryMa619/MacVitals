(function () {
  window.plausible = window.plausible || function () {
    (window.plausible.q = window.plausible.q || []).push(arguments);
  };

  function track(eventName) {
    if (!eventName) {
      return;
    }

    window.plausible(eventName);
  }

  document.addEventListener("click", function (event) {
    var target = event.target.closest("[data-analytics-event]");
    if (!target) {
      return;
    }

    track(target.getAttribute("data-analytics-event"));
  });
})();
