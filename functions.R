# Spotify Web API constants used throughout the app.
spotify_scopes <- c(
  "playlist-modify-public",
  "playlist-modify-private",
  "playlist-read-private",
  "playlist-read-collaborative",
  "user-read-private"
)

api_base_url <- "https://api.spotify.com/v1"
spotify_authorize_url <- "https://accounts.spotify.com/authorize"
spotify_token_url <- "https://accounts.spotify.com/api/token"

# Function: %||%
# Description: Returns a fallback value when an object is NULL or length zero.
`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

# Function: clean_text
# Description: Converts input to trimmed character values while replacing missing values with blanks.
clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  trimws(x)
}

# Function: normalise_key
# Description: Creates a lowercase alphanumeric key for song matching and duplicate detection.
normalise_key <- function(x) {
  x <- tolower(clean_text(x))
  x <- gsub("[^a-z0-9]+", " ", x)
  trimws(gsub("\\s+", " ", x))
}

# Function: normalise_playlist_name
# Description: Standardizes playlist names so existing Spotify playlists can be compared reliably.
normalise_playlist_name <- function(x) {
  tolower(trimws(x))
}

# Function: user_stop
# Description: Raises a clean user-facing error without an R call stack.
user_stop <- function(message) {
  stop(message, call. = FALSE)
}

# Function: read_uploaded_dataset
# Description: Reads CSV, TSV, TXT, XLS, or XLSX uploads into a data frame.
read_uploaded_dataset <- function(path, filename) {
  extension <- tolower(tools::file_ext(filename))

  if (extension == "csv") {
    return(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE))
  }

  if (extension %in% c("tsv", "tab", "txt")) {
    return(utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE))
  }

  if (extension %in% c("xls", "xlsx")) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      user_stop("Excel files require the readxl package. Install it or upload a CSV/TSV file.")
    }

    return(as.data.frame(readxl::read_excel(path), stringsAsFactors = FALSE, check.names = FALSE))
  }

  user_stop("Unsupported file type. Upload a CSV, TSV, XLS, or XLSX file.")
}

# Function: guess_column
# Description: Chooses a likely dataset column based on name patterns and a fallback.
guess_column <- function(columns, patterns, fallback = NULL) {
  if (length(columns) == 0) {
    return(character(0))
  }

  matched <- which(vapply(
    columns,
    function(column) any(grepl(paste(patterns, collapse = "|"), column, ignore.case = TRUE)),
    logical(1)
  ))

  if (length(matched) > 0) {
    return(columns[matched[[1]]])
  }

  fallback %||% columns[[1]]
}

# Function: data_frame_from_rows
# Description: Converts a list of scalar named lists into a row-bound data frame.
data_frame_from_rows <- function(rows) {
  if (length(rows) == 0) {
    return(data.frame())
  }

  frames <- lapply(rows, function(row) {
    as.data.frame(row, stringsAsFactors = FALSE, optional = TRUE)
  })
  output <- do.call(rbind, frames)
  rownames(output) <- NULL
  output
}

# Function: base64url_encode
# Description: Encodes raw bytes using the URL-safe base64 format required by PKCE.
base64url_encode <- function(raw_bytes) {
  encoded <- jsonlite::base64_enc(raw_bytes)
  # jsonlite wraps base64 output at 76 characters. Any newline left in place makes a
  # PKCE verifier illegal, because the spec allows only [A-Za-z0-9-._~].
  encoded <- gsub("[[:space:]]", "", encoded)
  encoded <- gsub("+", "-", encoded, fixed = TRUE)
  encoded <- gsub("/", "_", encoded, fixed = TRUE)
  gsub("=+$", "", encoded)
}

# Function: generate_oauth_state
# Description: Creates an unpredictable state value to connect an OAuth callback to its request.
generate_oauth_state <- function() {
  base64url_encode(openssl::rand_bytes(32))
}

# Function: generate_pkce_verifier
# Description: Creates the PKCE verifier used when authenticating without a client secret.
generate_pkce_verifier <- function() {
  base64url_encode(openssl::rand_bytes(64))
}

# Function: pkce_challenge
# Description: Converts a PKCE verifier into the SHA-256 challenge sent to Spotify.
pkce_challenge <- function(code_verifier) {
  base64url_encode(openssl::sha256(charToRaw(code_verifier)))
}

# Function: encode_query
# Description: Builds a URL query string from named parameters.
encode_query <- function(parameters) {
  parameters <- parameters[!vapply(parameters, is.null, logical(1))]

  paste(
    paste0(
      utils::URLencode(names(parameters), reserved = TRUE),
      "=",
      vapply(parameters, utils::URLencode, character(1), reserved = TRUE)
    ),
    collapse = "&"
  )
}

# Function: build_spotify_authorize_url
# Description: Creates the Spotify authorization URL that the browser should visit.
build_spotify_authorize_url <- function(client_id, redirect_uri, state, code_verifier = "") {
  parameters <- list(
    response_type = "code",
    client_id = client_id,
    scope = paste(spotify_scopes, collapse = " "),
    redirect_uri = redirect_uri,
    state = state
  )

  if (nzchar(code_verifier)) {
    parameters$code_challenge_method <- "S256"
    parameters$code_challenge <- pkce_challenge(code_verifier)
  }

  paste0(spotify_authorize_url, "?", encode_query(parameters))
}

# Function: parse_oauth_query
# Description: Parses the code, state, and error values Spotify returns to the Shiny app URL.
parse_oauth_query <- function(url_search) {
  search <- sub("^\\?", "", url_search %||% "")
  if (!nzchar(search)) {
    return(list())
  }

  shiny::parseQueryString(search)
}

# Function: current_redirect_uri
# Description: Builds the current Shiny app URL without query parameters for OAuth redirects.
current_redirect_uri <- function(session) {
  protocol <- session$clientData$url_protocol %||% "http:"
  hostname <- session$clientData$url_hostname %||% "127.0.0.1"
  port <- session$clientData$url_port %||% ""
  pathname <- session$clientData$url_pathname %||% "/"
  port_part <- if (nzchar(port)) paste0(":", port) else ""

  paste0(protocol, "//", hostname, port_part, pathname)
}

# Function: explain_auth_error
# Description: Adds an actionable hint to the Spotify sign-in errors users hit most often.
explain_auth_error <- function(message, redirect_uri = "") {
  message <- clean_text(message)

  if (grepl("redirect", message, ignore.case = TRUE)) {
    return(paste0(
      message,
      " Your Spotify app's Redirect URIs must contain this exact value: ",
      redirect_uri,
      " Open the API setup tab, copy it with the Copy button, and add it in the Spotify dashboard."
    ))
  }

  if (grepl("invalid.?client|client.?id", message, ignore.case = TRUE)) {
    return(paste0(
      message,
      " Check that the Client ID was copied in full from your Spotify app's Settings page."
    ))
  }

  message
}

# Function: encode_oauth_context
# Description: Serialises the OAuth login context so the browser tab can hold it across the Spotify redirect.
encode_oauth_context <- function(context) {
  fields <- c("client_id", "redirect_uri", "code_verifier", "state", "raw_client_id", "raw_redirect_uri")
  as.character(jsonlite::toJSON(context[fields], auto_unbox = TRUE))
}

# Function: decode_oauth_context
# Description: Restores a browser-held OAuth context, returning NULL unless it matches the returned state.
decode_oauth_context <- function(encoded, state) {
  encoded <- clean_text(encoded %||% "")
  if (!nzchar(encoded)) {
    return(NULL)
  }

  context <- tryCatch(
    jsonlite::fromJSON(encoded, simplifyVector = TRUE),
    error = function(error) NULL
  )

  if (!is.list(context) || !identical(clean_text(context$state %||% ""), state)) {
    return(NULL)
  }

  context
}

# Function: store_oauth_context
# Description: Saves the credentials and PKCE verifier needed when Spotify redirects back.
store_oauth_context <- function(store, state, context) {
  assign(state, context, envir = store)
  invisible(TRUE)
}

# Function: get_oauth_context
# Description: Retrieves the OAuth context associated with a returned Spotify state value.
get_oauth_context <- function(store, state) {
  if (!nzchar(state) || !exists(state, envir = store, inherits = FALSE)) {
    return(NULL)
  }

  get(state, envir = store, inherits = FALSE)
}

# Function: drop_oauth_context
# Description: Removes an OAuth context after it has been used or invalidated.
drop_oauth_context <- function(store, state) {
  if (nzchar(state) && exists(state, envir = store, inherits = FALSE)) {
    rm(list = state, envir = store)
  }

  invisible(TRUE)
}

# Function: first_nonblank
# Description: Returns the first non-empty text value from a set of candidate messages.
first_nonblank <- function(...) {
  candidates <- list(...)

  for (candidate in candidates) {
    if (is.null(candidate) || length(candidate) == 0) {
      next
    }

    text <- paste(as.character(candidate), collapse = " ")
    if (nzchar(text)) {
      return(text)
    }
  }

  ""
}

# Function: spotify_error_message
# Description: Extracts a readable error message from a Spotify API response.
spotify_error_message <- function(response_body, status_code) {
  spotify_error <- response_body[["error"]] %||% NULL
  spotify_error_message <- if (is.list(spotify_error)) {
    spotify_error[["message"]] %||% ""
  } else if (is.character(spotify_error)) {
    spotify_error[[1]]
  } else {
    ""
  }

  api_message <- first_nonblank(
    response_body[["error_description"]],
    response_body[["message"]],
    response_body[[".raw_body"]],
    spotify_error_message,
    "Spotify API request failed."
  )

  paste0("Spotify API error ", status_code, ": ", api_message)
}

# Function: parse_response_body
# Description: Parses JSON response bodies and preserves plain-text Spotify errors for readable messages.
parse_response_body <- function(response_text) {
  if (!nzchar(response_text)) {
    return(list())
  }

  tryCatch(
    jsonlite::fromJSON(response_text, simplifyVector = FALSE),
    error = function(error) list(.raw_body = response_text)
  )
}

# Function: perform_json_request
# Description: Performs an httr2 request and parses the JSON response while preserving Spotify errors.
perform_json_request <- function(request) {
  request <- httr2::req_retry(request, max_tries = 3)
  request <- httr2::req_error(request, is_error = function(response) FALSE)

  response <- httr2::req_perform(request)
  status_code <- httr2::resp_status(response)
  response_text <- httr2::resp_body_string(response)

  response_body <- parse_response_body(response_text)

  if (status_code >= 300) {
    user_stop(spotify_error_message(response_body, status_code))
  }

  if (!is.null(response_body[[".raw_body"]])) {
    user_stop(paste0("Spotify returned a non-JSON response: ", response_body[[".raw_body"]]))
  }

  response_body
}

# Function: request_spotify_token
# Description: Exchanges Spotify's authorization code for an access token using PKCE or a client secret.
request_spotify_token <- function(client_id, client_secret, redirect_uri, code, code_verifier = "") {
  body <- list(
    grant_type = "authorization_code",
    code = code,
    redirect_uri = redirect_uri
  )

  request <- httr2::request(spotify_token_url)
  request <- httr2::req_method(request, "POST")
  request <- httr2::req_headers(request, Accept = "application/json")

  if (nzchar(client_secret)) {
    request <- httr2::req_auth_basic(request, client_id, client_secret)
  } else {
    body$client_id <- client_id
    body$code_verifier <- code_verifier
  }

  request <- do.call(httr2::req_body_form, c(list(request), body))
  perform_json_request(request)
}

# Function: spotify_api
# Description: Sends authenticated requests to Spotify's Web API and returns parsed JSON.
spotify_api <- function(token, method, path, query = list(), body = NULL) {
  request <- httr2::request(paste0(api_base_url, path))
  request <- httr2::req_auth_bearer_token(request, token$access_token)
  request <- httr2::req_headers(
    request,
    Accept = "application/json",
    `Content-Type` = "application/json"
  )
  request <- httr2::req_user_agent(request, "spotify-playlist-builder-shiny/0.1")

  if (length(query) > 0) {
    request <- do.call(httr2::req_url_query, c(list(request), query))
  }

  if (!is.null(body)) {
    request <- httr2::req_body_json(request, body, auto_unbox = TRUE)
  }

  request <- httr2::req_method(request, method)
  perform_json_request(request)
}

# Function: escape_spotify_search
# Description: Removes quotation marks before values are embedded in Spotify search filters.
escape_spotify_search <- function(x) {
  gsub('"', "", clean_text(x), fixed = TRUE)
}

# Function: track_artists
# Description: Collapses a Spotify track's artist list into a display string.
track_artists <- function(track) {
  artists <- track$artists %||% list()
  names <- vapply(artists, function(artist) artist$name %||% "", character(1))
  paste(names[nzchar(names)], collapse = ", ")
}

# Function: track_score
# Description: Scores a Spotify search result against the requested artist and title.
track_score <- function(track, artist, title) {
  input_artist <- normalise_key(artist)
  input_title <- normalise_key(title)
  track_artist <- normalise_key(track_artists(track))
  track_title <- normalise_key(track$name %||% "")
  popularity <- suppressWarnings(as.numeric(track$popularity %||% 0))

  score <- popularity / 100

  if (identical(track_title, input_title)) {
    score <- score + 50
  } else if (nzchar(input_title) && grepl(input_title, track_title, fixed = TRUE)) {
    score <- score + 30
  } else if (nzchar(track_title) && grepl(track_title, input_title, fixed = TRUE)) {
    score <- score + 15
  }

  if (identical(track_artist, input_artist)) {
    score <- score + 30
  } else if (nzchar(input_artist) && grepl(input_artist, track_artist, fixed = TRUE)) {
    score <- score + 20
  }

  score
}

# Function: best_track_result
# Description: Selects the best Spotify track result while honoring explicit-content filtering.
best_track_result <- function(items, artist, title, filter_explicit) {
  if (length(items) == 0) {
    return(NULL)
  }

  available <- items
  explicit_count <- sum(vapply(available, function(item) isTRUE(item$explicit), logical(1)))

  if (isTRUE(filter_explicit)) {
    available <- available[!vapply(available, function(item) isTRUE(item$explicit), logical(1))]
  }

  if (length(available) == 0) {
    return(list(filtered_explicit = explicit_count > 0))
  }

  scores <- vapply(available, track_score, numeric(1), artist = artist, title = title)
  available[[which.max(scores)]]
}

# Function: search_spotify_track
# Description: Searches Spotify for one artist/title pair and returns the selected match details.
search_spotify_track <- function(token, artist, title, filter_explicit) {
  exact_query <- paste0(
    'track:"',
    escape_spotify_search(title),
    '" artist:"',
    escape_spotify_search(artist),
    '"'
  )
  plain_query <- paste(artist, title)

  queries <- unique(c(exact_query, plain_query))
  filtered_by_explicit <- FALSE

  for (query in queries) {
    search_result <- spotify_api(
      token,
      "GET",
      "/search",
      query = list(q = query, type = "track", limit = 10)
    )

    items <- search_result$tracks$items %||% list()
    chosen <- best_track_result(items, artist, title, filter_explicit)

    if (!is.null(chosen) && !isTRUE(chosen$filtered_explicit)) {
      return(list(
        matched = TRUE,
        spotify_uri = chosen$uri %||% "",
        spotify_url = chosen$external_urls$spotify %||% "",
        spotify_title = chosen$name %||% "",
        spotify_artist = track_artists(chosen),
        explicit = isTRUE(chosen$explicit),
        status = "Matched",
        message = ""
      ))
    }

    filtered_by_explicit <- filtered_by_explicit || isTRUE(chosen$filtered_explicit)
  }

  if (filtered_by_explicit) {
    return(list(
      matched = FALSE,
      spotify_uri = "",
      spotify_url = "",
      spotify_title = "",
      spotify_artist = "",
      explicit = NA,
      status = "Filtered explicit",
      message = "Only explicit matches were found."
    ))
  }

  list(
    matched = FALSE,
    spotify_uri = "",
    spotify_url = "",
    spotify_title = "",
    spotify_artist = "",
    explicit = NA,
    status = "No match",
    message = "No Spotify track was found."
  )
}

# Function: build_match_preview
# Description: Matches all source song rows against Spotify and returns the preview table shown in the app.
build_match_preview <- function(token, songs, filter_explicit) {
  if (is.null(token)) {
    user_stop("Connect to Spotify before matching tracks.")
  }

  unique_queries <- songs[!duplicated(songs$query_key), c("query_key", "artist", "title"), drop = FALSE]
  search_rows <- vector("list", nrow(unique_queries))

  shiny::withProgress(message = "Matching songs on Spotify", value = 0, {
    for (index in seq_len(nrow(unique_queries))) {
      query_row <- unique_queries[index, , drop = FALSE]
      result <- search_spotify_track(
        token,
        query_row$artist,
        query_row$title,
        filter_explicit
      )

      search_rows[[index]] <- c(
        list(query_key = query_row$query_key),
        result
      )

      shiny::incProgress(1 / nrow(unique_queries))
    }
  })

  search_results <- data_frame_from_rows(search_rows)
  matched_index <- match(songs$query_key, search_results$query_key)

  data.frame(
    source_row = songs$source_row,
    group = songs$group,
    input_artist = songs$artist,
    input_title = songs$title,
    matched = search_results$matched[matched_index],
    spotify_artist = search_results$spotify_artist[matched_index],
    spotify_title = search_results$spotify_title[matched_index],
    explicit = search_results$explicit[matched_index],
    status = search_results$status[matched_index],
    message = search_results$message[matched_index],
    spotify_url = search_results$spotify_url[matched_index],
    spotify_uri = search_results$spotify_uri[matched_index],
    group_label = songs$group_label,
    stringsAsFactors = FALSE
  )
}

# Function: get_current_user
# Description: Gets the authorized Spotify profile used for display and playlist ownership checks.
get_current_user <- function(token) {
  spotify_api(token, "GET", "/me")
}

# Function: get_current_user_playlists
# Description: Retrieves the authorized user's playlists so name conflicts can be handled safely.
get_current_user_playlists <- function(token) {
  playlists <- list()
  offset <- 0

  repeat {
    page <- spotify_api(
      token,
      "GET",
      "/me/playlists",
      query = list(limit = 50, offset = offset)
    )

    items <- page$items %||% list()
    playlists <- c(playlists, items)

    if (length(items) == 0 || length(playlists) >= (page$total %||% 0)) {
      break
    }

    offset <- offset + length(items)
  }

  playlists
}

# Function: get_playlist_track_uris
# Description: Retrieves track URIs from an existing playlist to avoid adding duplicates.
get_playlist_track_uris <- function(token, playlist_id) {
  uris <- character(0)
  offset <- 0

  repeat {
    page <- spotify_api(
      token,
      "GET",
      paste0("/playlists/", playlist_id, "/items"),
      query = list(
        limit = 50,
        offset = offset,
        fields = "total,limit,offset,next,items(item(uri,type))"
      )
    )

    items <- page$items %||% list()
    new_uris <- vapply(items, function(item) {
      track <- item$item %||% item$track %||% list()
      if (identical(track$type %||% "", "track")) {
        track$uri %||% ""
      } else {
        ""
      }
    }, character(1))

    uris <- c(uris, new_uris[nzchar(new_uris)])

    if (length(items) == 0 || length(uris) >= (page$total %||% 0) || is.null(page[["next"]])) {
      break
    }

    offset <- offset + length(items)
  }

  unique(uris)
}

# Function: create_playlist
# Description: Creates an empty playlist for the currently authorized Spotify user.
create_playlist <- function(token, playlist_name, public) {
  spotify_api(
    token,
    "POST",
    "/me/playlists",
    body = list(
      name = playlist_name,
      public = public,
      description = paste("Created by the Spotify Playlist Builder Shiny app on", Sys.Date())
    )
  )
}

# Function: add_playlist_items
# Description: Adds track URIs to a playlist in Spotify's maximum batch size of 100.
add_playlist_items <- function(token, playlist_id, uris) {
  if (length(uris) == 0) {
    return(invisible(NULL))
  }

  chunks <- split(uris, ceiling(seq_along(uris) / 100))
  for (chunk in chunks) {
    spotify_api(
      token,
      "POST",
      paste0("/playlists/", playlist_id, "/items"),
      body = list(uris = unname(chunk))
    )
  }

  invisible(NULL)
}

# Function: replace_playlist_items
# Description: Replaces an existing playlist's contents while preserving Spotify's 100-item limit.
replace_playlist_items <- function(token, playlist_id, uris) {
  first_chunk <- head(uris, 100)
  spotify_api(
    token,
    "PUT",
    paste0("/playlists/", playlist_id, "/items"),
    body = list(uris = unname(first_chunk))
  )

  if (length(uris) > 100) {
    add_playlist_items(token, playlist_id, uris[-seq_len(100)])
  }

  invisible(NULL)
}

# Function: playlist_url
# Description: Extracts the Spotify web URL from a playlist object.
playlist_url <- function(playlist) {
  playlist$external_urls$spotify %||% ""
}

# Function: playlist_id
# Description: Extracts the Spotify playlist ID from a playlist object.
playlist_id <- function(playlist) {
  playlist$id %||% ""
}

# Function: is_playlist_modifiable
# Description: Checks whether the authorized user can modify a playlist.
is_playlist_modifiable <- function(playlist, current_user_id) {
  identical(playlist$owner$id %||% "", current_user_id) || isTRUE(playlist$collaborative)
}

# Function: prepare_playlist_jobs
# Description: Converts matched tracks into one combined playlist job or one job per group.
prepare_playlist_jobs <- function(matches, playlist_name, split_by_group) {
  matched <- matches[matches$matched & nzchar(matches$spotify_uri), , drop = FALSE]

  if (nrow(matched) == 0) {
    user_stop("No playable Spotify tracks were matched. Review the match preview before creating a playlist.")
  }

  if (isTRUE(split_by_group)) {
    groups <- matched$group_label
    unique_groups <- unique(groups)
    rows <- lapply(unique_groups, function(group_name) {
      group_rows <- matched[groups == group_name, , drop = FALSE]
      uris <- unique(group_rows$spotify_uri)
      list(
        playlist_name = paste(playlist_name, group_name, sep = " - "),
        uris = uris,
        requested_rows = nrow(group_rows),
        unique_tracks = length(uris),
        duplicate_rows = nrow(group_rows) - length(uris)
      )
    })
  } else {
    uris <- unique(matched$spotify_uri)
    rows <- list(list(
      playlist_name = playlist_name,
      uris = uris,
      requested_rows = nrow(matched),
      unique_tracks = length(uris),
      duplicate_rows = nrow(matched) - length(uris)
    ))
  }

  rows
}

# Function: preflight_existing_playlists
# Description: Applies the selected conflict policy before changing any existing playlists.
preflight_existing_playlists <- function(jobs, playlists, current_user_id, existing_policy) {
  normalized_names <- vapply(playlists, function(playlist) {
    normalise_playlist_name(playlist$name %||% "")
  }, character(1))

  blockers <- list()

  for (job in jobs) {
    matches <- playlists[normalized_names == normalise_playlist_name(job$playlist_name)]
    modifiable <- matches[vapply(matches, is_playlist_modifiable, logical(1), current_user_id)]

    if (identical(existing_policy, "warn") && length(matches) > 0) {
      urls <- vapply(matches, playlist_url, character(1))
      blockers[[length(blockers) + 1]] <- paste0(
        "Playlist already exists: ",
        job$playlist_name,
        if (length(urls) > 0) paste0(" (", paste(urls[nzchar(urls)], collapse = ", "), ")") else ""
      )
    }

    if (!identical(existing_policy, "warn") && length(matches) > 0 && length(modifiable) == 0) {
      blockers[[length(blockers) + 1]] <- paste0(
        "A playlist named '",
        job$playlist_name,
        "' exists, but this app cannot modify it."
      )
    }

    if (!identical(existing_policy, "warn") && length(modifiable) > 1) {
      blockers[[length(blockers) + 1]] <- paste0(
        "More than one modifiable playlist named '",
        job$playlist_name,
        "' exists. Rename one of them before continuing."
      )
    }
  }

  if (length(blockers) > 0) {
    user_stop(paste(blockers, collapse = "\n"))
  }

  invisible(TRUE)
}

# Function: write_playlist_job
# Description: Creates, appends to, or overwrites one playlist according to the selected policy.
write_playlist_job <- function(token, job, playlists, current_user_id, existing_policy, public) {
  normalized_names <- vapply(playlists, function(playlist) {
    normalise_playlist_name(playlist$name %||% "")
  }, character(1))
  matches <- playlists[normalized_names == normalise_playlist_name(job$playlist_name)]
  modifiable <- matches[vapply(matches, is_playlist_modifiable, logical(1), current_user_id)]

  action <- "Created"
  playlist <- NULL
  added_count <- length(job$uris)

  if (length(modifiable) == 1) {
    playlist <- modifiable[[1]]
    action <- if (identical(existing_policy, "overwrite")) "Overwritten" else "Updated"

    if (identical(existing_policy, "overwrite")) {
      replace_playlist_items(token, playlist_id(playlist), job$uris)
    } else {
      existing_uris <- get_playlist_track_uris(token, playlist_id(playlist))
      uris_to_add <- setdiff(job$uris, existing_uris)
      added_count <- length(uris_to_add)
      add_playlist_items(token, playlist_id(playlist), uris_to_add)
    }
  } else {
    playlist <- create_playlist(token, job$playlist_name, public)
    add_playlist_items(token, playlist_id(playlist), job$uris)
  }

  list(
    playlist_name = job$playlist_name,
    action = action,
    playlist_url = playlist_url(playlist),
    requested_rows = job$requested_rows,
    unique_tracks = job$unique_tracks,
    duplicate_rows = job$duplicate_rows,
    tracks_added = added_count
  )
}
