#pragma newdecls required
#pragma dynamic 16777216
#include <regex>
#include <ripext>
#include <vdftojson>

#define REGEX "^(\"((?:\\\\.|[^\\\\\"])+)\"|([a-z0-9\\-\\_]+))([ \t]*(\"((?:\\\\.|[^\\\\\"])*)(\")?|([a-z0-9\\-\\_]+)))?"

public Plugin myinfo = {
	name = "VDFtoJSON",
	author = "Oscar Wos (OSWO)",
	description = "A plugin which converts Valve Data Format (VDF) files to JSON format.",
	version = "1.01",
	url = "https://github.com/oscar-wos/VDFtoJSON",
};

ConVar command;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("vdftojson");
    CreateNative("VDFtoJSON", Native_Convert);
    return APLRes_Success;
}

public void OnPluginStart()
{
    command = CreateConVar("sm_vdftojson", "1", "Enables the console command sm_vdf2json.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
    RegConsoleCmd("sm_vdf2json", Command_vdftojson, "Converts a VDF file to JSON format.");
    RegConsoleCmd("sm_vdftojson", Command_vdftojson, "Converts a VDF file to JSON format.");
}

public Action Command_vdftojson(int client, int args)
{
    if (!command.BoolValue) return Plugin_Continue;

    char buffer[PLATFORM_MAX_PATH];
    GetCmdArgString(buffer, sizeof(buffer));
    if (strlen(buffer) == 0) FormatEx(buffer, sizeof(buffer), "../../scripts/items/items_game.txt");

    ReplyToCommand(client, "VDFReturn: %d", Convert(buffer));
    return Plugin_Handled;
}

int Native_Convert(Handle plugin, int numParams)
{
    char path[PLATFORM_MAX_PATH], output[PLATFORM_MAX_PATH];
    GetNativeString(1, path, sizeof(path));
    GetNativeString(2, output, sizeof(output));

    return view_as<int>(Convert(path, output));
}

VDFReturn Convert(const char[] path, const char[] output = "output.json")
{
    char realPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, realPath, sizeof(realPath), path);
    if (!FileExists(realPath)) return VDFReturn_FileNotFound;

    File f = OpenFile(realPath, "r");    
    if (f == null) return VDFReturn_InvalidReadFile;

    char explode[64][PLATFORM_MAX_PATH];
    ExplodeString(realPath, "/", explode, sizeof(explode), PLATFORM_MAX_PATH);

    char outputPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, outputPath, sizeof(outputPath), "data/%s", output);

    File o = OpenFile(outputPath, "w");
    if (o == null) return VDFReturn_InvalidWriteFile;

    char curr[4096];
    bool expect = false;

    Regex r = CompileRegex(REGEX);
    JSONObject obj = new JSONObject();
    JSONArray stack = new JSONArray();
    stack.Push(obj);

    while (!f.EndOfFile()) {
        f.ReadLine(curr, sizeof(curr));
        TrimString(curr);

        if (strlen(curr) == 0 || strcmp(curr, "/") == 0) continue;

        if (strcmp(curr, "{") == 0) {
            expect = false;
            continue;
        }

        if (expect) return VDFReturn_InvalidFormat;

        if (strcmp(curr, "}") == 0) {
            if (stack.Length > 0) {
                JSONObject c = view_as<JSONObject>(stack.Get(stack.Length - 1));
                Clean(c);

                stack.Remove(stack.Length - 1);
            }

            continue;
        }

        for (;;) {
            r.Match(curr);

            char key[4096], val[4096];
            r.GetSubString(2, key, sizeof(key));
            r.GetSubString(6, val, sizeof(val));

            if (strlen(key) == 0) r.GetSubString(3, key, sizeof(key));
            if (strlen(val) == 0) r.GetSubString(8, val, sizeof(val));

            if (strlen(val) == 0) {
                JSONObject m = view_as<JSONObject>(stack.Get(stack.Length - 1));

                if (!m.HasKey(key)) {
                    JSONObject n = new JSONObject();
                    m.Set(key, n);

                    delete n;
                }

                JSONObject p = view_as<JSONObject>(m.Get(key));
                stack.Push(p);
                expect = true;

                delete m; delete p;
            } else {
                char check[4096], check1[4096];
                r.GetSubString(7, check, sizeof(check));
                r.GetSubString(8, check1, sizeof(check1));

                if (strlen(check) == 0 && strlen(check1) == 0) {
                    char next[4096];
                    f.ReadLine(next, sizeof(next));

                    Format(curr, sizeof(curr), "%s%s", curr, next);
                    continue;
                }

                JSONObject a = view_as<JSONObject>(stack.Get(stack.Length - 1));
                a.SetString(key, val);
                stack.Set(stack.Length - 1, a);

                delete a;
            }

            break;
        }
    }

    obj.ToFile(outputPath);
    delete f; delete o; delete r; delete obj; delete stack;

    return VDFReturn_Success;
}

void Clean(JSONObject obj)
{
    char key[4096], val[4096];
    JSONObjectKeys keys = obj.Keys();

    while (keys.ReadKey(key, sizeof(key))) {
        if (obj.GetString(key, val, sizeof(val))) continue;

        JSONObject o = view_as<JSONObject>(obj.Get(key));
        Clean(o);
    }

    delete keys; delete obj;
}