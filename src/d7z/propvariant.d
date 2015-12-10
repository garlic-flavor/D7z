/**
 * Version:      UC(dmd2.069.2)
 * Date:         2015-Dec-10 20:59:42
 * Authors:      KUMA
 * License:      CC0
*/
module d7z.propvariant;

private import d7z.binding.types;
private import d7z.misc;
debug import std.stdio;

/// $(LINK https://msdn.microsoft.com/en-us/library/windows/desktop/aa380072%28v=vs.85%29.aspx)
struct PropVariant
{
    PROPVARIANT _payload; ///
    alias _payload this;

    ///
    this(T)(in auto ref T src){ opAssign(src); }

    ///
    @property @trusted @nogc pure nothrow
    auto ptr() inout { return &_payload; }

    ///
    ref auto opAssign(in ref PROPVARIANT v)
    {
        clear;
        _payload = v;
        return this;
    }

    ///
    ref auto opAssign(CFSTR v)
    {
        if (_payload.vt != VARENUM.VT_BSTR)
        { clear; _payload.vt = VARENUM.VT_BSTR; }
        _payload.wReserved1 = 0;
        _payload.bstrVal = cast(BSTR)v;
        return this;
    }

    ///
    ref auto opAssign(bool v)
    {
        if (_payload.vt != VARENUM.VT_BOOL)
        { clear; _payload.vt = VARENUM.VT_BOOL; }
        _payload.wReserved1 = 0;
        _payload.boolVal = v ? VARIANT_TRUE : VARIANT_FALSE;

        return this;
    }

    ///
    ref auto opAssign(Byte v)
    {
        if (_payload.vt != VARENUM.VT_UI1)
        { clear; _payload.vt = VARENUM.VT_UI1; }
        _payload.wReserved1 = 0;
        _payload.bVal = v;
        return this;
    }

    ///
    ref auto opAssign(Int32 v)
    {
        if (_payload.vt != VARENUM.VT_I4)
        { clear; _payload.vt = VARENUM.VT_I4; }
        _payload.wReserved1 = 0;
        _payload.lVal = v;
        return this;
    }

    ///
    ref auto opAssign(UInt32 v)
    {
        if (_payload.vt != VARENUM.VT_UI4)
        { clear; _payload.vt = VARENUM.VT_UI4; }
        _payload.wReserved1 = 0;
        _payload.ulVal = v;
        return this;
    }

    ///
    ref auto opAssign(UInt64 v)
    {
        if (_payload.vt != VARENUM.VT_UI8)
        { clear; _payload.vt = VARENUM.VT_UI8; }
        _payload.wReserved1 = 0;
        _payload.hVal.QuadPart = v;
        return this;
    }

    ///
    ref auto opAssign(in ref FILETIME v)
    {
        if (_payload.vt != VARENUM.VT_FILETIME)
        { clear; _payload.vt = VARENUM.VT_FILETIME; }
        _payload.wReserved1 = 0;
        _payload.filetime = v;
        return this;
    }

    ///
    HRESULT clear() { return clear(_payload); }

    ///
    HRESULT Copy(in ref PROPVARIANT src) { opAssign(src); return S_OK; }

    /// copy from and clear src.
    HRESULT Attach(ref PROPVARIANT src)
    {
        clear;
        _payload = src;
        clear(src);
        return S_OK;
    }

    /// copy to dest and clear this.
    HRESULT Detach(ref PROPVARIANT dest)
    {
        clear(dest);
        dest = _payload;
        clear;
        return S_OK;
    }

    ///
    int opComp(in ref PropVariant a)
    {
        if (_payload.vt != a._payload.vt) return _payload.vt - a.vt;
        switch(_payload.vt)
        {
        case VARENUM.VT_EMPTY: return 0;
        case VARENUM.VT_UI1: return _payload.bVal - a.bVal;
        case VARENUM.VT_I2: return _payload.iVal - a.iVal;
        case VARENUM.VT_UI2: return _payload.uiVal - a.uiVal;
        case VARENUM.VT_I4: return _payload.lVal - a.lVal;
        case VARENUM.VT_UI4: return _payload.ulVal - a.ulVal;
        case VARENUM.VT_I8:
            return cast(int)(_payload.hVal.QuadPart - a.hVal.QuadPart);
        case VARENUM.VT_UI8:
            return cast(int)(_payload.uhVal.QuadPart - a.uhVal.QuadPart);
        case VARENUM.VT_BOOL: return a.boolVal - _payload.boolVal;
        case VARENUM.VT_FILETIME:
            version(Windows)
                return CompareFileTime(&_payload.filetime, &a.filetime);
            else
                return _payload.filetime.opCmp(a.filetime);
        case VARENUM.VT_BSTR: return 0;
        default: return 0;
        }
    }

    ///
    @property
    string toString()
    {
        import std.conv : to;
        version(Windows)
        {
            import std.datetime : FILETIMEToSysTime, FILETIME;
        }
        switch(_payload.vt)
        {
        case VARENUM.VT_I1:
        case VARENUM.VT_I2:
        case VARENUM.VT_I4:
        case VARENUM.VT_I8:
        case VARENUM.VT_INT:
        case VARENUM.VT_HRESULT:
        case VARENUM.VT_BOOL:
            return _payload.hVal.QuadPart.to!string;
        case VARENUM.VT_UI1:
        case VARENUM.VT_UI2:
        case VARENUM.VT_UI4:
        case VARENUM.VT_UI8:
        case VARENUM.VT_UINT:
            return _payload.uhVal.QuadPart.to!string;
        case VARENUM.VT_R4:
            return _payload.fltVal.to!string;
        case VARENUM.VT_R8:
            return _payload.dblVal.to!string;
        case VARENUM.VT_BSTR:
            return _payload.bstrVal.toBArray.to!string;
        case VARENUM.VT_FILETIME:
            version(Windows)
                return (cast(FILETIME*)(&_payload.filetime))
                    .FILETIMEToSysTime.toISOExtString;
            else
                return "NO IMPL about FILETIME.toString.";
        default:
        }
        return null;
    }

    ///
    @property
    bool toBool()
    {
        import std.exception;
        enforce(_payload.vt == VARENUM.VT_BOOL
             || _payload.vt == VARENUM.VT_EMPTY);
        return _payload.vt == VARENUM.VT_BOOL
            && (_payload.boolVal == VARIANT_TRUE);
    }

    ///
    @property
    UInt64 toUInt64()
    {
        import std.exception;
        enforce(_payload.vt == VARENUM.VT_EMPTY
             || _payload.vt == VARENUM.VT_UI1
             || _payload.vt == VARENUM.VT_UI2
             || _payload.vt == VARENUM.VT_UI4
             || _payload.vt == VARENUM.VT_UI8
             || _payload.vt == VARENUM.VT_UINT);
        return _payload.uhVal.QuadPart;
    }

    ///--------------------------------------------------------------------
    /// privates
    private static @trusted @nogc pure nothrow
    HRESULT clear(ref PROPVARIANT t)
    {
        with(t)
        {
            if (vt == VARENUM.VT_EMPTY) return S_OK;
            vt = VARENUM.VT_EMPTY;
            wReserved1 = 0;
            wReserved2 = 0;
            wReserved3 = 0;
            uhVal.QuadPart = 0;
        }
        return S_OK;
    }
}
