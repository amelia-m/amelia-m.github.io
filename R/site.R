# Shared helpers for pages that render the generated data in _data/.
# Base R + jsonlite only.

# Quarto does not set a locale: R inherits the shell's. In a cloud session that
# is POSIX, and output written through cat() then turns every non-ASCII
# character into literal "<U+2013>" text. The render still completes, so the
# corruption is easy to miss: 66 such characters on the CV page alone, found
# 2026-10-17. This switches the character locale for every page that sources
# this file, during a render only, so an interactive source() for bio_report()
# or work_areas() is left alone. A no-op wherever the locale is already UTF-8,
# which includes R 4.2 and later on Windows. If no UTF-8 locale can be set it
# stops, since a render that succeeds with mangled characters is worse than
# one that fails and _quarto.yml hides warnings from the page.
#
# use_utf8_ctype() does the switching; R/confirm-attendance.R calls it too, for
# the questions it prints before any page renders. TRUE if the character
# locale is UTF-8 afterwards.
use_utf8_ctype <- function() {
  if (isTRUE(l10n_info()[["UTF-8"]])) return(TRUE)
  for (loc in c("C.UTF-8", "C.utf8", "en_US.UTF-8", "en_US.utf8")) {
    if (nzchar(suppressWarnings(Sys.setlocale("LC_CTYPE", loc)))) break
  }
  isTRUE(l10n_info()[["UTF-8"]])
}
if (isTRUE(getOption("knitr.in.progress")) && !use_utf8_ctype()) {
  stop("No UTF-8 locale could be set, so non-ASCII text would render as <U+...>. ",
       "Set LC_ALL to a UTF-8 locale listed by `locale -a` and render again.",
       call. = FALSE)
}

site_root <- function() {
  root <- Sys.getenv("QUARTO_PROJECT_DIR")
  if (nzchar(root)) return(root)
  d <- normalizePath(getwd(), winslash = "/")
  while (!file.exists(file.path(d, "_quarto.yml"))) {
    parent <- dirname(d)
    if (identical(parent, d)) stop("_quarto.yml not found above ", getwd())
    d <- parent
  }
  d
}

site_path <- function(...) file.path(site_root(), ...)

cv_data <- function(name) {
  jsonlite::read_json(site_path("_data", paste0(name, ".json")), simplifyVector = TRUE)
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || identical(a, "")) b else a

# read_yaml_utf8() reads through readLines() in the session's locale, so under
# a C locale it truncates a value at the first non-ASCII byte: the en dash in
# "Nebraska-Lincoln" cut a 484 character bio down to 102. The locale switch at
# the top of this file only runs during a render, so this still matters for an
# interactive source(): reading the bytes and marking them UTF-8 makes these
# files parse the same whatever R is set to. likes.yml needs this too.
read_yaml_utf8 <- function(path) {
  yaml::yaml.load(paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n"))
}

# Markdown-safe text: backslash-escape every ASCII punctuation character
# Pandoc could read as markup (emphasis, code, links, raw HTML, math,
# citations, headings, sub/superscript, tables). Backslash goes first.
md <- function(x) {
  x <- ifelse(is.na(x), "", as.character(x))
  gsub("([\\\\*_`<>\\[\\]$@#~^|])", "\\\\\\1", x, perl = TRUE)
}

# Append a period unless the text already ends in terminal punctuation.
end_period <- function(x) {
  x <- trimws(x)
  if (!nzchar(x) || grepl("[.?!]$", x)) x else paste0(x, ".")
}

# "a", "a and b", "a, b, and c". Collapsing on " and " was fine while there
# were only ever two of anything; it reads as "a and b and c" from three on.
and_list <- function(x) {
  n <- length(x)
  if (n < 2) return(paste0(x, collapse = ""))
  if (n == 2) return(paste(x, collapse = " and "))
  paste0(paste(x[-n], collapse = ", "), ", and ", x[n])
}

# ---- BibTeX field text -> plain Unicode text --------------------------------

.greek <- c(
  alpha = "α", beta = "β", gamma = "γ", delta = "δ",
  epsilon = "ε", zeta = "ζ", eta = "η", theta = "θ",
  kappa = "κ", lambda = "λ", mu = "μ", nu = "ν",
  xi = "ξ", pi = "π", rho = "ρ", sigma = "σ",
  tau = "τ", phi = "φ", chi = "χ", psi = "ψ",
  omega = "ω", Gamma = "Γ", Delta = "Δ", Theta = "Θ",
  Lambda = "Λ", Pi = "Π", Sigma = "Σ", Phi = "Φ",
  Psi = "Ψ", Omega = "Ω"
)

.latex_symbols <- c(
  textregistered = "®", texttrademark = "™", textcopyright = "©",
  copyright = "©", ldots = "…", dots = "…", textendash = "–",
  textemdash = " - ", ss = "ß", o = "ø", O = "Ø", ae = "æ",
  AE = "Æ", aa = "å", AA = "Å", l = "ł", L = "Ł",
  pm = "±", times = "×", deg = "°", textdegree = "°"
)

# Combining marks for LaTeX accent commands (rendered as base letter + mark).
.latex_accents <- c(
  "'" = "́", "`" = "̀", "^" = "̂", "\"" = "̈",
  "~" = "̃", "=" = "̄", "." = "̇", c = "̧",
  v = "̌", u = "̆", H = "̋", r = "̊"
)

latex_text <- function(x) {
  if (is.null(x) || !length(x) || is.na(x[1])) return("")
  x <- paste(as.character(x), collapse = " ")
  # Escaped specials: park the ones that collide with later steps.
  x <- gsub("\\$", "\001", x, fixed = TRUE)
  x <- gsub("\\{", "\002", x, fixed = TRUE)
  x <- gsub("\\}", "\003", x, fixed = TRUE)
  x <- gsub("\\\\([&%#_])", "\\1", x)
  # URLs, bare or in \url{}, keep their ~ and -- (a personal page under
  # ~name, a slug with a double hyphen): park them until the end.
  x <- gsub("\\\\url\\{([^}]*)\\}", "\\1", x)
  um <- gregexpr("https?://[^[:space:]{}]+", x)
  urls <- regmatches(x, um)[[1]]
  regmatches(x, um) <- list(sprintf("\004%d\004", seq_along(urls)))
  # Dotless i and j, as accents are written over them: {\'\i} is í.
  x <- gsub("\\\\([ij])(?![A-Za-z])", "\\1", x, perl = TRUE)
  # Math delimiters \( \) and $ ... $: keep the content.
  x <- gsub("\\(", "", x, fixed = TRUE)
  x <- gsub("\\)", "", x, fixed = TRUE)
  x <- gsub("$", "", x, fixed = TRUE)
  for (nm in names(.greek)) {
    x <- gsub(paste0("\\\\", nm, "(?![A-Za-z])[ ]?"), .greek[[nm]], x, perl = TRUE)
  }
  # Accents: \'e, \'{e}, {\'e}, \c{c}, \v s
  for (a in names(.latex_accents)) {
    pat <- if (grepl("[A-Za-z]", a)) {
      paste0("\\\\", a, "(?:\\{([A-Za-z])\\}|[ ]+([A-Za-z]))")
    } else {
      paste0("\\\\\\Q", a, "\\E\\{?([A-Za-z])\\}?")
    }
    m <- gregexpr(pat, x, perl = TRUE)
    regmatches(x, m) <- lapply(regmatches(x, m), function(hits) {
      vapply(hits, function(h) {
        letter <- sub(".*([A-Za-z])\\}?$", "\\1", h)
        paste0(letter, .latex_accents[[a]])
      }, character(1), USE.NAMES = FALSE)
    })
  }
  for (nm in names(.latex_symbols)) {
    x <- gsub(paste0("\\\\", nm, "(?![A-Za-z])(\\{\\})?[ ]?"), .latex_symbols[[nm]], x, perl = TRUE)
  }
  x <- gsub("\\\\\\\\", " ", x)                  # \\ line break
  x <- gsub("\\\\[ ]", " ", x)                    # control space, as in "vs.\ "
  x <- gsub("\\\\[A-Za-z]+[ ]?", "", x)           # remaining commands, e.g. \emph
  x <- gsub("``", "“", x, fixed = TRUE)
  x <- gsub("''", "”", x, fixed = TRUE)
  x <- gsub("[[:space:]]*---[[:space:]]*", " - ", x)
  x <- gsub("--", "–", x, fixed = TRUE)
  x <- gsub("~", " ", x, fixed = TRUE)
  x <- gsub("[{}]", "", x)
  # URLs back before the escaped specials, which a URL can contain too.
  for (i in seq_along(urls)) x <- sub(sprintf("\004%d\004", i), urls[i], x, fixed = TRUE)
  x <- chartr("\001\002\003", "${}", x)
  trimws(gsub("[[:space:]]+", " ", x))
}

# Raw field values of a .bib file, keyed by entry id. Pandoc's BibTeX reader
# rewrites titles to sentence case (lowercasing unbraced words, capitalizing
# after a period), so text fields are taken from the file itself.
read_bib_fields <- function(path) {
  txt <- paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  ch <- strsplit(txt, "", fixed = TRUE)[[1]]
  n <- length(ch)
  bad <- function(msg) stop("Cannot parse ", path, ": ", msg, call. = FALSE)
  is_space <- function(c) c %in% c(" ", "\t", "\n", "\r")
  starts <- gregexpr("@[A-Za-z]+[[:space:]]*\\{", txt)[[1]]
  res <- list()
  if (starts[1] == -1) return(res)
  lens <- attr(starts, "match.length")
  last_end <- 0L
  for (k in seq_along(starts)) {
    if (starts[k] <= last_end) next
    type <- tolower(gsub("[@{[:space:]]", "", substr(txt, starts[k], starts[k] + lens[k] - 1L)))
    i <- starts[k] + lens[k]
    if (type %in% c("comment", "preamble", "string")) {
      depth <- 1L
      while (i <= n && depth > 0L) {
        if (ch[i] == "{") depth <- depth + 1L else if (ch[i] == "}") depth <- depth - 1L
        i <- i + 1L
      }
      last_end <- i - 1L
      next
    }
    j <- i
    while (j <= n && !(ch[j] %in% c(",", "}"))) j <- j + 1L
    if (j > n || j == i) bad(sprintf("entry at character %d has no key", starts[k]))
    key <- trimws(paste(ch[i:(j - 1L)], collapse = ""))
    i <- j
    fields <- list()
    repeat {
      while (i <= n && (is_space(ch[i]) || ch[i] == ",")) i <- i + 1L
      if (i > n) bad(sprintf("entry '%s' is not closed", key))
      if (ch[i] == "}") break
      j <- i
      while (j <= n && grepl("[A-Za-z0-9_:.+-]", ch[j])) j <- j + 1L
      if (j == i) bad(sprintf("unexpected '%s' in entry '%s'", ch[i], key))
      name <- tolower(paste(ch[i:(j - 1L)], collapse = ""))
      i <- j
      while (i <= n && is_space(ch[i])) i <- i + 1L
      if (i > n || ch[i] != "=") bad(sprintf("field '%s' in entry '%s' has no '='", name, key))
      i <- i + 1L
      while (i <= n && is_space(ch[i])) i <- i + 1L
      if (i > n) bad(sprintf("field '%s' in entry '%s' has no value", name, key))
      if (ch[i] %in% c("{", "\"")) {
        close <- if (ch[i] == "{") "}" else "\""
        depth <- 0L
        j <- i + 1L
        while (j <= n) {
          c1 <- ch[j]
          if (c1 == "\\") { j <- j + 2L; next }
          if (depth == 0L && c1 == close) break
          if (c1 == "{") depth <- depth + 1L else if (c1 == "}") depth <- depth - 1L
          j <- j + 1L
        }
        if (j > n) bad(sprintf("field '%s' in entry '%s' is not closed", name, key))
        value <- if (j > i + 1L) paste(ch[(i + 1L):(j - 1L)], collapse = "") else ""
        i <- j + 1L
      } else {
        j <- i
        while (j <= n && !(ch[j] %in% c(",", "}"))) j <- j + 1L
        value <- trimws(paste(ch[i:(j - 1L)], collapse = ""))
        i <- j
      }
      fields[[name]] <- value
    }
    res[[key]] <- fields
    last_end <- i
  }
  res
}

# ---- Reading --------------------------------------------------------------

pandoc_bin <- function() {
  env <- Sys.getenv("QUARTO_BIN_PATH")
  candidates <- c(
    if (nzchar(env)) file.path(env, "tools", c("pandoc.exe", "pandoc", file.path("x86_64", "pandoc.exe"), file.path("x86_64", "pandoc"))),
    Sys.which("pandoc")
  )
  hit <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (length(hit)) return(list(cmd = hit[1], pre = character()))
  q <- Sys.which("quarto")
  if (nzchar(q)) return(list(cmd = q, pre = "pandoc"))
  stop("pandoc not found (checked QUARTO_BIN_PATH, PATH, and quarto)")
}

# Read a .bib into a list of CSL-JSON items via pandoc. Each item also carries
# the file's raw field values in item[["_bib"]].
read_bib <- function(file) {
  path <- site_path("_data", file)
  if (!file.exists(path)) stop("Bibliography file not found: ", path, call. = FALSE)
  pb <- tryCatch(pandoc_bin(), error = function(e) {
    stop("Cannot convert ", path, ": ", conditionMessage(e), call. = FALSE)
  })
  errf <- tempfile("pandoc-stderr-", fileext = ".txt")
  on.exit(unlink(errf), add = TRUE)
  launch <- NULL
  out <- withCallingHandlers(
    tryCatch(
      system2(pb$cmd, c(pb$pre, shQuote(path), "-f", "bibtex", "-t", "csljson"),
              stdout = TRUE, stderr = errf),
      error = function(e) { launch <<- conditionMessage(e); structure(character(), status = 127L) }
    ),
    warning = function(w) invokeRestart("muffleWarning")
  )
  status <- attr(out, "status") %||% 0L
  err <- if (file.exists(errf)) trimws(paste(readLines(errf, warn = FALSE), collapse = "\n")) else ""
  if (!is.null(launch)) err <- trimws(paste(err, launch))
  detail <- if (nzchar(err)) paste0("\npandoc stderr:\n", err) else "\n(pandoc wrote nothing to stderr)"
  if (!identical(as.integer(status), 0L)) {
    stop(sprintf("pandoc failed on %s (exit status %s; command: %s)%s",
                 path, status, pb$cmd, detail), call. = FALSE)
  }
  json <- paste(out, collapse = "\n")
  if (!nzchar(trimws(json))) {
    stop(sprintf("pandoc returned no output for %s (command: %s)%s", path, pb$cmd, detail), call. = FALSE)
  }
  Encoding(json) <- "UTF-8"
  items <- tryCatch(
    jsonlite::fromJSON(json, simplifyVector = FALSE),
    error = function(e) {
      stop(sprintf("pandoc output for %s is not valid CSL JSON: %s\nFirst 200 characters: %s",
                   path, conditionMessage(e), substr(json, 1, 200)), call. = FALSE)
    }
  )
  if (!is.list(items) || (length(items) && is.null(names(items[[1]])))) {
    stop("pandoc output for ", path, " is not a list of CSL items", call. = FALSE)
  }
  raw <- read_bib_fields(path)
  lapply(items, function(it) {
    it[["_bib"]] <- raw[[it[["id"]] %||% ""]]
    it
  })
}

# ---- Formatting -----------------------------------------------------------

# First non-empty value among raw bib fields, then CSL fields, as plain text.
item_field <- function(it, bib = character(), csl = character()) {
  raw <- it[["_bib"]]
  for (f in bib) {
    v <- latex_text(raw[[f]])
    if (nzchar(v)) return(v)
  }
  for (f in csl) {
    v <- it[[f]]
    if (is.character(v) && length(v) == 1) {
      v <- latex_text(v)
      if (nzchar(v)) return(v)
    }
  }
  ""
}

item_year <- function(it) {
  y <- tryCatch(it$issued$`date-parts`[[1]][[1]], error = function(e) NA)
  y <- suppressWarnings(as.integer(y))
  if (length(y) != 1 || is.na(y)) y <- suppressWarnings(as.integer(sub("^\\D*(\\d{4}).*$", "\\1", it[["_bib"]][["year"]] %||% "")))
  if (length(y) != 1) NA_integer_ else y
}

month_number <- function(x) {
  x <- tolower(trimws(x %||% ""))
  if (!nzchar(x)) return(NA_integer_)
  if (grepl("^[0-9]", x)) {
    m <- as.integer(sub("^([0-9]+).*$", "\\1", x))
    return(if (m >= 1 && m <= 12) m else NA_integer_)
  }
  hit <- regmatches(x, regexpr("[a-z]{3}", x))
  if (!length(hit)) NA_integer_ else match(hit, tolower(month.abb))
}

# Sort parts from CSL date-parts, falling back to the raw bib month/day.
item_date <- function(it) {
  dp <- tryCatch(unlist(it$issued$`date-parts`[[1]]), error = function(e) NULL)
  dp <- suppressWarnings(as.integer(dp))
  mo <- if (length(dp) >= 2) dp[2] else month_number(it[["_bib"]][["month"]])
  dy <- if (length(dp) >= 3) dp[3] else suppressWarnings(as.integer(it[["_bib"]][["day"]] %||% NA))
  c(year = item_year(it), month = mo, day = if (length(dy) == 1) dy else NA_integer_)
}

# Month as displayed: bib text ("April", "May--June") or a macro/number.
item_month_label <- function(it) {
  raw <- trimws(it[["_bib"]][["month"]] %||% "")
  if (!nzchar(raw)) {
    dp <- tryCatch(unlist(it$issued$`date-parts`[[1]]), error = function(e) NULL)
    return(if (length(dp) >= 2) month.name[as.integer(dp[2])] else "")
  }
  if (grepl("^[0-9]{1,2}$", raw) || grepl("^[A-Za-z]{3}$", raw)) {
    m <- month_number(raw)
    return(if (is.na(m)) latex_text(raw) else month.name[m])
  }
  latex_text(raw)
}

months_in <- function(x) {
  x <- tolower(x)
  month.name[vapply(seq_along(month.name), function(i) {
    grepl(paste0("\\b(", tolower(month.name[i]), "|", tolower(month.abb[i]), ")\\b"), x, perl = TRUE)
  }, logical(1))]
}

format_authors <- function(authors) {
  if (is.null(authors)) return("")
  nm <- vapply(authors, function(a) {
    fam <- latex_text(a[["family"]] %||% a[["literal"]] %||% "")
    giv <- latex_text(a[["given"]] %||% "")
    initials <- paste0(substr(strsplit(giv, "[ .-]+")[[1]], 1, 1), collapse = "")
    s <- trimws(paste(md(fam), initials))
    if (identical(fam, "Miramonti")) paste0("**", s, "**") else s
  }, character(1))
  paste(nm, collapse = ", ")
}

doi_url <- function(doi) {
  enc <- utils::URLencode(doi, reserved = TRUE)
  paste0("https://doi.org/", gsub("%2F", "/", enc, ignore.case = TRUE))
}

format_item <- function(it, notes = TRUE) {
  yr <- item_year(it)
  raw <- it[["_bib"]]
  title <- item_field(it, "title", "title")
  venue <- item_field(it, c("booktitle", "journal"), c("container-title", "event-title", "event"))
  note <- if (notes) item_field(it, "note", "note") else ""
  conference <- !is.null(raw[["booktitle"]]) || identical(it[["type"]], "paper-conference")

  where <- if (conference) {
    place <- item_field(it, c("address", "location"), "publisher-place")
    month <- item_month_label(it)
    # Skip the month when the note already names it ("Presented April 10").
    if (nzchar(month) && nzchar(note) && length(intersect(months_in(month), months_in(note)))) month <- ""
    parts <- c(if (nzchar(venue)) paste0("*", md(venue), "*"), if (nzchar(place)) md(place), if (nzchar(month)) md(month))
    if (length(parts)) paste(parts, collapse = ", ") else ""
  } else {
    vol <- item_field(it, "volume", "volume")
    iss <- item_field(it, "number", "issue")
    pg <- item_field(it, "pages", "page")
    paste0(
      if (nzchar(venue)) paste0("*", md(venue), "*") else "",
      if (nzchar(vol)) paste0(if (nzchar(venue)) ", ", "*", md(vol), "*") else "",
      if (nzchar(iss)) paste0("(", md(iss), ")") else "",
      if (nzchar(pg)) paste0(", ", md(pg)) else ""
    )
  }
  if (nzchar(where) && !grepl("[.?!]\\*?$", where)) where <- paste0(where, ".")

  doi <- it[["DOI"]] %||% raw[["doi"]] %||% ""
  doi <- if (is.character(doi) && length(doi) == 1) trimws(doi) else ""

  out <- paste0(
    format_authors(it[["author"]]), " (", if (is.na(yr)) "n.d." else yr, "). ",
    md(end_period(title))
  )
  if (nzchar(where)) out <- paste0(out, " ", where)
  if (nzchar(note)) out <- paste0(out, " *", md(end_period(note)), "*")
  if (nzchar(doi)) out <- paste0(out, " [doi:", md(doi), "](", doi_url(doi), ")")
  out
}

# Print a reverse-chronological reference list grouped by year: newest year,
# month, and day first, then title; undated entries last.
print_bib <- function(file, notes = TRUE) {
  items <- read_bib(file)
  if (!length(items)) {
    cat("*0 entries*\n\n")
    return(invisible())
  }
  dates <- vapply(items, item_date, integer(3))
  titles <- vapply(items, function(it) tolower(item_field(it, "title", "title")), character(1))
  key <- function(v) ifelse(is.na(v), -1L, v)
  ord <- order(-key(dates["year", ]), -key(dates["month", ]), -key(dates["day", ]), titles,
               method = "radix")
  items <- items[ord]
  yrs <- dates["year", ord]
  cat(sprintf("*%d entries*\n\n", length(items)))
  for (y in unique(yrs)) {
    cat("## ", if (is.na(y)) "Undated" else y, "\n\n", sep = "")
    for (it in items[yrs %in% y]) cat("- ", format_item(it, notes = notes), "\n", sep = "")
    cat("\n")
  }
}

# ---- Links ---------------------------------------------------------------
# links.yml is the single source for profile, contact, and project links.

site_links <- function() {
  groups <- read_yaml_utf8(site_path("links.yml"))
  rows <- lapply(names(groups), function(g) {
    do.call(rbind, lapply(groups[[g]], function(l) data.frame(
      group = g, id = l$id, label = l$label, url = l$url,
      text = if (is.null(l$text)) l$label else l$text,
      icon = if (is.null(l$icon)) "" else l$icon,
      icon_ai = if (is.null(l$icon_ai)) "" else l$icon_ai,
      stringsAsFactors = FALSE
    )))
  })
  out <- do.call(rbind, rows)
  dup <- out$id[duplicated(out$id)]
  if (length(dup)) stop("Duplicate ids in links.yml: ", paste(dup, collapse = ", "))
  out
}

get_link <- function(id) {
  l <- site_links()
  hit <- l[l$id == id, , drop = FALSE]
  if (nrow(hit) != 1) stop("links.yml has no link with id '", id, "'")
  hit
}

# Markdown link, e.g. `r link("linkedin")` inline in a page.
link <- function(id, label = NULL) {
  l <- get_link(id)
  paste0("[", md(if (is.null(label)) l$text else label), "](", l$url, ")")
}

# Links for one group, joined for a single line.
link_line <- function(group, sep = " · ") {
  l <- site_links()
  l <- l[l$group == group, , drop = FALSE]
  if (!nrow(l)) stop("links.yml has no group '", group, "'")
  paste(vapply(l$id, link, character(1)), collapse = sep)
}

# Full-width sidebar button, with the Bootstrap icon when one is set.
link_button <- function(id, label = NULL, class = "btn-outline-primary") {
  l <- get_link(id)
  # Bootstrap Icons has no ORCID or Google Scholar glyph; those come from the
  # academicons extension, whose shortcode Quarto expands after knitr.
  icon <- if (nzchar(l$icon_ai)) {
    paste0("{{< ai ", l$icon_ai, " >}} ")
  } else if (nzchar(l$icon)) {
    paste0('<i class="bi bi-', l$icon, '" aria-hidden="true"></i> ')
  } else {
    ""
  }
  paste0("[", icon, md(if (is.null(label)) l$label else label), "](", l$url,
         "){.btn .", class, " .w-100 .mb-2}")
}

# ---- Things I Like -------------------------------------------------------
# likes.yml holds sections of items, either directly or in groups; see the
# comment at the top of that file for the fields.

print_likes <- function(file = "likes.yml") {
  data <- read_yaml_utf8(site_path(file))
  # Anchor so one card can point at another (`see:`), which keeps a tool in
  # one section instead of repeating it: browser extensions live together,
  # and the related software card links across to them.
  slug <- function(x) gsub("^-|-$", "", gsub("-+", "-", gsub("[^a-z0-9]+", "-", tolower(x))))
  card <- function(it) {
    if (is.null(it$name) || !nzchar(it$name)) stop(file, ": every item needs a name")
    title <- if (is.null(it$url)) md(it$name) else paste0("[", md(it$name), "](", it$url, ")")
    out <- c(paste0("::: {#like-", slug(it$name), " .g-col-12 .g-col-md-6 .like-card}"),
             paste0("**", title, "**",
             if (!is.null(it$by)) paste0(" <span class='like-by'>", md(it$by), "</span>") else ""))
    if (!is.null(it$description)) out <- c(out, "", trimws(it$description))
    if (length(it$links)) {
      out <- c(out, "", vapply(it$links, function(l) paste0("- [", md(l$label), "](", l$url, ")"),
                               character(1)))
    }
    if (length(it$see)) {
      out <- c(out, "", paste0("*See also: ",
        paste(vapply(it$see, function(n) paste0("[", md(n), "](#like-", slug(n), ")"), character(1)),
              collapse = ", "), "*"))
    }
    c(out, ":::", "")
  }
  grid <- function(items) c("::: {.grid .like-grid}", "", unlist(lapply(items, card)), ":::", "")
  # A repeated name gives two cards the same anchor, so `see:` lands on
  # whichever comes first; a bare duplicate line once rendered as an empty
  # card that way. Stop on both that and a `see:` naming no card.
  # A section with groups draws only those, as the loop below does, so its
  # own `items` would silently not appear: stop on that too. Unnamed items
  # are left to card(), which says so more plainly; a name with no letters
  # or digits would get the bare anchor "like-", so it stops here.
  for (s in data$sections) {
    if (length(s$groups) && length(s$items)) {
      stop(file, ": section '", s$title, "' has both `groups` and `items`; only the groups are shown")
    }
  }
  items <- unlist(lapply(data$sections, function(s) {
    if (length(s$groups)) unlist(lapply(s$groups, function(g) g$items), recursive = FALSE) else s$items
  }), recursive = FALSE)
  names <- vapply(items, function(it) it$name %||% "", character(1))
  slugs <- vapply(names, slug, character(1), USE.NAMES = FALSE)
  bare <- names[nzchar(names) & !nzchar(slugs)]
  if (length(bare)) stop(file, ": a card name needs a letter or digit for its anchor: ", paste(bare, collapse = ", "))
  slugs <- slugs[nzchar(slugs)]
  dup <- unique(slugs[duplicated(slugs)])
  if (length(dup)) stop(file, ": more than one card named ", paste(dup, collapse = ", "))
  see <- unlist(lapply(items, function(it) it$see))
  unknown <- see[!slug(see) %in% slugs]
  if (length(unknown)) stop(file, ": `see:` names no card: ", paste(unknown, collapse = ", "))
  for (s in data$sections) {
    groups <- if (length(s$groups)) s$groups else list(list(title = NULL, items = s$items))
    groups <- Filter(function(g) length(g$items) > 0, groups)
    if (!length(groups)) next
    cat("## ", md(s$title), "\n\n", sep = "")
    for (g in groups) {
      if (!is.null(g$title)) cat("### ", md(g$title), "\n\n", sep = "")
      cat(grid(g$items), sep = "\n")
    }
  }
  invisible()
}

# The navbar in _quarto.yml cannot read links.yml, so stop the render if any
# external navbar link has drifted from it.
check_navbar_links <- function() {
  cfg <- read_yaml_utf8(site_path("_quarto.yml"))
  nav <- cfg$website$navbar
  items <- c(nav$left, nav$right)
  hrefs <- unlist(lapply(items, function(i) c(i$href, unlist(lapply(i$menu, `[[`, "href")))))
  external <- hrefs[grepl("^(https?:|mailto:)", hrefs)]
  missing <- setdiff(external, site_links()$url)
  if (length(missing)) {
    stop("Navbar links in _quarto.yml are not in links.yml (update both together): ",
         paste(missing, collapse = ", "))
  }
  invisible(TRUE)
}

# ---- Events --------------------------------------------------------------
# events.yml is the single source for events.qmd and the home page callout, so
# the home page cannot advertise something that has already moved to Past. See
# the comment at the top of that file for the fields.

site_events <- function(file = "events.yml") {
  ev <- read_yaml_utf8(site_path(file))
  # Each of these would otherwise vanish or be ignored with the render still
  # succeeding: an entry with neither a date nor a year, or a year that is
  # not a number, matches no year block; a date in another form (2026/12/02)
  # turns NA in event_dates() and lands in Past; and a field event_line()
  # does not read for that kind of entry, or a misspelled one, never shows.
  # A `text` entry is its own whole line, so only its date or year and
  # `more` links are read; a linked entry reads every field below.
  linked <- c("id", "date", "year", "when", "where", "note", "past_note", "more", "attended")
  textual <- c("text", "date", "year", "more", "attended")
  for (e in ev$events) {
    what <- e$id %||% substr(trimws(e$text %||% "(no id or text)"), 1, 40)
    if (is.null(e$date) && is.null(e$year)) stop(file, ": ", what, " has neither `date` nor `year`")
    if (!is.null(e$date)) {
      d <- as.character(e$date)
      if (!grepl("^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$", d) ||
          is.na(as.Date(d, format = "%Y-%m-%d", optional = TRUE))) {
        stop(file, ": ", what, " has a `date` that is not YYYY-MM-DD: ", d)
      }
    }
    if (!is.null(e$year) && !grepl("^[0-9]{4}$", as.character(e$year))) {
      stop(file, ": ", what, " has a `year` that is not a four-digit year: ", e$year)
    }
    # `year` stands in for the date of an event already past whose day was
    # not recorded, so it is written down after the fact, with whether she
    # went; a year still to come needs a date instead.
    if (is.null(e$date) && !is.null(e$year)) {
      if (as.integer(e$year) > as.integer(format(site_today(), "%Y"))) {
        stop(file, ": ", what, " has `year: ", e$year, "`, which is for a past event; give a `date`")
      }
      if (is.null(e$attended)) {
        stop(file, ": ", what, " has only a `year`, so it is a past record and needs `attended: true` or `false`")
      }
    }
    if (!is.null(e$attended) && !(is.logical(e$attended) && length(e$attended) == 1 && !is.na(e$attended))) {
      stop(file, ": ", what, " has `attended: ", paste(deparse(e$attended), collapse = " "),
           "`; use true or false")
    }
    extra <- setdiff(names(e), if (is.null(e$text)) linked else textual)
    if (length(extra)) {
      stop(file, ": ", what, " has ", paste0("`", extra, "`", collapse = ", "),
           if (is.null(e$text)) ", which no entry uses" else
             ", which a `text` entry ignores; put it in the text instead")
    }
  }
  ev
}

# Today where the events happen. A build in a UTC container on a Nebraska
# evening would otherwise already be on tomorrow's date and file that day's
# event under Past, and js/events.js can only move events into Past, never
# back out.
site_today <- function() as.Date(format(Sys.time(), "%Y-%m-%d", tz = "America/Chicago"))

# Markdown for one event: the linked name, then the date or cadence, the venue,
# the note, and any further links in parentheses. A past event is not bolded
# and prefers `past_note`, for notes that were written looking forward.
event_line <- function(e, past = FALSE) {
  # `more` applies to a `text` entry too. It used to return here, so an entry
  # with no links.yml id of its own had no way to carry a link except by
  # writing the URL into the text, which is the duplication links.yml exists
  # to prevent.
  if (!is.null(e$text)) {
    out <- trimws(e$text)
  } else {
    name <- link(e$id)
    if (!past) name <- paste0("**", name, "**")
    parts <- c(name, e$when %||% NULL, e$cadence %||% NULL, e$where %||% NULL)
    out <- paste(Filter(nzchar, parts), collapse = ", ")
    note <- if (past) e$past_note %||% e$note else e$note
    if (!is.null(note)) out <- paste(end_period(out), trimws(note))
  }
  if (length(e$more)) {
    extra <- vapply(e$more, function(m) link(m$id, m$label), character(1))
    out <- paste0(end_period(out), " (", paste(extra, collapse = ", "), ")")
  }
  out
}

# The dates of every entry in `events`, NA where only a `year` is recorded.
event_dates <- function(ev) {
  as.Date(vapply(ev, function(e) as.character(e$date %||% NA), character(1)), format = "%Y-%m-%d")
}

# The year an event is filed under: from its date, or from `year` for a past
# event whose exact day is not recorded.
event_year <- function(e) {
  if (!is.null(e$date)) {
    as.integer(format(as.Date(e$date), "%Y"))
  } else {
    as.integer(e$year %||% NA)
  }
}

# Which list each event is on as of `today`, decided here once so that every
# event is on exactly one: "upcoming"; "past", which says Amelia was there
# and so needs `attended: true`; "unconfirmed", gone by and not yet marked, on
# neither list until she says; or "off", marked `attended: false`, which also
# takes a future event out of Upcoming (Amelia, 2026-10-23: "need to fix so
# it doesn't show I attended things I skipped"). A year-only entry always
# carries `attended` (site_events() checks), so it is past or off.
event_status <- function(ev, today = site_today()) {
  dates <- event_dates(ev)
  vapply(seq_along(ev), function(i) {
    a <- ev[[i]]$attended
    if (isFALSE(a)) return("off")
    if (!is.na(dates[i]) && dates[i] >= today) return("upcoming")
    if (isTRUE(a)) "past" else "unconfirmed"
  }, character(1))
}

# Upcoming events still ahead of `today`, soonest first. An event leaves
# Upcoming on its own the day after it happens.
upcoming_events <- function(today = site_today(), events = site_events()) {
  ev <- events$events
  if (!length(ev)) return(list())
  keep <- event_status(ev, today) == "upcoming"
  dates <- event_dates(ev)
  ev[keep][order(dates[keep])]
}

# The past list, as year blocks, newest year first. Within a year the dated
# ones come newest first, the undated ones after them.
past_events <- function(today = site_today(), events = site_events()) {
  ev <- events$events
  if (!length(ev)) return(list())
  keep <- event_status(ev, today) == "past"
  dates <- event_dates(ev)
  ev <- ev[keep]
  dates <- dates[keep]
  if (!length(ev)) return(list())
  years <- vapply(ev, event_year, integer(1))
  lapply(sort(unique(years), decreasing = TRUE), function(y) {
    i <- which(years == y)
    i <- i[order(is.na(dates[i]), -as.integer(dates[i]))]
    list(year = y, items = ev[i])
  })
}

# Events waiting for Amelia to say whether she went. A whole-site render at a
# terminal asks her about them first (R/confirm-attendance.R); any render of
# the events page also lists them in the log, for renders no one is watching.
unconfirmed_events <- function(today = site_today(), events = site_events()) {
  ev <- events$events
  if (!length(ev)) return(list())
  ev[event_status(ev, today) == "unconfirmed"]
}

# An event's name as plain text, for the render log and the pre-render
# questions: its links.yml label, or the start of its `text`.
event_label <- function(e) {
  if (!is.null(e$text)) return(substr(trimws(e$text), 1, 60))
  # An unmarked event is on neither list of the page, so an id since dropped
  # from links.yml should not stop the render; fall back to the id itself.
  # Only that case: a links.yml that will not read still stops it.
  if (!e$id %in% site_links()$id) return(e$id)
  get_link(e$id)$label
}

# Write the unconfirmed list to the render log. stderr rather than message(),
# which the project's `message: false` would swallow.
note_unconfirmed <- function(today = site_today(), events = site_events()) {
  ev <- unconfirmed_events(today, events)
  if (!length(ev)) return(invisible())
  what <- vapply(ev, function(e) paste0("  ", e$date %||% e$year, "  ", event_label(e)), character(1))
  cat("events.yml: ", length(ev), " past event", if (length(ev) > 1) "s", " left off the page ",
      "until marked `attended: true` (went) or `attended: false` (did not):\n",
      paste(what, collapse = "\n"), "\n", sep = "", file = stderr())
  invisible()
}

# The pages are rebuilt only when Amelia publishes, so what counts as upcoming
# is decided twice: here, as of the build, and again in the reader's browser by
# js/events.js, as of the day they read it. Each function below writes the
# build-time answer as the visible one and marks up the rest for the script, so
# a reader without JavaScript sees the page as built and everyone else sees it
# as of today. The data- attributes and classes are the interface between the
# two; change them together.

# An Upcoming list item, carrying its date so the script can drop it from
# Upcoming the day after it happens. It does not move into Past there: that
# waits for `attended: true` and the next publish. The date is written as
# YYYY-MM-DD whatever form YAML gave it, since the script compares dates as
# strings.
event_item <- function(e) {
  paste0("[", event_line(e), "]{.event data-date=\"", format(as.Date(as.character(e$date))), "\"}")
}

# The "Often at" line naming the regulars, or "" when there are none.
regulars_line <- function(events = site_events()) {
  reg <- events$regulars
  if (!length(reg)) return("")
  first <- reg[[1]]
  cadence <- first$cadence %||% "regularly"
  rest <- vapply(reg[-1], function(r) link(r$id), character(1))
  out <- paste0("**Often at:** ", link(first$id), ", ", cadence)
  if (length(rest)) {
    out <- paste0(out, ", plus ", and_list(rest))
  }
  paste0(out, ". [More events](events.qmd).")
}

# The home page callout.
#
# Names the next event only when it is close enough to be worth a reader's
# attention: a summit eleven months out told them nothing they could act on,
# while 1 Million Cups was happening that Wednesday. Past `weeks`, the callout
# points at the regulars instead, and with neither it returns "" so the home
# page simply omits it.
#
# Every upcoming event gets a line, soonest first, with the first day it is
# worth naming (`data-from`) and its own date; only the one current at build
# time is visible, and the script picks again on the day. The whole callout
# sits in an .event-callout wrapper, hidden when nothing is current at build
# time, so the script can still show an event that comes into range later.
# Returns the complete Markdown, or "" when there is nothing it could ever show.
home_callout <- function(weeks = 6, today = site_today(), events = site_events()) {
  soon <- upcoming_events(today, events)
  fallback <- regulars_line(events)
  if (!length(soon) && !nzchar(fallback)) return("")
  dates <- event_dates(soon)
  shown <- if (length(soon) && dates[1] - today <= weeks * 7) 1L else 0L
  hide <- function(h) if (h) " hidden=\"hidden\"" else ""
  lines <- vapply(seq_along(soon), function(i) {
    e <- soon[[i]]
    # `text` wins over `id`, as in event_line(). A text entry has no name to
    # link, so it is given whole, with its `more` links; a linked entry is
    # named by its link and date alone, the note and `more` links being for
    # the events page.
    what <- if (!is.null(e$text)) end_period(event_line(e)) else
      paste0(link(e$id), if (!is.null(e$when)) paste0(", ", e$when), ".")
    paste0("::: {.event-next data-from=\"", dates[i] - weeks * 7, "\" data-date=\"",
           dates[i], "\"", hide(i != shown), "}\n**Next up:** ", what,
           " [More events](events.qmd).\n:::")
  }, character(1))
  if (nzchar(fallback)) {
    lines <- c(lines, paste0("::: {.event-fallback", hide(shown > 0), "}\n", fallback, "\n:::"))
  }
  paste0(":::: {.event-callout", hide(!shown && !nzchar(fallback)), "}\n",
         "::: {.callout-tip appearance=\"simple\"}\n",
         paste(lines, collapse = "\n\n"), "\n:::\n::::\n")
}

# ---- Bios -----------------------------------------------------------------
# bios.yml lists every place a bio is published and what each one says, so a
# job change can be worked through as a list. See BIOS.md for the order.

site_bios <- function(file = "bios.yml") {
  read_yaml_utf8(site_path(file))
}

# Whitespace-insensitive, so a stored bio still matches a file that wraps it
# across lines. YAML folding and the pages themselves break lines differently.
.squash <- function(x) gsub("\\s+", " ", trimws(x))

# Is the recorded text still in the file it was taken from? A substring test
# rather than pulling the paragraph back out: paragraph boundaries differ by
# file type, and a first attempt at that swallowed an entire YAML file and a
# stray div marker. There is nothing to get wrong here.
bio_in_sync <- function(p) {
  if (is.null(p$file) || is.null(p$text)) return(NA)
  grepl(.squash(p$text), .squash(paste(readLines(site_path(p$file), encoding = "UTF-8", warn = FALSE),
                                       collapse = " ")), fixed = TRUE)
}

# Print every bio with its length and age, flagging any that is over a
# platform limit or no longer matches the file it was copied from.
bio_report <- function(bios = site_bios(), today = Sys.Date()) {
  for (p in bios$places) {
    cat("\n", strrep("-", 70), "\n", p$label, "\n  ", p$url %||% "", "\n", sep = "")
    if (is.null(p$text)) {
      cat("  NOT RECORDED YET\n")
      next
    }
    txt <- .squash(p$text)
    n <- nchar(txt)
    cat("  ", n, if (!is.null(p$limit)) paste0(" of ", p$limit) else "", " characters",
        if (!is.null(p$limit) && n > p$limit) "   OVER THE LIMIT" else "", "\n", sep = "")
    if (!is.null(p$updated)) {
      age <- as.integer(today - as.Date(p$updated))
      cat("  checked ", p$updated, " (", age, " days ago)\n", sep = "")
    } else {
      cat("  no `updated` date\n")
    }
    sync <- bio_in_sync(p)
    if (isTRUE(sync)) cat("  matches ", p$file, "\n", sep = "")
    if (isFALSE(sync)) cat("  DRIFTED: no longer found in ", p$file, "\n", sep = "")
    cat(paste0("  ", strwrap(txt, width = 68)), sep = "\n")
    cat("\n")
  }
  invisible()
}

# ---- Areas of work --------------------------------------------------------
# areas.yml maps projects to the general areas they fall in, so a bio written
# for one audience can name the strands that audience cares about, and so a
# project that produced no publication still has somewhere to be recorded.
# Renders nowhere: this is a reading aid, not page data.

site_areas <- function(file = "areas.yml") {
  read_yaml_utf8(site_path(file))
}

# The file stores the mapping project-first, since a project belongs to
# several areas and should only be written down once. This prints it the other
# way round, which is the direction it gets read in.
work_areas <- function(x = site_areas(), gaps = TRUE, detail = TRUE) {
  # A flag that is not TRUE or FALSE would quietly print no gaps, which reads
  # as "nothing missing".
  if (!(isTRUE(gaps) || isFALSE(gaps))) stop("work_areas(): gaps must be TRUE or FALSE", call. = FALSE)
  # YAML reads `id: 2020` as a number and `id: yes` as TRUE, so check the type
  # before vapply() does it with an error that names no area.
  lab <- function(a) if (is.null(a$label)) "(no label)" else .squash(a$label)
  id_ok <- vapply(x$areas, function(a) is.character(a$id) && length(a$id) == 1 && nzchar(a$id),
                  logical(1))
  if (!all(id_ok)) {
    stop("areas.yml: every area needs a text id; check ",
         paste(vapply(x$areas[!id_ok], lab, character(1)), collapse = ", "), call. = FALSE)
  }
  known <- vapply(x$areas, function(a) a$id, character(1))
  dup <- unique(known[duplicated(known)])
  if (length(dup)) {
    stop("areas.yml: an area id is used more than once: ",
         paste(vapply(dup, function(d) paste0("'", d, "' by ", paste(
           vapply(x$areas[known == d], lab, character(1)), collapse = " and ")), character(1)),
           collapse = "; "), call. = FALSE)
  }
  # A project whose areas are missing, empty, or all mistyped matches no
  # section and would vanish from the report entirely, which is the one
  # failure this file cannot afford: it exists to hold the projects nothing
  # else records. Name each one, with any unknown id, before the sections.
  for (p in x$projects) {
    ids <- unlist(p$areas)
    ok <- ids %in% known
    if (!all(ok) || !any(ok)) {
      cat(.squash(p$name), ": ",
          if (any(!ok)) paste0("unknown area id ", paste(ids[!ok], collapse = ", "), "; "),
          if (!any(ok)) "SHOWN NOWHERE BELOW" else "shown under its known areas only",
          "\n", sep = "")
    }
  }
  for (a in x$areas) {
    in_area <- Filter(function(p) a$id %in% unlist(p$areas), x$projects)
    cat("\n", strrep("-", 70), "\n", toupper(a$label),
        " (", length(in_area), ")\n", sep = "")
    cat(paste0("  ", strwrap(.squash(a$scope), width = 68)), sep = "\n")
    for (p in in_area) {
      also <- intersect(setdiff(unlist(p$areas), a$id), known)
      head <- paste0(.squash(p$name),
                     if (!is.null(p$when)) paste0("  [", p$when, "]"),
                     if (identical(p$current, "unknown")) "  (status unknown)"
                     else if (!isTRUE(p$current)) "  (past)",
                     # No CV line behind it, so a bio should not lean on it.
                     if (identical(p$source, "recalled")) "  (recalled)")
      cat("\n", paste(strwrap(head, width = 70, initial = "  * ",
                              prefix = "    "), collapse = "\n"), "\n", sep = "")
      if (!is.null(p$where)) {
        cat(strwrap(.squash(p$where), width = 70, initial = "      ",
                    prefix = "      "), sep = "\n")
      }
      if (length(also)) cat("      also ", paste(also, collapse = ", "), "\n", sep = "")
      if (isTRUE(detail)) {
        for (f in c("role", "output", "built_with", "note")) {
          if (!is.null(p[[f]])) {
            cat(strwrap(.squash(p[[f]]), width = 70,
                        initial = paste0("      ", f, ": "),
                        prefix = "        "), sep = "\n")
          }
        }
      }
      if (isTRUE(gaps) && !is.null(p$gaps)) {
        cat(strwrap(.squash(p$gaps), width = 70,
                    initial = "      GAPS ", prefix = "           "), sep = "\n")
      }
    }
    cat("\n")
  }
  # Entries with no `role` are placeholders: a name and an era, nothing about
  # what the work was. Worth seeing as one list, since filling them in is the
  # point of the file.
  stubs <- Filter(function(p) is.null(p$role), x$projects)
  if (length(stubs)) {
    cat(strrep("-", 70), "\nNOTHING RECORDED YET (", length(stubs), " of ",
        length(x$projects), ")\n", sep = "")
    for (p in stubs) {
      cat("  ", .squash(p$name),
          if (!is.null(p$when)) paste0("  [", p$when, "]"), "\n", sep = "")
    }
  }
  invisible()
}
