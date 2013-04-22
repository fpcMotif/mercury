#= require mercury/core/view

class Mercury.ToolbarButton extends Mercury.View

  @logPrefix: 'Mercury.ToolbarButton:'
  @className: 'mercury-toolbar-button'

  @events:
    'mousedown': 'indicate'
    'mouseup': 'deindicate'
    'mouseout': 'deindicate'
    'click': 'triggerAction'
    'mercury:region:focus': 'onRegionFocus'
    'mercury:region:action': 'onRegionUpdate'
    'mercury:region:update': 'onRegionUpdate'

  standardOptions: ['title', 'icon', 'action', 'global', 'button', 'settings']

  @create: (name, label, options = {}) ->
    if options.button && Klass = Mercury["toolbar_#{options.button}".toCamelCase(true)]
      return new Klass(name, label, options)
    if options.plugin && Klass = Mercury.getPlugin(options.plugin).Button
      return new Klass(name, label, options)
    return new Mercury.ToolbarButton(name, label, options)


  constructor: (@name, @label, @options = {}) ->
    @determineAction()
    @determineType()
    @type = @types[0]
    super(@options)


  get: (key) ->
    @[key]


  set: (key, value) ->
    attrs = {}
    if typeof(key) == 'object' then attrs = key else attrs[key] = value
    @[key] = value for key, value of attrs


  toggled: ->
    @isToggled = true
    @addClass('mercury-button-toggled')


  untoggled: ->
    @isToggled = false
    @removeClass('mercury-button-toggled')


  activate: ->
    @isActive = true
    @addClass('mercury-button-active')


  deactivate: ->
    @isActive = false
    @removeClass('mercury-button-active')


  enable: ->
    @isEnabled = true
    @removeClass('mercury-button-disabled')


  disable: ->
    @isEnabled = false
    @addClass('mercury-button-disabled')


  deindicate: ->
    @isIndicated = true
    @removeClass('mercury-button-pressed')


  indicate: (e) ->
    @isIndicated = false
    return if @isDisabled()
    if e && @subview?.visible
      @deactivate()
      e.preventDefault()
      e.stopPropagation()
    @addClass('mercury-button-pressed')


  determineAction: ->
    @action = @options.action || @name
    @action = [@action] if typeof(@action) == 'string'
    @actionName = @action[0]


  determineType: ->
    @types = []
    return @types = [@options.type] if @options.type
    @types.push(type) for type, value of @options when type not in @standardOptions


  build: ->
    @enablePlugin()
    @attr('data-type', @type)
    @attr('data-icon', Mercury.Toolbar.icons[@icon || @name] || @icon)
    @addClass("mercury-toolbar-#{@name.toDash()}-button")
    @html("<em>#{@label}</em>")
    @buildSubview()?.appendTo(@)


  buildSubview: ->
    return @subview if @subview
    if Klass = Mercury["toolbar_#{@type}".toCamelCase(true)]
      options = @options[@type]
      options = {template: options} if typeof(options) == 'string'
      return @subview = new Klass(options)


  enablePlugin: ->
    return unless @plugin
    @plugin = Mercury.getPlugin(@plugin, true)
    @plugin.buttonRegistered(@)


  triggerAction: ->
    return if @isDisabled()
    if @toggle || @mode
      unless @isToggled then @toggled() else @untoggled()
    if @subview
      if @subview.visible then @deactivate() else @activate()
      @subview.toggle()
    return @plugin.trigger('button:click') if @plugin
    return if @subview
    Mercury.trigger(@event) if @event
    Mercury.trigger('mode', @mode) if @mode
    Mercury.trigger('action', @action...)


  isDisabled: ->
    @$el.closest('.mercury-button-disabled').length


  regionSupported: (region) ->
    return @plugin.regionSupported(region) if @plugin
    region.hasAction(@actionName)


  onRegionFocus: (region) ->
    @delay(100, => @onRegionUpdate(region))


  onRegionUpdate: (region) ->
    @deactivate() unless @subview?.visible
    if @global || @regionSupported(region)
      @enable()
      @activate() if region.hasContext(@name)
    else
      @disable()
