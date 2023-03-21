#pragma newdecls required
#pragma dynamic 13107299
#include <regex>
#include <ripext>
#include <vdftojson>

#define REGEX "^(\"((?:\\\\.|[^\\\\\"])+)\"|([a-z0-9\\-\\_]+))([ \t]*(\"((?:\\\\.|[^\\\\\"])*)(\")?|([a-z0-9\\-\\_]+)))?"

public Plugin myinfo = {
	name = "VDFtoJSON",
	author = "Oscar Wos (OSWO)",
	description = "A plugin which converts Valve Data Format (VDF) files to JSON format.",
	version = "1.00",
	url = "https://github.com/oscar-wos/VDFtoJSON",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("VDFtoJSON");
    return APLRes_Success;
}

public void OnPluginStart()
{
    VDFReturn c = Convert("../../scripts/items/items_game.txt");
    PrintToServer("VDFReturn: %d", c);
    //RegConsoleCmd("vdf2json", Command_VDFtoJSON, "Converts a VDF file to JSON format.");
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

        if (strcmp(curr, "") == 0 || strcmp(curr, "/") == 0) continue;

        if (strcmp(curr, "{") == 0) {
            expect = false;
            continue;
        }

        if (expect) return VDFReturn_InvalidFormat;

        if (strcmp(curr, "}") == 0) {
            if (stack.Length > 0) {
                JSONObject c = view_as<JSONObject>(stack.Get(stack.Length - 1));
                stack.Remove(stack.Length - 1);
                delete c;
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
                }

                JSONObject p = view_as<JSONObject>(m.Get(key));
                stack.Push(p);
                expect = true;
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
            }

            break;
        }
    }

    obj.ToFile(outputPath);
    delete f, o, r, obj, stack;

    return VDFReturn_Success;
}