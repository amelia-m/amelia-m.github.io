// Drifting-dot background for the home page.
//
// Dots wander slowly and draw a line to any neighbour within LINK px, which
// is the effect from particles.js. This is hand-rolled rather than that
// library for three reasons: the site loads no third-party assets (see
// $web-font-path in styles.scss), the dot colour has to follow the light/dark
// toggle without re-initialising, and the layer's opacity is driven by scroll
// position.
//
// The layer stays invisible until the reader has scrolled past the banner
// photo, then fades in; scrolling back up fades it out again. Nothing is
// drawn while it is fully transparent, and nothing runs at all for readers
// who ask for reduced motion.
(function () {
  "use strict";

  var host = document.getElementById("particles-bg");
  if (!host) return;

  var reduceQuery =
    window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)");
  if (reduceQuery && reduceQuery.matches) return;

  var LINK = 140; // px: draw a line between dots closer than this
  var AREA_PER_DOT = 26000; // px^2 of viewport per dot
  var MIN_DOTS = 20;
  var MAX_DOTS = 90;
  var MAX_ALPHA = 0.55; // layer opacity once fully faded in
  var FADE_SPAN = 320; // px of scrolling over which it fades in

  var canvas = document.createElement("canvas");
  canvas.setAttribute("aria-hidden", "true");
  host.appendChild(canvas);
  var ctx = canvas.getContext("2d");
  if (!ctx) return;

  var dots = [];
  var w = 0;
  var h = 0;
  var dotColor = "45, 92, 138";
  var frame = null;
  var alpha = -1; // force the first opacity write

  // The dot colour lives in CSS (--particles-rgb) so each theme sets its own
  // and a toggle is picked up on the next frame with no re-init.
  function readColor() {
    var v = getComputedStyle(host).getPropertyValue("--particles-rgb");
    if (v) dotColor = v.trim();
  }

  function spawn() {
    return {
      x: Math.random() * w,
      y: Math.random() * h,
      vx: (Math.random() - 0.5) * 0.3,
      vy: (Math.random() - 0.5) * 0.3,
      r: 1.1 + Math.random() * 1.7
    };
  }

  function resize() {
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    w = host.clientWidth;
    h = host.clientHeight;
    canvas.width = Math.round(w * dpr);
    canvas.height = Math.round(h * dpr);
    canvas.style.width = w + "px";
    canvas.style.height = h + "px";
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    var target = Math.round((w * h) / AREA_PER_DOT);
    if (target < MIN_DOTS) target = MIN_DOTS;
    if (target > MAX_DOTS) target = MAX_DOTS;
    while (dots.length < target) dots.push(spawn());
    if (dots.length > target) dots.length = target;

    readColor();
  }

  // 0 while the banner is still on screen, ramping to 1 once past it.
  function scrollFade() {
    var banner = document.querySelector(".hero-banner");
    var start = banner ? banner.getBoundingClientRect().height * 0.55 : 150;
    var y = window.pageYOffset || document.documentElement.scrollTop || 0;
    var t = (y - start) / FADE_SPAN;
    if (t < 0) return 0;
    if (t > 1) return 1;
    return t;
  }

  function step() {
    frame = null;

    var next = scrollFade() * MAX_ALPHA;
    if (next !== alpha) {
      alpha = next;
      host.style.opacity = String(alpha);
    }

    // Fully transparent: advance nothing, draw nothing, just wait for scroll.
    if (alpha <= 0) return;

    var i, j, a, b, dx, dy, d2;
    var link2 = LINK * LINK;

    for (i = 0; i < dots.length; i++) {
      a = dots[i];
      a.x += a.vx;
      a.y += a.vy;
      if (a.x < -10) a.x = w + 10;
      else if (a.x > w + 10) a.x = -10;
      if (a.y < -10) a.y = h + 10;
      else if (a.y > h + 10) a.y = -10;
    }

    ctx.clearRect(0, 0, w, h);

    ctx.strokeStyle = "rgba(" + dotColor + ", 0.4)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (i = 0; i < dots.length; i++) {
      a = dots[i];
      for (j = i + 1; j < dots.length; j++) {
        b = dots[j];
        dx = a.x - b.x;
        dy = a.y - b.y;
        d2 = dx * dx + dy * dy;
        if (d2 < link2) {
          ctx.globalAlpha = 1 - d2 / link2;
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.stroke();
          ctx.beginPath();
        }
      }
    }
    ctx.globalAlpha = 1;

    ctx.fillStyle = "rgb(" + dotColor + ")";
    for (i = 0; i < dots.length; i++) {
      a = dots[i];
      ctx.beginPath();
      ctx.arc(a.x, a.y, a.r, 0, Math.PI * 2);
      ctx.fill();
    }

    schedule();
  }

  function schedule() {
    if (frame === null && !document.hidden) {
      frame = window.requestAnimationFrame(step);
    }
  }

  window.addEventListener("resize", function () {
    resize();
    schedule();
  });
  window.addEventListener("scroll", schedule, { passive: true });
  document.addEventListener("visibilitychange", schedule);

  // Stop for good if the reader turns on reduced motion while the page is open.
  if (reduceQuery && reduceQuery.addEventListener) {
    reduceQuery.addEventListener("change", function (e) {
      if (e.matches) {
        if (frame !== null) window.cancelAnimationFrame(frame);
        frame = null;
        host.style.display = "none";
      }
    });
  }

  resize();
  schedule();
})();
