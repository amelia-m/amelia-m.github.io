# Shared helpers for pages that render content exported from the cv repo
# (see R/export_site.R there). Base R + jsonlite only.

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

# Markdown-safe text: escape characters Pandoc would read as markup.
md <- function(x) {
  x <- ifelse(is.na(x), "", as.character(x))
  bs <- intToUtf8(92)
  for (ch in c("*", "_", "`", "<", ">", "[", "]")) {
    x <- gsub(ch, paste0(bs, ch), x, fixed = TRUE)
  }
  x
}

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
  stop("pandoc not found")
}

# Read a .bib into a list of CSL-JSON items via pandoc.
read_bib <- function(file) {
  pb <- pandoc_bin()
  out <- system2(pb$cmd, c(pb$pre, shQuote(site_path("_data", file)), "-f", "bibtex", "-t", "csljson"),
                 stdout = TRUE)
  jsonlite::fromJSON(paste(out, collapse = "\n"), simplifyVector = FALSE)
}

item_year <- function(it) {
  y <- tryCatch(it$issued$`date-parts`[[1]][[1]], error = function(e) NA)
  suppressWarnings(as.integer(y))
}

format_authors <- function(authors) {
  if (is.null(authors)) return("")
  nm <- vapply(authors, function(a) {
    fam <- a[["family"]] %||% a[["literal"]] %||% ""
    giv <- a[["given"]] %||% ""
    initials <- paste0(substr(strsplit(giv, "[ .-]+")[[1]], 1, 1), collapse = "")
    s <- trimws(paste(md(fam), initials))
    if (identical(fam, "Miramonti")) paste0("**", s, "**") else s
  }, character(1))
  paste(nm, collapse = ", ")
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || identical(a, "")) b else a

format_item <- function(it) {
  yr <- item_year(it)
  venue <- it[["container-title"]] %||% it[["event-title"]] %||% it[["event"]] %||% ""
  vol <- it[["volume"]] %||% ""
  iss <- it[["issue"]] %||% ""
  pg <- it[["page"]] %||% ""
  bits <- paste0(
    format_authors(it[["author"]]), " (", ifelse(is.na(yr), "n.d.", yr), "). ",
    md(sub("[.]$", "", it[["title"]] %||% "")), ". ",
    if (nzchar(venue)) paste0("*", md(venue), "*") else "",
    if (nzchar(vol)) paste0(", *", md(vol), "*") else "",
    if (nzchar(iss)) paste0("(", md(iss), ")") else "",
    if (nzchar(pg)) paste0(", ", md(pg)) else "",
    if (nzchar(venue) || nzchar(vol)) "." else "",
    if (!is.null(it[["DOI"]])) paste0(" [doi:", it[["DOI"]], "](https://doi.org/", it[["DOI"]], ")") else ""
  )
  bits
}

# Print a reverse-chronological reference list grouped by year.
print_bib <- function(file) {
  items <- read_bib(file)
  yrs <- vapply(items, item_year, integer(1))
  ord <- order(-ifelse(is.na(yrs), 0L, yrs))
  items <- items[ord]; yrs <- yrs[ord]
  cat(sprintf("*%d entries*\n\n", length(items)))
  for (y in unique(yrs)) {
    cat("## ", ifelse(is.na(y), "Undated", y), "\n\n", sep = "")
    for (it in items[yrs %in% y]) cat("- ", format_item(it), "\n", sep = "")
    cat("\n")
  }
}
