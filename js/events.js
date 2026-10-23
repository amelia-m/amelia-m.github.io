// Keeps the event lists current between publishes.
//
// The site is static and rebuilt only when Amelia publishes, so the home page
// callout and the events page used to stay as they were on the day of the
// build: a session that had already happened stayed "Next up" until the next
// publish. R/site.R now writes every candidate into the page with its date,
// the build-time choice visible and the rest hidden, and this script makes the
// choice again with the reader's own date. Without JavaScript the page reads
// as built. The classes and data- attributes are set in R/site.R; change the
// two together.
//
// Dates are compared as YYYY-MM-DD strings in the reader's time zone. An event
// stays upcoming through its own day and leaves the day after, the same rule
// the build uses.
(function () {
  "use strict";

  function pad(n) {
    return (n < 10 ? "0" : "") + n;
  }

  // Run on load, and again when the page comes back into view: a page left
  // open past midnight, or restored by the Back button from the browser's
  // page cache (which does not rerun scripts), would otherwise keep the day
  // it was first shown. Both events can fire on one restore; running twice
  // is safe, since what has been hidden stays hidden.
  function update() {
    var now = new Date();
    var today =
      now.getFullYear() + "-" + pad(now.getMonth() + 1) + "-" + pad(now.getDate());

    // Home page: one .event-next per upcoming event, soonest first, each with
    // the first day it is worth naming (data-from) and its date. Show the
    // first one in range, else the .event-fallback line; the .event-callout
    // wrapper around the whole callout is shown only when one of them is.
    var next = document.querySelectorAll(".event-next");
    var wrap = document.querySelector(".event-callout");
    if (next.length && wrap) {
      var pick = null;
      for (var i = 0; i < next.length; i++) {
        var from = next[i].getAttribute("data-from");
        var date = next[i].getAttribute("data-date");
        if (!pick && from <= today && today <= date) pick = next[i];
        next[i].hidden = true;
      }
      var fallback = document.querySelector(".event-fallback");
      if (fallback) fallback.hidden = true;
      var show = pick || fallback;
      if (show) show.hidden = false;
      wrap.hidden = !show;
    }

    // Events page: each Upcoming item is a .event span inside its <li>. An
    // item whose date has gone leaves Upcoming. It does not go into Past
    // here: Past lists only events Amelia has confirmed with `attended: true`
    // in events.yml, which takes effect at the next publish.
    var items = document.querySelectorAll("#upcoming .event[data-date]");
    for (var j = 0; j < items.length; j++) {
      if (items[j].getAttribute("data-date") >= today) continue;
      var li = items[j].closest("li");
      if (li) li.hidden = true;
    }
    var upcoming = document.getElementById("upcoming");
    if (upcoming && items.length && !upcoming.querySelector("li:not([hidden])")) {
      upcoming.hidden = true;
    }
  }

  update();
  window.addEventListener("pageshow", function (e) {
    if (e.persisted) update();
  });
  document.addEventListener("visibilitychange", function () {
    if (!document.hidden) update();
  });
})();
