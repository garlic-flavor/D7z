/**
 * Version:      UC(dmd2.069.0)
 * Date:         2015-Dec-01 23:05:36
 * Authors:      KUMA
 * License:      CC0
*/
module d7z.misc;

private import d7z.binding.types;
import std.traits : isCallable;
pragma(lib, "Oleaut32.lib");

debug import std.stdio;

/** like enforce one.

Throws:
  when ret != S_OK, enOK throws Exception.
**/
void enOK( HRESULT ret, lazy const(char)[] msg = null, string file = __FILE__
         , size_t line = __LINE__ )
{
	if (S_OK != ret)
		throw new Exception( msg.ptr ? msg.idup : "Enforcement failed"
		                   , file, line );
}

/// ditto
void enOK( HRESULT ret, Throwable t, string file = __FILE__
         , size_t line = __LINE__ )
{
	if (S_OK != ret)
	{
		if (t !is null) throw t;
		else throw new Exception("enOK failed", file, line);
	}
}


///
alias OnErrorCallback = void delegate(Throwable);

/**
functions that will be called from DLL, shouldn't throw anything.
wrap with tryCode(), and call OnErrorCallback().
**/
nothrow
HRESULT tryCode(T)( OnErrorCallback cb, scope T proc
                  , string FUNC_NAME = __FUNCTION__) if (isCallable!T)
{
	try
	{
		try
		{
			debug(D7Z_TRACE_TRYCODE) writeln("enter : ", FUNC_NAME);
			import std.traits : ReturnType;
			static if (!is(ReturnType!T == void))
				return proc();
			else
				proc();
		}
		catch(Throwable t)
		{
			if (cb) cb(t);
			return E_FAIL;
		}
		finally
		{
			debug(D7Z_TRACE_TRYCODE) writeln("done : ", FUNC_NAME);
		}
	}
	catch(Throwable){}

	return S_OK;
}

/** BSTR.
do delete.

$(LINK https://msdn.microsoft.com/en-us/library/windows/desktop/ms221069%28v=vs.85%29.aspx)
**/
struct BSTRIMPL
{
	wchar* _payload;
	alias _payload this;

	///
	this(T)(const(T)[] filename)
	{
		import std.utf : toUTF16z;
		if (0 < filename.length)
			this(filename.toUTF16z);
		else
			this(null);
	}

	///
	this(const(wchar)* filename)
	{
		if (filename !is null)
			_payload = SysAllocString(filename);
	}

	///
	~this() { clear; }

	void clear()
	{ if (_payload !is null) SysFreeString(_payload); _payload = null; }

	///
	@property @trusted @nogc pure nothrow
	auto ptr() inout { return _payload; }

	@property @trusted @nogc pure nothrow
	bool empty() const { return _payload is null; }
}

/// suger.
auto toWstr(inout BSTR bstr)
{
	if (bstr is null) return null;
	return bstr[0..(*((cast(uint*)bstr)-1))/wchar.sizeof];
}

