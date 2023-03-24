#if defined _vdftojson_included
    #endinput
#endif
#define _vdftojson_included

enum VDFReturn {
    VDFReturn_Success,
    VDFReturn_FileNotFound,
    VDFReturn_InvalidReadFile,
    VDFReturn_InvalidWriteFile,
    VDFReturn_InvalidFormat
}

enum VDFType {
    VDFType_8,
    VDFType_16
}

/**
 * Converts a VDF file to JSON format.
 *
 * @param vdfPath   origin addons/sourcemod/
 * @param jsonPath  origin addons/sourcemod/data/
 * @param encoding  VDFType_8 for utf-8, VDFType_16 for utf-16
 * @return          VDFReturn_Success on success, otherwise VDFReturn_*
 */
native VDFReturn VDFtoJSON(const char[] vdfPath, const char[] jsonPath, VDFType encoding);