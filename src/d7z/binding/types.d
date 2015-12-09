/**
 * Version:      UC(dmd2.069.0)
 * Date:         2015-Dec-01 23:05:36
 * Authors:      KUMA
 * License:      CC0
**/
module d7z.binding.types;

public import d7z.binding.mywindows;

//==============================================================================
//
// PODs
//
//==============================================================================
alias Byte = byte;
alias Int32 = int;
alias Int64 = long;
alias UInt32 = uint;
alias UInt64 = ulong;
version     (Windows)
    alias FChar = wchar;
else version(Posix)
    alias FChar = dchar;
alias PROPID = ULONG;
alias CFSTR = const(FChar)*;

// alias Func_IsArc = extern(C) UInt32 function(const(Byte)* p, size_t size);

//==============================================================================
//
// COM interfaces
//
//==============================================================================
interface IHasher : IUnknown
{
    void Init();
    void Update(const(void)* data, UInt32 size);
    void Final(Byte* digest);
    UInt32 GetDigeestSize();
}

interface IHashers : IUnknown
{
    UInt32 GetNumHashers();
    HRESULT GetHasherProp(UInt32 index, PROPID propID, PROPVARIANT* value);
    HRESULT CreateHasher(UInt32 index, IHasher* hasher);
}

interface ICompressCodecsInfo : IUnknown
{
    HRESULT GetNumMethods(UInt32* numMethods);
    HRESULT GetProperty(UInt32 index, PROPID propID, PROPVARIANT* value);
    HRESULT CreateDecoder(UInt32 index, const(GUID)* iid, void** coder);
    HRESULT CreateEncoder(UInt32 index, const(GUID)* iid, void** coder);
}

interface IArchiveOpenCallback : IUnknown
{
    HRESULT SetTotal(const(UInt64)* files, const(UInt64)* bytes);
    HRESULT SetCompleted(const(UInt64)* files, const(UInt64)* bytes);
}

interface IInArchive : IUnknown
{
    HRESULT Open( IInStream stream, const(UInt64)* maxCheckStartPosition
                , IArchiveOpenCallback openCallback );
    HRESULT Close();
    HRESULT GetNumberOfItems(UInt32* numItems);
    HRESULT GetProperty(UInt32 index, PROPID propID, PROPVARIANT* value);
    HRESULT Extract( const(UInt32)* indices, UInt32 numItems, Int32 testMode
                   , IArchiveExtractCallback extractCallback );
    HRESULT GetArchiveProperty(PROPID propID, PROPVARIANT* value);
    HRESULT GetNumberOfProperties(UInt32* numProps);
    HRESULT GetPropertyInfo( UInt32 index, BSTR* name, PROPID* propID
                           , VARTYPE* varType );
    HRESULT GetNumberOfArchiveProperties(UInt32* numProps);
    HRESULT GetArchivePropertyInfo( UInt32 index, BSTR* name, PROPID* propID
                                  , VARTYPE* varType );
}

interface IOutArchive : IUnknown
{
    HRESULT UpdateItems( ISequentialOutStream outStream, UInt32 numItems
                       , IArchiveUpdateCallback updateCallback );
    HRESULT GetFileTimeType(UInt32* type);
}


interface IProgress : IUnknown
{
    HRESULT SetTotal(UInt64 total);
    HRESULT SetCompleted(const(UInt64)* completeValue);
}

interface IArchiveExtractCallback : IProgress
{
    HRESULT GetStream( UInt32 index, ISequentialOutStream* outStream
                     , Int32 askExtractMode );
    HRESULT PrepareOperation(Int32 askExtractMode);
    HRESULT SetOperationResult(Int32 opRes);
}

interface IArchiveUpdateCallback : IProgress
{
    HRESULT GetUpdateItemInfo( UInt32 index, Int32* newData, Int32* newProps
                             , UInt32* indexInArchive );
    HRESULT GetProperty(UInt32 index, PROPID propID, PROPVARIANT* value);
    HRESULT GetStream(UInt32 index, ISequentialInStream* inStream);
    HRESULT SetOperationResult(Int32 operationResult);
}

interface IArchiveUpdateCallback2 : IArchiveUpdateCallback
{
    HRESULT GetVolumeSize(UInt32 index, UInt64* size);
    HRESULT GetVolumeStream(UInt32 index, ISequentialOutStream* volumeStream);
}


interface ISequentialInStream : IUnknown
{
    HRESULT Read(void* data, UInt32 size, UInt32* processedSize);
}

interface IInStream : ISequentialInStream
{
    HRESULT Seek(Int64 offset, UInt32 seekOrigin, UInt64* newPosition);
}

interface IStreamGetSize : IUnknown
{
    HRESULT GetSize(UInt64* size);
}

interface IStreamGetProps : IUnknown
{
    HRESULT GetProps( UInt64* size, FILETIME* cTime, FILETIME* aTime
                    , FILETIME* mTime, UInt32* attrib );
}

struct CStreamFileProps
{
    UInt64 Size;
    UInt64 VolID;
    UInt64 FileID_Low;
    UInt64 FileID_High;
    UInt32 NumLinks;
    UInt32 Attrib;
    FILETIME CTime;
    FILETIME ATime;
    FILETIME MTime;
}

interface IStreamGetProps2 : IUnknown
{
    HRESULT GetProps2(CStreamFileProps* props);
}

interface ISequentialOutStream : IUnknown
{
    HRESULT Write(const(void)* data, UInt32 size, UInt32* processedSize);
}

interface IOutStream : ISequentialOutStream
{
    HRESULT Seek(Int64 offset, UInt32 seekOrigin, UInt64* newPosition);
    HRESULT SetSize(UInt64 newSize);
}

interface ICryptoGetTextPassword : IUnknown
{
    HRESULT CryptoGetTextPassword(BSTR* password);
}

interface ICryptoGetTextPassword2 : IUnknown
{
    HRESULT CryptoGetTextPassword2( Int32* passwordIsDefined
                                  , BSTR* password );
}
