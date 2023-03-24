#pragma newdecls required
#pragma dynamic 33554432

#include <regex>
#include <ripext>
#include <vdftojson>

#define REGEX "^[ \\t]*(\"((?:\\\\.|[^\\\\\"])+)\"|([a-zA-Z0-9\\-\\_]+))([ \\t]*(\"((?:\\\\.|[^\\\\\"])*)(\")?|([a-zA-Z0-9\\-\\_.]+)))?"
#define EMPTY "^.*?\"[^\"]*\".*?\"([^\"]*)\""

public Plugin myinfo = {
	name = "VDFtoJSON",
	author = "Oscar Wos (OSWO)",
	description = "A plugin which converts Valve Data Format (VDF) files to JSON format.",
	version = "1.10",
	url = "https://github.com/oscar-wos/VDFtoJSON",
};

ConVar enabled;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("VDFtoJSON", Native_Convert);
    RegPluginLibrary("vdftojson");
    return APLRes_Success;
}

public void OnPluginStart()
{
    enabled = CreateConVar("sm_vdftojson_enabled", "1", "Enables the console command sm_vdf2json.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
    RegConsoleCmd("sm_vdf2json", Command_vdftojson, "Converts a utf-8 VDF file to JSON format.");
    RegConsoleCmd("sm_vdftojson", Command_vdftojson, "Converts a utf-8 VDF file to JSON format.");

    RegConsoleCmd("sm_vdf2json16", Command_vdftojson16, "Converts a utf-16 VDF file to JSON format.");
    RegConsoleCmd("sm_vdftojson16", Command_vdftojson16, "Converts a utf-16 VDF file to JSON format.");
}

public Action Command_vdftojson(int client, int args)
{
    if (!enabled.BoolValue)
        return Plugin_Continue;

    char buffer[PLATFORM_MAX_PATH];
    GetCmdArgString(buffer, sizeof(buffer));
    
    if (strlen(buffer) == 0)
        FormatEx(buffer, sizeof(buffer), "../../scripts/items/items_game.txt");

    ReplyToCommand(client, "VDFReturn: %d", Convert(buffer));
    return Plugin_Handled;
}

public Action Command_vdftojson16(int client, int args)
{
    if (!enabled.BoolValue)
        return Plugin_Continue;

    char buffer[PLATFORM_MAX_PATH];
    GetCmdArgString(buffer, sizeof(buffer));

    if (strlen(buffer) == 0)
        FormatEx(buffer, sizeof(buffer), "../../resource/csgo_english.txt");

    ReplyToCommand(client, "VDFReturn: %d", Convert(buffer, _, VDFType_16));
    return Plugin_Handled;
}

VDFReturn Convert(const char[] input, const char[] output = "output.json", VDFType type = VDFType_8)
{
    char inputPath[PLATFORM_MAX_PATH], outputPath[PLATFORM_MAX_PATH], line[4096];

    BuildPath(Path_SM, inputPath, sizeof(inputPath), input);
    BuildPath(Path_SM, outputPath, sizeof(outputPath), "data/%s", output);

    if (!FileExists(inputPath))
        return VDFReturn_FileNotFound;

    File f = OpenFile(inputPath, "r");
    File o = OpenFile(outputPath, "w");

    if (f == null)
        return Exit(f, o, VDFReturn_InvalidReadFile);

    if (o == null)
        return Exit(f, o, VDFReturn_InvalidWriteFile);

    Regex r = new Regex(REGEX);
    Regex e = new Regex(EMPTY);
    JSONObject obj = new JSONObject();
    JSONArray stack = new JSONArray();
    stack.Push(obj);

    while (!f.EndOfFile())
    {
        if (!ReadLine(f, line, sizeof(line), type))
            break;

        int length = TrimString(line);
        int empty = e.Match(line);

        if (empty > 0)
        {
            char val[4096];
            e.GetSubString(1, val, sizeof(val));

            if (strlen(val) == 0)
                continue;     
        }

        if (strlen(line) == 0 || line[0] == '/')
            continue;

        if (line[length - 1] == '{')
        {
            if (length > 1)
                line[length - 1] = '\0';
            else
                continue;
        }

        if (line[0] == '}')
        {
            if (stack.Length > 0)
            {
                JSONObject last = view_as<JSONObject>(stack.Get(stack.Length - 1));
                Clean(last);

                stack.Remove(stack.Length - 1);
            }

            continue;
        }

        for (;;)
        {
            char key[4096], val[4096];
            int find = r.Match(line);
            if (find == 0) break;

            r.GetSubString(2, key, sizeof(key));
            r.GetSubString(6, val, sizeof(val));

            if (strlen(key) == 0) r.GetSubString(3, key, sizeof(key));
            if (strlen(val) == 0) r.GetSubString(8, val, sizeof(val));
            
            if (strlen(val) == 0)
            {
                JSONObject last = view_as<JSONObject>(stack.Get(stack.Length - 1));

                if (!last.HasKey(key))
                {  
                    JSONObject n = new JSONObject();
                    last.Set(key, n);

                    delete n;
                }
                
                JSONObject curr = view_as<JSONObject>(last.Get(key));
                stack.Push(curr);

                delete curr;
                delete last;
            }
            else
            {
                char check[4096], check1[4096];
                r.GetSubString(7, check, sizeof(check));
                r.GetSubString(8, check1, sizeof(check1));

                if (strlen(check) == 0 && strlen(check1) == 0)
                {
                    char next[4096];
                    if (ReadLine(f, next, sizeof(next), type))
                        Format(line, sizeof(line), "%s%s", line, next);

                    continue;
                }

                if (strlen(val) == 0)
                    continue;

                if (stack.Length > 0)
                {
                    JSONObject last = view_as<JSONObject>(stack.Get(stack.Length - 1));
                    last.SetString(key, val);
                    stack.Set(stack.Length - 1, last);

                    delete last;
                }
            }

            break;
        }
    }

    obj.ToFile(outputPath);

    delete r;
    delete e;
    delete obj;
    delete stack;

    return Exit(f, o, VDFReturn_Success);
}

bool ReadLine(File f, char[] line, int maxlength, VDFType type)
{
    if (f.EndOfFile())
        return false;

    if (type == VDFType_8)
        return f.ReadLine(line, maxlength);

    int i, data;

    while (ReadFileCell(f, data, 2) == 1)
    {
        if (data == 0xFEFF)
            continue;

        if (data < 0x80)
        {
            line[i++] = data;

            if (data == '\n')
            {
                line[i] = '\0';
                return true;
            }
            
        }
        else if (data < 0x800)
        {
            line[i++] = 0xC0 | (data >> 6);
            line[i++] = 0x80 | (data & 0x3F);
        }
        else
        {
            line[i++] = 0xE0 | (data >> 12);
            line[i++] = 0x80 | ((data >> 6) & 0x3F);
            line[i++] = 0x80 | (data & 0x3F);
        }
    }

    return false;
}

void Clean(JSONObject obj)
{
    char key[4096], val[4096];
    JSONObjectKeys keys = obj.Keys();

    while (keys.ReadKey(key, sizeof(key)))
    {
        if (obj.GetString(key, val, sizeof(val)))
            continue;

        JSONObject o = view_as<JSONObject>(obj.Get(key));
        Clean(o);
    }

    delete keys;
    delete obj;
}

VDFReturn Exit(File f, File o, VDFReturn r)
{
    if (f != INVALID_HANDLE)
        delete f;

    if (o != INVALID_HANDLE)
        delete o;

    return r;
}

int Native_Convert(Handle plugin, int numParams)
{
    char path[PLATFORM_MAX_PATH], output[PLATFORM_MAX_PATH];

    GetNativeString(1, path, sizeof(path));
    GetNativeString(2, output, sizeof(output));
    VDFType type = GetNativeCell(3);

    return view_as<int>(Convert(path, output, type));
}