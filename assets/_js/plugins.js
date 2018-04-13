// usage: log('inside coolFunc', this, arguments);
// paulirish.com/2009/log-a-lightweight-wrapper-for-consolelog/
window.log = function f(){ log.history = log.history || []; log.history.push(arguments); if(this.console) { var args = arguments, newarr; args.callee = args.callee.caller; newarr = [].slice.call(args); if (typeof console.log === 'object') log.apply.call(console.log, console, newarr); else console.log.apply(console, newarr);}};

// make it safe to use console.log always
(function(a){function b(){}for(var c="assert,count,debug,dir,dirxml,error,exception,group,groupCollapsed,groupEnd,info,log,markTimeline,profile,profileEnd,time,timeEnd,trace,warn".split(","),d;!!(d=c.pop());){a[d]=a[d]||b;}})
(function(){try{console.log();return window.console;}catch(a){return (window.console={});}}());


//
// Add a .active class to nav li's containing an anchor to the current page.
//
// Note: If you want to mark main section or parent links as active while on
// their sub-pages, use the section variable in the back-end template. For
// multi-level dropdown navigation, we would have to compare the anchor's path
// to the start of the current path.
// 
$(function(){

  var url = window.location.pathname;
  // create regexp to match current url pathname and remove trailing slash if
  // present as it could collide with the link in navigation in case trailing
  // slash wasn't present there
  var urlRegExp = new RegExp(url.replace(/\/$/,'') + "$");
  var location_start = window.location.protocol + '//' + window.location.host;

  $('nav a').each(function(){
    // special case for site root
    if (url == '/')
    {
      // Take the hostname out of the href
      var href_path = this.href.replace(location_start, '');
      if (href_path == '/')
      {
        $(this).parents('li').addClass('active');
      }
    } else {
      // test the normalized href against the url pathname regexp
      if(urlRegExp.test(this.href.replace(/\/$/,''))){
        $(this).parents('li').addClass('active');
      }
    }

  });
});


// place any jQuery/helper plugins in here, instead of separate, slower script files.

