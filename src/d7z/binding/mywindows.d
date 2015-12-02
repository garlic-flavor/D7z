/** import or emulate windows.h
 * Version:      UC(dmd2.069.0)
 * Date:         2015-Dec-01 23:05:36
 * Authors:      KUMA
 * License:      CC0
**/
/**
Description:
You can use this module with $(LINK2 https://github.com/smjgordon/bindings/tree/master/win32, Win32 Bindings).

To do that, please ensure that the win32.windows can be imported.
$(D_INLINECODE import win32.windows;)

ToDo:
Write implementations other than on windows.

**/
module d7z.binding.mywindows;

// https://github.com/smjgordon/bindings
static if (__traits(compiles, {import win32.windows;}))
{
	public import win32.windows;
	public import win32.wtypes;
	public import win32.objidl;
}
else
{
	version(Windows)
	{
		public import core.sys.windows.windows;
		public import core.sys.windows.com;
	}
	else
	{
		static assert(0, "mywindows needs an implementation for "
		                 "this platform.");
	}

	enum FACILITY_WIN32 = 7;

	@trusted @nogc pure nothrow
	HRESULT HRESULT_FROM_WIN32(uint x)
	{
		return (cast(HRESULT)x) <= 0
			? (cast(HRESULT)x)
			: (cast(HRESULT)((x & 0x0000FFFF) | (FACILITY_WIN32 << 16)
			                                  | 0x80000000) );
	}

	struct BY_HANDLE_FILE_INFORMATION
	{
		DWORD    dwFileAttributes;
		FILETIME ftCreationTime;
		FILETIME ftLastAccessTime;
		FILETIME ftLastWriteTime;
		DWORD    dwVolumeSerialNumber;
		DWORD    nFileSizeHigh;
		DWORD    nFileSizeLow;
		DWORD    nNumberOfLinks;
		DWORD    nFileIndexHigh;
		DWORD    nFileIndexLow;
	}
	alias PBY_HANDLE_FILE_INFORMATION = BY_HANDLE_FILE_INFORMATION*;
	alias LPBY_HANDLE_FILE_INFORMATION = BY_HANDLE_FILE_INFORMATION*;

	alias VARTYPE = ushort;
	alias PROPVAR_PAD1 = WORD;
	alias PROPVAR_PAD2 = WORD;
	alias PROPVAR_PAD3 = WORD;
	alias VARIANT_BOOL = short;
	alias SCODE = LONG;
	alias OLECHAR = WCHAR;
	alias BSTR = OLECHAR*;
	alias LPCOLESTR = const(OLECHAR)*;

	enum VARIANT_TRUE  = cast(VARIANT_BOOL)-1;
	enum VARIANT_FALSE = cast(VARIANT_BOOL)0;

	struct BLOB
	{
		ULONG cbSize;
		BYTE* pBlobData;
	}
	
	enum VARENUM
	{
		VT_EMPTY = 0,
		VT_NULL = 1,
		VT_I2 = 2,
		VT_I4 = 3,
		VT_R4 = 4,
		VT_R8 = 5,
		VT_CY = 6,
		VT_DATE = 7,
		VT_BSTR = 8,
		VT_DISPATCH = 9,
		VT_ERROR = 10,
		VT_BOOL = 11,
		VT_VARIANT = 12,
		VT_UNKNOWN = 13,
		VT_DECIMAL = 14,
		VT_I1 = 16,
		VT_UI1 = 17,
		VT_UI2 = 18,
		VT_UI4 = 19,
		VT_I8 = 20,
		VT_UI8 = 21,
		VT_INT = 22,
		VT_UINT = 23,
		VT_VOID = 24,
		VT_HRESULT = 25,
		VT_FILETIME = 64
	}

	struct PROPVARIANT
	{
		VARTYPE vt = VARENUM.VT_EMPTY;
		PROPVAR_PAD1 wReserved1;
		PROPVAR_PAD2 wReserved2;
		PROPVAR_PAD3 wReserved3;
		union
		{
			CHAR cVal;
			UCHAR bVal;
			SHORT iVal;
			USHORT uiVal;
			LONG lVal;
			ULONG ulVal;
			INT intVal;
			UINT uintVal;
			LARGE_INTEGER hVal;
			ULARGE_INTEGER uhVal;
			VARIANT_BOOL boolVal;
			SCODE scode;
			FILETIME filetime;
			BSTR bstrVal;
			BLOB blob;
			float fltVal;
			double dblVal;
		}
	}

	extern(Windows) BOOL SetDllDirectoryW(const(wchar)*);
	extern(Windows) BOOL SetFilePointerEx( HANDLE, LARGE_INTEGER
	                                     , PLARGE_INTEGER
	                                     , DWORD );
	extern(Windows) BOOL GetFileInformationByHandle
		(HANDLE, LPBY_HANDLE_FILE_INFORMATION);

	extern(Windows) BSTR SysAllocString(const(OLECHAR)*);
	extern(Windows) HRESULT SysFreeString(BSTR);

	extern(Windows) HMODULE LoadLibraryExW(const(wchar)*, HANDLE, DWORD);
	enum : DWORD
	{
		DONT_RESOLVE_DLL_DEFERENCES         = 0x00000001,
		LOAD_IGNORE_CODE_AUTHZ_LEVEL        = 0x00000010,
		LOAD_LIBRARY_AS_DATAFILE            = 0x00000002,
		LOAD_LIBRARY_AS_DATAFILE_EXCLUSIVE  = 0x00000040,
		LOAD_LIBRARY_AS_IMAGE_RESOURCE      = 0x00000020,
		LOAD_LIBRARY_SEARCH_APPLICATION_DIR = 0x00000200,
		LOAD_LIBRARY_SEARCH_DEFAULT_DIRS    = 0x00001000,
		LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR    = 0x00000100,
		LOAD_LIBRARY_SEARCH_SYSTEM32        = 0x00000800,
		LOAD_LIBRARY_SEARCH_USER_DIRS       = 0x00000400,
		LOAD_WITH_ALTERED_SEARCH_PATH       = 0x00000008,
	}
}
