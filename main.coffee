require "cornerstone"
require "./lib/markdown"

# Store posts as JSON
# Also store posts as html
# Display Ace editor to edit markdown
# Stylesheet
# Header
# Navigation
# Manifest JSON
# Filetree

style = document.createElement "style"
style.innerHTML = require "./style"
document.head.appendChild style
document.body.appendChild require("./template")
  actions: require("./actions")()

global.editor = ace.edit('ace')
