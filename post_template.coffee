entityMap =
    "&": "&amp;"
    "<": "&lt;"
    ">": "&gt;"
    '"': '&quot;'
    "'": '&#39;'
    "/": '&#x2F;'

escapeHTML = (string) ->
  String(string).replace /[&<>"'\/]/g, (s) ->
    entityMap[s]

module.exports = (post) ->
  # Stylesheet
  # Post content

  """
    <html>
      <head>
        <meta charset="utf-8" />
        <title>#{escapeHTML post.title}</title>
        <link rel="stylesheet" type="text/css" href="/style.css">
      </head>
      <body>
        <iframe src="/header.html" id="header"></iframe>
        <main>
          <iframe src="/navigation.html" id="navigation"></iframe>
          <content>#{post.html}</content>
        </main>
      </body>
    </html>
  """
