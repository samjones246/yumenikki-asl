state("RPG_RT", "0.10_eng")
{
    // Current map
    int levelid : 0xD1F70, 0x4;

    // Player x coordinate
    int posX : 0xD2004, 0x14;

    // Pointer to the start of the array containing the player's inventory
    int effectsPtr : 0xD1FF8, 0x20;

    // A value used for detecting when start is pressed. I have no idea what it is.
    int weirdMenuVal : 0x000D1F60, 0x5DC;

    // Frame counter, resets on entering menu and on entering instructions screen after starting game
    int frames : 0xD1FF8, 0x8;

    // State variable for Uboa room: 0 = light on, 1 = light off, 2 = uboa spawned
    int uboaState : 0xD1FF8, 0x28, 0x28;
}

state("RPG_RT", "steam")
{ 

    int levelid : 0xD2068, 0x4;
    int posX : 0xD2014, 0x14;
    int effectsPtr : 0xD2008, 0x20;
    int weirdMenuVal : 0x000D2078, 0x9A4;
    int frames : 0xD2008, 0x8;
    int uboaState : 0xD2008, 0x28, 0x28;
}



startup
{
    vars.Log = (Action<object>)((output) => print("[Yume Nikki ASL] " + output));

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

    settings.Add("splitUboa", true, "Split on Uboa spawn");
}

init
{
    vars.DEBUG = true;
    if (vars.DEBUG){
        vars.Log(modules.First().ModuleName);
        vars.Log(modules.First().ModuleMemorySize.ToString("X"));
    }
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

    if (current.levelid != old.levelid && vars.DEBUG){
        vars.Log("Level changed: " + old.levelid + " -> " + current.levelid);
    }
}

start
{
    // Bad and hacky
    if (old.weirdMenuVal == 1000 && current.weirdMenuVal == 800){
        vars.Log("Starting");
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
                if (settings["effect"+i]){
                    vars.Log("Effect " + i + " acquired");
                    return true;
                }
            }
        }
    }

    // Split on entering closet
    if (settings["splitCloset"] && (old.levelid == 35 || old.levelid == 36) && current.levelid == 30){
        vars.Log("Entered closet");
        return true;
    }

    // Split on ending game
    if (current.levelid == 4 && current.posX < 10 && old.posX >= 10){
        vars.Log("End");
        return true;
    }

    if (settings["splitUboa"] && current.uboaState == 2 && old.uboaState != 2){
        vars.Log("Uboa Spawned");
        return true;
    }

    return false;
}

reset
{
    return current.frames < old.frames && old.frames != vars.startFrames;
}
