angular.module('classy.computed', ['classy.core']).classy.plugin.controller
  localInject: ['$parse']
  
  options:
    enabled: true

  isActive: (klass, deps) ->
    if @options.enabled and angular.isObject(klass.computed)
      if !deps.$scope
        throw new Error "You need to inject `$scope` to use computed properties"
        return false

      return true

  postInit: (klass, deps, module) ->
    if !@isActive(klass, deps) then return

    for prop, computeUsing of klass.computed
      if angular.isFunction computeUsing
        @registerGet(prop, computeUsing, klass, deps)
      else if angular.isObject computeUsing
        @registerAdvanced(prop, computeUsing, klass, deps)

  registerGet: (prop, getFn, klass, deps) ->
    getter = @$parse prop
    setter = getter.assign
    boundFn = angular.bind(klass, getFn)

    deps.$scope.$watch boundFn, (newVal) ->
      setter deps.$scope, newVal

  registerGetWithWatch: (prop, obj, klass, deps) ->
    watch = "[#{obj.watch.toString()}]"

    getter = @$parse prop
    setter = getter.assign
    boundFn = angular.bind(klass, obj.get)

    deps.$scope.$watchCollection watch, ->
      setter deps.$scope, boundFn()

  registerSet: (prop, setFn, klass, deps) ->
    boundFn = angular.bind(klass, setFn)
    getter = @$parse prop
    deps.$scope.$watch prop, boundFn

  registerAdvanced: (prop, obj, klass, deps) ->
    if typeof obj.get is 'function'
      if obj.watch
        @registerGetWithWatch(prop, obj, klass, deps)
      else
        @registerGet(prop, obj.get, klass, deps)

    if typeof obj.set is 'function'
      @registerSet(prop, obj.set, klass, deps)