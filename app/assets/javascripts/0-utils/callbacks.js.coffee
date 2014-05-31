# Original Author: David Morrow
# https://github.com/dperrymorrow/callbacks.js
# MIT license
#
# Modified:
# - Rename method names. For example, remove `Callback`
# - Fix `remove`
# - Remove `instance`, change `method` from string to real method
# - Callbacks.add = Callbacks.get().add

class @Callbacks

  constructor: ->
    @triggerMap = {}

  add: (trigger, method) ->
    (@triggerMap[trigger] ||= []).push {trigger, method}
    return

  remove: (trigger, method) ->
    triggers = @triggerMap[trigger]
    return if !triggers
    @triggerMap[trigger] = (listener for listener in triggers when listener.method != method)
    return

  removeAll: (trigger) ->
    if trigger
      @triggerMap[trigger] = null
    else
      @triggerMap = {}
    return

  fire: (trigger) ->
    return if !@triggerMap[trigger]
    for listener in @triggerMap[trigger]
      methodArguments = [] # Array.prototype.slice(arguments) won't work in nodejs
      for argument, i in arguments
        methodArguments.push argument if i != 0
      listener.method.apply null, methodArguments
    return

  _instance = new @

  @get: -> _instance
  @add: _instance.add.bind(_instance)
  @fire: _instance.fire.bind(_instance)
  @removeAll: _instance.removeAll.bind(_instance)
  @remove: _instance.remove.bind(_instance)
