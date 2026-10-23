# Pre-render: ask whether Amelia went to each past event events.yml has not
# marked yet, record the answers, then let the render go on.
#
# The events page lists a past event under Past only once it is marked
# `attended: true` (see event_status() in R/site.R); unmarked, it is on
# neither list. So a whole-site render is the moment to ask (Amelia,
# 2026-10-23: "checks whether there are unmarked events first, if yes
# prompts me to update or skip/defer, and then renders").
#
# It asks only when a person can answer: a whole-project render, with a
# terminal on standard input. Otherwise, for quarto preview's per-file renders
# or a render run by an agent, a scheduled session or anything with piped
# input, it does nothing, and the events page lists the unmarked events in the
# render log instead. `quarto preview --render all` is a whole-project render
# and does ask; Quarto gives no way to tell it apart. A blank or unrecognised
# answer skips that event until the next render.
#
# An answer becomes an `attended:` line under the entry's `date:` line in
# events.yml, and nothing else in the file changes. The render does not commit
# it; commit events.yml afterwards, and before publishing if possible, or the
# live site will show marks that main does not have.

local({

if (Sys.getenv("QUARTO_PROJECT_RENDER_ALL") == "1" && isatty(stdin())) {

# Into this local() environment, so every function below can use its helpers.
source(file.path("R", "site.R"), local = TRUE)

# R/site.R switches to a UTF-8 locale only inside knitr; the questions are
# printed here, before any page renders, so switch for them too, or a dash
# in an event's text prints as <U+2013> in a POSIX shell.
if (!l10n_info()[["UTF-8"]]) {
  for (loc in c("C.UTF-8", "C.utf8", "en_US.UTF-8", "en_US.utf8")) {
    if (nzchar(suppressWarnings(Sys.setlocale("LC_CTYPE", loc)))) break
  }
}

# The fields that identify an entry, as text, for matching a block of
# events.yml against the parsed event it came from.
key <- function(e) {
  paste(e$id %||% "", e$text %||% "", as.character(e$date %||% ""),
        as.character(e$year %||% ""), sep = "\r")
}

ask_all <- function() {
  ev <- unconfirmed_events()
  if (!length(ev)) return(invisible())
  ev <- ev[order(event_dates(ev))]
  cat("\nevents.yml: ", length(ev), " past event", if (length(ev) > 1) "s",
      " not yet marked, so not on the events page.\n",
      "For each: y = went, n = did not go, Enter = ask again next time.\n\n", sep = "")
  con <- file("stdin", "r")
  on.exit(close(con), add = TRUE)
  answers <- list()
  for (e in ev) {
    cat("  ", e$date %||% e$year, "  ", event_label(e), "? [y/n/Enter] ", sep = "")
    flush(stdout())
    a <- tolower(trimws(readLines(con, n = 1)))
    if (!length(a)) {
      cat("\n  no more input; the rest are skipped.\n")
      break
    }
    if (a %in% c("y", "yes")) {
      answers[[length(answers) + 1]] <- list(e = e, value = TRUE)
    } else if (a %in% c("n", "no")) {
      answers[[length(answers) + 1]] <- list(e = e, value = FALSE)
    }
  }
  if (!length(answers)) {
    cat("\nNothing recorded; rendering.\n\n")
    return(invisible())
  }
  n <- record(answers)
  cat("\nRecorded ", n, " in events.yml. Commit it, before publishing if you can,",
      " so main has the same marks as the site.\n\n", sep = "")
}

# Insert each answer under its entry's date line. Entries are found by
# reading each list item under `events:` and matching it field for field,
# among those not yet marked, so two entries sharing an id (a monthly call)
# are told apart by their dates and an identical pair takes one answer each.
# Returns how many were recorded.
record <- function(answers) {
  path <- site_path("events.yml")
  original <- readLines(path, encoding = "UTF-8", warn = FALSE)
  lines <- original
  done <- 0
  for (a in answers) {
    top <- grep("^[A-Za-z_]+:", lines)
    start <- which(lines == "events:")
    end <- c(top[top > start], length(lines) + 1)[1] - 1
    heads <- grep("^  - ", lines)
    heads <- heads[heads > start & heads <= end]
    stops <- c(heads[-1] - 1, end)
    hit <- NA
    for (i in seq_along(heads)) {
      block <- lines[heads[i]:stops[i]]
      p <- yaml::yaml.load(paste(block, collapse = "\n"))[[1]]
      if (is.null(p$attended) && identical(key(p), key(a$e))) {
        # The date may be the item's first key, on the "  - " line itself.
        hit <- heads[i] - 1 + grep("^(  - |    )date:", block)[1]
        break
      }
    }
    if (is.na(hit)) {
      cat("  could not find the entry for ", event_label(a$e), "; left unmarked.\n", sep = "")
      next
    }
    lines <- append(lines, paste0("    attended: ", if (a$value) "true" else "false"), after = hit)
    done <- done + 1
  }
  write_lf(lines, path)
  # Check the result, not just that it parses: every answered event marked as
  # answered, and every other entry exactly as it was. Otherwise put the file
  # back and stop the render with the reason.
  # `after` is read the way the site reads it; read_yaml_utf8() is the same
  # yaml.load() call used on `original` below, so the two compare like for like.
  problem <- tryCatch({
    after <- site_events()$events
    NULL
  }, error = function(err) conditionMessage(err))
  if (is.null(problem)) {
    old <- yaml::yaml.load(paste(original, collapse = "\n"))$events
    if (length(after) != length(old)) {
      problem <- "the number of entries changed"
    } else {
      expect <- old
      for (a in answers) {
        j <- which(vapply(expect, function(x) is.null(x$attended) && identical(key(x), key(a$e)),
                          logical(1)))[1]
        if (!is.na(j)) expect[[j]]$attended <- a$value
      }
      if (!identical(lapply(after, function(x) x[order(names(x))]),
                     lapply(expect, function(x) x[order(names(x))]))) {
        problem <- "an entry other than the answered ones changed, or an answer landed in the wrong one"
      }
    }
  }
  if (!is.null(problem)) {
    write_lf(original, path)
    stop("confirm-attendance: events.yml was left as it was, because after the change ",
         problem, call. = FALSE)
  }
  done
}

# LF endings whatever the platform, as .gitattributes asks for.
write_lf <- function(lines, path) {
  con <- file(path, "wb")
  on.exit(close(con))
  writeLines(enc2utf8(lines), con, sep = "\n", useBytes = TRUE)
}

ask_all()

}

})
