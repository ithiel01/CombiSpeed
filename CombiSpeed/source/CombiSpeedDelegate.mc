using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Communications as Comm;
using Toybox.Time.Gregorian;
using Toybox.System as System;
using Toybox.Application as App;
using Toybox.Background;

(:background)
class BgbgServiceDelegate extends Toybox.System.ServiceDelegate {

    function initialize(){
      //System.println("-> BgbgServiceDelegate initialize");
      ServiceDelegate.initialize();	
    }
	
    function onTemporalEvent() {
      //System.println("-> BgbgServiceDelegate onTemporalEvent");
      getWeather();
    }
        
    function getWeather() {
      System.println("-> BgbgServiceDelegate Querying API...");
      var lastPos = App.getApp().getProperty("lastpos");
      //lastPos = "Utrecht";
        
      if ((lastPos!=null) && !(lastPos.equals(""))) {           
        System.println("-> BgbgServiceDelegate "+lastPos);  
        Comm.makeWebRequest(
            // Url
            "https://query.yahooapis.com/v1/public/yql",
            // Params
            {
                "q" => "select wind.direction, wind.speed, location.city, units.speed from weather.forecast where woeid in (select woeid from geo.places(1) where text='("+lastPos+")')",
                "format" => "json"
            },
            // Options
            {
                "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            // Callback
            method(:receiveWeather)
        );
      } else {
        System.println("-> BgbgServiceDelegate no last position.");
        var lastdata = "";
        Background.exit(lastdata);
      }
    }

    function receiveWeather(responseCode, data) {
      System.println("-> BgbgServiceDelegate Data received with code "+responseCode.toString());
      var lastdata = data;
      if (responseCode!=200) {
        // invalid response, wipe the data
        lastdata = "";
      }
      // App.getApp().getProperty does not work here, so exit and pas the data
      Background.exit(lastdata);
    }

   
}
