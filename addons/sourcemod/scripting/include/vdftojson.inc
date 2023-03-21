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