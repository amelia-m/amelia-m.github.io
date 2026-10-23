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
// stays upcoming through its own day and moves on the day after, the same rule
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
  // is safe, since what has moved stays moved.
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

    // Events page: each Upcoming item is a .event span inside its <li>. Every
    // item whose date has gone moves into Past, under its year, in past
    // wording: the hidden .event-then where the build wrote one (a linked
    // event with a past_note), otherwise the same text, with the name no
    // longer bold where the build marked it as a bold name (data-unbold; a
    // `text` entry keeps its own bold, as it does on a build). Items arrive
    // soonest first and each goes to the top of its year, so the newest ends
    // up first, as the build orders them.
    var past = document.getElementById("past");
    var items = document.querySelectorAll("#upcoming .event[data-date]");
    for (var j = 0; j < items.length; j++) {
      var ev = items[j];
      var day = ev.getAttribute("data-date");
      if (day >= today) continue;
      var li = ev.closest("li");
      if (!li) continue;
      var nowText = ev.querySelector(".event-now");
      var thenText = ev.querySelector(".event-then");
      if (nowText && thenText) {
        nowText.hidden = true;
        thenText.hidden = false;
      } else if (ev.hasAttribute("data-unbold")) {
        var name = ev.firstChild;
        if (name && name.nodeName === "STRONG") {
          while (name.firstChild) ev.insertBefore(name.firstChild, name);
          ev.removeChild(name);
        }
      }
      var list = past ? yearList(past, day.slice(0, 4)) : null;
      if (list) {
        list.insertBefore(li, list.firstChild);
      } else {
        li.hidden = true;
      }
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

  // The list under a year heading in Past, made if the year has none yet.
  // Years run newest first, so a new one goes before the first older year.
  function yearList(past, year) {
    var heads = past.querySelectorAll("h3");
    var before = null;
    for (var k = 0; k < heads.length; k++) {
      var y = heads[k].textContent.trim();
      var sec = heads[k].closest("section") || heads[k].parentNode;
      if (y === year) {
        var ul = sec.querySelector("ul");
        if (ul) return ul;
        ul = document.createElement("ul");
        sec.appendChild(ul);
        return ul;
      }
      if (!before && y < year) before = sec;
    }
    // Quarto would give a heading of bare digits an id like "section-2"; a
    // year-based one cannot collide with those.
    var section = document.createElement("section");
    section.className = "level3";
    section.id = "past-" + year;
    var h = document.createElement("h3");
    h.className = "anchored";
    h.setAttribute("data-anchor-id", section.id);
    h.textContent = year;
    var list = document.createElement("ul");
    section.appendChild(h);
    section.appendChild(list);
    past.insertBefore(section, before);
    return list;
  }
})();
