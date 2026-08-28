# Package: shiny
# Needed for the web app UI, server runtime, reactive values, notifications,
# progress indicators, URL query parsing, and browser redirect messages.
#
# Package: DT
# Needed for the uploaded data preview and editable manual song spreadsheet.
#
# Package: httr2
# Needed for direct HTTP requests to Spotify's authorization and Web API endpoints.
#
# Package: jsonlite
# Needed to parse Spotify JSON responses and base64-encode PKCE bytes.
#
# Package: openssl
# Needed to generate cryptographically strong PKCE random bytes and SHA-256 hashes.
required_packages <- c("shiny", "DT", "httr2", "jsonlite", "openssl")

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install required packages before running this app: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

# Optional package: readxl
# Needed only when the uploaded dataset is an Excel workbook. CSV and TSV files
# work without it, and the app shows a targeted message if readxl is unavailable.
