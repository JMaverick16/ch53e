input = {
  replay:           "sim/replay/replay-state",
  elapsed:          "sim/time/elapsed-sec",
  impact:			"/ai/models/model-impact",
};

  # setup property nodes for the loop
  foreach(var name; keys(input)) {
      input[name] = props.globals.getNode(input[name], 1);
  }

var fire_gun = func(){
	if(getprop("controls/armament/trigger")){
		var scnd = getprop("sim/time/delta-sec");
		var rounds=getprop("controls/armament/ammo");
		if(rounds>0){
			setprop("controls/armament/gun-trigger",1);
			var spent= 80 * scnd;
			rounds = rounds-spent;
			if(rounds<0)rounds=0;
		}
		setprop("controls/armament/ammo",rounds);
		settimer(fire_gun,0.1);
	} else {
		setprop("controls/armament/gun-trigger",0);
	}
};

setlistener("/controls/armament/trigger", fire_gun);

var reload_ammo = func(){
	setprop("controls/armament/ammo",2800);
}

var hit_count = 0;
var hit_callsign = "";
var hit_timer = 0;
var closest_distance = 50;

setlistener("/ai/models/model-impact", func {
    var ballistic_name = input.impact.getValue();
    var ballistic = props.globals.getNode(ballistic_name, 0);
	var closest_distance = 10000;
	var inside_callsign = "";
	#print("inside listener");
    if (ballistic != nil) {
		#print("ballistic isn't nil");
		var typeNode = ballistic.getNode("impact/type");
		if (typeNode != nil and typeNode.getValue() != "terrain") {
			#print("typenode isnt nil");
			var lat = ballistic.getNode("impact/latitude-deg").getValue();
			var lon = ballistic.getNode("impact/longitude-deg").getValue();
			var impactPos = geo.Coord.new().set_latlon(lat, lon);
			foreach(var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")){
				#print("Gau impact - hit: " ~ typeNode.getValue());
				var mlat = mp.getNode("position/latitude-deg").getValue();
				var mlon = mp.getNode("position/longitude-deg").getValue();
				var malt = mp.getNode("position/altitude-ft").getValue() * FT2M;
				var selectionPos = geo.Coord.new().set_latlon(mlat, mlon, malt);
				var distance = impactPos.distance_to(selectionPos);
				#print("distance = " ~ distance);
				if (distance < closest_distance) {
					closest_distance = distance;
					inside_callsign = mp.getNode("callsign").getValue();
				}
			}

			if ( inside_callsign != "" ) {
				#we have a successful hit
				#print("successful hit");
				if ( inside_callsign == hit_callsign ) {
					hit_count = hit_count + 1;
					#print("hit_count: " ~ hit_count);
				} else {
					#print("new callsign");
					hit_callsign = inside_callsign;
					hit_count = 1;
				}
				if ( hit_timer == 0 ) {
					hit_timer = 1;
					print("should be going into the timer...");
					settimer(hitmessage,1);
				}
			}
		}
	}
});

var hitmessage = func() {
	print("inside hitmessage");
	message = "50 BMG hit: " ~ hit_callsign ~ ": " ~ hit_count ~ " hits";
	defeatSpamFilter(message);
	hit_callsign = "";
	hit_timer = 0;
	hit_count = 0;
}

var spams = 0;
var spamList = [];

var defeatSpamFilter = func (str) {
  spams += 1;
  if (spams == 15) {
    spams = 1;
  }
  str = str~":";
  for (var i = 1; i <= spams; i+=1) {
    str = str~".";
  }
  var newList = [str];
  for (var i = 0; i < size(spamList); i += 1) {
    append(newList, spamList[i]);
  }
  spamList = newList;  
}

var spamLoop = func {
  var spam = pop(spamList);
  if (spam != nil) {
    setprop("/sim/multiplay/chat", spam);
  }
  settimer(spamLoop, 1.20);
}

spamLoop();
