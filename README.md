# Spotify Playlist Builder

A Shiny app that turns a list of songs into Spotify playlists. Upload a spreadsheet
or type songs directly, match them against the Spotify catalog, review what matched,
then create or update playlists in your own Spotify account without duplicate tracks.

## What it does

- Reads songs from a CSV, TSV, TXT, XLS, or XLSX upload, or from an editable in-app table.
- Guesses which columns hold the artist, title, and optional grouping variable.
- Searches Spotify for each song and scores candidate tracks against your artist and title.
- Optionally filters out explicit tracks.
- Creates one playlist per group, or one combined playlist.
- Handles a name collision with an existing playlist by warning you, appending only new
  songs, or overwriting it.
- Shows a per-song match table so you can see what was found, what was not, and why.

## Sign-in and privacy

The app never ships with credentials. Each user connects with their own Spotify
developer app using the Authorization Code flow with PKCE, so **no client secret is
ever requested or transmitted**. Your access token lives only in your Shiny session
and is never written to disk.

## Using the hosted app

1. Open the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and create an app.
2. In the app's settings, add the hosted app's URL as a **Redirect URI**. The app's
   "API setup" tab shows the exact string to paste.
3. Copy the **Client ID** into the app's sidebar and click **Connect to Spotify**.
4. While your Spotify app is in development mode, only accounts you add under
   **User Management** can sign in. Add anyone else you want to share it with.

## Running it locally

Requires R with `shiny`, `DT`, `httr2`, `jsonlite`, and `openssl`. `readxl` is optional
and only needed for Excel uploads.

```r
install.packages(c("shiny", "DT", "httr2", "jsonlite", "openssl", "readxl"))
shiny::runApp(".")   # or: source("run_app.R")
```

`run_app.R` serves on `http://127.0.0.1:3838/`, which is a valid Spotify redirect URI
for local testing. Add that exact string to your Spotify app alongside the hosted URL.

## Deploying to Posit Connect Cloud

`manifest.json` in this repository describes the R version and package dependencies.

1. Push this repository to GitHub.
2. Go to [connect.posit.cloud](https://connect.posit.cloud), sign in, and choose
   **New Content → Shiny → R**.
3. Pick this repository and `app.R` as the entry point, then deploy.
4. Copy the resulting `https://…` URL into your Spotify app's Redirect URIs.

Pushes to the default branch trigger a redeploy. Regenerate the manifest whenever
dependencies change:

```r
rsconnect::writeManifest(appDir = ".")
```

## Repository layout

| File | Purpose |
| --- | --- |
| `app.R` | Shiny UI and server, including the OAuth callback handling. |
| `functions.R` | Spotify API calls, track matching, playlist writing, and OAuth helpers. |
| `libraries.R` | Dependency check with an actionable message when a package is missing. |
| `run_app.R` | Local development launcher on port 3838. |
| `manifest.json` | Dependency lock file read by Posit Connect Cloud. |

## License

MIT. See [LICENSE](LICENSE).
