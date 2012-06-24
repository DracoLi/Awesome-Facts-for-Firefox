// Generated by CoffeeScript 1.3.3
(function() {

  self.on('message', function(message) {
    var $onOffBox, isEnabled;
    if (message.type === 'pluginEnabled') {
      isEnabled = message.value;
      if (isEnabled) {
        $(':checkbox').prop('checked', "checked");
      }
    }
    return $onOffBox = $(':checkbox').iphoneStyle({
      onChange: function(elem, value) {
        return self.postMessage({
          type: 'pluginEnabled',
          value: value
        });
      }
    });
  });

  $('#feedback').click(function() {
    return self.postMessage({
      type: 'sendEmail',
      value: {
        email: 'draco@dracoli.com',
        subject: 'Awesome Facts for Firefox Feedback'
      }
    });
  });

}).call(this);