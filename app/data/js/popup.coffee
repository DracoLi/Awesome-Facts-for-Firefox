self.on 'message', (message) ->
  if message.type == 'pluginEnabled'
    # Set default slider value
    isEnabled = message.value
    $(':checkbox').prop('checked', "checked") if isEnabled
  
  # Make checkbox a slider and listen for change events
  $onOffBox = $(':checkbox').iphoneStyle
    onChange: (elem, value) ->
      # Save slider state and send result to plugin
      self.postMessage
        type: 'pluginEnabled', value: value
        
# Attach handler for feedback link
$('#feedback').click ->
  self.postMessage
    type: 'sendEmail'
    value: 
      email: 'draco@dracoli.com'
      subject: 'Awesome Facts for Firefox Feedback'