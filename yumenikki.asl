state("RPG_RT", "0.10_eng")
{
    // Current map
    int levelid : 0xD1F70, 0x4;

    // Player x coordinate
    int posX : 0xD2004, 0x14;

    // Pointer to the start of the array containing the player's inventory
    int effectsPtr : 0xD1FF8, 0x20;

    // Becomes true when the new game button is pressed.
    bool start : 0xD1E08, 0x8, 0x14, 0x70;

    // Frame counter, resets on entering menu and on entering instructions screen after starting game
    int frames : 0xD1FF8, 0x8;

    // State variable for Uboa room: 0 = light on, 1 = light off, 2 = uboa spawned
    int uboaState : 0xD1FF8, 0x28, 0x28;

    // A boolean which is true during transitions and certain other places
    bool doorFlag : 0xD1FF8, 0x20, 0x7f;
}

state("RPG_RT", "steam")
{ 
    int levelid : 0xD2068, 0x4;
    int posX : 0xD2014, 0x14;
    int effectsPtr : 0xD2008, 0x20;
    bool start : 0xD1E08, 0x8, 0x14, 0x70;
    int frames : 0xD2008, 0x8;
    int uboaState : 0xD2008, 0x28, 0x28;
    bool doorFlag : 0xD2008, 0x20, 0x7f; 
}

startup
{
    vars.Log = (Action<object>)((output) => {
        print("[Yume Nikki ASL] " + output);
        using (StreamWriter writer = new StreamWriter("yumenikki-asl.log", true)) {
            writer.WriteLine("[" + DateTime.Now.ToString("yyMMdd HH:mm:ss.fff") + "] " + output);
        }
    });

    vars.Log("---STARTUP---");

    // String at index i has offset i from effects ptr
    string[] effect_names = new string[] {
        "Frog",              "Umbrella",   "Hat and scarf", "Yuki-onna",
        "Medamaude",         "Fat",        "Midget",        "Flute", 
        "Neon",              "Nopperabou", "Severed head",  "Knife", 
        "Triangle kerchief", "Towel",      "Cat",           "Lamp", 
        "Bicycle",           "Long hair",  "Poop hair",     "Blonde hair", 
        "Witch",             "Demon",      "Buyo buyo",     "Stoplight"
    };

    List<string> defaults = new List<string>() {"Demon", "Triangle kerchief", "Witch"};

    settings.Add("splitEffect", true, "Split on effect acquired");
    for (int i = 0; i < effect_names.Length; i++)
    {
        settings.Add("effect"+i, defaults.Contains(effect_names[i]), effect_names[i], "splitEffect");
    }

    settings.Add("splitCloset", true, "Split on entering closet");

    settings.Add("splitBarracks", false, "Split on barracks warp");

    settings.Add("splitUboa", false, "Split on Uboa spawn");

    settings.Add("splitFace", false, "Split on FACE event");
}

init
{
    vars.Log("---INIT---");
    vars.Log("Module name: " + modules.First().ModuleName);
    vars.Log("Module size: " + modules.First().ModuleMemorySize.ToString("X"));
    if (modules.First().ModuleMemorySize == 0x106000){
        version = "steam";
    }
    else if (modules.First().ModuleMemorySize == 0xF2000){
        version = "0.10_eng";
    }
}

update
{
    // Update inventory array
    if (!((IDictionary<String, Object>)current).ContainsKey("effects")){
        current.effects = null;
    }
    old.effects = current.effects;
    current.effects = game.ReadBytes(new IntPtr(current.effectsPtr), 24);

    if (current.levelid != old.levelid){
        vars.Log("Level changed: " + old.levelid + " -> " + current.levelid);
    }

    if(current.start != old.start){
        vars.Log("Start flag: " + current.start);
    }
}

start
{
    // Bad and hacky
    if (current.start && !old.start){
        vars.Log("Starting timer");
        vars.startFrames = current.frames;
        return true;
    }
}

split
{
    // Split on effect acquisition
    if (old.effects != null && current.effects != null){
        for (int i=0;i<24;i++){
            if (current.effects[i] == 0x01 && old.effects[i] == 0x00){
                vars.Log("Effect " + i + " acquired");
                if (settings["effect"+i]){
                    return true;
                }
            }
        }
    }

    // Split on entering closet
    if ((old.levelid == 35 || old.levelid == 36) && current.levelid == 30){
        vars.Log("Entered closet");
        return settings["splitCloset"];
    }

    // Split on barracks warp
    if (old.levelid == 66 && current.levelid == 154){
        vars.Log("Barracks warp");
        return settings["splitBarracks"];
    }

    // Split on ending game
    if (current.levelid == 4 && current.posX < 10 && old.posX >= 10){
        vars.Log("Balcony jump");
        return true;
    }

    if (current.levelid == 109 && current.uboaState == 2 && old.uboaState != 2){
        vars.Log("Uboa Spawned");
        return settings["splitUboa"];
    }

    // Split on entering FACE door.
    // Checks for: right level, right x-coord, and door flag active
    if (current.levelid == 33 && current.doorFlag && !old.doorFlag && current.posX == 29){
        vars.Log("Face");
        return settings["splitFace"];
    }

    return false;
}

reset
{
    if (current.frames < old.frames && old.frames != vars.startFrames){
        vars.Log("Resetting");
        return true;
    }
}

exit
{
    vars.Log("---EXIT---");
}

shutdown
{
    vars.Log("---SHUTDOWN---");
}
