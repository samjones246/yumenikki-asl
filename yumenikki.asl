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
}

init
{
    current.effects = null;
}

update
{
    // Update inventory array
    old.effects = current.effects;
    current.effects = game.ReadBytes(new IntPtr(current.effectsPtr), 24);
}

start
{
    // Bad and hacky
    return old.weirdMenuVal == 1000 && current.weirdMenuVal == 800;
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
    if (settings["splitCloset"] && old.levelid == 35 && current.levelid == 30){
        vars.Log("Entered closet");
        return true;
    }

    // Split on ending game
    if (current.levelid == 4 && current.posX < 10 && old.posX >= 10){
        vars.Log("End");
        return true;
    }

    return false;
}