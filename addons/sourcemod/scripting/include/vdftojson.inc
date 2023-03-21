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

/**
 * Converts a VDF file to JSON format.
 *
 * @param vdfPath   An integer.
 * @param jsonPath  A float.
 * @return          VDFReturn_Success on success, otherwise an error
 */
native VDFReturn VDFtoJSON(const char[] vdfPath, const char[] jsonPath);