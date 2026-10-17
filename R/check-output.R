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
# apart was left out. One that was: R's NA printed as text, which on an R
# blog is indistinguishable from writing about NA. That belongs where the data
# enters R/site.R, not in a scan of the HTML.
#
# Every check skips source code shown on a page, so a post can show any of
# these strings on purpose. Prose and chunk output are checked: chunk output is
# where R's own breakage lands. Two checks were dropped because broken output
# and correct output look the same: R's NA printed as text (see TODO.md), and
# an unexpanded shortcode, which renders exactly like Quarto's documented
# escape for showing one.
#
# Finding nothing to check is a failure, not a pass. Base R only. Run it by
# hand from anywhere in the project with `Rscript R/check-output.R`.

# UTF-8 decoded as Latin-1 or Windows-1252 and encoded again: the lead byte of
# a multi-byte character becomes a letter, followed by a symbol or punctuation
# mark. Only combinations that real text does not produce are listed, so
# "Gauß–Markov", "3× daily", "með”" or a French "â" before a quote all pass:
#   Â Ã  + a Latin-1 symbol or Windows-1252 mark (Â©, Ã©, Ã€, Ã¡)
#   Î Ï  + the same, without curly quotes (Greek: Î², Ï€)
#   Ä Å  + the same, without curly quotes or a no-break space (Central
#          European: Å‚, Å¡, Ä‡)
#   â    + € ‚ „ † ‡ ‰ (three-byte characters: â€™, â„¢, â†’)
#   ð    + Ÿ (emoji: ðŸ˜€)
latin1 <- "\\xc2[\\xa0-\\xbf]"
marks  <- "\\xe2\\x82\\xac|\\xe2\\x80[\\x93\\x94\\x9a\\x9e\\xa0\\xa1\\xa2\\xa6\\xb0\\xb9\\xba]|\\xe2\\x84\\xa2|\\xc5[\\x92\\x93\\xa0\\xa1\\xb8\\xbd\\xbe]|\\xc6\\x92|\\xcb[\\x86\\x9c]"
quotes <- "\\xe2\\x80[\\x98\\x99\\x9c\\x9d]"
mojibake <- paste0(
  "\\xc3[\\x82\\x83](", latin1, "|", marks, "|", quotes, ")",
  "|\\xc3[\\x8e\\x8f](", latin1, "|", marks, ")",
  "|\\xc3[\\x84\\x85](\\xc2[\\xa1-\\xbf]|", marks, ")",
  "|\\xc3\\xa2(\\xe2\\x82\\xac|\\xe2\\x80[\\x9a\\x9e\\xa0\\xa1\\xb0])",
  "|\\xc3\\xb0\\xc5\\xb8")

byte_checks <- list(
  list(name = "replacement character U+FFFD", pattern = "\\xef\\xbf\\xbd",
       cause = "text was decoded with the wrong encoding somewhere before output"),
  list(name = "C1 control character", pattern = "\\xc2[\\x80-\\x9f]",
       cause = "UTF-8 text was decoded as Latin-1, which turns part of every non-ASCII character into an invisible control code"),
  list(name = "mojibake: UTF-8 read as Latin-1 or Windows-1252", pattern = mojibake,
       cause = "a UTF-8 file was read as Latin-1 or Windows-1252 and written back out")
)

text_checks <- list(
  list(name = "escaped code point such as <U+2013>",
       pattern = "(&lt;|<|%3[Cc])U\\+[0-9A-Fa-f]{4}",
       cause = "R wrote non-ASCII text under a non-UTF-8 locale; see the locale switch at the top of R/site.R"),
  list(name = "octal byte escape such as \\342\\200\\223",
       pattern = "\\\\3[0-7]{2}\\\\[0-7]{3}",
       cause = "R printed non-ASCII text under a non-UTF-8 locale; see the locale switch at the top of R/site.R"),
  list(name = "inline R left as literal text", pattern = "`r [A-Za-z_.]",
       cause = "an inline R call passed through md() or another escape, so knitr never saw it")
)

# Unevaluated inline R renders as an inline code span starting "r ", so this
# is looked for in prose code spans only: never in <pre> blocks, where chunk
# output such as "r = 0.42" is routine. Inline R shown on purpose keeps its
# backticks inside the span (`` `r x` `` gives <code>`r x`</code>) and so does
# not match.
unrun_r <- list(name = "inline R left unevaluated",
                pattern = "<code[^>]*>(r [^<\\s]|\\{r\\} )",
                cause = "a `r ...` call sits where knitr does not run it, such as a YAML field printed with cat()")

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
# During a render Quarto says where the output went; a hand run reads
# `output-dir` from _quarto.yml instead of assuming _site.
out_dir <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR")
if (!nzchar(out_dir)) {
  conf <- grep("^[[:space:]]*output-dir:", readLines(file.path(project, "_quarto.yml"), warn = FALSE), value = TRUE)
  out_dir <- file.path(project, if (length(conf)) sub("^[[:space:]]*output-dir:[[:space:]]*([^#[:space:]]+).*$", "\\1", conf[1]) else "_site")
}

# During a render Quarto lists the files it just wrote, one per line, in
# QUARTO_PROJECT_OUTPUT_FILES; or, when QUARTO_USE_FILE_FOR_PROJECT_OUTPUT_FILES
# is set, it writes that list to the file this variable names instead.
list_file <- Sys.getenv("QUARTO_USE_FILE_FOR_PROJECT_OUTPUT_FILES")
in_render <- nzchar(list_file) || nzchar(Sys.getenv("QUARTO_PROJECT_OUTPUT_FILES")) ||
  nzchar(Sys.getenv("QUARTO_PROJECT_RENDER_ALL"))
listed <- if (nzchar(list_file)) {
  if (!file.exists(list_file)) fail(paste0("check-output: nothing was checked, so this is not a pass. ",
                                            "The output list ", list_file, " does not exist."))
  readLines(list_file, warn = FALSE)
} else {
  strsplit(Sys.getenv("QUARTO_PROJECT_OUTPUT_FILES"), "\n", fixed = TRUE)[[1]]
}
listed <- listed[nzchar(listed)]
scope <- if (Sys.getenv("QUARTO_PROJECT_RENDER_ALL") == "1") {
  "whole project"
} else if (in_render) {
  "partial render, not a full check"
} else {
  "files already in _site, not a fresh render"
}

if (in_render) {
  if (!length(listed)) fail("check-output: nothing was checked, so this is not a pass. The render listed no output files.")
  files <- ifelse(grepl("^(/|[A-Za-z]:)", listed), listed, file.path(project, listed))
  if (length(files) && !any(grepl("\\.html$", files))) {
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

# Show a match safely: ASCII as is, every other byte as <xx>.
show <- function(s) {
  b <- as.integer(charToRaw(s))
  paste(ifelse(b >= 32 & b < 127, vapply(b, function(x) rawToChar(as.raw(x)), ""),
               sprintf("<%02x>", b)), collapse = "")
}

report <- function(text, ch, f) {
  m <- gregexpr(ch$pattern, text, perl = TRUE, useBytes = TRUE)[[1]]
  if (m[1] < 0) return(NULL)
  nl <- gregexpr("\n", text, fixed = TRUE, useBytes = TRUE)[[1]]
  line <- sum(nl > 0 & nl < m[1]) + 1
  sprintf("  %s, line %d%s: %s\n    %s\n    likely cause: %s",
          sub(paste0(project, "/"), "", normalizePath(f, winslash = "/"), fixed = TRUE), line,
          if (length(m) > 1) sprintf(" and %d more", length(m) - 1) else "", ch$name,
          show(substr(text, m[1], m[1] + attr(m, "match.length")[1] - 1)), ch$cause)
}

# Replace matched regions with spaces, keeping newlines and byte length, so
# line numbers still point at the right place. `keep` spares a match; all the
# rest are replaced in one pass.
blank <- function(text, pattern, keep = function(start, s) FALSE) {
  m <- gregexpr(pattern, text, perl = TRUE, useBytes = TRUE)
  if (m[[1]][1] < 0) return(text)
  starts <- m[[1]]
  regmatches(text, m) <- list(mapply(function(st, s) if (keep(st, s)) s else gsub("[^\n]", " ", s, useBytes = TRUE),
                                     starts, regmatches(text, m)[[1]], USE.NAMES = FALSE))
  text
}

found <- character()
for (f in files) {
  if (file.size(f) == 0) {
    found <- c(found, sprintf("  %s: empty file\n    likely cause: the page failed to write, or was truncated",
                              sub(paste0(project, "/"), "", normalizePath(f, winslash = "/"), fixed = TRUE)))
    next
  }
  text <- readChar(f, file.size(f), useBytes = TRUE)
  Encoding(text) <- "bytes"
  # Skip source code shown on the page. <pre> blocks and inline code spans are
  # matched together, left to right, so a span inside a block is taken with
  # its block. Chunk output, a <pre> directly inside a cell-output div, stays.
  is_output <- function(start, s) {
    startsWith(s, "<pre") &&
      grepl("<div[^>]*class=\"[^\"]*cell-output[^\"]*\"[^>]*>\\s*$",
            substr(text, max(1, start - 300), start - 1), perl = TRUE, useBytes = TRUE)
  }
  code <- "(?s)<pre[^>]*>.*?</pre>|<code[^>]*>.*?</code>"
  prose <- blank(text, code, keep = is_output)
  for (ch in c(byte_checks, text_checks)) found <- c(found, report(prose, ch, f))
  # Inline R that never ran is itself an inline code span, so it is looked
  # for with every <pre> block blanked and inline spans left in place.
  spans <- blank(text, "(?s)<pre[^>]*>.*?</pre>")
  found <- c(found, report(spans, unrun_r, f))
}

if (length(found)) {
  fail(paste0("check-output: the output is broken (", scope, "):\n",
              paste(found, collapse = "\n")))
}
cat(sprintf("check-output: %d file%s clean (%s)\n", length(files),
            if (length(files) == 1) "" else "s", scope))
