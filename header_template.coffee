module.exports = (content, cssClass) ->
  """
    <html>
      <head>
        <meta charset="utf-8" />
        <link rel="stylesheet" type="text/css" href="/style.css">
      </head>
      <body class="#{cssClass}">
        #{content}
      </body>
    </html>
  """
