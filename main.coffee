require "./lib/markdown"
Uploader = require "s3-uploader"

# Store posts as JSON
# Maybe a manifest json?
# Also store posts as html
# Display Ace editor to edit markdown
# Edit a stylesheet
# Upload to S3

style = document.createElement "style"
style.innerHTML = require "./style"
document.head.appendChild style
document.body.appendChild require("./template")
  actions: require("./actions")()

ace.edit('ace')
