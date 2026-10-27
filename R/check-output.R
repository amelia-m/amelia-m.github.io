# Post-render check: fail the render when its output is visibly broken.
#
# Run by Quarto after every render (`post-render` in _quarto.yml). A render
# that "succeeds" is only evidence that nothing threw an error. On 2026-10-17
# a cloud render wrote 66 en dashes on the CV page as literal "<U+2013>" text
# and still reported success, which is the failure this exists to stop: if the
# output shows a known symptom, the render exits non-zero and says where.
#
# It must not fire on correct work either, or it gets ignored. So every
# pattern here was measured against the known-good site and against pages that
# legitimately show the same strings, and a check that could not tell the two
# apart was left out.
#
# Every check skips source code shown on a page, so a post can show any of
# these strings on purpose, and the two inline R checks also skip scripts and
# styles (not JSON data). Prose and chunk output are checked: chunk output is
# where R's own breakage lands. Two checks were dropped because broken output
# and correct output look the same: R's NA printed as text (see TODO.md), and
# an unexpanded shortcode, which renders exactly like Quarto's documented
# escape for showing one. A page whose content is missing but whose file was
# written is not caught either; only a zero-length file is. It also fails a page
# that has lost the analytics script, which nothing else would notice.
#
# Finding nothing to check is a failure, not a pass. Base R only, and wrapped
# in local() so that source()-ing it by hand leaves nothing behind. Run it from
# anywhere in the project with `Rscript R/check-output.R`.

local({

# UTF-8 decoded as Windows-1252 (or Latin-1) and encoded again: the lead byte
# of a multi-byte character becomes a letter, and each following byte becomes
# a symbol or punctuation mark. Which follow-on marks count depends on the
# letter, so that real text passes:
#   Â Ã  + any of them (Â©, Ã©, Ã–, Ã¡). Real text puts these capitals before
#          a mark almost never; a Portuguese capital before a closing quote
#          ("IRMÃ”") would be flagged, and is accepted as the cost.
#   â    + any of them except a no-break space. This is where three-byte
#          characters land, including the ones R's cli package prints: ✔ as
#          "âœ”", ─ as "â”€", − as "âˆ’".
#   Î Ï Ä Å + symbols and marks, but not dashes, quotes, ellipsis or bullet,
#          which real text puts after a capital ("Ä–Ö"). Greek and Central
#          European damage still shows: Î², Ï€, Å‚, Ä‡.
#   ð    + Ÿ only (emoji: ðŸ˜€), so Icelandic "með”" passes.
# Not leads at all: ß × É Ö and the rest, so "Gauß–Markov" and "3× daily" pass.
sym   <- "\\xc2[\\xa1-\\xbf]"
nbsp  <- "\\xc2\\xa0"
punct <- "\\xe2\\x80[\\x93\\x94\\x98\\x99\\x9c\\x9d\\xa2\\xa6]"
other <- paste0("\\xe2\\x82\\xac|\\xe2\\x80[\\x9a\\x9e\\xa0\\xa1\\xb0\\xb9\\xba]|\\xe2\\x84\\xa2",
                "|\\xc6\\x92|\\xcb[\\x86\\x9c]|\\xc5[\\x92\\x93\\xa0\\xa1\\xb8\\xbd\\xbe]")
mojibake <- paste0(
  "\\xc3[\\x82\\x83](", sym, "|", nbsp, "|", other, "|", punct, ")",
  "|\\xc3\\xa2(", sym, "|", other, "|", punct, ")",
  "|\\xc3[\\x84\\x85\\x8e\\x8f](", sym, "|", other, ")",
  "|\\xc3\\xb0\\xc5\\xb8")

byte_checks <- list(
  list(name = "replacement character U+FFFD", pattern = "\\xef\\xbf\\xbd",
       cause = "text was decoded with the wrong encoding somewhere before output"),
  list(name = "C1 control character", pattern = "\\xc2[\\x80-\\x9f]",
       cause = "UTF-8 text was decoded as Latin-1, which turns part of every non-ASCII character into an invisible control code"),
  list(name = "mojibake: UTF-8 read as Windows-1252 or Latin-1", pattern = mojibake,
       cause = "a UTF-8 file was read as Windows-1252 or Latin-1 and written back out")
)

locale_cause <- "R wrote non-ASCII text under a non-UTF-8 locale; see the locale switch at the top of R/site.R"
text_checks <- list(
  list(name = "escaped code point such as <U+2013>",
       pattern = "(&lt;|<|%3[Cc])U\\+[0-9A-Fa-f]{4}", cause = locale_cause),
  list(name = "octal byte escape such as \\342\\200\\223",
       pattern = "\\\\3[0-7]{2}\\\\[0-7]{3}", cause = locale_cause),
  list(name = "hex byte escape such as \\xe2\\x80\\x93",
       pattern = "\\\\x[c-fC-F][0-9a-fA-F]\\\\x[89abAB][0-9a-fA-F]", cause = locale_cause),
  # iconv(sub = "byte") writes <e2><80><93>; Pandoc keeps <e2> as a tag, which
  # hides it on the page, and escapes the digit-led ones.
  list(name = "byte written as <e2><80>",
       pattern = "(<|&lt;)[c-fC-F][0-9a-fA-F](>|&gt;)(<|&lt;)[89abAB][0-9a-fA-F](>|&gt;)", cause = locale_cause)
)

# Inline R that knitr never saw, in its two forms. Both are looked for outside
# <pre> blocks, scripts and styles, so chunk output that prints R source (an
# Rmd template, "r = 0.42") and JavaScript are never mistaken for it. JSON
# data blocks are still checked, because a widget shows its data on the page;
# a JS() callback inside one that holds a template literal starting "r " would
# be flagged, and is accepted as the cost. Inline R shown on purpose keeps its
# backticks inside the span (`` `r x` `` gives <code>`r x`</code>) and so does
# not match the first form.
#
# Both forms need "r " followed by something an R expression can start with:
# a name, number, string or bracket, or a unary ! or - (with no space after,
# so "r - 1" is not one). So `r = 0.42`, `r <- cor(x, y)`, `r != 0` and
# `r ~ x` in code font, on a page with no R chunks, are ordinary code, while
# `r nrow(d)`, `r 2026 - 1990`, `r "a"`, `r (a)` and `r -x` are caught.
# Pandoc writes < > & as entities, hence the & in the exclusions.
r_start <- "(?:[A-Za-z0-9._\"'(]|!(?![\\s=])|-(?![\\s=&]))"
unrun_r <- list(name = "inline R left unevaluated",
                pattern = paste0("<code[^>]*>(r ", r_start, "|\\{r\\} )"),
                cause = "a `r ...` call sits where knitr does not run it, such as a YAML field printed with cat()")
literal_r <- list(name = "inline R left as literal text", pattern = paste0("`r ", r_start),
                  cause = "an inline R call passed through md() or another escape, so knitr never saw it")

fail <- function(msg) {
  if (interactive()) stop(msg, call. = FALSE)
  message(msg)
  quit(status = 1)
}

# The project root, found the way R/site.R finds it. Kept separate rather than
# sourcing R/site.R, so the check does not depend on the file it may be
# catching a failure in.
project <- Sys.getenv("QUARTO_PROJECT_DIR")
if (!nzchar(project)) {
  project <- normalizePath(getwd(), winslash = "/")
  while (!file.exists(file.path(project, "_quarto.yml"))) {
    parent <- dirname(project)
    if (identical(parent, project)) fail(paste0("check-output: no _quarto.yml above ", getwd()))
    project <- parent
  }
}
project <- normalizePath(project, winslash = "/")

# Quarto sets QUARTO_PROJECT_OUTPUT_DIR for every post-render script, so its
# presence is what says this is a render. A hand run reads `output-dir` from
# _quarto.yml instead of assuming _site.
out_dir <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR")
in_render <- nzchar(out_dir)
if (!in_render) {
  conf <- grep("^[[:space:]]*output-dir:", readLines(file.path(project, "_quarto.yml"), warn = FALSE), value = TRUE)
  dir <- if (length(conf)) sub("^[[:space:]]*output-dir:[[:space:]]*([^#[:space:]]+).*$", "\\1", conf[1]) else "_site"
  out_dir <- file.path(project, gsub("^[\"']|[\"']$", "", dir))
}

# During a render Quarto lists the files it just wrote, one per line, in
# QUARTO_PROJECT_OUTPUT_FILES; or, when QUARTO_USE_FILE_FOR_PROJECT_OUTPUT_FILES
# is set, it writes that list to the file this variable names instead.
scope <- if (Sys.getenv("QUARTO_PROJECT_RENDER_ALL") == "1") {
  "whole project"
} else if (in_render) {
  "partial render, not a full check"
} else {
  "files already in _site, not a fresh render"
}
if (in_render) {
  list_file <- Sys.getenv("QUARTO_USE_FILE_FOR_PROJECT_OUTPUT_FILES")
  listed <- if (nzchar(list_file)) {
    if (!file.exists(list_file)) fail(paste0("check-output: nothing was checked, so this is not a pass. ",
                                              "The output list ", list_file, " does not exist."))
    readLines(list_file, warn = FALSE)
  } else {
    strsplit(Sys.getenv("QUARTO_PROJECT_OUTPUT_FILES"), "\n", fixed = TRUE)[[1]]
  }
  listed <- listed[nzchar(listed)]
  if (!length(listed)) fail("check-output: nothing was checked, so this is not a pass. The render listed no output files.")
  files <- ifelse(grepl("^(/|[A-Za-z]:)", listed), listed, file.path(project, listed))
  if (!any(grepl("\\.html$", files))) {
    cat("check-output: skipped, this render produced no HTML\n")
    quit(status = 0)
  }
  files <- files[grepl("\\.html$", files)]
} else {
  files <- list.files(out_dir, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
}
missing <- files[!file.exists(files)]
if (!length(files) || length(missing)) {
  fail(paste0("check-output: nothing was checked, so this is not a pass. ",
              if (length(missing)) paste0("Listed output not found: ", paste(missing, collapse = ", "))
              else paste0("No .html files to check under ", out_dir, ".")))
}

rel <- function(f) sub(paste0(project, "/"), "", normalizePath(f, winslash = "/"), fixed = TRUE)

# Show a match safely: ASCII as is, every other byte as <xx>.
show_bytes <- function(s) {
  b <- as.integer(charToRaw(s))
  paste(ifelse(b >= 32 & b < 127, vapply(b, function(x) rawToChar(as.raw(x)), ""),
               sprintf("<%02x>", b)), collapse = "")
}

report <- function(text, ch, f) {
  m <- gregexpr(ch$pattern, text, perl = TRUE, useBytes = TRUE)[[1]]
  if (m[1] < 0) return(NULL)
  nl <- gregexpr("\n", text, fixed = TRUE, useBytes = TRUE)[[1]]
  line <- sum(nl > 0 & nl < m[1]) + 1
  sprintf("  %s, line %d%s: %s\n    %s\n    likely cause: %s", rel(f), line,
          if (length(m) > 1) sprintf(" and %d more", length(m) - 1) else "", ch$name,
          show_bytes(substr(text, m[1], m[1] + attr(m, "match.length")[1] - 1)), ch$cause)
}

# Replace matched regions with spaces, keeping newlines and byte length, so
# line numbers still point at the right place. `keep` spares a match; all the
# rest are replaced in one pass.
blank <- function(text, pattern, keep = function(start, s) FALSE) {
  m <- gregexpr(pattern, text, perl = TRUE, useBytes = TRUE)
  if (m[[1]][1] < 0) return(text)
  regmatches(text, m) <- list(mapply(function(st, s) if (keep(st, s)) s else gsub("[^\n]", " ", s, useBytes = TRUE),
                                     m[[1]], regmatches(text, m)[[1]], USE.NAMES = FALSE))
  text
}

code <- "(?s)<pre[^>]*>.*?</pre>|<code[^>]*>.*?</code>"
pre  <- "(?s)<pre[^>]*>.*?</pre>"
# Scripts and styles, but not JSON data blocks such as htmlwidgets', whose
# contents can be shown on the page. Skipped by the two inline R checks, where
# JavaScript template literals look like `r x`, and kept for the encoding
# checks, where damage is damage wherever it is. The type attribute must follow
# whitespace, so data-type="application/json" on a real script does not count.
script <- paste0("(?is)<script\\b(?![^>]*\\stype\\s*=\\s*[\"']?application/json)[^>]*>.*?</script\\s*>",
                 "|<style\\b[^>]*>.*?</style\\s*>")
# The analytics script, as a real tag: the escaped text of one shown on a page
# does not count. The code must be this site's own, because the script posts
# every page view to the subdomain it names, and a placeholder such as the
# YOURCODE it once shipped with is a subdomain anyone could register.
goatcounter <- "<script\\b[^>]*\\sdata-goatcounter=[\"']https://amelia-m\\.goatcounter\\.com/count[\"']"
found <- character()
for (f in files) {
  if (file.size(f) == 0) {
    found <- c(found, sprintf("  %s: zero-length file\n    likely cause: the page failed to write, or was truncated", rel(f)))
    next
  }
  text <- readChar(f, file.size(f), useBytes = TRUE)
  Encoding(text) <- "bytes"
  # Every page is counted through the include-in-header in _quarto.yml.
  # Vendored HTML under site_libs/ is not a page.
  if (!grepl("(^|/)site_libs/", rel(f)) &&
      !grepl(goatcounter, text, perl = TRUE, useBytes = TRUE)) {
    found <- c(found, sprintf(paste0("  %s: no GoatCounter script counting to amelia-m\n    likely cause: ",
                                     "_includes/analytics.html, or the include-in-header in _quarto.yml that ",
                                     "pulls it in, was changed or removed"), rel(f)))
  }
  # Chunk output is a <pre> inside a cell-output div: directly, or, when the
  # output is highlighted (class-output), inside the copy-button scaffold and
  # sourceCode divs Quarto wraps it in. Shown source code sits in a "cell"
  # div instead, so it is still skipped. <pre> blocks and inline code spans
  # are matched together, left to right, so a span inside a block is taken
  # with its block.
  is_output <- function(start, s) {
    startsWith(s, "<pre") &&
      grepl("<div[^>]*class=\"[^\"]*cell-output[^\"]*\"[^>]*>\\s*(?:<div[^>]*>\\s*)*$",
            substr(text, max(1, start - 400), start - 1), perl = TRUE, useBytes = TRUE)
  }
  prose_and_output <- blank(text, code, keep = is_output)  # shown code skipped
  no_script <- blank(text, script)
  prose_only <- blank(no_script, code)                      # all code skipped
  prose_and_spans <- blank(no_script, pre)                  # inline spans kept
  for (ch in c(byte_checks, text_checks)) found <- c(found, report(prose_and_output, ch, f))
  found <- c(found, report(prose_only, literal_r, f), report(prose_and_spans, unrun_r, f))
}

if (length(found)) {
  fail(paste0("check-output: the output is broken (", scope, "):\n",
              paste(found, collapse = "\n")))
}
cat(sprintf("check-output: %d file%s clean (%s)\n", length(files),
            if (length(files) == 1) "" else "s", scope))

})
