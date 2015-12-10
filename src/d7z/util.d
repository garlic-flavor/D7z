/**
 * Version:      UC(dmd2.069.2)
 * Date:         2015-Dec-10 20:59:42
 * Authors:      KUMA
 * License:      CC0
*/
module d7z.util;

private import d7z.binding;
private import d7z.propvariant;
private import d7z.streams;
private import d7z.callbacks;
private import d7z.misc;
debug import std.stdio;

/** readArchive extracts one file from an archive.

Params:
  archivePath = the file path for an archive.
  target      = the targets name in the archive.
  password    =
**/
immutable(void)[] readArchive( string archivePath, string target
                             , string password = null)
{
    import std.exception : assumeUnique;
    import std.path : extension;
    import std.file : exists;

    D7z.load;

    if (!archivePath.exists)
        throw new Exception(archivePath ~ " is not found.");

    IInArchive archive;
    CreateObject( archivePath.getHandlerGUID, &IID_IInArchive
                , cast(void**)&archive)
        .enOK( "the extract handler for " ~ archivePath.extension
             ~ " is not found in current runtime." );
    scope(exit) if (archive) archive.Release;

    Throwable error;
    void callback(Throwable t){ if (error is null) error = t; }

    auto inStream = new InFileStream(archivePath, &callback);
    scope(exit) if (inStream) inStream.clear;

    auto openCallback = new ArchiveOpenCallback(&callback, password);
    scope(exit) if (openCallback) openCallback.clear;

    const UInt64 scanSize = 1 << 23;
    archive.Open(inStream, &scanSize, openCallback).enOK(error);

    UInt32 numItems;
    PropVariant prop;
    UInt32 targetID;
    archive.GetNumberOfItems(&numItems);
    for(targetID = 0; targetID < numItems; ++targetID)
    {
        prop.clear;
        archive.GetProperty(targetID, kpidPath, prop.ptr);
        if (prop.toString == target) break;
    }

    if (numItems <= targetID)
        throw new Exception(target ~ " is not found in " ~ archivePath);

    auto extractCallback
        = new ArchiveExtractToMemCallback(archive, password, &callback);
    scope(exit) if (extractCallback) extractCallback.clear;

    archive.Extract(&targetID, 1, false, extractCallback).enOK(error);

    return extractCallback.data.assumeUnique;
}


//==============================================================================
/** my implementation of a tiny mount system, that aim to be like 'PhysicsFS'.

Description:
  this module is very inspired by $(LINK https://icculus.org/physfs/).

  You can mount these,
  $(OL
    $(LI a directory in a directory.)
    $(LI an archive file in a directory.)
    $(LI a directory in an archive file.)
    $(LI an archive file in an archive file.)
  )

Examples:
---
auto mp = new MountPointRoot;

// mount 'test' folder inside './sample.7z'.
mp.mount("sample.7z/text", "/", "password");

// 'text/foo.txt' in 'sample.7z' is written to console.
(cast(char[])mpr.serch("/foo.txt").data).writeln;

mp.clear; // MountPointRoot needs clear.
---

*///===========================================================================
class MountPointRoot : MountPoint
{
    bool enableCD = true; /// カレントディレクトリをサーチパスに含めるか。

    ///
    this(string cd = "."){ super(""); _cd = new DirInDir(cd); }

    ///
    void mount(string path, string point = "/", string password = null)
    {
        import std.file : exists;
        import std.array : replace, array;
        import std.path : isDir, buildNormalizedPath, pathSplitter, buildPath;

        if (0 < point.length && point[0] == SEPARATOR)
            point = point[1..$];
        auto mp = makePoint(point);

        if (enableCD)
        {
            if (auto d = _cd.searchDirectory(path, password, _archiveStore))
            {
                mp.dirs ~= d;
                return;
            }
        }
        if (auto d = searchDir(path, password, _archiveStore))
        {
            mp.dirs ~= d;
            return;
        }

        throw new Exception( path ~ " is not found.");
    }

    ///
    bool unount(string point)
    { return removePoint(point); }

    override
    IFile search(string path)
    {
        if (0 < path.length && path[0] == SEPARATOR)
            path = path[1..$];
        return super.search(path);
    }

    override
    void clear()
    {
        super.clear;
        foreach(val; _archiveStore) val.clear;
        _archiveStore = null;
    }

private:
    IDirectory _cd;
    Archive[string] _archiveStore;
}


// import SDL, if could.
static if (__traits(compiles, {import derelict.sdl2.sdl;}))
    enum SDL_PORTING = "import derelict.sdl2.sdl;";
else
    enum SDL_PORTING = false;


// sworks.base.aio is my module for I/O abstraction.
// don't worry about this.
static if (__traits(compiles, {import sworks.base.aio;}))
    enum MY_AIO = "import sworks.base.aio;";
else
    enum MY_AIO = false;


///
interface IFile
{
    ///
    @property
    immutable(void)[] data();

    // use with SDL
    static if (SDL_PORTING)
    {
        mixin(SDL_PORTING);
        ///
        SDL_RWops* getRW();
    }

    // use with my library.
    static if (MY_AIO)
    {
        mixin(MY_AIO);
    }
}

///
interface IDirectory
{
    ///
    IFile getFile(string path);
    ///
    IDirectory getDir(string path, string password = null);
    /// abstract path or relative path from current directory.
    @property @trusted @nogc pure nothrow
    string path() const;
    ///
    void clear();
}

/** this treats a 7-zip archive.

Description:
  what can Archive do depends on the runtime of 7zip.
*/
class Archive : IDirectory
{
    ///
    this(string archivePath, string password = null)
    {
        import std.file : exists;
        if (!archivePath.exists)
            throw new Exception(archivePath ~ " is not found.");

        this(archivePath, new InFileStream(archivePath, &callback), password);
    }

    ///
    void clear()
    {
        if(_archive) _archive.Release;
        _archive = null;
        if      (auto s = cast(InFileStream)_inStream) s.clear;
        else if (auto s = cast(InMemStream)_inStream) s.clear;
        _inStream = null;
    }

    ///
    IDirectory getDir(string path, string password = null)
    {
        import std.path : buildPath;

        path = toValidPath(path);
        if (isDir(searchID(path)))
            return new DirInArchive(_path.buildPath(path), path, this);
        return null;
    }

    ///
    IFile getFile(string name)
    {
        name = toValidPath(name);
        auto id = searchID(name);
        if (_numItems <= id || isDir(id)) return null;
        return new Item(id);
    }

    @property @trusted @nogc pure nothrow
    string path() const { return _path; }

    ///
    class Item : IFile
    {
        ///
        private this(UInt32 id) { _id = id; }

        ///
        @property
        immutable(void)[] data()
        {
            import std.exception : assumeUnique;

            if (0 < _data.length) return _data;

            auto e = new ArchiveExtractToMemCallback( _archive, _password
                                                      , &callback );
            scope(exit) if (e) e.clear;
            _archive.Extract(&_id, 1, false, e).enOK(_error);
            _data = e.data.assumeUnique;
            return _data;
        }

        static if (SDL_PORTING)
        {
            SDL_RWops* getRW()
            {
                data();
                return SDL_RWFromConstMem(_data.ptr, _data.length);
            }
        }


        //----------------------------------------------------------
    private:
        const UInt32 _id;
        immutable(void)[] _data;
    }

    //----------------------------------------------------------
private:
    const string _path;
    IInArchive _archive;
    IInStream _inStream;
    const string _password;
    const UInt32 _numItems;

    Throwable _error;
    void callback(Throwable t){ if (_error is null) _error = t; }

    //
    this(string path, const(void)[] buf, string password)
    { this(path, new InMemStream(buf, &callback), password); }

    //
    this(string path, IInStream input, string password)
    {
        import std.path : extension;

        D7z.load;

        _path = toValidPath(path);
        _inStream = input;
        _password = password;
        CreateObject( path.getHandlerGUID, &IID_IInArchive
                    , cast(void**)&_archive).enOK(
            "Fail to load the Handler for " ~ path.extension ~ " file." );

        auto openCallback = new ArchiveOpenCallback(&callback, password);
        scope(exit) if (openCallback) openCallback.clear;

        const UInt64 scanSize = 1 << 23;
        _archive.Open(_inStream, &scanSize, openCallback).enOK(_error);
        UInt32 ni;
        _archive.GetNumberOfItems(&ni);
        _numItems = ni;
    }


    UInt32[string] _items;
    UInt32 _lastID; // _numItems中、ここまで調べたよ。
    UInt32 searchID(alias pred = "a == b")(string name)
    in { assert(_archive); }
    body
    {
        import std.functional : binaryFun;

        if (auto pi = name in _items) return (*pi);

        PropVariant prop;
        for(; _lastID < _numItems; ++_lastID)
        {
            prop.clear;
            _archive.GetProperty(_lastID, kpidPath, prop.ptr);
            auto nn = prop.toString;
            _items[nn] = _lastID;
            if (binaryFun!pred(nn, name)) return _lastID++;
        }
        return _lastID;
    }

    bool isDir(UInt32 id)
    in
    {
        assert(_archive);
    }
    body
    {
        if (_numItems <= id) return false;
        PropVariant prop;
        _archive.GetProperty(id, kpidIsDir, prop.ptr);
        return prop.toBool;
    }

    string toValidPath(string path)
    {
        import std.path : buildNormalizedPath;
        return path.buildNormalizedPath;
    }
}


//##############################################################################
private:

class FileInDir : IFile
{
    private const size_t _length;
    private const immutable(char)* _path;
    private this(string path)
    {
        import std.utf : toUTFz;
        _path = path.toUTFz!(immutable(char)*);
        _length = path.length;
    }

    @property
    immutable(ubyte)[] data()
    {
        import std.file : read;
        import std.exception : assumeUnique;
        return (cast(ubyte[])_path[0.._length].read).assumeUnique;
    }

    static if (SDL_PORTING)
    {
        SDL_RWops* getRW(){ return SDL_RWFromFile(path, "rb"); }
    }
}


//
class DirInDir : IDirectory
{
    private this(string p) { _path = p; }

    IFile getFile(string p)
    {
        import std.file : exists;
        import std.path : buildPath, isFile;
        if (0 == p.length) return null;

        auto target = _path.buildPath(p);
        if (target.exists && target.isFile) return new FileInDir(target);
        return null;
    }

    IDirectory getDir(string p, string password = null)
    {
        import std.file : exists;
        import std.path : buildPath, isDir;
        if (0 == p.length) return null;
        auto target = _path.buildPath(p);
        if (target.exists && target.isDir) return new DirInDir(target);
        return null;
    }

    void clear(){}

    @property @trusted @nogc pure nothrow
    string path() const { return _path; }

private:
    const string _path;
}

//
class DirInArchive : IDirectory
{
    /*
      Params:
      fullpath = archive へのパス + path
      path     = archive 内でのアイテム名
      archive  =
    */
    private this(string fullpath, string path, Archive archive)
    {
        assert(archive);
        _fullpath = fullpath;
        _path = path;
        _archive = archive;
    }

    IFile getFile(string p)
    {
        import std.path : buildPath;
        return _archive.getFile(_path.buildPath(p));
    }

    IDirectory getDir(string p, string password = null)
    {
        import std.path : buildPath;

        if (0 == p.length) return null;

        auto target = _path.buildPath(p);
        if (auto dia = _archive.getDir(target)) return dia;
        return null;
    }

    @property @trusted @nogc pure nothrow
    string path() const { return _fullpath; }

    void clear() {}

private:
    const string _fullpath;
    const string _path;
    Archive _archive;
}

// マウントポイントの区切り文字として '/' を使うこととする。
class MountPoint
{
    enum SEPARATOR = '/';
    IDirectory[] dirs;

    //
    protected this(string n){ _name = n; }

    //
    void clear()
    {
        foreach(dir; dirs) dir.clear;
        dirs = null;
        foreach(child; _children) child.clear;
        _children = null;
    }

    //
    IFile search(string path)
    {
        if (0 == path.length) return null;
        foreach(dir; dirs) if (auto id = dir.getFile(path)) return id;

        auto next = chompMP(path);
        if (auto pc = next in _children) return pc.search(path);
        return null;
    }

protected:

    //
    IDirectory searchDir( string path, string password
                          , ref Archive[string] archiveStore )
    {
        if (0 == path.length) return null;
        foreach(dir; dirs)
            if (auto id = dir.searchDirectory(path, password, archiveStore))
                return id;

        auto next = chompMP(path);
        if (auto pc = next in _children)
            return pc.searchDir(path, password, archiveStore);
        return null;
    }

    ///
    MountPoint makePoint(string name)
    {
        if (0 == name.length) return this;

        auto top = chompMP(name);
        if (auto pc = top in _children)
            return pc.makePoint(name);

        auto mp = new MountPoint(top);
        _children[top] = mp;
        return mp.makePoint(name);
    }

    ///
    bool removePoint(string path)
    {
        auto top = chompMP(path);
        if (top != _name) return false;
        return removeNext(path);
    }

private:
    const string _name;
    MountPoint[string] _children;

    string chompMP(ref string path)
    {
        size_t i;
        for(; i < path.length; ++i)
            if (path[i] == SEPARATOR) break;

        auto ret = path[0..i];
        path = path[(i < $ ? i+1 : $)..$];
        return ret;
    }

    bool removeNext(string path)
    {
        if (path.length == 0) return false;
        auto next = chompMP(path);
        if      (0 == path.length)
        {
            if (auto pc = next in _children)
            {
                pc.clear;
                _children.remove(next);
                return true;
            }
        }
        else if (auto pc = next in _children)
            return pc.removeNext(path);
        return false;
    }
}


/*
Todo:
  implement all formats supported by 7-zip.
*/
GUID* getHandlerGUID(string path)
{
    import std.path : extension;
    switch(path.extension)
    {
    case".7z": return &CLSID_CFormat7z;
    case ".zip": return &CLSID_CFormatZip;
    case ".lzma": return &CLSID_CFormatLZMA;
    case ".xz": return &CLSID_CFormatXz;
        break; default:
        throw new Exception( path ~ " has an unknown file extension.");
    }
    assert(0);
}

//
IDirectory searchDirectory(IDirectory dir, string path, string password
                          , ref Archive[string] archiveStore)
{
    import std.array : array;
    import std.path : pathSplitter, buildPath;

    assert(dir);
    if (0 == path.length) return null;

    if (auto id = dir.getDir(path, password)) return id;

    auto pathItems = path.pathSplitter.array;
    for(size_t i = 1; i < pathItems.length-1; ++i)
    {
        auto base = pathItems[0..i].buildPath;
        auto fullpath = dir.path.buildPath(base);

        if      (auto pa = fullpath in archiveStore)
            return (*pa).searchDirectory( pathItems[i..$].buildPath, password
                                          , archiveStore );
        else if (auto file = dir.getFile(base))
        {
            auto a = new Archive(fullpath, file.data, password);
            archiveStore[fullpath] = a;
            return a.searchDirectory( pathItems[i..$].buildPath, password
                                      , archiveStore );
        }
    }
    return null;
}

//
IFile searchFile( IDirectory dir, string path, string password
                , ref Archive[string] archiveStore)
{
    import std.array : array;
    import std.path : pathSplitter, buildPath;

    assert(dir);
    if (0 == path.length) return null;

    if (auto id = dir.getFile(path)) return id;

    auto pathItems = path.pathSplitter.array;
    for(size_t i = 1; i < pathItems.length-1; ++i)
    {
        auto base = pathItems[0..i].buildPath;
        auto fullpath = dir.path.buildPath(base);

        if      (auto pa = fullpath in archiveStore)
            return (*pa).searchFile( pathItems[i..$].buildPath, password
                                     , archiveStore );
        else if (auto file = dir.getFile(base))
        {
            auto a = new Archive(fullpath, file.data, password);
            archiveStore[fullpath] = a;
            return a.searchFile( pathItems[i..$].buildPath, password
                                 , archiveStore );
        }
    }
    return null;
}


//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
debug(d7z_util):

import std.stdio;

void setDLLDir(string dir)
{
    version     (Windows)
    {
        import std.array : array;
        import std.utf : toUTF16z;
        import std.file : thisExePath;
        import std.path : isAbsolute, buildPath, asNormalizedPath, dirName;
        if (dir.isAbsolute)
            SetDllDirectoryW(dir.toUTF16z);
        else
            SetDllDirectoryW(thisExePath.dirName.buildPath(dir).asNormalizedPath
                             .array.toUTF16z);
    }
    else version(Posix)
    {
        D7z.setDLLDir(dir);
    }
    else static assert(0);
}

void main()
{
    setDLLDir("bin");

    (cast(char[])"sample.7z".readArchive("a_file_in_the_archive.txt")).writeln;
}
