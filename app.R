source("libraries.R")
source("functions.R")

oauth_context_store <- new.env(parent = emptyenv())

# Bumped with each release so a bug report can name the exact build it came from.
app_build <- "2026-08-28e"

app_css <- "
:root {
  --bg: #081426;
  --panel: #0f2038;
  --panel-2: #162c4a;
  --line: #23426b;
  --text: #eef3fa;
  --muted: #9db2ce;
  --gold: #d9ad3c;
  --gold-hi: #f0c85c;
  --ink: #0a1a30;
  --red: #f0748a;
  --radius: 10px;
}

html {
  font-size: 18px;
}

body {
  background: var(--bg);
  color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif;
  font-size: 1rem;
  line-height: 1.55;
}

.container-fluid {
  max-width: 1500px;
}

h1, h2, h3, h4, h5 {
  color: var(--text);
  font-weight: 650;
  letter-spacing: -0.01em;
}

a {
  color: var(--gold-hi);
}
a:hover, a:focus {
  color: var(--gold);
}

hr {
  border-top: 1px solid var(--line);
}

/* Header */
.app-title {
  background: linear-gradient(135deg, #16365e 0%, #102844 55%, #0b1c33 100%);
  border: 1px solid var(--line);
  border-top: 3px solid var(--gold);
  border-radius: var(--radius);
  padding: 26px 28px;
  margin: 6px 0 22px 0;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.45);
}
.app-title h2 {
  margin: 0 0 6px 0;
  font-size: 2rem;
  font-weight: 750;
  color: var(--gold-hi);
}
.app-title .quiet-note {
  color: rgba(238, 243, 250, 0.86);
  margin: 0;
  font-size: 1rem;
}

.quiet-note {
  color: var(--muted);
  font-size: 1rem;
}
.step-note {
  color: var(--muted);
  font-size: 1rem;
  margin: 8px 0 0 0;
  line-height: 1.55;
}

/* Panels */
.well, .sidebar-panel {
  background: var(--panel);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  box-shadow: none;
  padding: 18px;
}
.sidebar-panel h4 {
  font-size: 0.97rem;
  text-transform: uppercase;
  letter-spacing: 0.09em;
  color: var(--muted);
  margin-top: 4px;
  margin-bottom: 12px;
}

.entry-card, .callout {
  background: var(--panel);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  padding: 18px 20px;
  margin-bottom: 20px;
}
.callout {
  border-left: 3px solid var(--gold);
}

/* Form controls */
label, .control-label {
  color: var(--text);
  font-weight: 600;
  font-size: 0.98rem;
}
.form-control, .selectize-input, .copy-field {
  font-size: 1rem;
  background: var(--panel-2);
  border: 1px solid var(--line);
  border-radius: 7px;
  color: var(--text);
  box-shadow: none;
  height: auto;
  padding: 8px 11px;
}
.form-control:focus, .selectize-input.focus, .copy-field:focus {
  background: var(--panel-2);
  border-color: var(--gold);
  box-shadow: 0 0 0 3px rgba(217, 173, 60, 0.22);
  color: var(--text);
  outline: none;
}
.form-control::placeholder {
  color: #6b85a8;
}
.selectize-input, .selectize-input input, .selectize-dropdown {
  color: var(--text) !important;
  background: var(--panel-2) !important;
}
.selectize-dropdown .active {
  background: var(--gold) !important;
  color: var(--ink) !important;
}
.radio label, .checkbox label {
  font-weight: 450;
  color: #cfdcec;
  font-size: 1rem;
}
.form-control[readonly] {
  background: var(--panel-2);
}
.progress {
  background: var(--panel-2);
}
.progress-bar {
  background-color: var(--gold);
}

/* Buttons */
.btn {
  border-radius: 999px;
  font-weight: 620;
  font-size: 1rem;
  padding: 9px 19px;
  border: 1px solid var(--line);
  background: var(--panel-2);
  color: var(--text);
  transition: transform 0.06s ease, background 0.15s ease, border-color 0.15s ease;
}
.btn:hover, .btn:focus {
  background: #1d3860;
  color: var(--text);
  border-color: #2d5183;
}
.btn:active {
  transform: translateY(1px);
}
.btn-primary, .btn-success {
  background: var(--gold);
  border-color: var(--gold);
  color: var(--ink);
}
.btn-primary:hover, .btn-primary:focus, .btn-success:hover, .btn-success:focus {
  background: var(--gold-hi);
  border-color: var(--gold-hi);
  color: var(--ink);
}
.btn-sm {
  padding: 7px 15px;
  font-size: 1rem;
}

/* Tabs */
.nav-tabs {
  border-bottom: 1px solid var(--line);
}
.nav-tabs > li > a {
  font-size: 1.02rem;
  color: var(--muted);
  border: none;
  border-bottom: 2px solid transparent;
  border-radius: 0;
  font-weight: 600;
  padding: 10px 16px;
  background: transparent;
}
.nav-tabs > li > a:hover {
  background: transparent;
  color: var(--text);
  border-bottom-color: #2d5183;
}
.nav-tabs > li.active > a,
.nav-tabs > li.active > a:hover,
.nav-tabs > li.active > a:focus {
  background: transparent;
  color: var(--text);
  border: none;
  border-bottom: 2px solid var(--gold);
}
.tab-content {
  padding-top: 20px;
}

/* Status boxes */
.status-box {
  border: 1px solid var(--line);
  border-left: 3px solid var(--gold);
  background: var(--panel);
  padding: 12px 14px;
  margin: 12px 0;
  border-radius: 8px;
}
.status-box strong {
  display: block;
  font-size: 0.95rem;
  text-transform: uppercase;
  letter-spacing: 0.09em;
  color: var(--muted);
  margin-bottom: 4px;
}
.status-box p {
  margin: 0;
  color: var(--text);
  font-size: 1rem;
  line-height: 1.55;
  white-space: pre-line;
}
.error-box {
  border-left-color: var(--red);
}

/* Copy row */
.copy-row {
  display: flex;
  gap: 8px;
  margin: 10px 0 4px 0;
  max-width: 640px;
}
.copy-field {
  flex: 1 1 auto;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 0.95rem;
}
.copy-button {
  flex: 0 0 auto;
}

code {
  background: var(--panel-2);
  color: var(--gold-hi);
  border-radius: 5px;
  padding: 2px 6px;
  font-size: 0.94em;
}

/* Song entry */
.entry-action {
  margin-top: 25px;
}
.entry-action .btn {
  width: 100%;
}
.list-header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin: 4px 0 10px 0;
}
.list-header h4 {
  margin: 0;
}
.table-actions {
  margin-top: 14px;
  display: flex;
  gap: 8px;
}

/* DataTables */
.dataTables_wrapper {
  color: var(--muted);
}
table.dataTable {
  background: var(--panel);
  border-collapse: separate !important;
  border-spacing: 0;
  border-radius: var(--radius);
  overflow: hidden;
  width: 100% !important;
}
table.dataTable thead th {
  background: var(--panel-2);
  color: #c3d3e6;
  border-bottom: 1px solid var(--line) !important;
  font-size: 0.98rem;
  letter-spacing: 0.02em;
  font-weight: 700;
  padding: 12px 12px;
}
table.dataTable tbody td {
  border-top: 1px solid var(--line);
  color: var(--text);
  padding: 11px 12px;
  background: transparent;
  font-size: 1rem;
}
table.dataTable tbody tr {
  background: transparent;
}
table.dataTable tbody tr:hover td {
  background: #14294697;
}
table.dataTable tbody tr.selected td {
  background: rgba(217, 173, 60, 0.16) !important;
  box-shadow: inset 3px 0 0 var(--gold);
}
.editable-grid table.dataTable tbody td {
  cursor: text;
}
.editable-grid table.dataTable tbody td:hover {
  outline: 1px dashed #3a628f;
  outline-offset: -3px;
}
.dataTables_wrapper .dataTables_filter input,
.dataTables_wrapper .dataTables_length select,
table.dataTable thead .form-control {
  background: var(--panel-2);
  border: 1px solid var(--line);
  border-radius: 7px;
  color: var(--text);
  padding: 5px 9px;
}
.dataTables_wrapper .dataTables_info,
.dataTables_wrapper .dataTables_length,
.dataTables_wrapper .dataTables_filter,
.dataTables_wrapper .dataTables_paginate {
  color: var(--muted);
  font-size: 0.95rem;
}
.dataTables_wrapper .dataTables_paginate .paginate_button {
  color: var(--muted) !important;
  border: 1px solid transparent;
  border-radius: 7px;
  margin: 0 2px;
}
.dataTables_wrapper .dataTables_paginate .paginate_button:hover {
  background: var(--panel-2) !important;
  border-color: var(--line) !important;
  color: var(--text) !important;
}
.dataTables_wrapper .dataTables_paginate .paginate_button.current,
.dataTables_wrapper .dataTables_paginate .paginate_button.current:hover {
  background: var(--gold) !important;
  border-color: var(--gold) !important;
  color: var(--ink) !important;
}
.dataTables_wrapper .dataTables_paginate .paginate_button.disabled {
  color: #4d6a92 !important;
}
.dataTables_empty {
  color: var(--muted) !important;
  padding: 28px 12px !important;
  font-style: italic;
  font-size: 1rem;
}

.build-stamp {
  color: #5b7a9e;
  font-size: 0.92rem;
  text-align: right;
  margin: 26px 0 8px 0;
}

/* File input */
.input-group .form-control, .input-group-btn .btn {
  border-radius: 7px;
}
.progress.shiny-file-input-progress {
  background: var(--panel-2);
}

/* Notifications */
#shiny-notification-panel {
  width: 380px;
}
.shiny-notification {
  font-size: 0.98rem;
  line-height: 1.5;
  background: var(--panel-2);
  color: var(--text);
  border: 1px solid var(--line);
  border-left: 3px solid var(--gold);
  border-radius: 8px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
  opacity: 1;
}
.shiny-notification-error {
  border-left-color: var(--red);
}
.shiny-notification-close {
  color: var(--muted);
}
"

oauth_javascript <- "
var spotifyContextKey = 'spotify_oauth_context';
var spotifyClientIdKey = 'spotify_client_id';

function copySpotifyRedirect(button) {
  var field = button.parentNode.querySelector('.copy-field');
  if (!field) {
    return;
  }
  field.select();
  var done = function() {
    var original = button.getAttribute('data-label') || button.innerHTML;
    button.setAttribute('data-label', original);
    button.innerHTML = 'Copied';
    window.setTimeout(function() {
      button.innerHTML = button.getAttribute('data-label');
    }, 1500);
  };
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(field.value).then(done, function() {
      document.execCommand('copy');
      done();
    });
  } else {
    document.execCommand('copy');
    done();
  }
}

$(document).on('keydown', '#entry_artist, #entry_title, #entry_group', function(event) {
  if (event.key === 'Enter') {
    event.preventDefault();
    $('#add_song').click();
  }
});

Shiny.addCustomMessageHandler('focusEntry', function(id) {
  var field = document.getElementById(id);
  if (field) {
    field.focus();
  }
});

Shiny.addCustomMessageHandler('rememberClientId', function(value) {
  try {
    if (value) {
      window.localStorage.setItem(spotifyClientIdKey, value);
    } else {
      window.localStorage.removeItem(spotifyClientIdKey);
    }
  } catch (error) {
    // Storage can be blocked; remembering the Client ID is only a convenience.
  }
});

$(document).on('shiny:sessioninitialized', function() {
  var stored = '';
  try {
    stored = window.sessionStorage.getItem(spotifyContextKey) || '';
  } catch (error) {
    stored = '';
  }
  Shiny.setInputValue('stored_oauth_context', stored, {priority: 'event'});

  var savedClientId = '';
  try {
    savedClientId = window.localStorage.getItem(spotifyClientIdKey) || '';
  } catch (error) {
    savedClientId = '';
  }
  Shiny.setInputValue('stored_client_id', savedClientId, {priority: 'event'});
});

Shiny.addCustomMessageHandler('storeOauthContext', function(payload) {
  try {
    window.sessionStorage.setItem(spotifyContextKey, payload);
  } catch (error) {
    // Private browsing can block sessionStorage; the in-process store still applies.
  }
});

Shiny.addCustomMessageHandler('clearOauthContext', function(message) {
  try {
    window.sessionStorage.removeItem(spotifyContextKey);
  } catch (error) {
    // Nothing to clean up when sessionStorage is unavailable.
  }
});

Shiny.addCustomMessageHandler('spotifyRedirect', function(url) {
  window.location.href = url;
});

Shiny.addCustomMessageHandler('replaceUrl', function(path) {
  window.history.replaceState({}, document.title, path || '/');
});
"

ui <- shiny::fluidPage(
  shiny::tags$head(
    shiny::tags$style(shiny::HTML(app_css)),
    shiny::tags$script(shiny::HTML(oauth_javascript))
  ),
  shiny::div(
    class = "app-title",
    shiny::tags$h2("Spotify Playlist Builder"),
    shiny::tags$p(
      class = "quiet-note",
      "Upload or type songs, match them against Spotify, then create clean playlists without repeated tracks."
    )
  ),
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      class = "sidebar-panel",
      width = 3,
      shiny::tags$h4("Spotify credentials"),
      shiny::textInput("client_id", "Client ID", value = ""),
      shiny::textInput("redirect_uri", "Redirect URI", value = ""),
      shiny::tags$p(
        class = "quiet-note",
        "Only the Client ID is needed. Sign-in uses PKCE, so never paste your client secret here."
      ),
      shiny::actionButton("connect_spotify", "Connect to Spotify", class = "btn-primary"),
      shiny::uiOutput("auth_status"),
      shiny::tags$hr(),
      shiny::tags$h4("Playlist options"),
      shiny::textInput("playlist_name", "Playlist name", value = "Imported songs"),
      shiny::radioButtons(
        "song_source",
        "Song source",
        choices = c("Uploaded dataset" = "upload", "Typed spreadsheet" = "manual"),
        selected = "upload"
      ),
      shiny::checkboxInput("filter_explicit", "Filter out explicit songs", value = TRUE),
      shiny::radioButtons(
        "playlist_visibility",
        "Playlist visibility",
        choices = c("Private" = "private", "Public" = "public"),
        selected = "private"
      ),
      shiny::conditionalPanel(
        condition = "output.hasGroup",
        shiny::radioButtons(
          "group_mode",
          "When a group variable is present",
          choices = c(
            "Create one playlist for each group" = "split",
            "Create one giant playlist" = "combined"
          ),
          selected = "combined"
        )
      ),
      shiny::radioButtons(
        "existing_policy",
        "If a playlist with the same name exists",
        choices = c(
          "Warn me before changing anything" = "warn",
          "Include only the new songs" = "append",
          "Overwrite it" = "overwrite"
        ),
        selected = "warn"
      ),
      shiny::actionButton("preview_tracks", "Preview matches"),
      shiny::actionButton("create_playlist", "Create playlist", class = "btn-success")
    ),
    shiny::mainPanel(
      width = 9,
      shiny::tabsetPanel(
        id = "main_tabs",
        shiny::tabPanel(
          "API setup",
          shiny::div(
            class = "instruction-block",
            shiny::div(
              class = "callout",
              shiny::tags$strong("First time here? This takes about three minutes."),
              shiny::tags$p(
                class = "step-note",
                "Spotify requires every person to connect through their own free developer app. You only do this once. Nothing you create here is shared with anyone else, and playlists are always built in your own Spotify account."
              )
            ),
            shiny::tags$h3("Step 1. Create your Spotify app"),
            shiny::tags$p(
              "Open the ",
              shiny::tags$a(
                href = "https://developer.spotify.com/dashboard",
                target = "_blank",
                rel = "noopener",
                "Spotify Developer Dashboard"
              ),
              " and sign in with your normal Spotify account, then click ",
              shiny::tags$strong("Create app"),
              "."
            ),
            shiny::tags$p(
              class = "step-note",
              "App name and description can be anything, for example \"My playlist builder\". A website is not required."
            ),
            shiny::tags$h3("Step 2. Add this redirect URI"),
            shiny::tags$p(
              "Paste this into the ",
              shiny::tags$strong("Redirect URIs"),
              " box, then click ",
              shiny::tags$strong("Add"),
              ":"
            ),
            shiny::uiOutput("redirect_uri_hint"),
            shiny::tags$p(
              class = "step-note",
              "It must match exactly, including the trailing slash. A mismatch here is the single most common reason sign-in fails."
            ),
            shiny::tags$h3("Step 3. Select the Web API"),
            shiny::tags$p(
              "Under ",
              shiny::tags$strong("Which API/SDKs are you planning to use?"),
              " tick ",
              shiny::tags$strong("Web API"),
              ", accept the terms, and save."
            ),
            shiny::tags$h3("Step 4. Copy your Client ID"),
            shiny::tags$p(
              "Open your new app's ",
              shiny::tags$strong("Settings"),
              ", copy the ",
              shiny::tags$strong("Client ID"),
              ", and paste it into the sidebar on the left. Then click ",
              shiny::tags$strong("Connect to Spotify"),
              " and approve the permissions."
            ),
            shiny::tags$p(
              class = "step-note",
              "Leave the Client Secret where it is. This app signs in with PKCE and never asks for it. Your Client ID is remembered in this browser so you can skip these steps next time."
            ),
            shiny::tags$hr(),
            shiny::tags$h4("Permissions this app requests"),
            shiny::tags$ul(
              shiny::tags$li(
                shiny::tags$code("playlist-modify-public"),
                " and ",
                shiny::tags$code("playlist-modify-private"),
                " to create or update playlists."
              ),
              shiny::tags$li(
                shiny::tags$code("playlist-read-private"),
                " and ",
                shiny::tags$code("playlist-read-collaborative"),
                " to detect existing playlists."
              ),
              shiny::tags$li(
                shiny::tags$code("user-read-private"),
                " to identify your Spotify account for playlist ownership checks."
              )
            ),
            shiny::tags$h4("Common problems"),
            shiny::tags$ul(
              shiny::tags$li(
                shiny::tags$strong("INVALID_CLIENT: Invalid redirect URI"),
                " means the value in step 2 does not match. Re-copy it with the button above and check for a missing trailing slash."
              ),
              shiny::tags$li(
                shiny::tags$strong("INVALID_CLIENT: Invalid client"),
                " means the Client ID was mistyped or truncated. Copy it again from your app's Settings page."
              ),
              shiny::tags$li(
                "Your own app starts in development mode, which is fine. You are its only user, so there is nothing to configure."
              )
            ),
            shiny::tags$p(
              class = "quiet-note",
              "Your Client ID is used only to complete your own Spotify sign-in and is stored in your browser, not on the server. Nothing is written to disk, and the app never asks for your client secret."
            )
          )
        ),
        shiny::tabPanel(
          "Upload dataset",
          shiny::fileInput(
            "song_file",
            "Upload a song dataset",
            accept = c(".csv", ".tsv", ".txt", ".xls", ".xlsx")
          ),
          shiny::fluidRow(
            shiny::column(4, shiny::selectInput("artist_col", "Column with song authors or artists", choices = character(0))),
            shiny::column(4, shiny::selectInput("title_col", "Column with song titles", choices = character(0))),
            shiny::column(4, shiny::selectInput("group_col", "Optional grouping column", choices = c("No grouping column" = "")))
          ),
          DT::DTOutput("uploaded_preview")
        ),
        shiny::tabPanel(
          "Type songs",
          shiny::div(
            class = "entry-card",
            shiny::tags$h4("Add a song"),
            shiny::tags$p(
              class = "step-note",
              "Fill in the artist and the song title, then press Add. Songs are added one at a time and appear in the list below."
            ),
            shiny::fluidRow(
              shiny::column(
                4,
                shiny::textInput("entry_artist", "Artist or author", value = "", placeholder = "Fleetwood Mac")
              ),
              shiny::column(
                4,
                shiny::textInput("entry_title", "Song title", value = "", placeholder = "Dreams")
              ),
              shiny::column(
                3,
                shiny::textInput("entry_group", "Group (optional)", value = "", placeholder = "Road trip")
              ),
              shiny::column(
                1,
                shiny::div(
                  class = "entry-action",
                  shiny::actionButton("add_song", "Add", class = "btn-success")
                )
              )
            ),
            shiny::tags$p(
              class = "step-note",
              "Press Enter from any box to add the song. Group is optional: give songs different group names and you can create one playlist per group."
            )
          ),
          shiny::div(
            class = "list-header",
            shiny::tags$h4(shiny::textOutput("manual_count", inline = TRUE))
          ),
          shiny::div(
            class = "editable-grid",
            DT::DTOutput("manual_table")
          ),
          shiny::div(
            class = "table-actions",
            shiny::actionButton("remove_manual_rows", "Remove selected"),
            shiny::actionButton("clear_manual", "Clear all")
          ),
          shiny::tags$p(
            class = "step-note",
            "Double-click a cell to correct it. Click a row to select it, then choose Remove selected."
          )
        )
      ),
      shiny::tags$hr(),
      shiny::uiOutput("run_summary"),
      DT::DTOutput("match_table")
    )
  ),
  shiny::tags$p(
    class = "build-stamp",
    paste("Build", app_build)
  )
)

server <- function(input, output, session) {
  spotify_token <- shiny::reactiveVal(NULL)
  spotify_user <- shiny::reactiveVal(NULL)
  auth_message <- shiny::reactiveVal("Not connected.")
  match_preview <- shiny::reactiveVal(NULL)
  run_result <- shiny::reactiveVal(NULL)
  processed_oauth_state <- shiny::reactiveVal("")

  empty_manual_data <- function() {
    data.frame(
      artist = character(0),
      title = character(0),
      group = character(0),
      stringsAsFactors = FALSE
    )
  }

  manual_data <- shiny::reactiveVal(empty_manual_data())

  # The sidebar radio and the visible tab drifted apart too easily, which aborted
  # runs with no visible reason, so follow whichever tab the user moves to.
  shiny::observeEvent(input$main_tabs, {
    if (identical(input$main_tabs, "Type songs")) {
      shiny::updateRadioButtons(session, "song_source", selected = "manual")
    } else if (identical(input$main_tabs, "Upload dataset")) {
      shiny::updateRadioButtons(session, "song_source", selected = "upload")
    }
  }, ignoreInit = TRUE)

  uploaded_data <- shiny::reactive({
    shiny::req(input$song_file)
    read_uploaded_dataset(input$song_file$datapath, input$song_file$name)
  })

  shiny::observeEvent(uploaded_data(), {
    dataset <- uploaded_data()
    columns <- names(dataset)

    shiny::updateSelectInput(
      session,
      "artist_col",
      choices = columns,
      selected = guess_column(columns, c("artist", "author", "singer", "performer", "band"))
    )
    shiny::updateSelectInput(
      session,
      "title_col",
      choices = columns,
      selected = guess_column(columns, c("title", "song", "track", "name"), fallback = columns[min(2, length(columns))])
    )
    shiny::updateSelectInput(
      session,
      "group_col",
      choices = c("No grouping column" = "", columns),
      selected = guess_column(columns, c("group", "playlist", "category", "album", "genre"), fallback = "")
    )
  })

  output$uploaded_preview <- DT::renderDT({
    shiny::req(uploaded_data())
    DT::datatable(
      uploaded_data(),
      rownames = FALSE,
      options = list(pageLength = 10, scrollX = TRUE)
    )
  })

  output$manual_count <- shiny::renderText({
    count <- nrow(manual_data())
    if (count == 0) "No songs added yet" else paste(count, if (count == 1) "song added" else "songs added")
  })

  output$manual_table <- DT::renderDT({
    DT::datatable(
      manual_data(),
      rownames = FALSE,
      colnames = c("Artist or author", "Song title", "Group"),
      editable = "cell",
      selection = "multiple",
      options = list(
        pageLength = 12,
        lengthChange = FALSE,
        searching = FALSE,
        ordering = FALSE,
        scrollX = TRUE,
        columnDefs = list(list(targets = 2, defaultContent = "")),
        language = list(
          emptyTable = "No songs yet. Use the Add a song box above to enter your first one."
        )
      )
    )
  }, server = FALSE)

  shiny::observeEvent(input$manual_table_cell_edit, {
    edited <- DT::editData(manual_data(), input$manual_table_cell_edit, rownames = FALSE)
    edited[] <- lapply(edited, clean_text)
    manual_data(edited)
  })

  shiny::observeEvent(input$add_song, {
    artist <- clean_text(input$entry_artist %||% "")
    title <- clean_text(input$entry_title %||% "")
    group <- clean_text(input$entry_group %||% "")

    if (!nzchar(artist) || !nzchar(title)) {
      shiny::showNotification("Enter both an artist and a song title before adding.", type = "error")
      return()
    }

    existing <- manual_data()
    duplicate <- any(
      normalise_key(existing$artist) == normalise_key(artist) &
        normalise_key(existing$title) == normalise_key(title)
    )
    if (duplicate) {
      shiny::showNotification("That song is already in the list.", type = "warning")
      return()
    }

    manual_data(rbind(
      existing,
      data.frame(artist = artist, title = title, group = group, stringsAsFactors = FALSE)
    ))

    # Keep the group so a run of songs for one playlist can be typed without retyping it.
    shiny::updateTextInput(session, "entry_artist", value = "")
    shiny::updateTextInput(session, "entry_title", value = "")
    session$sendCustomMessage("focusEntry", "entry_artist")
  })

  shiny::observeEvent(input$clear_manual, {
    if (nrow(manual_data()) == 0) {
      shiny::showNotification("The song list is already empty.", type = "message")
      return()
    }

    manual_data(empty_manual_data())
    shiny::showNotification("Song list cleared.", type = "message")
  })

  shiny::observeEvent(input$remove_manual_rows, {
    selected <- input$manual_table_rows_selected
    if (length(selected) == 0) {
      shiny::showNotification("Click one or more rows in the list to select them first.", type = "message")
      return()
    }

    manual_data(manual_data()[-selected, , drop = FALSE])
  })

  output$hasGroup <- shiny::reactive({
    if (identical(input$song_source, "upload")) {
      return(nzchar(input$group_col %||% ""))
    }

    typed <- manual_data()
    any(nzchar(clean_text(typed$group)))
  })
  shiny::outputOptions(output, "hasGroup", suspendWhenHidden = FALSE)

  source_songs <- shiny::reactive({
    if (identical(input$song_source, "upload")) {
      if (is.null(input$song_file)) {
        user_stop(paste(
          "Song source is set to 'Uploaded dataset' but no file has been uploaded.",
          "Upload one on the Upload dataset tab, or set Song source to 'Typed spreadsheet'",
          "if you entered your songs on the Type songs tab."
        ))
      }

      dataset <- uploaded_data()
      artist_col <- input$artist_col %||% ""
      title_col <- input$title_col %||% ""

      if (!nzchar(artist_col) || !artist_col %in% names(dataset)) {
        user_stop("Choose the dataset column that contains song authors or artists.")
      }
      if (!nzchar(title_col) || !title_col %in% names(dataset)) {
        user_stop("Choose the dataset column that contains song titles.")
      }

      group_col <- input$group_col %||% ""
      groups <- if (nzchar(group_col) && group_col %in% names(dataset)) {
        dataset[[group_col]]
      } else {
        rep("", nrow(dataset))
      }

      songs <- data.frame(
        source_row = seq_len(nrow(dataset)),
        artist = clean_text(dataset[[artist_col]]),
        title = clean_text(dataset[[title_col]]),
        group = clean_text(groups),
        stringsAsFactors = FALSE
      )
    } else {
      typed <- manual_data()
      songs <- data.frame(
        source_row = seq_len(nrow(typed)),
        artist = clean_text(typed$artist),
        title = clean_text(typed$title),
        group = clean_text(typed$group),
        stringsAsFactors = FALSE
      )
    }

    blank_rows <- !nzchar(songs$artist) & !nzchar(songs$title)
    partial_rows <- xor(nzchar(songs$artist), nzchar(songs$title))
    if (any(partial_rows)) {
      user_stop("Every song row needs both an artist and a title. Remove or complete partial rows.")
    }

    songs <- songs[!blank_rows, , drop = FALSE]
    if (nrow(songs) == 0) {
      user_stop("Add at least one song with both an artist and a title.")
    }

    songs$query_key <- paste(normalise_key(songs$artist), normalise_key(songs$title), sep = "||")
    songs$group_label <- songs$group
    songs$group_label[!nzchar(songs$group_label)] <- "Ungrouped"
    songs
  })

  # The redirect URI must match wherever the app is actually served from, so it is
  # filled in from the live browser URL instead of a hard-coded localhost address.
  shiny::observeEvent(session$clientData$url_hostname, {
    shiny::updateTextInput(session, "redirect_uri", value = current_redirect_uri(session))
  }, once = TRUE, ignoreNULL = TRUE)

  output$redirect_uri_hint <- shiny::renderUI({
    shiny::div(
      class = "copy-row",
      shiny::tags$input(
        type = "text",
        class = "copy-field",
        readonly = NA,
        value = current_redirect_uri(session),
        onclick = "this.select();"
      ),
      shiny::tags$button(
        type = "button",
        class = "btn btn-default copy-button",
        onclick = "copySpotifyRedirect(this);",
        "Copy"
      )
    )
  })

  # Returning visitors should not have to re-paste a Client ID that is not secret.
  # Skip the restore mid-login so it cannot overwrite the value carried through OAuth.
  shiny::observeEvent(input$stored_client_id, {
    saved <- clean_text(input$stored_client_id %||% "")
    mid_login <- nzchar(parse_oauth_query(session$clientData$url_search)$code %||% "")

    if (nzchar(saved) && !mid_login && !nzchar(clean_text(input$client_id %||% ""))) {
      shiny::updateTextInput(session, "client_id", value = saved)
    }
  }, once = TRUE, ignoreNULL = TRUE)

  shiny::observe({
    query <- parse_oauth_query(session$clientData$url_search)
    code <- query$code %||% ""
    state <- query$state %||% ""
    oauth_error <- query$error %||% ""

    if (!nzchar(code) && !nzchar(oauth_error)) {
      return(NULL)
    }

    if (nzchar(state) && identical(processed_oauth_state(), state)) {
      return(NULL)
    }

    context <- get_oauth_context(oauth_context_store, state)

    if (is.null(context)) {
      # A hosted deployment can answer the callback from a different R worker than the
      # one that started the login, so fall back to the copy kept in the browser tab.
      stored_context <- input$stored_oauth_context
      if (is.null(stored_context)) {
        return(NULL)
      }
      context <- decode_oauth_context(stored_context, state)
    }

    processed_oauth_state(state)

    clear_path <- session$clientData$url_pathname %||% "/"
    session$sendCustomMessage("replaceUrl", clear_path)
    session$sendCustomMessage("clearOauthContext", TRUE)

    restore_inputs <- function() {
      if (is.null(context)) {
        return(invisible(NULL))
      }
      shiny::updateTextInput(session, "client_id", value = context$raw_client_id %||% context$client_id)
      shiny::updateTextInput(session, "redirect_uri", value = context$raw_redirect_uri %||% context$redirect_uri)
      invisible(NULL)
    }

    if (nzchar(oauth_error)) {
      restore_inputs()
      drop_oauth_context(oauth_context_store, state)
      auth_message(paste0("Spotify authorization failed: ", oauth_error))
      shiny::showNotification(auth_message(), type = "error", duration = 10)
      return(NULL)
    }

    if (is.null(context)) {
      auth_message("Spotify authorization could not be completed because the login session was not found. Click Connect to Spotify and try again.")
      shiny::showNotification(auth_message(), type = "error", duration = 10)
      return(NULL)
    }

    tryCatch({
      token <- request_spotify_token(
        client_id = context$client_id,
        client_secret = "",
        redirect_uri = context$redirect_uri,
        code = code,
        code_verifier = context$code_verifier
      )
      user <- get_current_user(token)

      spotify_token(token)
      spotify_user(user)
      drop_oauth_context(oauth_context_store, state)
      shiny::updateTextInput(session, "client_id", value = context$client_id)
      shiny::updateTextInput(session, "redirect_uri", value = context$redirect_uri)
      auth_message(paste0("Connected as ", user$display_name %||% user$id %||% "Spotify user", "."))
      shiny::showNotification("Connected to Spotify.", type = "message")
    }, error = function(error) {
      restore_inputs()
      drop_oauth_context(oauth_context_store, state)
      spotify_token(NULL)
      spotify_user(NULL)
      explained <- explain_auth_error(conditionMessage(error), context$redirect_uri %||% "")
      auth_message(explained)
      shiny::showNotification(explained, type = "error", duration = 14)
    })

    NULL
  })

  shiny::observeEvent(input$connect_spotify, {
    raw_client_id <- input$client_id %||% ""
    raw_redirect_uri <- input$redirect_uri %||% ""

    client_id <- clean_text(raw_client_id)
    redirect_uri <- clean_text(raw_redirect_uri)

    if (!nzchar(redirect_uri)) {
      redirect_uri <- current_redirect_uri(session)
      raw_redirect_uri <- redirect_uri
      shiny::updateTextInput(session, "redirect_uri", value = redirect_uri)
    }

    if (!nzchar(client_id)) {
      shiny::showNotification("Enter your Spotify Client ID.", type = "error")
      return()
    }

    state <- generate_oauth_state()
    context <- list(
      client_id = client_id,
      redirect_uri = redirect_uri,
      code_verifier = generate_pkce_verifier(),
      state = state,
      raw_client_id = raw_client_id,
      raw_redirect_uri = raw_redirect_uri
    )

    store_oauth_context(oauth_context_store, state, context)
    session$sendCustomMessage("storeOauthContext", encode_oauth_context(context))
    session$sendCustomMessage("rememberClientId", client_id)

    authorize_url <- build_spotify_authorize_url(
      client_id = client_id,
      redirect_uri = redirect_uri,
      state = state,
      code_verifier = context$code_verifier
    )

    auth_message("Redirecting to Spotify for authorization...")
    session$sendCustomMessage("spotifyRedirect", authorize_url)
  })

  output$auth_status <- shiny::renderUI({
    connected <- !is.null(spotify_token())
    shiny::div(
      class = if (connected) "status-box" else "status-box error-box",
      shiny::tags$strong(if (connected) "Status" else "Not connected"),
      shiny::tags$p(auth_message()),
      if (!connected) {
        shiny::tags$p(
          class = "quiet-note",
          "New here? Open the API setup tab for a short walkthrough."
        )
      }
    )
  })

  shiny::observeEvent(input$preview_tracks, {
    tryCatch({
      preview <- build_match_preview(spotify_token(), source_songs(), isTRUE(input$filter_explicit))
      match_preview(preview)
      run_result(NULL)
      shiny::showNotification("Track matching preview is ready.", type = "message")
    }, error = function(error) {
      shiny::showNotification(readable_error(error), type = "error", duration = 12)
    })
  })

  shiny::observeEvent(input$create_playlist, {
    token <- spotify_token()
    user <- spotify_user()

    if (is.null(token) || is.null(user)) {
      shiny::showNotification("Connect to Spotify before creating playlists.", type = "error")
      return()
    }

    playlist_name_input <- clean_text(input$playlist_name)
    if (!nzchar(playlist_name_input)) {
      shiny::showNotification("Enter a playlist name.", type = "error")
      return()
    }

    tryCatch({
      preview <- build_match_preview(spotify_token(), source_songs(), isTRUE(input$filter_explicit))
      match_preview(preview)

      has_group <- any(nzchar(clean_text(preview$group)))
      split_by_group <- has_group && identical(input$group_mode %||% "combined", "split")
      public <- identical(input$playlist_visibility, "public")

      jobs <- prepare_playlist_jobs(preview, playlist_name_input, split_by_group)
      playlists <- get_current_user_playlists(token)
      current_user_id <- user$id %||% ""

      preflight_existing_playlists(
        jobs,
        playlists,
        current_user_id,
        input$existing_policy
      )

      results <- vector("list", length(jobs))
      shiny::withProgress(message = "Writing playlists to Spotify", value = 0, {
        for (index in seq_along(jobs)) {
          results[[index]] <- write_playlist_job(
            token,
            jobs[[index]],
            playlists,
            current_user_id,
            input$existing_policy,
            public
          )
          shiny::incProgress(1 / length(jobs))
        }
      })

      result_table <- data_frame_from_rows(results)
      run_result(list(error = NULL, table = result_table))
      shiny::showNotification("Playlist creation finished.", type = "message")
    }, error = function(error) {
      explained <- readable_error(error)
      run_result(list(error = explained, table = NULL))
      shiny::showNotification(explained, type = "error", duration = 14)
    })
  })

  output$run_summary <- shiny::renderUI({
    result <- run_result()
    preview <- match_preview()

    summary_bits <- list()

    if (!is.null(result) && !is.null(result$error)) {
      summary_bits <- c(summary_bits, list(
        shiny::div(
          class = "status-box error-box",
          shiny::tags$strong("Playlist not created"),
          shiny::tags$p(result$error)
        )
      ))
    }

    if (!is.null(result) && is.null(result$error) && !is.null(result$table)) {
      rows <- lapply(seq_len(nrow(result$table)), function(index) {
        row <- result$table[index, , drop = FALSE]
        shiny::tags$li(
          shiny::tags$strong(row$playlist_name),
          ": ",
          row$action,
          ", ",
          row$tracks_added,
          " tracks added. ",
          shiny::tags$a(href = row$playlist_url, target = "_blank", "Open playlist")
        )
      })

      summary_bits <- c(summary_bits, list(
        shiny::div(
          class = "status-box",
          shiny::tags$strong("Playlist work completed"),
          shiny::tags$ul(rows)
        )
      ))
    }

    if (!is.null(preview)) {
      matched_count <- sum(preview$matched, na.rm = TRUE)
      no_match_count <- sum(preview$status == "No match", na.rm = TRUE)
      filtered_count <- sum(preview$status == "Filtered explicit", na.rm = TRUE)

      summary_bits <- c(summary_bits, list(
        shiny::div(
          class = "status-box",
          shiny::tags$strong("Latest match preview"),
          shiny::tags$p(
            matched_count,
            " matched, ",
            no_match_count,
            " not found, ",
            filtered_count,
            " filtered for explicit content."
          )
        )
      ))
    }

    if (length(summary_bits) == 0) {
      return(NULL)
    }

    do.call(shiny::tagList, summary_bits)
  })

  output$match_table <- DT::renderDT({
    shiny::req(match_preview())

    display <- match_preview()[, c(
      "source_row",
      "group",
      "input_artist",
      "input_title",
      "status",
      "spotify_artist",
      "spotify_title",
      "explicit",
      "message",
      "spotify_url"
    ), drop = FALSE]

    DT::datatable(
      display,
      rownames = FALSE,
      filter = "top",
      options = list(pageLength = 15, scrollX = TRUE)
    )
  })
}

shiny::shinyApp(ui, server)
