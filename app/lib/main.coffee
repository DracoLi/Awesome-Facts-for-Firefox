###
# By Draco Li $$$
###

widgets = require 'widget'
pageMod = require 'page-mod'
tabs = require 'tabs'
data = require('self').data
panels = require 'panel'
simpleStorage = require 'simple-storage'
notifications = require 'notifications'
Request = require('request').Request

DEBUG = true

DLog = (content) ->
  console.log console if DEBUG

class FactsManager
  MINIMUM_FACTS_COUNT: 50

  MAX_STORED: 200
  
  factPages: []
  
  isEnabled: true
  
  facts: []
  
  readFacts: []
  
  storage: simpleStorage.storage
  
  factsUrl: "http://simple-planet-5852.herokuapp.com/facts?format=json&count=80"
  
  _instance = null
  @instance: ->
    if not @._instance?
      _instance = new @
    _instance 
      
  constructor: ->
    # Set plugin enabled
    @updateEnabled(true) if !@storage.pluginEnabled
    @isEnabled = @storage.pluginEnabled
    
    # Set facts and read facts
    @facts = @storage.facts || []
    @readFacts = @storage.readFacts || []
    
    # Load facts if required
    @fetchFactsIfRequired()
  
  updatePages: (message) ->
    for page in @factPages
      page.postMessage(message)
  
  detachWorker: (worker)->
    index = @factPages.indexOf worker
    if index != -1
      @factPages.splice index, 1
  
  fetchFactsIfRequired: ->
    @fetchFacts() if @facts.length < @MINIMUM_FACTS_COUNT

  getFact: ->
    @fetchFactsIfRequired()
    targetFact = @facts.splice(0, 1)[0]
    while @isReadFact(targetFact)
      targetFact = @facts.splice(0, 1)[0]
    
    DLog "Got fact: #{targetFact.content}"
    @saveReadFact targetFact
    @saveFacts()
    targetFact
  
  fetchFacts: (callback = null) ->
    console.log 'fetching facts'
    Request
      url: @factsUrl
      onComplete: (response) =>
        console.log 'completed fetch'
        if response.status == 200
          @facts = @facts.concat response.json
          @saveFacts()
          callback @facts if callback?
    .get()

  updateEnabled: (value) ->
    @storage.pluginEnabled = value
    @isEnabled = value
    console.log 'true that' if value == 'true'
  
  saveFacts: ->
    @storage.facts = @facts
    
  saveReadFacts: ->
    @storage.readFacts = @readFacts
  
  getWidgetImage: ->
    if @isEnabled
      data.url('images/plugin-on.png')
    else
      data.url('images/plugin-off.png')  
  
  isReadFact: (fact) ->
    if @readFacts[fact.id]?
      return true
    return false
    
  clearReadFactsIfRequired: ->
    if @readFacts["count"] > @MAX_STORED
      @readFacts = { "count": 0 }
      @saveReadFacts()
      
  saveReadFact: (fact) ->
    @readFacts[fact.id] = true
    @readFacts["count"] += 1
    @saveReadFacts()
    @clearReadFactsIfRequired()
  
exports.main = ->
  fM = FactsManager.instance()
  
  popupPanel = panels.Panel
    width: 240
    height: 110
    contentURL: data.url('html/popup.html')
    contentScriptFile: [
      data.url('js/jquery-1.7.2.min.js')
      data.url('js/iphone-style-checkboxes.js')
      data.url('js/popup.js')
    ]
    onMessage: (message) ->
      if message.type == 'pluginEnabled'
        fM.updateEnabled message.value
        fM.updatePages isEnabled: message.value
        widget.contentURL = fM.getWidgetImage()
      else if message.type == 'sendEmail'
        {email, subject} = message.value
        actionUrl = "mailto:#{email}?"
        actionUrl += "subject=#{encodeURIComponent(subject)}"
        tabs.open 
          url: actionUrl
          inNewWindow: true
    onShow: ->
      @postMessage
        type: 'pluginEnabled'
        value: fM.isEnabled
    
  widget = widgets.Widget
    id: 'toggle-popup'
    label: 'Awesome Facts'
    contentURL: fM.getWidgetImage()
    panel: popupPanel
  
  contentPage = pageMod.PageMod
    include: ['*']                     
    contentScriptWhen: 'start'
    contentScriptFile: [
      data.url('js/jquery-1.7.2.min.js')
      data.url('js/jquery.noty.js')
      data.url('js/bootstrap-tooltip.js')
      data.url('js/content.js') 
    ]
    # When a new page is opened
    onAttach: (worker) ->
      # Save the page
      fM.factPages.push worker
      
      # Remove the page on detach
      worker.on 'detach', ->
        fM.detachWorker @
        
      # Give worker facts when requested
      worker.port.on 'getFact', ->
        worker.postMessage 
          fact: fM.getFact()
          
      worker.port.on 'getEnabled', ->
        worker.postMessage
          isEnabled: fM.isEnabled
      
      # Load the css files
      worker.postMessage 
        css: data.load('css/jquery.noty.css') + \
             data.load('css/noty_theme_facebook.css') + \
             data.load('css/content.css')
      
  simpleStorage.on 'OverQuota', ->
    notifications.notify
      title: 'Storage Space Exceeded'
      text: 'More storage space required'
  
  null