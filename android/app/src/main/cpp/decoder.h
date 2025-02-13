#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

extern "C"
{
    EXPORT const char *__cdecl decode_wrapper(const char **input, size_t length);
    EXPORT void __cdecl free_string(const char *ptr);
}
