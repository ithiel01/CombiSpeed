Shows the speed, average speed, time, gps quality, battery percentage, compass direction, wind direction, elapsed time and paused time.
Connects to Yahoo weather for wind direction and speed.

The field is intended as the top field, in a 9 or 8 field layout. For all the features to work it needs the full width of the screen. 

- Top left corner: time, gps, battery percentage (gps is shown when reception is poor, battery when less than 15%)
- Top right corner: compass direction (blinks if not available), wind direction (blue  2 bft, green  3 bft, dark green  4 bft, yellow  5 bft, orange 6 bft, red 7 bft or above)
- Bottom left corner: average speed
- Bottom right corner: elapsed time or paused time (pause time displayed when paused) 
- Center: speed (in mph or kmh depending on user settings)  
- Label: when the wind direction is obtained the name of the city (via Yahoo)

The wind direction is retrieved via Yahoo Weather (https://developer.yahoo.com/weather/) every 5 minutes (needs internet via phone). If the GPS accuracy is poor then the wind direction will not be retrieved. 
Language: Dutch/English

This datafield is experimental, expect bugs, code is based on antirez/iqmeteo and others. 

