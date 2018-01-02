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
  	  System.println("-> BgbgServiceDelegate initialize");
	  ServiceDelegate.initialize();	
	}
	
	function onTemporalEvent() {
	  System.println("-> BgbgServiceDelegate onTemporalEvent");
      getWeather();
    }
  
      
    function getWeather() {
        System.println("-> BgbgServiceDelegate Querying API...");
        
        var myapp = App.getApp();        
        
        var queryunit;
        var settings = System.getDeviceSettings();
        if (settings.temperatureUnits == System.UNIT_METRIC) {
            queryunit = "c";
        } else {
            queryunit = "f";
        }
       
        var lastPos = null;
        lastPos = myapp.getProperty("lastpos");
        // lastPos = "Utrecht";
        
        if ((lastPos!=null) && !(lastPos.equals(""))) {    
          System.println("-> BgbgServiceDelegate "+lastPos);            
          Comm.makeWebRequest(
            "https://query.yahooapis.com/v1/public/yql",
            {
                "q" => "select wind, location, units from weather.forecast where woeid in (select woeid from geo.places(1) where text='("+lastPos+")') and u='"+queryunit+"'",
                "format" => "json"
            },
            {
                "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
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
          // ivalid response, wipe the data
          lastdata = "";
        }
        // App.getApp().getProperty does not work here, so exit and pas the data
        Background.exit(lastdata);
    }

   
}
