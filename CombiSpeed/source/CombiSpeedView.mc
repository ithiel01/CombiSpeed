using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Communications;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Math;
using Toybox.Application as App;


class CombiSpeedView extends Ui.DataField {
    hidden var is24Hour = true;
    hidden var isSpdMetric = true;
    hidden const _180_PI = 57.2957;
    hidden const _PI_180 = 0.0175;    
    
    hidden var mFull  = false;
    hidden var mValue = "__._";
    hidden var mLabel = Rez.Strings.speed;
    hidden var mAvgValue = "__._";
    hidden var mState = Activity.TIMER_STATE_OFF ;
    hidden var mTimerTime = 0;
    hidden var mElapsed = 0;
    hidden var mBlink = true;
    hidden var mSpeed = 0.0;
 
    hidden var mGpsSignal;
    hidden var mSF = Gfx.FONT_SMALL ;
    hidden var mTrack;
    
    function initialize() {
      DataField.initialize();  
      App.getApp().setProperty("lastpos", "");  
      App.getApp().setProperty("lastdata", "");  
    }
    
    function populateConfigFromDeviceSettings() {
      isSpdMetric = System.getDeviceSettings().paceUnits == System.UNIT_METRIC;
      is24Hour = System.getDeviceSettings().is24Hour;
    }
    
    function onLayout(dc) {
       mFull = (dc.getWidth()>250);
       
       populateConfigFromDeviceSettings();
       
       View.setLayout(Rez.Layouts.MainLayout(dc));
       var labelView = View.findDrawableById("label");
       labelView.locY = 2;
            
       var valueView = View.findDrawableById("value");
       valueView.locY = valueView.locY + 20;

       return true;
    }
                 
    function compute(info) {
       var lastPos = "";
       
       if ((info.currentLocation != null) && (info.currentLocationAccuracy!=null)) {
         if (info.currentLocationAccuracy>=2) {
           lastPos = info.currentLocation.toDegrees()[0].toString() + "," +
                         info.currentLocation.toDegrees()[1].toString();
           App.getApp().setProperty("lastpos", lastPos);
         } else {
           App.getApp().setProperty("lastpos", "");
         }
       }
                      
       if (info.track  != null)  {
          mTrack = info.track * _180_PI;
       } 
           
       if (info.currentLocationAccuracy  != null)  {
          mGpsSignal = info.currentLocationAccuracy;
          if (mGpsSignal<2) {
            App.getApp().setProperty("lastpos" , "");
            App.getApp().setProperty("lastdata", "");
          }
       }   
                 
       mElapsed = 0;
       if (info.elapsedTime != null) {
         mElapsed = info.elapsedTime;
       }  
         
       mTimerTime = 0;
       if (info.elapsedTime !=  null) {
         mTimerTime = info.timerTime;
       }
       
       mValue = "0.0";
       mSpeed = 0;
       if (info has :currentSpeed) {
         if (info.currentSpeed != null) {
            mValue = info.currentSpeed * 60 * 60 /  (isSpdMetric ? 1000 : 1610);
            mValue = mValue.format("%.1f");
            mSpeed = info.currentSpeed;
          } 
       }
       
       if (info has :timerState) {
         if (info.timerState != null) {
           mState = info.timerState; 
         }
       }
       
       if (info has :averageSpeed) {
         if (info.averageSpeed != null) {
            mAvgValue = info.averageSpeed * 60 * 60 /  (isSpdMetric ? 1000 : 1610);
            mAvgValue = mAvgValue.format("%.1f");
         } 
       }           
    }

    function drawFields (dc) {
        var v = mValue;
        var l = mLabel;
        var f = Gfx.FONT_NUMBER_HOT;
        
        // Top Label
        var label = View.findDrawableById("label");
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            label.setColor(Gfx.COLOR_WHITE);
        } else {
            label.setColor(Gfx.COLOR_BLACK);
        }
        if (!l.equals("")) {
          label.setText(l);
        }
        
       // Speed Value
       var value = View.findDrawableById("value");
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            value.setColor(Gfx.COLOR_WHITE);
        } else {
            value.setColor(Gfx.COLOR_BLACK);
        }
        if (v!=null) {
          value.setFont(f);
          value.setText(v);      
        }

    }
 
    function drawGpsBars(dc, xStart, yStart, color1, color2, color3, color4) {
    // Draw GPS bars
        dc.setColor(color1, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xStart, yStart + 20 - 4, 4, 4);

        dc.setColor(color2, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xStart+5, yStart + 20 - 8, 4, 8);

        dc.setColor(color3, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xStart+10, yStart + 20 - 12, 4, 12);

        dc.setColor(color4, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xStart+15, yStart + 20 - 16, 4, 16);
    }    
    
    function drawIcons(dc) {
    // Draw GPS bars if reception is poor or lower otherwise don't display it
        var width  = dc.getWidth();
        var height = dc.getHeight();
        var x = 60;
        var y = 2;
        var col;
    
        var myStats = System.getSystemStats();
      
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
          col =  Graphics.COLOR_WHITE;
        } else {
          col = Graphics.COLOR_BLACK;
        }
        
        if ((myStats.battery<=15)  && (mBlink)) {
           dc.drawText(x, y, mSF, myStats.battery.format("%i")+"%", Gfx.TEXT_JUSTIFY_LEFT);                     
        } else if ((mGpsSignal!=null) && (mGpsSignal<3)) {
          if (mGpsSignal < 1) {
            drawGpsBars(dc, x, y, Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
          } else if (mGpsSignal == 1) {
            drawGpsBars(dc, x, y, col, Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
          } else if (mGpsSignal == 2) {
            drawGpsBars(dc, x, y, col, col, Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
          } else if (mGpsSignal == 3) {
            drawGpsBars(dc, x, y, col, col, col, Graphics.COLOR_LT_GRAY);
          } else {
            drawGpsBars(dc, x, y, col, col, col, col);
          }
        }
    }
    
    function drawTime(dc) {
      var width  = dc.getWidth();
      var height = dc.getHeight();
      var y = 2;
        
      if (getBackgroundColor() == Gfx.COLOR_BLACK) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      } else {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
      }
      
      var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
      var v;
      var h;
      if ((today.hour>12) && (!is24Hour)) {
        h = today.hour - 12;
      } else {
        h = today.hour;
      }
      
      v = h.format("%02d")+":"+today.min.format("%02d");
      dc.drawText(5, y, mSF, v, Gfx.TEXT_JUSTIFY_LEFT);
    }    
              
    function drawArrow (dc, bearing, wind, windspeed) {
    // Draw Direction Arrow
       
        var width = dc.getWidth();
        var height = dc.getHeight();
        var showBft = true;
       
        var x1_1;
        var y1_1;
        var x2_1;
        var y2_1;
        var x3_1;
        var y3_1;        
        var x4_1;
        var y4_1;   
        var x5_1;
        var y5_1;   
        var x6_1;
        var y6_1;  

        var x1_2;
        var y1_2;
        var x2_2;
        var y2_2;
        var x3_2;
        var y3_2;        
        var x4_2;
        var y4_2;   
        var x5_2;
        var y5_2;   
        var x6_2;
        var y6_2;  

        
        var minx = 9999;
        var maxx = 0;
        var miny = 9999;
        var maxy = 0;
        var xoffset = 0;
        var yoffset = 0;
        
        var angle;
        var sim = false;
        
        var l = 0.65;
        var l2 = 0.3;
        var a = 180-35;
        var r = height+0.0;
        
        if (height>width) {
          r = width+0.0;
        }
        
        if (wind==null) {
          r = r/2.4;
        } else {
          r = r/2.8;
        }    
        
        if (r>50) {
          r = 50;
        }

        var i = 0;
        
        if (bearing!=null) {
          angle = - bearing - 90;        
        } else {
          angle = - 315 - 90;
          sim = true;
        }       
                    
        x1_1 = r * Math.cos(angle*_PI_180);
        y1_1 = r * Math.sin(angle*_PI_180);     
        x2_1 = r * Math.cos((angle+a)*_PI_180) * l;
        y2_1 = r * Math.sin((angle+a)*_PI_180) * l;
        x3_1 = r * Math.cos((angle+180)*_PI_180) * l2;
        y3_1 = r * Math.sin((angle+180)*_PI_180) * l2;             
        x4_1 = r * Math.cos(angle*_PI_180) ;
        y4_1 = r * Math.sin(angle*_PI_180) ;      
        x5_1 = r * Math.cos((angle-a)*_PI_180) * l;
        y5_1 = r * Math.sin((angle-a)*_PI_180) * l; 
        x6_1 = r * Math.cos((angle+180)*_PI_180) * l2;
        y6_1 = r * Math.sin((angle+180)*_PI_180) * l2;
        
        if (x1_1<minx) { minx = x1_1; }
        if (x1_1>maxx) { maxx = x1_1; }
        if (x2_1<minx) { minx = x2_1; }
        if (x2_1>maxx) { maxx = x2_1; }
        if (x3_1<minx) { minx = x3_1; }
        if (x3_1>maxx) { maxx = x3_1; }
        if (x4_1<minx) { minx = x4_1; }
        if (x4_1>maxx) { maxx = x4_1; }
        if (x5_1<minx) { minx = x5_1; }
        if (x5_1>maxx) { maxx = x5_1; }
        if (x6_1<minx) { minx = x6_1; }
        if (x6_1>maxx) { maxx = x6_1; }
        
        if (y1_1<miny) { miny = y1_1; }        
        if (y1_1>maxy) { maxy = y1_1; }
        if (y2_1<miny) { miny = y2_1; }
        if (y2_1>maxy) { maxy = y2_1; }
        if (y3_1<miny) { miny = y3_1; }
        if (y3_1>maxy) { maxy = y3_1; }
        if (y4_1<miny) { miny = y4_1; }
        if (y4_1>maxy) { maxy = y4_1; }
        if (y5_1<miny) { miny = y5_1; }
        if (y5_1>maxy) { maxy = y5_1; }
        if (y6_1<miny) { miny = y6_1; }
        if (y6_1>maxx) { maxy = y6_1; }
		
        if (wind!=null) {
          angle = wind+90+180;      
          var l1 = 1;
          l = -0.4;
          l2 = -0.2;
          a = 90;
          //a = -45;
        		
          x1_2 = r * Math.cos(angle*_PI_180) * l1;
          y1_2 = r * Math.sin(angle*_PI_180) * l1;     
          x2_2 = r * Math.cos((angle+a)*_PI_180) * l;
          y2_2 = r * Math.sin((angle+a)*_PI_180) * l;
          x3_2 = r * Math.cos((angle+180)*_PI_180) * l2;
          y3_2 = r * Math.sin((angle+180)*_PI_180) * l2;       
                
          x4_2 = r * Math.cos(angle*_PI_180)  * l1;
          y4_2 = r * Math.sin(angle*_PI_180)  * l1;      
          x5_2 = r * Math.cos((angle-a)*_PI_180) * l;
          y5_2 = r * Math.sin((angle-a)*_PI_180) * l; 
          x6_2 = r * Math.cos((angle+180)*_PI_180) * l2;
          y6_2 = r * Math.sin((angle+180)*_PI_180) * l2;
        
          if (x1_2<minx) { minx = x1_2; }
          if (x1_2>maxx) { maxx = x1_2; }
          if (x2_2<minx) { minx = x2_2; }
          if (x2_2>maxx) { maxx = x2_2; }
          if (x3_2<minx) { minx = x3_2; }
          if (x3_2>maxx) { maxx = x3_2; }
          if (x4_2<minx) { minx = x4_2; }
          if (x4_2>maxx) { maxx = x4_2; }
          if (x5_2<minx) { minx = x5_2; }
          if (x5_2>maxx) { maxx = x5_2; }
          if (x6_2<minx) { minx = x6_2; }
          if (x6_2>maxx) { maxx = x6_2; }
        
          if (y1_2<miny) { miny = y1_2; }        
          if (y1_2>maxy) { maxy = y1_2; }
          if (y2_2<miny) { miny = y2_2; }
          if (y2_2>maxy) { maxy = y2_2; }
          if (y3_2<miny) { miny = y3_2; }
          if (y3_2>maxy) { maxy = y3_2; }
          if (y4_2<miny) { miny = y4_2; }
          if (y4_2>maxy) { maxy = y4_2; }
          if (y5_2<miny) { miny = y5_2; }
          if (y5_2>maxy) { maxy = y5_2; }
          if (y6_2<miny) { miny = y6_2; }
          if (y6_2>maxx) { maxy = y6_2; }		
        } else {
          x1_2 = 0;
          y1_2 = 0; 
          x2_2 = 0;
          y2_2 = 0;
          x3_2 = 0;
          y3_2 = 0;            
          x4_2 = 0;
          y4_2 = 0;   
          x5_2 = 0;
          y5_2 = 0;
          x6_2 = 0;
          y6_2 = 0;
        }     
        
        xoffset = -minx + (width - (maxx-minx)) - 6;
        yoffset = -miny + 4;
        
        if ((wind!=null) && (showBft)) {
          xoffset = -minx + (width - (maxx-minx)) - 18;
          yoffset = -miny + 4;
        }
               
        if (sim) {
          if (mBlink) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
          } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
          }
        } else {
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
      
        if (!sim) {
          // dc.fillPolygon([[x1+xoffset,y1+yoffset],[x2+xoffset,y2+yoffset],[x3+xoffset,y3+yoffset]]);
        } else {
          dc.drawLine(x1_1+xoffset,y1_1+yoffset,x2_1+xoffset,y2_1+yoffset);
          dc.drawLine(x2_1+xoffset,y2_1+yoffset,x3_1+xoffset,y3_1+yoffset);
          dc.drawLine(x3_1+xoffset,y3_1+yoffset,x1_1+xoffset,y1_1+yoffset);
        }
                
        if (sim) {
          if (mBlink) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
          } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
          }
        } else {
          dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
 
        if (!sim) {
          dc.fillPolygon([[x4_1+xoffset,y4_1+yoffset],[x5_1+xoffset,y5_1+yoffset],[x6_1+xoffset,y6_1+yoffset]]);
        } else {
          dc.drawLine(x4_1+xoffset,y4_1+yoffset,x5_1+xoffset,y5_1+yoffset);
          dc.drawLine(x5_1+xoffset,y5_1+yoffset,x6_1+xoffset,y6_1+yoffset);
          dc.drawLine(x6_1+xoffset,y6_1+yoffset,x4_1+xoffset,y4_1+yoffset);        
        }  
        
        if (!sim)  {
          if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
          } else {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
          }        
          dc.setPenWidth(2);
          dc.drawLine(x1_1+xoffset, y1_1+yoffset, x2_1+xoffset,y2_1+yoffset);
          dc.drawLine(x2_1+xoffset, y2_1+yoffset, x3_1+xoffset,y3_1+yoffset);
          dc.drawLine(x3_1+xoffset, y3_1+yoffset, x4_1+xoffset,y4_1+yoffset);
          dc.drawLine(x4_1+xoffset, y4_1+yoffset, x5_1+xoffset,y5_1+yoffset);
          dc.drawLine(x5_1+xoffset, y5_1+yoffset, x6_1+xoffset,y6_1+yoffset);
        }
        
        if (wind != null) {
          var bft = "";
          
          /*
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
          dc.fillPolygon([[x1_2+xoffset,y1_2+yoffset],[x2_2+xoffset,y2_2+yoffset],[x3_2+xoffset,y3_2+yoffset]]);
          */
          
          if (windspeed!=null) {
            
            if (windspeed<=3) {          // 1
              dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
              bft = 1;
              
            } if (windspeed<=7) {          // 2
              dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_DK_BLUE);
              bft = 2;
              
            } else if (windspeed<=12) {  // 3
              dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
              bft = 3;
              
            } else if (windspeed<=18) { //  4
              dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
              bft = 4;
              
            } else if (windspeed<=24) { //  5
              dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_YELLOW);
              bft = 5;
              
            } else if (windspeed<=31) { //  6
              dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_ORANGE);              
              bft = 6;

            } else if (windspeed<=38) { //  7
              dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);              
              bft = 7;
    
            } else if (windspeed<=46) { //  8
              dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);              
              bft = 8;
    
            } else if (windspeed<=54) { //  9
              dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);              
              bft = 9;
    
            } else if (windspeed<=63) { //  10
              dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);              
              bft = 10;
    
            } else if (windspeed<=72) { //  11
              dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);              
              bft = 11;
    
            } else {                    //  12
              dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
              bft = 12;             
            }
          } else {
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
          }
          
          /*
          dc.fillCircle(x4_2+xoffset-3, y4_2+yoffset-3, 6);
          */
          dc.fillPolygon([[x1_2+xoffset,y1_2+yoffset],[x2_2+xoffset,y2_2+yoffset],[x3_2+xoffset,y3_2+yoffset]]);
          dc.fillPolygon([[x4_2+xoffset,y4_2+yoffset],[x5_2+xoffset,y5_2+yoffset],[x6_2+xoffset,y6_2+yoffset]]);     
    
          dc.setPenWidth(2);
          if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
          } else {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
          }  
          dc.drawLine(x1_2+xoffset, y1_2+yoffset, x2_2+xoffset,y2_2+yoffset);
          dc.drawLine(x2_2+xoffset, y2_2+yoffset, x3_2+xoffset,y3_2+yoffset);
          dc.drawLine(x3_2+xoffset, y3_2+yoffset, x4_2+xoffset,y4_2+yoffset);
          dc.drawLine(x4_2+xoffset, y4_2+yoffset, x5_2+xoffset,y5_2+yoffset);
          dc.drawLine(x5_2+xoffset, y5_2+yoffset, x6_2+xoffset,y6_2+yoffset);
          
          
          /*
          if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
          } else {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
          }  
          dc.drawCircle(x4_2+xoffset-3, y4_2+yoffset-3, 6);
          dc.drawLine(xoffset, yoffset, x4_2+xoffset-3, y4_2+yoffset-3);
          */
          if (showBft) {
            dc.drawText(width-15, 0, mSF, bft.format("%i"), Gfx.TEXT_JUSTIFY_LEFT); 
          }    
        }
    }

    
    function drawAvg(dc) {
    // Draw Average Speed
      var width = dc.getWidth();
      var height = dc.getHeight();
        
      if (getBackgroundColor() == Gfx.COLOR_BLACK) {
       dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      } else {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
      }
               
      if (mAvgValue!=null) {
        dc.drawText(5, height-28, mSF, mAvgValue, Gfx.TEXT_JUSTIFY_LEFT);
      } 
      else {
        var v = "__._";
        dc.drawText(5, height-28, mSF, v, Gfx.TEXT_JUSTIFY_LEFT);
      }
    }
    
    function calculateElapsedTime(ms) {
    // Formar ms into human readable format
       ms = ms / 1000;
            
       var hours   = 0.0;
       var minutes = ms / 60;
       var seconds = ms % 60;
            
       if (minutes >= 60) {
         hours = minutes / 60;
         minutes = minutes % 60;
       }
       
       if (hours>0) {     
         return hours.format("%d") + ":" + minutes.format("%02d");
       } else if (minutes>0) {
         return minutes.format("%i")+"m";
       } else {
         return seconds.format("%i")+"s";
       }
    }
       
    function drawElapsed(dc) {
      var width = dc.getWidth();
      var height = dc.getHeight();
      var x1 = width  - 28;
        
      // During activity display elapsed time
      if (mState==Activity.TIMER_STATE_ON) {
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
         dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
          dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        }
      
        if ((mElapsed!=null) && (mElapsed > 0)) {
          var v = calculateElapsedTime(mElapsed); 
          x1 = width - dc.getTextDimensions(v, mSF)[0]- 8;        
          dc.drawText(x1, height-28, mSF, v, Gfx.TEXT_JUSTIFY_LEFT);
        }
      }
      
      // When pauzed blink total paused time
      if (mBlink) {
        if (mState==Activity.TIMER_STATE_PAUSED) {
          if (getBackgroundColor() == Gfx.COLOR_BLACK) {
           dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
          } else {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
          }
        
        if ((mElapsed!=null) && (mElapsed > 0) && (mTimerTime!=null)) {
            var v = calculateElapsedTime(mElapsed - mTimerTime); 
            x1 = width - dc.getTextDimensions(v, mSF)[0]- 8;        
            dc.drawText(x1, height-28, mSF, v, Gfx.TEXT_JUSTIFY_LEFT);
          }
        }
      }      
    }
       
    function drawState(dc) {
      var width = dc.getWidth();
      var height = dc.getHeight();
      
      var x1 = width  - 26;
      var y1 = height - 22;
      
      if (mBlink) {
         // If speed above 10km/h and not recording start blinking
         if ((mSpeed != null) && (mState != null)) {
           if (mSpeed>1000*10) {
             if (mState==Activity.TIMER_STATE_OFF) {
              if (getBackgroundColor() == Gfx.COLOR_BLACK) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
              } else {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
              }
              dc.fillRectangle(x1, y1, 6, 14);
              dc.fillRectangle(x1+7, y1, 6, 14);
            }
          }
        }
      }

      // Stopped timer
      if (mState!=null) {
        if (mState==Activity.TIMER_STATE_STOPPED) {
          if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
          } else {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
          }
          dc.fillRectangle(x1, y1, 14, 14);
        }
      }
    
      mBlink = !mBlink;
        
    }
         
    function onUpdate(dc) { 
       var winddirection = null;
       var windspeed = null;
        
       var data = App.getApp().getProperty("lastdata");
       
       mLabel = Rez.Strings.speed;
       if ((data!=null) && (!data.equals(""))) {      
            var windunit = data["query"]["results"]["channel"]["units"]["speed"];          
            windspeed = data["query"]["results"]["channel"]["wind"]["speed"].toNumber(); 
            if (windunit.equals("km/h")) {
              // convert to mp/h
              windspeed = windspeed / 1.609344;
            }       
            //System.println("windspeed "+windspeed);
          
            winddirection = data["query"]["results"]["channel"]["wind"]["direction"].toNumber();          
            //System.println("winddirection "+winddirection);
          
            //System.println("windunit "+windunit);
          
            var cityname = data["query"]["results"]["channel"]["location"]["city"];
            if ((cityname!=null) && (!cityname.equals(""))){
              mLabel = cityname;
            }
            //System.println("cityname "+cityname);
       }
 
               
      View.findDrawableById("Background").setColor(getBackgroundColor());
      dc.setColor(getBackgroundColor(), getBackgroundColor());
      dc.clear();        
       
      drawFields(dc); // Only this part is based on the layouts, so doesn't make much sense :)
      View.onUpdate(dc); 
      
      // Custom drawing routines
      if (mFull) {
        drawTime(dc); 
        drawIcons(dc); 
        drawAvg(dc);
        drawArrow (dc, mTrack, winddirection, windspeed);  
        drawState(dc);
        drawElapsed(dc);
      }
   }

}
