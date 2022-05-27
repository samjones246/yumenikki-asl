state("RPG_RT", "0.10_eng")
{
    // Current map
    int levelid : 0xD1F70, 0x4;

    // Player x coordinate
    int posX : 0xD2004, 0x14;

    // Pointer to the start of the array containing the games switches (global booleans)
    int switchesPtr : 0xD1FF8, 0x20;

    // Pointer to the start of the array containing the games variables (global integers)
    int varsPtr : 0xD1FF8, 0x28;

    // Becomes true when the new game button is pressed.
    bool start : 0xD1E08, 0x8, 0x14, 0x70;

    // Frame counter, resets on entering menu and on entering instructions screen after starting game
    int frames : 0xD1FF8, 0x8;

    // State variable for Uboa room: 0 = light on, 1 = light off, 2 = uboa spawned
    int uboaState : 0xD1FF8, 0x28, 0x28;

    // A boolean which is true during transitions and certain other places
    bool doorFlag : 0xD1FF8, 0x20, 0x7f;

    // ID of the (top level) room event currently being executed
    int eventID : 0xD1FF8, 0x88, 0x1C, 0x0, 0x1C;
}

state("RPG_RT", "steam")
{ 
    int levelid : 0xD2068, 0x4;
    int posX : 0xD2014, 0x14;
    int switchesPtr : 0xD2008, 0x20;
    int varsPtr : 0xD2008, 0x28;
    bool start : 0xD1E08, 0x8, 0x14, 0x70;
    int frames : 0xD2008, 0x8;
    int uboaState : 0xD2008, 0x28, 0x28;
    bool doorFlag : 0xD2008, 0x20, 0x7f;
    int eventID : 0xD2008, 0x88, 0x1C, 0x0, 0x1C;
}

startup
{
    vars.Log = (Action<object>)((output) => {
        print("[Yume Nikki ASL] " + output);
        using (StreamWriter writer = new StreamWriter("yumenikki-asl.log", true)) {
            writer.WriteLine("[" + DateTime.Now.ToString("yyMMdd HH:mm:ss.fff") + "] " + output);
        }
    });

    try{
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

    Dictionary<int, string> room_names = new Dictionary<int, string> {
        {114, "Ghost World (Kerchief)"},
        {79, "Mall Music Room (Flute)"},
        {20, "Neon World (Neon)"},
        {86, "Dark Woods (Stoplight)"},
        {93, "Witch Island (Witch)"},
        {18, "Candle World (Midget)"},
    };

    List<string> defaults = new List<string>() {"Demon", "Triangle kerchief", "Witch"};

    settings.Add("splitEffect", true, "Split on effect acquired");
    for (int i = 0; i < effect_names.Length; i++)
    {
        settings.Add("effect"+i, defaults.Contains(effect_names[i]), effect_names[i], "splitEffect");
    }

    settings.Add("splitCloset", true, "Split on closet (entry)");
    settings.Add("splitClosetExit", false, "Split on closet (exit)");
    settings.Add("splitBarracks", false, "Split on barracks warp (activation)");
    settings.Add("splitBarracksExit", false, "Split on barracks warp (after)");
    settings.Add("splitDemon", false, "Split on demon warp (activation)");
    settings.Add("splitDemonExit", false, "Split on demon warp (after)");

    vars.piroriEvents = new int[] {1, 25, 72, 64, 67, 65}; 

    settings.Add("splitUboa", false, "Split on Uboa spawn");
    settings.Add("splitFace", false, "Split on FACE event");

    settings.Add("splitWarp", false, "Split on any Medamaude warp");
    settings.Add("splitRoomWarp", false, "Split on Medamaude warp from certain rooms");
    foreach (int id in room_names.Keys)
    {
        settings.Add("warp"+id, false, room_names[id], "splitRoomWarp");
    }
    } catch (Exception e) {
        vars.Log(e);
        throw e;
    }
}

init
{
    try {
    vars.Log("---INIT---");
    vars.Log("Module name: " + modules.First().ModuleName);
    vars.Log("Module size: " + modules.First().ModuleMemorySize.ToString("X"));
    if (modules.First().ModuleMemorySize == 0x106000 || modules.First().ModuleMemorySize == 0xF1000){
        version = "steam";
    }
    else if (modules.First().ModuleMemorySize == 0xF2000){
        version = "0.10_eng";
    }
    vars.firstUpdate = true;
    } catch (Exception e) {
        vars.Log(e);
        throw e;
    }
}

update
{
    try {
    // Update inventory array
    if (!((IDictionary<String, Object>)current).ContainsKey("switches")){
        current.switches = null;
    }
    if (!((IDictionary<String, Object>)current).ContainsKey("variables")){
        current.variables = null;
    }
    old.switches = current.switches;
    current.switches = game.ReadBytes(new IntPtr(current.switchesPtr), 300);
    old.variables = current.variables;
    byte[] varsBytes = game.ReadBytes(new IntPtr(current.varsPtr), 300 * 4);
    current.variables = new int[300];
    for (int i = 0; i < 300; i++)
    {
        current.variables[i] = BitConverter.ToInt32(varsBytes, i * 4);
    }

    if(vars.firstUpdate){
        vars.firstUpdate = false;
        vars.Log("Build: " + current.variables[0]);
    }

    if (current.levelid != old.levelid){
        vars.Log("Level changed: " + old.levelid + " -> " + current.levelid);
    }

    if(current.start != old.start){
        vars.Log("Start flag: " + current.start);
    }
    } catch (Exception e) {
        vars.Log(e);
        throw e;
    }
}

start
{
    try {
    // Bad and hacky
    if (current.start && !old.start){
        vars.Log("Starting timer");
        vars.startFrames = current.frames;
        return true;
    }
    } catch (Exception e) {
        vars.Log(e);
        throw e;
    }
}

split
{
    try {
    // Split on effect acquisition
    if (old.switches != null && current.switches != null){
        for (int i=0;i<24;i++){
            if (current.switches[i] == 0x01 && old.switches[i] == 0x00){
                vars.Log("Effect " + i + " acquired");
                if (settings["effect"+i]){
                    return true;
                }
            }
        }
    }

    // Split on closet (entry)
    if ((current.levelid == 35 || current.levelid == 36) && current.switches[128] == 0x01 && old.switches[128] == 0x00){
        vars.Log("Entered closet");
        return settings["splitCloset"];
    }

    // Split on closet (exit)
    if ((old.levelid == 35 || old.levelid == 36) && current.levelid == 30){
        vars.Log("Exited closet");
        return settings["splitClosetExit"];
    }

    // Split on demon warp (activation)
    // S247 Map Moving: ON
    // V048 Map Move Type: 2
    if (current.levelid == 146 && current.eventID == 1 && old.eventID != 1){
        vars.Log("Demon warp activated");
        return settings["splitDemon"];
    }

    // Split on demon warp (after)
    if (current.levelid == 140 && old.levelid==146){
        vars.Log("Demon warp finished");
        return settings["splitDemonExit"];
    }

    // Split on barracks warp (activation)
    // Pirori Engaged == V011: Private Room Var A 
    if (current.levelid == 66 && current.eventID == vars.piroriEvents[current.variables[10]-1] && old.eventID != current.eventID){
        vars.Log("Barracks warp activated");
        return settings["splitBarracks"];
    }

    // Split on barracks warp (after)
    if (old.levelid == 66 && current.levelid == 154){
        vars.Log("Barracks warp exit");
        return settings["splitBarracksExit"];
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

    // Split on warp
    if (current.switches[225] == 1 && old.switches[225] == 0){
        vars.Log("Medamaude warp");
        return settings["splitWarp"] || settings["warp"+current.levelid];
    }

    return false;
    } catch (Exception e) {
        vars.Log(e);
        throw e;
    }
}

reset
{
    try {
    if (current.frames < old.frames && old.frames != vars.startFrames){
        vars.Log("Resetting");
        return true;
    }
    } catch (Exception e) {
        vars.Log(e);
        throw e;
    }
}

isLoading
{
    try {
    return current.levelid == 9 && current.switches[128] == 0x01 && current.switches[132] == 0x00;
    } catch (Exception e) {
        vars.Log(e);
        throw e;
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
