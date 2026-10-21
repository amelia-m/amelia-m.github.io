// Drifting-dot background for the home page.
//
// Dots wander slowly and draw a line to any neighbour within LINK px. This is
// hand-rolled rather than particles.js because the dot colour has to follow
// the light/dark toggle and the layer's opacity is driven by scroll position.
//
// The text column stays solid: dots and lines are cleared from it, and a thin
// rail marks each edge, so nothing moves behind the words. The layer shows
// faintly from the top of the page (the banner photo covers it there) and
// reaches full strength once the banner has scrolled off. Nothing runs at all
// for readers who ask for reduced motion.
(function () {
  "use strict";

  var host = document.getElementById("particles-bg");
  if (!host) return;

  var reduceQuery =
    window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)");
  if (reduceQuery && reduceQuery.matches) return;

  var LINK = 160; // px: draw a line between dots closer than this
  // Dots per area is the same on every screen. The bounds only catch the
  // extremes: a small window still gets a few, and the cap is a cost limit,
  // since every frame checks every pair (250 dots is ~31k pairs). Only a
  // window above about 3.2 million px^2, such as 2560 x 1440, reaches it.
  // A fixed cap of 90 used to thin out every large window, and a floor of
  // 20 crowded small ones.
  var AREA_PER_DOT = 13000; // px^2 of viewport per dot
  var MIN_DOTS = 8;
  var MAX_DOTS = 250;
  var MAX_ALPHA = 0.55; // layer opacity once the banner has scrolled off
  var START_FRACTION = 0.45; // share of MAX_ALPHA shown at the top of the page
  var COLUMN_PAD = 32; // px of solid background either side of the text
  var MIN_MARGIN = 48; // px: a narrower margin is treated as no margin at all
  var RAIL_ALPHA = 0.5; // rail strength, relative to the layer
  var BUCKETS = 5; // line alphas are quantised into this many batched strokes

  var canvas = document.createElement("canvas");
  canvas.setAttribute("aria-hidden", "true");
  host.appendChild(canvas);
  var ctx = canvas.getContext("2d");
  if (!ctx) return;

  var dots = [];
  var w = 0;
  var h = 0;
  var fadeEnd = 450; // scroll offset at which the banner is gone; set in resize()
  var colL = 0; // the solid text column, in px; both 0 when there is none
  var colR = 0;
  var dotColor = "43, 92, 138";
  var frame = null;
  var alpha = -1; // force the first opacity write
  var stopped = false;

  // The dot colour lives in CSS (--particles-rgb) so each theme sets its own.
  // Re-read on a theme change rather than every frame: getComputedStyle forces
  // a style flush, and this value only changes when the theme does.
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

    measure();
    readColor();
  }

  // Where the banner ends and where the text column sits. Both depend on the
  // page layout rather than only the window, so this also runs when the page
  // reflows (late fonts or images, a scrollbar appearing), which fires no
  // window resize. Never from the frame loop, where the read/write pair would
  // thrash layout at 60fps.
  function measure() {
    var y = window.pageYOffset || 0;

    // The banner counts as gone once its bottom passes under the fixed navbar.
    var banner = document.querySelector(".hero-banner");
    if (banner) {
      var header = document.getElementById("quarto-header");
      var nav = header ? header.getBoundingClientRect().height : 0;
      fadeEnd = banner.getBoundingClientRect().bottom + y - nav;
    }

    // The text column: the home grid under the banner, which shares its
    // edges with the title above it. A margin too thin to show anything
    // counts as none, so the rail is not drawn hugging the window edge.
    var col = document.querySelector("main .home-grid");
    colL = colR = 0;
    if (col) {
      var cr = col.getBoundingClientRect();
      colL = Math.round(cr.left) - COLUMN_PAD;
      colR = Math.round(cr.right) + COLUMN_PAD;
      if (colL < MIN_MARGIN) colL = 0;
      if (w - colR < MIN_MARGIN) colR = w;
    }
  }

  // START_FRACTION at the top of the page, ramping to 1 as the banner leaves.
  function scrollFade() {
    var y = window.pageYOffset || document.documentElement.scrollTop || 0;
    var t = fadeEnd > 0 ? y / fadeEnd : 1;
    if (t > 1) t = 1;
    return START_FRACTION + (1 - START_FRACTION) * t;
  }

  // Scratch space for the batched line passes, reused across frames.
  var lines = [];
  for (var bi = 0; bi < BUCKETS; bi++) lines.push([]);

  function step() {
    frame = null;
    if (stopped) return;

    var next = scrollFade() * MAX_ALPHA;
    if (next !== alpha) {
      alpha = next;
      host.style.opacity = String(alpha);
    }

    // Column as wide as the window, as on a phone: nothing would show, so
    // leave the frame empty and let the loop idle until a resize.
    if (colL === 0 && colR >= w) {
      ctx.clearRect(0, 0, w, h);
      return;
    }

    var i, j, a, b, dx, dy, d2, arr;
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

    for (i = 0; i < BUCKETS; i++) lines[i].length = 0;

    // Sort each segment into an alpha bucket so the whole bucket can be laid
    // down as one path and stroked once, instead of a stroke per pair.
    for (i = 0; i < dots.length; i++) {
      a = dots[i];
      for (j = i + 1; j < dots.length; j++) {
        b = dots[j];
        dx = a.x - b.x;
        dy = a.y - b.y;
        d2 = dx * dx + dy * dy;
        if (d2 < link2) {
          var t = 1 - d2 / link2;
          var k = (t * BUCKETS) | 0;
          if (k >= BUCKETS) k = BUCKETS - 1;
          arr = lines[k];
          arr.push(a.x, a.y, b.x, b.y);
        }
      }
    }

    ctx.strokeStyle = "rgb(" + dotColor + ")";
    ctx.lineWidth = 1;
    for (i = 0; i < BUCKETS; i++) {
      arr = lines[i];
      if (!arr.length) continue;
      ctx.globalAlpha = (((i + 0.5) / BUCKETS) * 0.4);
      ctx.beginPath();
      for (j = 0; j < arr.length; j += 4) {
        ctx.moveTo(arr[j], arr[j + 1]);
        ctx.lineTo(arr[j + 2], arr[j + 3]);
      }
      ctx.stroke();
    }
    ctx.globalAlpha = 1;

    ctx.fillStyle = "rgb(" + dotColor + ")";
    for (i = 0; i < dots.length; i++) {
      a = dots[i];
      ctx.beginPath();
      ctx.arc(a.x, a.y, a.r, 0, Math.PI * 2);
      ctx.fill();
    }

    // Cut the text column out of the frame and mark its edges. A rail sitting
    // on the window edge would only read as a border, so it is left off; on a
    // phone the column is the whole width and neither rail is drawn.
    if (colR > colL) {
      ctx.clearRect(colL, 0, colR - colL, h);
      ctx.strokeStyle = "rgb(" + dotColor + ")";
      ctx.lineWidth = 1;
      ctx.globalAlpha = RAIL_ALPHA;
      ctx.beginPath();
      if (colL > 0) {
        ctx.moveTo(colL + 0.5, 0);
        ctx.lineTo(colL + 0.5, h);
      }
      if (colR < w) {
        ctx.moveTo(colR - 0.5, 0);
        ctx.lineTo(colR - 0.5, h);
      }
      ctx.stroke();
      ctx.globalAlpha = 1;
    }

    schedule();
  }

  function schedule() {
    if (!stopped && frame === null && !document.hidden) {
      frame = window.requestAnimationFrame(step);
    }
  }

  window.addEventListener("resize", function () {
    resize();
    schedule();
  });
  if (window.ResizeObserver) {
    new ResizeObserver(function () {
      measure();
      schedule();
    }).observe(document.body);
  }
  window.addEventListener("scroll", schedule, { passive: true });
  document.addEventListener("visibilitychange", schedule);

  // Quarto's colour-scheme toggle swaps which stylesheet is live and sets a
  // class on <body>; it fires no event of its own. Watch the class instead of
  // relying on the reflow the toggle happens to cause.
  if (window.MutationObserver) {
    new MutationObserver(function () {
      readColor();
      schedule();
    }).observe(document.body, { attributes: true, attributeFilter: ["class"] });
  }
  var schemeQuery =
    window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)");
  if (schemeQuery && schemeQuery.addEventListener) {
    schemeQuery.addEventListener("change", function () {
      readColor();
      schedule();
    });
  }

  // Stop for good if the reader turns on reduced motion while the page is
  // open. `stopped` is what makes it stick: cancelling the pending frame alone
  // would let the next scroll event start the loop up again.
  if (reduceQuery && reduceQuery.addEventListener) {
    reduceQuery.addEventListener("change", function (e) {
      if (!e.matches) return;
      stopped = true;
      if (frame !== null) window.cancelAnimationFrame(frame);
      frame = null;
      ctx.clearRect(0, 0, w, h);
      host.style.opacity = "0";
    });
  }

  resize();
  schedule();
})();
