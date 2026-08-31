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

The app is public and anyone can use it. Spotify requires each person to connect
through their own free developer app, which takes about three minutes and is a
one-time setup. Your playlists are always created in your own Spotify account.

1. Open the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and
   sign in with your normal Spotify account. Click your profile in the top right
   corner, choose **Dashboard**, then click **Create app**. The name and description
   can be anything; a website is not required.
2. Paste the hosted app's URL into **Redirect URIs** and click **Add**. The app's
   **API setup** tab shows the exact string with a Copy button — it must match
   exactly, trailing slash included.
3. Under **Which API/SDKs are you planning to use?**, tick **Web API**, accept the
   terms, and save.
4. Copy the **Client ID** from your app's Settings page into the sidebar, then click
   **Connect to Spotify** and approve the permissions.

Your Client ID is remembered in your browser, so you only do this once per device.
Your own Spotify app stays in development mode, which is fine — you are its only
user, so there is nothing further to configure.

### Why you need your own Spotify app

A Spotify app in development mode allows at most 25 users, each added by hand in the
dashboard. Having every visitor bring their own app removes that ceiling entirely, so
the hosted app can be shared with anyone. It also means each person gets their own
API rate-limit budget rather than competing for a shared one.

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
