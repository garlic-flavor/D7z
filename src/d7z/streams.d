/**
 * Version:      UC(dmd2.069.0)
 * Date:         2015-Dec-01 23:05:36
 * Authors:      KUMA
 * License:      CC0
*/
module d7z.streams;

private import d7z.binding;
private import d7z.misc;
debug import std.stdio;

//------------------------------------------------------------------------------
alias My_UINT_PTR = UINT_PTR;

///
extern(System)
class InFileStream : IInStream
{
    import std.stdio : File;
    import std.traits : isSomeChar;
    private File _file;
    private OnErrorCallback _onError;
    private int _refCount;

    ///
    this(T)(const(T)[] fileName, OnErrorCallback cb = null) if(isSomeChar!T)
    {
        import std.conv : to;
        _onError = cb;
        _file = File(fileName.to!string, "rb");
    }

    ///
    void clear()
    {
        if (_file.isOpen) _file.close;
    }

version(Posix) extern(Windows):

    // for ISequentialInStream
    HRESULT Read(void* data, UInt32 size, UInt32* processedSize)
    {
        return _onError.tryCode(
        {
            auto read = _file.rawRead(data[0..size]);
            if (processedSize !is null)
                (*processedSize) = cast(UInt32)read.length;
        });
    }

    // for IInStream
    HRESULT Seek(Int64 offset, UInt32 seekOrigin, UInt64* newPosition)
    {
        return _onError.tryCode(
        {
            _file.seek(offset, seekOrigin);
            if (newPosition !is null) (*newPosition) = _file.tell;
        });
    }


    // for IStreamGetSize
    extern(System)
    class StreamGetSize : IStreamGetSize
    {
    version(Posix) extern(Windows):
        HRESULT GetSize(UInt64* size)
        {
            return _onError.tryCode(
            {
                if (size)
                    (*size) = _file.size;
            });
        }

        HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
        { return InFileStream.QueryInterface(riid, pvObject); }
        ULONG AddRef(){ return 1; }
        ULONG Release(){ return 0; }

        version(Posix)
        {
            void _DO_NOT_CALL_ME(){assert(0, "DO NOT CALL ME!"); }
            void _DO_NOT_CALL_ME_2(){assert(0, "DO NOT CALL ME!"); }
        }
    }
    StreamGetSize streamGetSizeImpl;


    version(Windows)
    {
        // for IStreamGetProps
        class StreamGetProps : IStreamGetProps
        {
            HRESULT GetProps( UInt64* size, FILETIME* cTime, FILETIME* aTime
                            , FILETIME* mTime, UInt32* attrib )
            {
                import std.exception : enforce;
                return _onError.tryCode(
                {
                    BY_HANDLE_FILE_INFORMATION info;
                    assert(_file.isOpen);
                    auto _hFile = _file.windowsHandle.enforce;

                    GetFileInformationByHandle(_hFile, &info).enforce;
                    if (size) (*size) = ((cast(UInt64)info.nFileSizeHigh)<<32)
                                  + info.nFileSizeLow;
                    if (cTime) (*cTime) = info.ftCreationTime;
                    if (aTime) (*aTime) = info.ftLastAccessTime;
                    if (mTime) (*mTime) = info.ftLastWriteTime;
                    if (attrib) (*attrib) = info.dwFileAttributes;
                });
            }

            HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
            { return InFileStream.QueryInterface(riid, pvObject); }
            ULONG AddRef(){ return ++_refCount; }
            ULONG Release(){ return --_refCount; }
        }
        StreamGetProps streamGetPropsImpl;


        // for IStreamGetProps2
        class StreamGetProps2 : IStreamGetProps2
        {
            HRESULT GetProps2(CStreamFileProps* props)
            {
                import std.exception : enforce;
                return _onError.tryCode(
                {
                    assert(_file.isOpen);
                    auto _hFile = _file.windowsHandle.enforce;
                    BY_HANDLE_FILE_INFORMATION info;
                    GetFileInformationByHandle(_hFile, &info).enforce;
                    assert(props);
                    with(props)
                    {
                        Size = ((cast(UInt64)info.nFileSizeHigh)<<32)
                            + info.nFileSizeLow;
                        VolID = info.dwVolumeSerialNumber;
                        FileID_Low = ((cast(UInt64)info.nFileIndexHigh)<<32)
                            + info.nFileIndexLow;
                        FileID_High = 0;
                        NumLinks = 1;//info.nNumberOfLinks;
                        Attrib = info.dwFileAttributes;
                        CTime = info.ftCreationTime;
                        ATime = info.ftLastAccessTime;
                        MTime = info.ftLastWriteTime;
                    }
                });
            }

            HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
            {return InFileStream.QueryInterface(riid, pvObject); }
            ULONG AddRef(){return ++_refCount; }
            ULONG Release(){return --_refCount; }

            version(Posix)
            {
                void _DO_NOT_CALL_ME(){assert(0, "DO NOT CALL ME!"); }
                void _DO_NOT_CALL_ME_2(){assert(0, "DO NOT CALL ME!"); }
            }
        }
        StreamGetProps2 streamGetProps2Impl;
    }


    // for IUnknown
    HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
    {
        if      ((*riid) == IID_IUnknown)
            (*pvObject) = cast(void*)cast(IUnknown)this;
        else if ((*riid) == IID_ISequentialInStream)
            (*pvObject) = cast(void*)cast(ISequentialInStream)this;
        else if ((*riid) == IID_IInStream)
            (*pvObject) = cast(void*)cast(IInStream)this;
        else if ((*riid) == IID_IStreamGetSize)
        {
            if (streamGetSizeImpl is null)
                streamGetSizeImpl = new StreamGetSize;
            (*pvObject) = cast(void*)cast(IStreamGetSize)streamGetSizeImpl;
        }
        else
        {
            version(Windows)
            {
                if      ((*riid) == IID_IStreamGetProps)
                {
                    if (streamGetPropsImpl is null)
                        streamGetPropsImpl = new StreamGetProps;
                    (*pvObject) = cast(void*)cast(IStreamGetProps)
                        streamGetPropsImpl;
                }
                else if ((*riid) == IID_IStreamGetProps2)
                {
                    if (streamGetProps2Impl is null)
                        streamGetProps2Impl = new StreamGetProps2;
                    (*pvObject) = cast(void*)cast(IStreamGetProps2)
                        streamGetProps2Impl;
                }
                else
                    return E_NOINTERFACE;
            }
            else
                return E_NOINTERFACE;
        }
        return S_OK;
    }

    ULONG AddRef(){ return ++_refCount; }
    ULONG Release(){ return --_refCount; }

    version(Posix)
    {
        void _DO_NOT_CALL_ME(){assert(0, "DO NOT CALL ME!"); }
        void _DO_NOT_CALL_ME_2(){assert(0, "DO NOT CALL ME!"); }
    }
}
//------------------------------------------------------------------------------
///
extern(System)
class OutFileStream : IOutStream
{
    import std.stdio : File;
    private File _file;
    private OnErrorCallback _onError;

    this(const(OLECHAR)[] fileName, OnErrorCallback cb = null)
    {
        _onError = cb;
        _file = File(fileName, "wb");
    }

    void clear()
    {
        if (_file.isOpen) _file.close;
        Release();
    }

    version(Windows)
    {
        ///
        BOOL SetTime( const(FILETIME)* cTime, const(FILETIME)* aTime
                      , const(FILETIME)* mTime )
        { return SetFileTime(_file.windowsHandle, cTime, aTime, mTime); }

        ///
        BOOL SetMTime(const(FILETIME)* mTime)
        { return SetFileTime(_file.windowsHandle, null, null, mTime); }
    }

version(Posix) extern(Windows):

    // IOutStream
    HRESULT Write(const(void)* data, UInt32 size, UInt32* processedSize)
    {
        return _onError.tryCode(
        {
            _file.rawWrite(data[0..size]);
            if (processedSize !is null)
                (*processedSize) = size;
        });
    }

    HRESULT Seek(Int64 offset, UInt32 seekOrigin, UInt64* newPosition)
    {
        return _onError.tryCode(
        {
            _file.seek(offset, seekOrigin);
            if (newPosition !is null)
                (*newPosition) = _file.tell;
        });
    }

    HRESULT SetSize(UInt64 newSize)
    {
        return E_FAIL;
    }

    HRESULT GetSize(UInt64* size)
    {
        return _onError.tryCode(
        {
            if (size)
                (*size) = _file.size;
        });
    }

    // IUnknown
    HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
    {
        if      ((*riid) == IID_IUnknown)
            (*pvObject) = cast(void*)cast(IUnknown)this;
        else if ((*riid) == IID_IOutStream)
            (*pvObject) = cast(void*)cast(IOutStream)this;
        else
            return E_NOINTERFACE;

        return S_OK;
    }

    ULONG AddRef() {return 1;}
    ULONG Release() {return 0;}

    version(Posix)
    {
        void _DO_NOT_CALL_ME(){assert(0, "DO NOT CALL ME!"); }
        void _DO_NOT_CALL_ME_2(){assert(0, "DO NOT CALL ME!"); }
    }
}


//------------------------------------------------------------------------------
///
extern(System)
class InMemStream : IInStream
{
    ///
    this(const(void)[] buf, OnErrorCallback cb = null)
    {
        _onError = cb;
        _rest = _buf = buf;
    }

    ///
    @trusted @nogc pure nothrow
    void clear(){ _buf = null; }

    ///
    @property @trusted @nogc pure nothrow
    int refCount() const { return _refCount; }

version(Posix) extern(Windows):

    // for ISqeuentialInStream
    HRESULT Read(void* data, UInt32 size, UInt32* processedSize)
    {
        return _onError.tryCode(
        {
            if (_rest.length < size) size = cast(UInt32)_rest.length;
            data[0..size] = _rest[0..size];
            _rest = _rest[size..$];
            if (processedSize) (*processedSize) = size;
        });
    }

    // for IInStream
    HRESULT Seek(Int64 offset, UInt32 seekOrigin, UInt64* newPosition)
    {
        return _onError.tryCode(
        {
            import std.stdio : SEEK_SET, SEEK_END;
            sizediff_t np;
            switch(seekOrigin)
            {
            case        SEEK_SET:
                if      (offset < 0) np = 0;
                else if (_buf.length < offset) np = _buf.length;
                else np = cast(sizediff_t)offset;
                break; case SEEK_END:
                if      (0 < offset) np = _buf.length;
                else if (_buf.length < -offset) np = 0;
                else np = cast(sizediff_t)(_buf.length - offset);
                break; default:
                np = cast(sizediff_t)(_buf.length - _rest.length + offset);
                if      (np < 0) np = 0;
                else if (_buf.length < np) np = _buf.length;
            }
            _rest = _buf[np .. $];
            if (newPosition) (*newPosition) = cast(UInt64)np;
        });
    }

    // for IStreamGetSize
    extern(System)
    class StreamGetSize : IStreamGetSize
    {
    version(Posix) extern(Windows):
        HRESULT GetSize(UInt64* size)
        {
            if (size) (*size) = _buf.length;
            else return E_FAIL;
            return S_OK;
        }

        HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
        { return InMemStream.QueryInterface(riid, pvObject); }
        ULONG AddRef(){ return 1; }
        ULONG Release(){ return 0; }

        version(Posix)
        {
            void _DO_NOT_CALL_ME(){assert(0, "DO NOT CALL ME!"); }
            void _DO_NOT_CALL_ME_2(){assert(0, "DO NOT CALL ME!"); }
        }
    }
    StreamGetSize getSizeImpl;

    // for IUnkown
    HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
    {
        if      ((*riid) == IID_IUnknown)
            (*pvObject) = cast(void*)cast(IUnknown)this;
        else if ((*riid) == IID_ISequentialInStream)
            (*pvObject) = cast(void*)cast(ISequentialInStream)this;
        else if ((*riid) == IID_IInStream)
            (*pvObject) = cast(void*)cast(IInStream)this;
        else if ((*riid) == IID_IStreamGetSize)
        {
            if (getSizeImpl is null) getSizeImpl = new StreamGetSize;
            (*pvObject) = cast(void*)cast(IStreamGetSize)getSizeImpl;
        }
        else
            return E_NOINTERFACE;
        return S_OK;
    }

    ULONG AddRef(){ return ++_refCount; }
    ULONG Release(){ return --_refCount; }

    version(Posix)
    {
        void _DO_NOT_CALL_ME(){assert(0, "DO NOT CALL ME!"); }
        void _DO_NOT_CALL_ME_2(){assert(0, "DO NOT CALL ME!"); }
    }


    //----------------------------------------------------------
    //
    private OnErrorCallback _onError;
    private const(void)[] _buf;
    private const(void)[] _rest;
    private int _refCount;
}

//------------------------------------------------------------------------------
///
extern(System)
class OutMemStream : IOutStream
{
    import std.array : Appender;

    ///
    this(OnErrorCallback cb = null) {_onError = cb;}

    ///
    void clear(){ _buf.clear; }

    ///
    @property @trusted pure
    const(void)[] data() { return cast(const(void)[])_buf.data; }

    ///
    @property @trusted @nogc pure nothrow
    int refCount() const { return _refCount; }

version(Posix) extern(Windows):

    // IOutStream
    HRESULT Write(const(void)* data, UInt32 size, UInt32* processedSize)
    {
        return _onError.tryCode(
        {
            _buf.put(cast(ubyte[])data[0..size]);
            if (processedSize) (*processedSize) = size;
        });
    }

    HRESULT Seek(Int64 offset, UInt32 seekOrigin, UInt64* newPosition)
    {
        return _onError.tryCode(
        {
            import std.stdio : SEEK_SET, SEEK_END;
            sizediff_t np;
            auto l = _buf.data.length;
            switch(seekOrigin)
            {
            case        SEEK_SET:
                if      (offset < 0) np = 0;
                else if (l < offset) np = l;
                else np = cast(sizediff_t)offset;
                break; case SEEK_END:
                if      (0 < offset) np = l;
                else if (l < -offset) np = 0;
                else np = cast(sizediff_t)(l - offset);
                break; default:
                np = cast(sizediff_t)(l + offset);
                if      (np < 0) np = 0;
                else if (l < np) np = l;
            }
            _buf.shrinkTo(np);
            if (newPosition) (*newPosition) = cast(UInt64)np;
        });
    }

    HRESULT SetSize(UInt64 newSize)
    {return _onError.tryCode({_buf.reserve(cast(size_t)newSize);}); }

    HRESULT GetSize(UInt64* size)
    {return _onError.tryCode({ if (size) (*size) = _buf.data.length;});}

    // IUnknown
    HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
    {
        if      ((*riid) == IID_IUnknown)
            (*pvObject) = cast(void*)cast(IUnknown)this;
        else if ((*riid) == IID_IOutStream)
            (*pvObject) = cast(void*)cast(IOutStream)this;
        else
            return E_NOINTERFACE;

        return S_OK;
    }

    ULONG AddRef() {return ++_refCount;}
    ULONG Release() {return --_refCount;}

    version(Posix)
    {
        void _DO_NOT_CALL_ME(){assert(0, "DO NOT CALL ME!"); }
        void _DO_NOT_CALL_ME_2(){assert(0, "DO NOT CALL ME!"); }
    }


    private Appender!(ubyte[]) _buf;
    private OnErrorCallback _onError;
    private int _refCount;
}
