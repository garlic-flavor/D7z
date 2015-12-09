/** Load 7-zip shared library.
 * Version:      UC(dmd2.069.0)
 * Date:         2015-Dec-01 23:05:36
 * Authors:      KUMA
 * License:      CC0
 **/
/**
   Description:
   You can use this module with
   $(LINK2 https://github.com/DerelictOrg, DerelictUtil).$(BR)
   To do that, please ensure that the derelict.util.loader can be imported.

   Usage:
   ---
   import derelict.util.loader; // use with DerelictUtil.

   My7z.load;  // load the shared library.

   assert(My7z.isLoaded); // return true, if loaded.

   My7z.unload; // free the shared library(not necessary).
   ---

   ToDo:
   write implementations othor than on windows.

**/
module d7z.binding.loader;

private import d7z.binding.types;
private import d7z.binding.functions;

static if (__traits(compiles, {import derelict.util.loader;}))
{
    private {
        import derelict.util.loader;
        import derelict.util.system;

        static if (Derelict_OS_Windows)
            enum libNames = "7z.dll, 7za.dll, 7zxa.dll, 7zxr.dll";
        else
            static assert(0, "Need to implement 7z libNames for this oparating"
                          " system.");
    }

    /** Use DerelictUtil.

      $(LINK https://github.com/DerelictOrg).
    **/
    class MyDerelict7zLoader : SharedLibLoader {
        public this(){
            super(libNames);
        }

        protected override void loadSymbols() {
            // bindFunc(cast(void**)&CreateDecoder, "CreateDecoder");
            // bindFunc(cast(void**)&CreateEncoder, "CreateEncoder");
            bindFunc(cast(void**)&CreateObject, "CreateObject");
            bindFunc(cast(void**)&GetHandlerProperty, "GetHandlerProperty");
            bindFunc(cast(void**)&GetHandlerProperty2, "GetHandlerProperty2");
            // bindFunc(cast(void**)&GetHashers, "GetHashers");
            // bindFunc(cast(void**)&GetIsArc, "GetIsArc");
            bindFunc(cast(void**)&GetMethodProperty, "GetMethodProperty");
            bindFunc(cast(void**)&GetNumberOfFormats, "GetNumberOfFormats");
            bindFunc(cast(void**)&GetNumberOfMethods, "GetNumberOfMethods");
            // bindFunc(cast(void**)&SetCaseSensitive, "SetCaseSensitive");
            // bindFunc(cast(void**)&SetCodecs, "SetCodecs");
            bindFunc(cast(void**)&SetLargePageMode, "SetLargePageMode");
        }
    }

    __gshared MyDerelict7zLoader My7z;

    shared static this() {
        My7z = new MyDerelict7zLoader;
    }
}
else
{
    private
    auto toS(T)(const(T)* n)
    {
        for(size_t i = 0; i < 256; ++i)
            if (n[i] == '\0') return n[0..i].idup;
        return null;
    }

    private
    string toS(T)(const(T)*[] n)
    {
        import std.string : join;
        import std.conv : to;
        auto ret = new string[n.length];
        for(size_t i = 0; i < n.length; ++i)
            ret[i] = toS(n[i]).to!string;
        return ret.join(" / ");
    }

    version(Windows)
    {
        /** My implementation of Shared Library Loader.

        like $(LINK https://github.com/DerelictOrg).

        Desctiption:
        searching order is,
        $(OL
            $(LI the application's installation directory.)
            $(LI system32.)
            $(LI directories these are added by user, using SetDllDirectory.)
        )
        and then, search inside of directories in the standard search path.

        **/
        struct My7z
        {
        static:
            private const(wchar)*[] libNames = [ "7z.dll", "7za.dll", "7zxa.dll"
                                                 , "7zxr.dll" ];
            private HMODULE _lib;

            static ~this() { unload; }

            @trusted @nogc nothrow
            bool isLoaded() { return _lib !is null; }

            void unload()
            {
                if (_lib !is null) FreeLibrary(_lib);
                _lib = null;
            }

            void load()
            {
                if (_lib !is null) return;

                for(size_t i = 0; i < libNames.length && _lib is null; ++i)
                    _lib = LoadLibraryExW( libNames[i], null
                                           , LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
                for(size_t i = 0; i < libNames.length && _lib is null; ++i)
                    _lib = LoadLibraryW(libNames[i]);

                if (_lib is null)
                    throw new Exception("DLL " ~ toS(libNames)~ " not found.");

                // bindFunc(cast(void**)&CreateDecoder, "CreateDecoder");
                // bindFunc(cast(void**)&CreateEncoder, "CreateEncoder");
                bindFunc(cast(void**)&CreateObject, "CreateObject");
                bindFunc(cast(void**)&GetHandlerProperty, "GetHandlerProperty");
                bindFunc( cast(void**)&GetHandlerProperty2
                        , "GetHandlerProperty2");
                // bindFunc(cast(void**)&GetHashers, "GetHashers");
                // bindFunc(cast(void**)&GetIsArc, "GetIsArc");
                bindFunc(cast(void**)&GetMethodProperty, "GetMethodProperty");
                bindFunc(cast(void**)&GetNumberOfFormats, "GetNumberOfFormats");
                bindFunc(cast(void**)&GetNumberOfMethods, "GetNumberOfMethods");
                // bindFunc(cast(void**)&SetCaseSensitive, "SetCaseSensitive");
                // bindFunc(cast(void**)&SetCodecs, "SetCodecs");
                bindFunc(cast(void**)&SetLargePageMode, "SetLargePageMode");
            }

            //
            void bindFunc(void** target, const(char)* name)
            in
            {
                assert(_lib);
                assert(target);
                assert(name);
            }
            body
            {
                (*target) = GetProcAddress(_lib, name);
                if ((*target) is null)
                    throw new Exception( "fail to Load a symbol named "
                                         ~ toS(name) ~ "." );
            }
        }
    }
    else
    {
        struct My7z
        {
            import core.sys.posix.dlfcn;
            alias SharedLibHandle = void*;
        static:
            private SharedLibHandle _lib;
            private string dlldir = ".";
            private string[] libNames = ["7z.so", "7za.so", "7zr.so"];

            static ~this() { unload; }

            @trusted @nogc nothrow
            bool isLoaded() { return _lib !is null; }

            void unload()
            {
                if (_lib !is null) dlclose(_lib);
                _lib = null;
            }

            void setDLLDir(string dir)
            { dlldir = dir; }

            void load()
            {
                import std.utf : toUTFz;
                alias toUTF8z = toUTFz!(const(char)*);
                import std.path : buildPath;
                import std.string : join;

                if (_lib !is null) return;

                for(size_t i = 0; i < libNames.length && _lib is null; ++i)
                    _lib = dlopen( toUTF8z(dlldir.buildPath(libNames[i]))
                                 , RTLD_NOW);

                if (_lib is null)
                    throw new Exception( "DLL " ~ libNames.join(" / ")
                                       ~ " not found.");

                // bindFunc(cast(void**)&CreateDecoder, "CreateDecoder");
                // bindFunc(cast(void**)&CreateEncoder, "CreateEncoder");
                bindFunc(cast(void**)&CreateObject, "CreateObject");
                bindFunc(cast(void**)&GetHandlerProperty, "GetHandlerProperty");
                bindFunc( cast(void**)&GetHandlerProperty2
                          , "GetHandlerProperty2");
                // bindFunc(cast(void**)&GetHashers, "GetHashers");
                // bindFunc(cast(void**)&GetIsArc, "GetIsArc");
                bindFunc(cast(void**)&GetMethodProperty, "GetMethodProperty");
                bindFunc(cast(void**)&GetNumberOfFormats, "GetNumberOfFormats");
                bindFunc(cast(void**)&GetNumberOfMethods, "GetNumberOfMethods");
                // bindFunc(cast(void**)&SetCaseSensitive, "SetCaseSensitive");
                // bindFunc(cast(void**)&SetCodecs, "SetCodecs");
                bindFunc(cast(void**)&SetLargePageMode, "SetLargePageMode");

                bindFunc(cast(void**)&SysAllocString, "SysAllocString");
                bindFunc(cast(void**)&SysFreeString, "SysFreeString");
            }

            //
            void bindFunc(void** target, const(char)* name)
            in
            {
                assert(_lib);
                assert(target);
                assert(name);
            }
            body
            {
                (*target) = dlsym(_lib, name);
                if ((*target) is null)
                    throw new Exception( "fail to Load a symbol named "
                                         ~ toS(name) ~ "." );
            }
        }
    }
}
