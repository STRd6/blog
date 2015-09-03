module.exports = ->
  actions =
    preview: ->
    load: ->
      if name = prompt "Name"
        console.log name
    save: ->

  Object.keys(actions).map (name) ->
    name: name
    fn: actions[name]
