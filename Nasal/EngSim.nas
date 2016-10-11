
################
#
# Engine
# A sophisticated YASim style turbine simulation by Josh Babcock.
#
################

rpm0 = '';
rpm1 = '';
rpm2 = '';
rpmR = '';
engineSim =  func {
	var rpm = (rpmR.getValue() / 0.185);
	rpm0.setDoubleValue(rpm);
	rpm1.setDoubleValue(rpm);
	rpm2.setDoubleValue(rpm);
	
	#calculate fuel usage, see my notes below
	#because i'm lazy and cant find fuel usage info after a 5 minute google search:
	#estimate fuel usage based on range. rpm's sit at ~1000, cruise speed is ~170 mph, range is ~625 miles.
	#that gives us a rough flight time of 625/170 = 3.66hrs
	#spread that across 6 tanks with total capacity of 15,936 lbs split across 6 tanks
	#ergo, fuel usage would be 4354 lbs/hr or 72.5 lbs per minute
	#72.5 lbs per minute at 1000 revolutions per minute gets us a fuel usage of .0725 per rpm per minute, 
	#.001208 per rpm per second, or .0001208 per rpm per tenth second (the rate this script is updating at)
	
	var fuel_usage_per_tank = rpm * 0.0001208  / 6;
	for ( i = 0; i < 6; i += 1 ) {
		setprop("/consumables/fuel/tank["~i~"]/level-lbs",getprop("/consumables/fuel/tank["~i~"]/level-lbs") - fuel_usage_per_tank);
	}
	
	settimer(engineSim, 0.1);
}
engineInit = func {
	rpm0 = props.globals.getNode('engines/engine[0]/rpm', 1);
	rpm1 = props.globals.getNode('engines/engine[1]/rpm', 1);
	rpm2 = props.globals.getNode('engines/engine[2]/rpm', 1);
	rpmR = props.globals.getNode('rotors/main/rpm', 1);
	rpmR.setDoubleValue(0);
	engineSim();
}
settimer(engineInit, 0);

