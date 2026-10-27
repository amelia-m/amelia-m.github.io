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
# and does ask; Quarto gives no way to tell it apart. A blank answer skips
# that event until the next render; anything other than y or n is asked again.
#
# An answer becomes an `attended:` line under the entry's `date:` line in
# events.yml, and nothing else in the file changes. The render does not commit
# it; commit events.yml afterwards, and before publishing if possible, or the
# live site will show marks that main does not have.

local({

if (Sys.getenv("QUARTO_PROJECT_RENDER_ALL") == "1" && isatty(stdin())) {

# Into this local() environment, so every function below can use its helpers.
source(file.path("R", "site.R"), local = TRUE)

# The questions print here, before any page renders, so switch to a UTF-8
# character locale for them as R/site.R does for pages, or a dash in an
# event's text prints as <U+2013> in a POSIX shell.
if (!use_utf8_ctype()) {
  cat("\nconfirm-attendance: no UTF-8 locale could be set, so accented letters or dashes in",
      " event names may print as <U+...> below. The file is not affected.\n", sep = "")
}

# Each list item under `events:` as a block of lines, in file order, which is
# the order site_events() returns them in, so block i should be event i.
# Taken once, before any question, so each answer is written where its entry
# was found instead of being matched up again afterwards. Also the line to
# write under: the entry's date, which may be its first key, on the "  - "
# line itself.
event_blocks <- function(lines) {
  start <- grep("^events:[[:space:]]*(#.*)?$", lines)[1]
  if (is.na(start)) return(NULL)
  top <- grep("^[A-Za-z_]+:", lines)
  end <- c(top[top > start], length(lines) + 1)[1] - 1
  heads <- grep("^  - ", lines)
  heads <- heads[heads > start & heads <= end]
  if (!length(heads)) return(NULL)
  stops <- c(heads[-1] - 1, end)
  date_line <- vapply(seq_along(heads), function(i) {
    hit <- grep("^(  - |    )date:", lines[heads[i]:stops[i]])
    if (length(hit)) heads[i] - 1L + hit[1] else NA_integer_
  }, integer(1))
  data.frame(head = heads, stop = stops, date_line = date_line)
}

ask_all <- function() {
  ev <- site_events()$events
  todo <- which(event_status(ev) == "unconfirmed")
  if (!length(todo)) return(invisible())
  path <- site_path("events.yml")
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  blocks <- event_blocks(lines)
  # Block i has to be event i. Counting is not enough on its own, so each
  # block about to be asked about is also parsed and compared with its
  # event. If either check fails, ask nothing; the events page still lists
  # the unmarked events in the render log.
  lined_up <- !is.null(blocks) && nrow(blocks) == length(ev) &&
    all(vapply(todo, function(i) {
      p <- yaml::yaml.load(paste(lines[blocks$head[i]:blocks$stop[i]], collapse = "\n"))[[1]]
      identical(p, ev[[i]])
    }, logical(1)))
  if (!lined_up) {
    cat("\nconfirm-attendance: could not line up the entries in events.yml with its lines,",
        " so nothing is asked; the events page lists the unmarked past events in the log.\n\n", sep = "")
    return(invisible())
  }
  missing <- todo[is.na(blocks$date_line[todo])]
  for (i in missing) {
    cat("\nconfirm-attendance: cannot find the `date:` line of ", event_label(ev[[i]]),
        ", so it is not asked about; write its date as `    date: YYYY-MM-DD`.\n", sep = "")
  }
  todo <- setdiff(todo, missing)
  if (!length(todo)) return(invisible())
  todo <- todo[order(event_dates(ev[todo]))]
  cat("\nevents.yml: ", length(todo), " past event", if (length(todo) > 1) "s",
      " not yet marked, so not on the events page.\n",
      "For each: y = went, n = did not go, Enter = ask again next time.\n\n", sep = "")
  con <- file("stdin", "r")
  on.exit(close(con), add = TRUE)
  answers <- list()
  for (i in todo) {
    e <- ev[[i]]
    # A typo is asked again rather than taken as a skip.
    repeat {
      cat("  ", e$date, "  ", event_label(e), "? [y/n/Enter] ", sep = "")
      flush(stdout())
      a <- readLines(con, n = 1)
      if (!length(a)) break
      a <- tolower(trimws(a))
      if (a %in% c("y", "yes", "n", "no", "")) break
      cat("    y, n, or Enter to skip.\n")
    }
    if (!length(a)) {
      cat("\n  no more input; the rest are skipped.\n")
      break
    }
    if (nzchar(a)) answers[[as.character(i)]] <- a %in% c("y", "yes")
  }
  if (!length(answers)) {
    cat("\nNothing recorded; rendering.\n\n")
    return(invisible())
  }
  # The file was read before the questions; if it was saved in the meantime,
  # writing the answers in would overwrite that edit, so leave it.
  if (!identical(readLines(path, encoding = "UTF-8", warn = FALSE), lines)) {
    cat("\nconfirm-attendance: events.yml changed while waiting for answers, so they were not",
        " written in; render again to be asked again.\n\n", sep = "")
    return(invisible())
  }
  record(answers, lines, blocks$date_line, ev, path)
  cat("\nRecorded ", length(answers), " in events.yml. Commit it, before publishing if you can,",
      " so main has the same marks as the site.\n\n", sep = "")
}

# Write each answer as an `attended:` line under its entry's date line,
# from the bottom of the file up so earlier line numbers stay right. Then
# check the result, not just that it parses: the file read back must equal
# the entries as they were with exactly the answered ones marked. Otherwise
# put it back and stop the render with the reason.
record <- function(answers, lines, date_line, ev, path) {
  idx <- as.integer(names(answers))
  updated <- lines
  for (i in sort(idx, decreasing = TRUE)) {
    updated <- append(updated, paste0("    attended: ", if (answers[[as.character(i)]]) "true" else "false"),
                      after = date_line[i])
  }
  write_lf(updated, path)
  expect <- ev
  for (i in idx) expect[[i]]$attended <- answers[[as.character(i)]]
  sorted <- function(x) lapply(x, function(e) e[order(names(e))])
  problem <- tryCatch({
    if (!identical(sorted(site_events()$events), sorted(expect))) {
      "an entry other than the answered ones changed, or an answer landed in the wrong one"
    }
  }, error = function(err) conditionMessage(err))
  if (!is.null(problem)) {
    write_lf(lines, path)
    stop("confirm-attendance: events.yml was left as it was, because after the change ",
         problem, call. = FALSE)
  }
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
