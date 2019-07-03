###############################################################################
##
##   Sometimes we crashed our Aircrafts :-(
##   Now we can get help from yasim - multiplayer helicopter pilots :-)
##   The great work from Anders Gidenstamm is the root of this script, 
##   written by Marc Kraus :: Lake of Constance Hangar
##
##   Copyright (C) 2012 - 2014  Marc Kraus  (info(at)marc-kraus.de)
##
###############################################################################

# =============================================================================
#               H-21C Piasecki rescue action for your aircraft            
# =============================================================================
var debug = 0;
# fix this string value for mp-weight-calculation
var p_callsign  = "/sim/multiplay/generic/string[15]"; 

setprop(p_callsign, "");
setprop("/sar_service/helicopter_rescue", 0);
setprop("/sar_service/sar-callsign", "");
setprop("/sar_service/sar-locked", 0);


###########################  start up the SAR action ###########################

# set here the path of the helicopter, you want to use for heaving procedure
# note: the helicopter must have a generic float[x] with the /position/altitude-agl-ft

var heroes = [
  { model: "Aircraft/H-21C-Shawnee/Models/H21-piasecki.xml", agl: "/sim/multiplay/generic/float[0]", alt: 8.06 },
  { model: "Aircraft/hughes500/Models/MD-500E.xml", agl: "/sim/multiplay/generic/float[1]", alt: 6.0 }
];


var helicopter_path     = ["Aircraft/H-21C-Shawnee/Models/H21-piasecki.xml",
                           "Aircraft/ch47/Models/CH47.xml",
                           "Aircraft/hughes500/Models/MD-500E.xml",
                           "Aircraft/ch53e/Models/ch53e.xml"]; 

var agl_float           = "";
var agl_h21             = "/sim/multiplay/generic/float[0]";
var agl_c47             = "/sim/multiplay/generic/float[1]"; 
var agl_h500             = "/sim/multiplay/generic/float[0]";
var agl_ch53             = "/sim/multiplay/generic/float[0]"; 

var sar_alt_correction  = 0.0;
var sar_alt_h21         = 8.06;
var sar_alt_c47         = 6.0;
var sar_alt_h500         = 4.0;
var sar_alt_ch53         = 7.0;

# look what the /position/altitude-ft is, when you are on ground and set this property
var sar_alt_correction  =  8.06; # SAR Helicopter is the Piasecki
var this_alt_correction =  8.06; # an this is the Piasecki so its the same correction
var towel_length        = 50.0;
var in_the_air          = 0;
var in_mount_range      = 0;
var ballastInPound      = 3500.0;

## if the aircraft is on the hook the working helicopter recept this property with his own callsign set weight ###

var my_poid = func (){
    var mpOther = props.globals.getNode("/ai/models").getChildren("multiplayer");
    var otherNr = size(mpOther);
    setprop("/sim/weight[5]/weight-lb", 0.0);
     for(var v = 0; v < otherNr; v += 1) {
        if (getprop("/sim/multiplay/callsign") == getprop("/ai/models/multiplayer["~v~"]"~p_callsign)) {
          setprop("/sim/weight[5]/weight-lb", ballastInPound);
        }
     }

  settimer( func { my_poid(); }, 2.5);

}

my_poid();
#################################################################################
############################## crash control ###################################

setlistener("/sar_service/helicopter_rescue", func(oje) {
     if(debug) print("Notruf wurde abgesetzt ...");
     if(oje.getBoolValue()){
        sar_service.sar_dialog.show(helicopter_path);
        in_the_air = 0;
     }
}, 1, 0);

setlistener("/sar_service/sar-callsign", func(sar_callsign) {
     if(debug) print("SAR Pilot wurde ausgewaehlt.");
     if(sar_callsign.getValue()){
        setprop("/sim/multiplay/chat", "");
        setprop("/sim/multiplay/chat", ":: MAYDAY :: MAYDAY :: MAYDAY ::");
        settimer( func { setprop("/sim/multiplay/chat", "I'm here, "~sar_callsign.getValue()~", please help me!"); }, 3);
        setprop("/sar_service/sar-locked", 1);
        in_the_air = 0;
        in_mount_range = 0;
        var mp   = props.globals.getNode("/ai/models").getChildren("multiplayer");
        var mpNr = size(mp);

        for(var v = 0; v < mpNr; v += 1) {
            if (find_the_sar_hero(mp[v], sar_callsign)) {
                var sar_index = v;
            }
        }
        if(debug) print(sar_index);
        rescue_me(sar_index);
     }else{
        if(in_the_air == 1) {
            setprop("/sar_service/sar-callsign", "");
            setprop("/sar_service/sar-locked", 0);
            setprop("/sim/crashed",0);
        }
        setprop("/sar_service/helicopter_rescue",0);
        setprop("/sar_service/sar-locked",0);
        setprop("/controls/shadow-and-fire", 1);
        in_mount_range = 0;
        setprop(p_callsign, "");
     }
}, 1, 0);

############################### Rescue procedure ###############################

var rescue_me = func(v) {
  
    if (v != nil and v >= 0){
      var sar_mp = props.globals.getNode("/ai/models/multiplayer[" ~v~ "]");
      yourLocked  = getprop("/sar_service/sar-locked") or 0;

      if(yourLocked){
         var my_alt   = props.globals.getNode("/position/altitude-ft");
         var heaving_heli_alt = (getprop("/ai/models/multiplayer["~v~"]/position/altitude-ft") + sar_alt_correction) - towel_length;
         var ground = getprop("/ai/models/multiplayer["~v~"]"~agl_float) - sar_alt_correction + this_alt_correction - towel_length; 

         # if we are on ground and not on heaving procedure, look for the distance to the hook
         if (in_the_air == 0){
           var sar_pos_lat = getprop("/ai/models/multiplayer["~v~"]/position/latitude-deg"); 
           var sar_pos_lon = getprop("/ai/models/multiplayer["~v~"]/position/longitude-deg");
           var my_pos_lat = getprop("/position/latitude-deg");
           var my_pos_lon = getprop("/position/longitude-deg");
           
           if((math.abs(sar_pos_lat - my_pos_lat) <= 0.00008) and (math.abs(sar_pos_lon - my_pos_lon) <= 0.0012)){
              in_mount_range = 1;
              setprop(p_callsign, getprop("/ai/models/multiplayer["~v~"]/callsign"));
           }else{
              setprop(p_callsign, "");
              in_mount_range = 0;
           }
         }

         # wenn eingehaengt, und die richtige Hoehe erreicht ist
         if(ground >= 1 and in_mount_range){
              in_the_air = 1;
              setprop("/controls/shadow-and-fire", 0);
              setprop("/sim/crashed", 1);
              my_alt.setValue(heaving_heli_alt);

              setprop("/position/longitude-deg", getprop("/ai/models/multiplayer["~v~"]/position/longitude-deg"));
              setprop("/position/latitude-deg", getprop("/ai/models/multiplayer["~v~"]/position/latitude-deg"));
              setprop("/orientation/pitch-deg", getprop("/ai/models/multiplayer["~v~"]/orientation/pitch-deg"));
              setprop("/orientation/roll-deg", getprop("/ai/models/multiplayer["~v~"]/orientation/roll-deg")); 
              setprop("/position/latitude-deg", getprop("/ai/models/multiplayer["~v~"]/position/latitude-deg"));  
      
              if(debug){
                  print("Hebevorgang laeuft.");
                  print("Ground ist: "~ground);
                  print("my_alt ist: "~my_alt.getValue());
                  print("heaving__alt "~heaving_heli_alt);
                  print("mounted "~in_mount_range);
              }
          }else{       # wenn eingehaengt, aber noch nicht die richtige Hoehe erreicht ist, ist der Flieger ganz
              if(in_the_air == 1) {
                  setprop("/sar_service/sar-callsign", "");
                  setprop("/sar_service/sar-locked", 0);
                  setprop("/sim/crashed",0);
              }
              setprop(p_callsign, "");
              in_mount_range = 0;
              in_the_air = 0;
          }

          settimer( func { rescue_me(v); }, 0);

       }else{
          # if nobody is in range... nobody can help. So set /sar_service back to 0
          # setprop("/sim/crashed",0);
          setprop("/sar_service/helicopter_rescue",0);
          setprop("/sar_service/sar-callsign","");
          setprop("/controls/shadow-and-fire", 1);
          setprop(p_callsign, "");
          in_mount_range = 0;
          if(in_the_air == 1) {
              setprop("/sim/crashed",0);
          }
          in_the_air = 0;
          if(debug) print("Nicht mehr eingehaengt."); 
       } 
     } # end v nil control

}

var find_the_sar_hero = func(hero, callsign) {
    if (hero.getNode("sim/model/path").getValue() == helicopter_path[0]
        and hero.getNode("callsign").getValue() == callsign.getValue()
        and hero.getNode("id").getValue() >= 0){               # if other aircraft crashed the id is -1
    
      if(debug) print ("You never walk alone - Piasecki is comming!");
      sar_alt_correction  = sar_alt_h21;
      agl_float           = agl_h21;
      return 1;

    }elsif (hero.getNode("sim/model/path").getValue() == helicopter_path[1]
        and hero.getNode("callsign").getValue() == callsign.getValue()
        and hero.getNode("id").getValue() >= 0){               # if other aircraft crashed the id is -1
    
      if(debug) print ("You never walk alone - Chinook is comming");
      sar_alt_correction  = sar_alt_c47;
      agl_float           = agl_c47;
      return 1;

    }elsif (hero.getNode("sim/model/path").getValue() == helicopter_path[2]
        and hero.getNode("callsign").getValue() == callsign.getValue()
        and hero.getNode("id").getValue() >= 0){               # if other aircraft crashed the id is -1
    
      if(debug) print ("You never walk alone - Hughes500E is comming");
      sar_alt_correction  = sar_alt_h500;
      agl_float           = agl_h500;
      return 1;

    }elsif (hero.getNode("sim/model/path").getValue() == helicopter_path[3]
        and hero.getNode("callsign").getValue() == callsign.getValue()
        and hero.getNode("id").getValue() >= 0){               # if other aircraft crashed the id is -1
    
      if(debug) print ("You never walk alone - CH-53 is comming");
      sar_alt_correction  = sar_alt_ch53;
      agl_float           = agl_ch53;
      return 1;

    }else{

      if(debug) print("Ups... the hero is gone.");
      return 0;
    }
}

########################### create a new main menu ################################
var DLG_SAR = 0;

var dialog = {

    init: func(x = nil, y = nil) {
        me.x = x;
        me.y = y;
        # "private"
        me.name = "SAR_Pilots";
        me.dialog = nil;
        me.loopid = 0;
    },

    create: func {
        if (me.dialog != nil)
            me.close();

        me.dialog = gui.dialog[me.name] = gui.Widget.new();
        me.dialog.set("name", me.name);
        me.dialog.set("dialog-name", me.name);
        if (me.x != nil)
            me.dialog.set("x", me.x);
        if (me.y != nil)
            me.dialog.set("y", me.y);

        me.dialog.set("layout", "vbox");
	      me.dialog.set("valign", "fill");
        me.dialog.set("resizable", 1);
        var titlebar = me.dialog.addChild("group");
        titlebar.set("layout", "hbox");

        if (me.x != nil)
            me.dialog.set("x", me.x);
        if (me.y != nil)
            me.dialog.set("y", me.y);
        me.update(me.loopid += 1);
        fgcommand("dialog-new", me.dialog.prop());
        fgcommand("dialog-show", me.dialog.prop());
    },

    update: func(id) {

    },

    close: func {
        if (me.dialog != nil) {
            me.x = me.dialog.prop().getNode("x").getValue();
            me.y = me.dialog.prop().getNode("y").getValue();
        }
        fgcommand("dialog-close", me.dialog.prop());
    },
    del: func {
        DLG_SAR = 0;
        me.close();
        foreach (var l; me.listeners)
            removelistener(l);
        delete(gui.dialog, me.name);
    },
    show: func {
        if (!DLG_SAR) {
            DLG_SAR = 1;
            me.init(-2, -2);
            me.create();
            me.update(me.loopid += 1);
        }
    },
    toggle: func {
        if (!DLG_SAR)
            me.show();
        else
            me.del();
    },
};

dialog.show();
dialog.close();

var list= props.globals.getNode("/sim/menubar/default").getChildren("menu");
var menup = "/sim/menubar/default/menu[" ~ size(list) ~ "]/";
setprop (menup ~ "enabled", 'true');
setprop (menup ~ "label", "SAR");    
var nn = menup ~ "item/";
setprop (nn ~ "label", "Call SAR helicopter");
var bind = nn ~ "binding/";
setprop (bind ~ "command", "property-toggle");
setprop (bind ~ "property", "/sar_service/helicopter_rescue");

fgcommand("gui-redraw");



################## new menu for the SAR Pilot selection ########################
var SAR_DLG = 0;
var sar_dialog = {};
############################################################
sar_dialog.init = func (sar_type, x = nil, y = nil) {
    me.x = x;
    me.y = y;
    me.bg = [0, 0, 0, 0.3];    # background color
    me.fg = [[1.0, 1.0, 1.0, 1.0]]; 
    #
    # "private"
    me.title = "SAR";
    me.basenode = props.globals.getNode("/sar_service", 1);
    me.dialog = nil;
    me.namenode = props.Node.new({"dialog-name" : me.title });
    me.listeners = [];
    me.sar_type = helicopter_path;
}
############################################################
sar_dialog.create = func {
    if (me.dialog != nil)
        me.close();

    me.dialog = gui.Widget.new();
    me.dialog.set("name", me.title);
    if (me.x != nil)
        me.dialog.set("x", me.x);
    if (me.y != nil)
        me.dialog.set("y", me.y);

    me.dialog.set("layout", "vbox");
    me.dialog.set("default-padding", 0);
    var titlebar = me.dialog.addChild("group");
    titlebar.set("layout", "hbox");
    titlebar.addChild("empty").set("stretch", 1);
    titlebar.addChild("text").set("label", "SAR pilots in range");
    var w = titlebar.addChild("button");
    w.set("pref-width", 16);
    w.set("pref-height", 16);
    w.set("legend", "");
    w.set("default", 0);
    w.set("key", "esc");
    w.setBinding("nasal", "sar_service.sar_dialog.destroy(); ");
    w.setBinding("dialog-close");
    me.dialog.addChild("hrule");

    var content = me.dialog.addChild("group");
    content.set("layout", "vbox");
    content.set("halign", "center");
    content.set("default-padding", 5);

    # Generate the dialog contents.
    me.players = me.find_sar_players();
    var i = 0;
    var tmpbase  = me.basenode.getNode("dialog", 1);
    var selected = me.basenode.getNode("sar-callsign").getValue();
    foreach (var p; me.players) {
        var tmp = tmpbase.getNode("b[" ~ i ~ "]", 1);
        tmp.setBoolValue(streq(selected, p));
        var w = content.addChild("checkbox");
        w.node.setValues({"label"    : p,
                          "halign"   : "left",
                          "property" : tmp.getPath()});
        w.setBinding
            ("nasal",
             "sar_service.sar_dialog.select_action(" ~ i ~ ");");
        i = i + 1;
    }
    me.dialog.addChild("hrule");

    # Display the dialog.
    fgcommand("dialog-new", me.dialog.prop());
    fgcommand("dialog-show", me.namenode);
}
############################################################
sar_dialog.close = func {
    fgcommand("dialog-close", me.namenode);
}
############################################################
sar_dialog.destroy = func {
    SAR_DLG = 0;
    me.close();
    foreach(var l; me.listeners)
        removelistener(l);
    delete(gui.dialog, "\"" ~ me.title ~ "\"");
}
############################################################
sar_dialog.show = func (sar_type) {
#    print("Showing MPCopilots dialog!");
    if (!SAR_DLG) {
        SAR_DLG = int(getprop("/sim/time/elapsed-sec"));
        me.init(sar_type);
        me.create();
        me._update_(SAR_DLG);
    }
}
############################################################
sar_dialog._redraw_ = func {
    if (me.dialog != nil) {
        me.close();
        me.create();
    }
}
############################################################
sar_dialog._update_ = func (id) {
    if (SAR_DLG != id) return;
    me._redraw_();
    settimer(func { me._update_(id); }, 5.0);
}
############################################################
sar_dialog.select_action = func (n) {
    var selected = me.basenode.getNode("sar-callsign").getValue();
    var bs = me.basenode.getNode("dialog").getChildren();
    # Assumption: There are two true b:s or none. The one not matching selected
    #             is the new selection.
    var i = 0;
    me.basenode.getNode("sar-callsign").setValue("");
    foreach (var b; bs) {
        if (!b.getValue() and (i == n)) {
            b.setValue(1);
            me.basenode.getNode("sar-callsign").setValue(me.players[i]);
        } else {
            b.setValue(0);
        }
        i = i + 1;
    }
    #dual_control.main.reset();
    me._redraw_();
}
############################################################
# Return a list containing all nearby copilot players of the right type.
sar_dialog.find_sar_players = func {
    var mpplayers =
        props.globals.getNode("/ai/models").getChildren("multiplayer");

    var res = [];
    foreach (var pilot; mpplayers) {
        if ((pilot.getNode("valid") != nil) and
            (pilot.getNode("valid").getValue()) and
            (pilot.getNode("sim/model/path") != nil)) {
            var type = pilot.getNode("sim/model/path").getValue();

            if (type == me.sar_type[0] or type == me.sar_type[1] or type == me.sar_type[2] or type == me.sar_type[3] ) {
                append(res, pilot.getNode("callsign").getValue());
            }
        }
    }
#    debug.dump(res);
    return res; 
}
###############################################################################
