module.exports = (content) ->
  """
    <html>
      <head>
        <meta charset="utf-8" />
        <link rel="stylesheet" type="text/css" href="/style.css">
      </head>
      <body>
        #{content}
      </body>
    </html>
  """
