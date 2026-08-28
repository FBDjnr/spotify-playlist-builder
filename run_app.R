# Local development entry point.
#
# Run this from the repository root to serve the app on the loopback address that
# Spotify accepts for local testing. Add http://127.0.0.1:3838/ to your Spotify
# app's redirect URIs before connecting.
shiny::runApp(
  ".",
  host = "127.0.0.1",
  port = 3838,
  launch.browser = TRUE
)
