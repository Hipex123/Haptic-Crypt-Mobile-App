#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

typedef const char *(*DecodeWrapperFunc)(const char **, size_t);
typedef void (*FreeStringFunc)(const char *);

int main()
{
#ifdef _WIN32
    HMODULE lib = LoadLibrary("libdecode_wrapper.dll");
    if (!lib)
    {
        printf("Failed to load DLL\n");
        return 1;
    }
    DecodeWrapperFunc decode_wrapper = (DecodeWrapperFunc)GetProcAddress(lib, "decode_wrapper");
    FreeStringFunc free_string = (FreeStringFunc)GetProcAddress(lib, "free_string");
#else
    void *lib = dlopen("./libdecode_wrapper.so", RTLD_LAZY);
    if (!lib)
    {
        printf("Failed to load shared library: %s\n", dlerror());
        return 1;
    }
    DecodeWrapperFunc decode_wrapper = (DecodeWrapperFunc)dlsym(lib, "decode_wrapper");
    FreeStringFunc free_string = (FreeStringFunc)dlsym(lib, "free_string");
#endif

    if (!decode_wrapper || !free_string)
    {
        printf("Failed to load functions\n");
        return 1;
    }

    const char *input[] = {
        "  x0196",
        "  m109",
        " xdd",
        "  x0162",
        "  x01b6",
        "#",
        "102",
        "ev3uamc"};
    size_t length = 8;

    printf("Calling decode_wrapper...\n");
    const char *result = decode_wrapper(input, length);

    if (result)
    {
        printf("Decoded result: %s\n", result);
        free_string(result);
    }
    else
    {
        printf("decode_wrapper returned NULL\n");
    }

#ifdef _WIN32
    FreeLibrary(lib);
#else
    dlclose(lib);
#endif

    return 0;
}
