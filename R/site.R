# Shared helpers for pages that render the generated data in _data/.
# Base R + jsonlite only.

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
  groups <- yaml::read_yaml(site_path("links.yml"))
  rows <- lapply(names(groups), function(g) {
    do.call(rbind, lapply(groups[[g]], function(l) data.frame(
      group = g, id = l$id, label = l$label, url = l$url,
      text = if (is.null(l$text)) l$label else l$text,
      icon = if (is.null(l$icon)) "" else l$icon,
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
  icon <- if (nzchar(l$icon)) paste0('<i class="bi bi-', l$icon, '" aria-hidden="true"></i> ') else ""
  paste0("[", icon, md(if (is.null(label)) l$label else label), "](", l$url,
         "){.btn .", class, " .w-100 .mb-2}")
}

# ---- Things I Like -------------------------------------------------------
# likes.yml holds sections of items, either directly or in groups; see the
# comment at the top of that file for the fields.

print_likes <- function(file = "likes.yml") {
  data <- yaml::read_yaml(site_path(file))
  card <- function(it) {
    if (is.null(it$name) || !nzchar(it$name)) stop(file, ": every item needs a name")
    title <- if (is.null(it$url)) md(it$name) else paste0("[", md(it$name), "](", it$url, ")")
    out <- c("::: {.g-col-12 .g-col-md-6 .like-card}", paste0("**", title, "**",
             if (!is.null(it$by)) paste0(" <span class='like-by'>", md(it$by), "</span>") else ""))
    if (!is.null(it$description)) out <- c(out, "", trimws(it$description))
    if (length(it$links)) {
      out <- c(out, "", vapply(it$links, function(l) paste0("- [", md(l$label), "](", l$url, ")"),
                               character(1)))
    }
    c(out, ":::", "")
  }
  grid <- function(items) c("::: {.grid .like-grid}", "", unlist(lapply(items, card)), ":::", "")
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
  cfg <- yaml::read_yaml(site_path("_quarto.yml"))
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
