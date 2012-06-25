if window.frameElement != null
  console.log 'Is Iframe'
  return

# Check if plugin is enabled
self.port.emit 'getEnabled'

self.on 'message', (msg) ->
  if msg.isEnabled?
    if msg.isEnabled == true
      factMananger.showFact()
    else
      factMananger.hideFact()
  else if msg.fact?
    factMananger.showFact msg.fact
  else if msg.css?
    script = $('<style type="text/css"></style>')
    script.html msg.css
    $(script).appendTo $('head:first')

is_site_disabled = ->
  ignoredTags = [
    'navbar.navbar-fixed-top'
    '#blueBar.fixed_elem'
    '#onegoogbar'
    '#gb'
    '#mngb'
    '.topbar .global-nav'
    '#navBar.fixed'
  ]
  selectors = ignoredTags.join(', ')
  if $(selectors).length > 0 then true else false
      
factMananger =
  
  shareURL: "http://simple-planet-5852.herokuapp.com/share"
  
  hasFact: ->
    $('#draco-interesting-facts123').length > 0
  
  createNewFact: (fact) ->
    $factsBar = $('''
      <table id="draco-interesting-facts123">
      <tbody>
        <tr>
          <td id="draco-interesting-facts-share">
            <iframe src=""></iframe>
          </td>
          <td id="draco-interesting-facts-fact123">
          </td>
          <td id="draco-interesting-facts-close123">
            &times;
          </td>
        </tr>
      </tbody>
      </table>
      '''
    )
    
    console.log $factsBar

    # give content and share url to facts bar
    $factsBar.find('#draco-interesting-facts-fact123')
      .html fact.content
    $factsBar.find('#draco-interesting-facts-share iframe')
      .attr "src", "#{@shareURL}/#{fact.id}"
        
    # Handlers for sharing
    window.addEventListener 'message', @handleShareMessage, false

    # attach close action
    $factsBar.find('#draco-interesting-facts-close123').click ->
      $factsBar.remove()
        
    # attach fact to DOM
    $('html:first').prepend $factsBar
    
    # attach share action and tooltip
    $factsBar.find('#draco-interesting-facts-share').tooltip
      title: "Share Fact"
      placement: 'right'
    
    $factsBar
    
  showFact: (value = null) ->
    if @hasFact()
      $('#draco-interesting-facts123').show()
    else if value != null
      return if is_site_disabled()
      @createNewFact value
    else
      self.port.emit 'getFact'

  hideFact: ->
    $('#draco-interesting-facts123').hide() 
  
  handleShareMessage: (event) ->
    console.log event
    if event.data? && event.data == "Awesome Fact Shared"
      $('#draco-interesting-facts-share')
        .addClass("disabled")
        .tooltip('disable')
      noty
        text: 'Current Fact Shared :)'
        layout: 'topLeft'
        type: 'success'
        theme: 'noty_theme_facebook'
    else if event.data? && event.data == "Awesome Fact Failed"
      @noty
        text: 'Sharing Failed :('
        layout: 'topLeft'
        type: 'error'
        theme: 'noty_theme_facebook'
    
# Remove facts on DOM load if we have google sticky bars
$ ->
  if is_site_disabled()
    $('#draco-interesting-facts123').remove()