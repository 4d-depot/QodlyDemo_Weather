Class extends DataStoreImplementation


exposed Function getManifestObject() : Object
	var $manifestFile : 4D:C1709.File
	var $manifestObject : Object
	
	$manifestFile:=File:C1566("/PACKAGE/Project/Sources/Shared/manifest.json")
	$manifestObject:=JSON Parse:C1218($manifestFile.getText())
	return $manifestObject
	
	
exposed Function getCapitalsObject() : Collection
	var $capitalsFile : 4D:C1709.File
	var $capitalsObject : Collection
	
	$capitalsFile:=File:C1566("/PACKAGE/Project/Sources/Shared/capitals.json")
	$capitalsObject:=JSON Parse:C1218($capitalsFile.getText())
	
	return $capitalsObject
	
	
Function getWeatherPict($code : Integer) : Text
	
	var $pict : Text
	var $root : Text
	
	$root:="/$shared/assets/images/"
	
	Case of 
		: ($code=0)
			$pict:="clear_sky.png"
		: ($code=1) || ($code=2) || ($code=3)
			$pict:="cloudy.png"
		: ($code=45) || ($code=48) || ($code=51) || ($code=53) || ($code=55) || ($code=56) || ($code=57)
			$pict:="fog.png"
		: ($code=61) || ($code=63) || ($code=65) || ($code=66) || ($code=67) || ($code=80) || ($code=81) || ($code=82)
			$pict:="rain.png"
		: ($code=71) || ($code=73) || ($code=75) || ($code=77) || ($code=85) || ($code=86)
			$pict:="snow.png"
		: ($code=95) || ($code=96) || ($code=99)
			$pict:="thunderstorm.png"
	End case 
	
	return $root+$pict
	
exposed Function getWeatherDataWithCity($capital : Object) : Object
	
	var $url; $timeResp; $day; $dateString : Text
	var $currentTemp; $winddirection; $windspeed; $tempMax; $tempMin : Integer
	var $currentCode; $code; $viDay : Integer
	var $dateResp : Date
	
	var $temp : Object
	var $tempDaily : Object
	
	var $request : 4D:C1709.HTTPRequest
	var $col : Collection
	var $weatherObject : Object
	
	$request:=4D:C1709.HTTPRequest.new("https://api.open-meteo.com/v1/forecast?latitude="+$capital.CapitalLatitude+"&longitude="+$capital.CapitalLongitude+"&timezone=Europe/Berlin&daily=temperature_2m_max&daily=temperature_2m_min&daily=weathercode&current_weather=true&forecast_days=7").wait()
	
	If ($request.response.status=200)
		
		$weatherObject:=New object:C1471()
		
		$temp:=$request.response.body.current_weather
		$currentTemp:=$temp.temperature
		$currentCode:=$temp.weathercode
		$winddirection:=$temp.winddirection
		$windspeed:=$temp.windspeed
		
		$weatherObject.current:=New object:C1471("currentTemp"; $currentTemp; "currentPict"; This:C1470.getWeatherPict($currentCode); "windDirection"; $winddirection; "windSpeed"; $windspeed)
		
		$col:=New collection:C1472()
		var $i : Integer
		
		$tempDaily:=$request.response.body.daily
		
		For ($i; 1; $tempDaily.temperature_2m_max.length-1)
			$tempMax:=$tempDaily.temperature_2m_max[$i]
			$tempMin:=$tempDaily.temperature_2m_min[$i]
			$timeResp:=$tempDaily.time[$i]
			$code:=$tempDaily.weathercode[$i]
			
			// UPDATE DATE FORMAT
			$dateResp:=Add to date:C393(!00-00-00!; Num:C11(Substring:C12($timeResp; 1; 4)); Num:C11(Substring:C12($timeResp; 6; 2)); Num:C11(Substring:C12($timeResp; 9; 2)))
			
			// GET WEEK DAY FROM DATE
			$viDay:=Day number:C114($dateResp)  // viDay gets the current day number
			
			Case of 
				: ($viDay=1)
					$day:="Sunday"
					
				: ($viDay=2)
					$day:="Monday"
					
				: ($viDay=3)
					$day:="Tuesday"
					
				: ($viDay=4)
					$day:="Wednesday"
					
				: ($viDay=5)
					$day:="Thursday"
					
				: ($viDay=6)
					$day:="Friday"
					
				: ($viDay=7)
					$day:="Saturday"
			End case 
			
			$col.push(New object:C1471("tempMax"; $tempMax; "tempMin"; $tempMin; "day"; $day; "pict"; This:C1470.getWeatherPict($code)))
			
		End for 
		
		$weatherObject.forecast:=$col
		return $weatherObject
		
	Else 
		// The code to handle errors.
	End if 