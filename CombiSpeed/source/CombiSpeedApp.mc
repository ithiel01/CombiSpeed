using Toybox.Application as App;
using Toybox.Background;
using Toybox.System as Sys;
using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;

class CombiSpeedApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
        Sys.println("-> CombiSpeedApp initialize"); 
    }

   function onStart(state) {
      Sys.println("-> CombiSpeedApp onStart"); 
    }

    function onStop(state) {
       Sys.println("-> CombiSpeedApp onStop");   
       // Background.deleteTemporalEvent(); // Do not delete, the delegator has to exit to pass the data
    }

    function getInitialView() {
      Sys.println("-> CombiSpeedApp getInitialView");   
      Background.registerForTemporalEvent(new Time.Duration(5*60)); // Every 5 minutes
      return [ new CombiSpeedView() ];
    }

    function onBackgroundData(data){
    	Sys.println("-> CombiSpeedApp onBackgroundData: Background data received: " + data);   
        App.getApp().setProperty("lastdata", data);
        Ui.requestUpdate();
    }
    
    function getServiceDelegate(){
    	return [new BgbgServiceDelegate()];
    }	   
}