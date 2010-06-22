// from http://codesnippets.joyent.com/posts/show/835
Position.GetWindowSize = function(w) {
    var width, height;
        w = w ? w : window;
        this.width = w.innerWidth || (w.document.documentElement.clientWidth || w.document.body.clientWidth);
        this.height = w.innerHeight || (w.document.documentElement.clientHeight || w.document.body.clientHeight);

        return this;
}

function loadRemainingItems(){
  // compute amount of page below the current scroll position
  var remaining =  $('people_form').getHeight() - $('people').getHeight() - $('people_form').cumulativeScrollOffset()[1];

  //compute height of bottom element
  var last = $$(".person").last().getHeight();

  if(remaining < last*2 && !$('complete')){
    if(Ajax.activeRequestCount == 0){
      var url = "/people";
      var last = $$(".person").last().className.match(/[0-9]+/)[0];
      new Ajax.Request(url, {
        method: 'get',
        parameters: 'page=' + ++last,
        onLoading: function(){
          $('loading').show();
        },
        onSuccess: function(xhr){
          $('loading').hide();
          $('loading').insert({before : xhr.responseText})
        }
      });
    }
  }
}

// hide the pagination links
document.observe("dom:loaded", function(){
  $('pagination').hide();
  Event.observe("people", 'scroll', function(e){
      loadRemainingItems(); });
});


Event.observe(window, 'resize', function(e){
  loadRemainingItems();
});

