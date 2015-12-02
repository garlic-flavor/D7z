/**
 * Version:      UC(dmd2.069.0)
 * Date:         2015-Dec-01 23:05:36
 * Authors:      KUMA
 * License:      CC0
*/
module d7z.callbacks;

private import d7z.binding;
private import d7z.misc;
private import d7z.streams;
private import d7z.propvariant;
debug import std.stdio;

//==============================================================================
//
// open an archive.
//
//==============================================================================
/**
 * do clear().
**/
class ArchiveOpenCallback : IArchiveOpenCallback
{
	import std.traits : isSomeChar;

	///
	this(T)(OnErrorCallback cb = null, const(T)[] password = null)
		if (isSomeChar!T)
	{
		_onError = cb;
		_password = BSTRIMPL(password);
	}

	///
	@property @trusted @nogc pure nothrow
	int refCount() const { return _refCount; }

	///
	void clear() { _password.clear; }

	// IArchiveOpenCallback
	HRESULT SetTotal(const(UInt64)* files, const(UInt64)* bytes)
	{ return S_OK; }

	HRESULT SetCompleted(const(UInt64)* files, const(UInt64)* bytes)
	{ return S_OK; }


	// ICryptoGetTextPassword
	class CryptoGetTextPassword : ICryptoGetTextPassword
	{
		HRESULT CryptoGetTextPassword(BSTR* password)
		{ (*password) = _password.ptr; return S_OK; }

		HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
		{ return ArchiveOpenCallback.QueryInterface(riid, pvObject); }

		ULONG AddRef(){ return ++_refCount; }
		ULONG Release(){ return --_refCount; }
	}
	CryptoGetTextPassword passwordImpl;


	// IUnknown
	HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
	{
		return _onError.tryCode(
		{
			if      ((*riid) == IID_IUnknown)
				(*pvObject) = cast(void*)cast(IUnknown)this;
			else if ((*riid) == IID_IArchiveOpenCallback)
				(*pvObject) = cast(void*)cast(IArchiveOpenCallback)this;
			else if ((*riid) == IID_ICryptoGetTextPassword)
			{
				if (passwordImpl is null)
					passwordImpl = new CryptoGetTextPassword;
				(*pvObject) = cast(void*)cast(ICryptoGetTextPassword)
					passwordImpl;
			}
			else
				return E_NOINTERFACE;
			return S_OK;
		});
	}
	ULONG AddRef(){ return ++_refCount; }
	ULONG Release(){ return --_refCount; }

	//----------------------------------------------------------
	// privates
	private OnErrorCallback _onError;
	private BSTRIMPL _password;
	private int _refCount;
}



//==============================================================================
//
// extract an archive.
//
//==============================================================================

///
bool IsArchiveItemProp(IInArchive archive, UInt32 index, PROPID propID)
{
	PropVariant prop;
	archive.GetProperty(index, propID, prop.ptr).enOK;
	return prop.toBool;
}

///
bool IsArchiveItemFolder(IInArchive archive, UInt32 index)
{ return IsArchiveItemProp(archive, index, kpidIsDir); }


/// do clear()
class ArchiveExtractToFileCallback : IArchiveExtractCallback
{
	enum
	{
		kTestingString    =  "Testing     ",
		kExtractingString =  "Extracting  ",
		kSkippingString   =  "Skipping    ",

		kUnsupportedMethod = "Unsupported Method",
		kCRCFailed = "CRC Failed",
		kDataError = "Data Error",
		kUnavailableData = "Unavailable data",
		kUnexpectedEnd = "Unexpected end of data",
		kDataAfterEnd = "There are some data after the end of the payload data",
		kIsNotArc = "Is not archive",
		kHeadersError = "Headers Error",
	}

	///
	this( IInArchive acv, const(wchar)[] outDir, const(wchar)[] password
	    , OnErrorCallback cb = null)
	{
		import std.path : asNormalizedPath;
		import std.conv : to;
		assert(acv);
		_archiveHandler = acv;
		_archiveHandler.AddRef;
		_onError = cb;
		_outDir = outDir.asNormalizedPath.to!wstring;
		_password = BSTRIMPL(password);
	}

	///
	void clear()
	{
		if (_archiveHandler) _archiveHandler.Release;
		_archiveHandler = null;
		if (_outFileStream) _outFileStream.clear;
		_outFileStream = null;
		_onError = null;
		_password.clear;
	}

	///
	@property @trusted @nogc pure nothrow
	int refCount() const { return _refCount; }

	// IProgress
	HRESULT SetTotal(UInt64 size) {return S_OK;}
	HRESULT SetCompleted(const(UInt64)* completeValue) { return S_OK; }

	// IArchiveExtractCallback
	HRESULT GetStream( UInt32 index, ISequentialOutStream* outStream
	                 , Int32 askExtractMode )
	{
		import std.conv : to;
		import std.path : dirName, buildPath;
		import std.file : mkdirRecurse, exists, remove;

		return _onError.tryCode(
		{
			// テストとかだった場合。
			if (askExtractMode != NArchive.NExtract.NAskMode.kExtract)
				return S_OK;

			PropVariant prop;
			_archiveHandler.GetProperty(index, kpidPath, prop.ptr).enOK;
			assert(prop.vt == VARENUM.VT_BSTR);
			_currentInfo.outPath = _outDir.buildPath(prop.bstrVal.toWstr);
			prop.clear;

			// フォルダだった場合。
			if (_archiveHandler.IsArchiveItemFolder(index))
			{
				auto dir = _currentInfo.outPath.dirName;

				if (0 < dir.length && !dir.exists) dir.to!string.mkdirRecurse;
				return S_OK;
			}

			_archiveHandler.GetProperty(index, kpidAttrib, prop.ptr).enOK;
			if (prop.vt == VARENUM.VT_EMPTY)
			{
				_currentInfo.Attrib = 0;
				_currentInfo.AttribDefined = false;
			}
			else
			{
				if (prop.vt != VARENUM.VT_UI4) return E_FAIL;
				_currentInfo.Attrib = prop.ulVal;
				_currentInfo.AttribDefined = true;
			}
			prop.clear;

			_archiveHandler.GetProperty(index, kpidMTime, prop.ptr);
			_currentInfo.MTimeDefined = false;
			switch (prop.vt)
			{
				case VARENUM.VT_EMPTY:
					break;
				case VARENUM.VT_FILETIME:
					_currentInfo.MTime = prop.filetime;
					_currentInfo.MTimeDefined = true;
					break;
				default:
					return E_FAIL;
			}
			prop.clear;

			if (_currentInfo.outPath.exists)
				_currentInfo.outPath.remove;

			if (_outFileStream !is null) _outFileStream.clear;
			_outFileStream = new OutFileStream(_currentInfo.outPath, _onError);
			(*outStream) = _outFileStream;
			return S_OK;
		});
	}

	HRESULT PrepareOperation(Int32 askExtractMode)
	{ return S_OK; }

	HRESULT SetOperationResult(Int32 result)
	{
		return _onError.tryCode(
		{
			import std.conv : to;
			import std.file : setAttributes, exists;
			alias R = NArchive.NExtract.NOperationResult;

			if (result != R.kOK)
			{
				string s;
				switch (result)
				{
					case        R.kUnsupportedMethod: s = kUnsupportedMethod;
					break; case R.kCRCError: s = kCRCFailed;
					break; case R.kDataError: s = kDataError;
					break; case R.kUnavailable: s = kUnavailableData;
					break; case R.kUnexpectedEnd: s = kUnexpectedEnd;
					break; case R.kDataAfterEnd: s = kDataAfterEnd;
					break; case R.kHeadersError: s = kHeadersError;
					break; default:
				}
				if (0 < s.length)
					throw new Exception("Error : " ~ s);
				else
					throw new Exception("Error : #" ~ result.to!string);
			}

			if (_outFileStream !is null)
			{
				if (_currentInfo.MTimeDefined)
					_outFileStream.SetMTime(&_currentInfo.MTime);
				_outFileStream.clear;
				_outFileStream = null;
			}
			if (_currentInfo.AttribDefined)
			{
				if (0 < _currentInfo.outPath.length
				 && _currentInfo.outPath.exists)
					_currentInfo.outPath.setAttributes(_currentInfo.Attrib);
			}
			_currentInfo.clear;
			_password.clear;
			return S_OK;
		});
	}

	// ICryptoGetTextPassword
	class CryptoGetTextPassword : ICryptoGetTextPassword
	{
		HRESULT CryptoGetTextPassword(BSTR* password)
		{ (*password) = _password.ptr; return S_OK; }

		HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
		{ return ArchiveExtractToFileCallback.QueryInterface(riid, pvObject); }

		ULONG AddRef(){ return ++_refCount; }
		ULONG Release(){ return --_refCount; }
	}
	private CryptoGetTextPassword passwordImpl;

	HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
	{
		if      ((*riid) == IID_IUnknown)
			(*pvObject) = cast(void*)cast(IUnknown)this;
		else if ((*riid) == IID_IProgress)
			(*pvObject) = cast(void*)cast(IProgress)this;
		else if ((*riid) == IID_IArchiveExtractCallback)
			(*pvObject) = cast(void*)cast(IArchiveExtractCallback)this;
		else if ((*riid) == IID_ICryptoGetTextPassword)
		{
			if (passwordImpl is null)
				passwordImpl = new CryptoGetTextPassword;
			(*pvObject) = cast(void*)cast(ICryptoGetTextPassword)passwordImpl;
		}
		else
			return E_NOINTERFACE;
		return S_OK;
	}

	ULONG AddRef(){ return ++_refCount; }
	ULONG Release(){ return --_refCount;; }

	//----------------------------------------------------------
	private:
	IInArchive _archiveHandler;
	wstring _outDir;
	BSTRIMPL _password;

	struct FileInfo
	{
		wstring outPath;
		FILETIME MTime;
		UInt32 Attrib;
		bool AttribDefined;
		bool MTimeDefined;

		void clear()
		{
			outPath = null;
			MTime = FILETIME();
			Attrib = 0;
			AttribDefined = false;
			MTimeDefined = false;
		}
	}
	FileInfo _currentInfo;
	OutFileStream _outFileStream;
	OnErrorCallback _onError;
	int _refCount;
}


//==============================================================================
//
// create new archive.
//
//==============================================================================
///
struct DirItem
{
	const UInt64 Size;       ///
	const FILETIME CTime;    ///
	const FILETIME ATime;    ///
	const FILETIME MTime;    ///
	const BSTRIMPL Name;     ///
	const wstring FullPath; ///
	const UInt32 Attrib;     ///

	///
	bool isDir() const
	{
		version(Windows)
			return (Attrib & FILE_ATTRIBUTE_DIRECTORY) != 0;
		else
			static assert(0);
	}

	///
	this(wstring filename)
	{
		import std.file : getSize, getAttributes;
		import std.datetime : SysTime, SysTimeToFILETIME;
		import std.path : baseName;
		import std.exception : enforce;
		FullPath = filename;
		Name = BSTRIMPL(filename.baseName);
		Size = filename.getSize;

		SysTime ct, at, mt;
		version(Windows)
		{
			import std.file : getTimesWin;
			filename.getTimesWin(ct, at, mt);
		}
		else
		{
			import std.file : getTimes;
			filename.getTimes(at, mt);
		}
		CTime = cast(const(FILETIME))ct.SysTimeToFILETIME;
		ATime = cast(const(FILETIME))at.SysTimeToFILETIME;
		MTime = cast(const(FILETIME))mt.SysTimeToFILETIME;

		Attrib = filename.getAttributes;
	}
}

//------------------------------------------------------------------------------
///
class ArchiveUpdateByFilesCallback : IArchiveUpdateCallback
{
	///
	this(OnErrorCallback cb, DirItem[] items, const(wchar)[] password = null)
	{
		_onError = cb;
		dirItems = items;
		_password = BSTRIMPL(password);
	}

	///
	void clear()
	{
		if (inStream) inStream.clear;
		inStream = null;
		_password.clear;
	}

	///
	@property @trusted @nogc pure nothrow
	int refCount() const { return _refCount; }

	// IProgress
	HRESULT SetTotal(UInt64 size) { return S_OK; }
	HRESULT SetCompleted(const(UInt64)* completeValue) { return S_OK; }

	// IUpdateCallback2
	HRESULT GetUpdateItemInfo( UInt32 index, Int32* newData
	                         , Int32* newProperties, UInt32* indexInArchive )
	{
		return _onError.tryCode({
			if (newData) (*newData) = 1;
			if (newProperties) (*newProperties) = 1;
			if (indexInArchive) (*indexInArchive) = cast(UInt32)cast(Int32)-1;
		});
	}

	HRESULT GetProperty(UInt32 index, PROPID propID, PROPVARIANT* value)
	{
		return _onError.tryCode(
		{
			assert(value);
			PropVariant prop;
			if (propID == kpidIsAnti)
			{
				prop = false;
				prop.Detach(*value);
				return S_OK;
			}

			assert(index < dirItems.length);
			auto dirItem = &dirItems[index];
			switch(propID)
			{
				case kpidPath:   prop = dirItem.Name;   break;
				case kpidIsDir:  prop = dirItem.isDir;  break;
				case kpidSize:   prop = dirItem.Size;   break;
				case kpidAttrib: prop = dirItem.Attrib; break;
				case kpidCTime:  prop = dirItem.CTime;  break;
				case kpidATime:  prop = dirItem.ATime;  break;
				case kpidMTime:  prop = dirItem.MTime;  break;
				default: return E_FAIL;
			}
			prop.Detach(*value);
			return S_OK;
		});
	}

	HRESULT GetStream(UInt32 index, ISequentialInStream* inStream)
	{
		return _onError.tryCode(
		{
			import std.utf : toUTF16z;
			auto dirItem = &dirItems[index];

			if (dirItem.isDir) return;

			if (this.inStream) this.inStream.clear;
			this.inStream = new InFileStream(dirItem.FullPath, _onError);
			(*inStream) = this.inStream;
		});
	}

	HRESULT SetOperationResult(Int32 operationResult)
	{
		return _onError.tryCode(
		{
			import std.conv : to;
			alias R = NArchive.NExtract.NOperationResult;
			if (R.kOK != operationResult)
				throw new Exception((cast(R)operationResult).to!string);
		});
	}

	// ICryptoGetTextPassword2
	private class CryptoGetTextPassword2 : ICryptoGetTextPassword2
	{
		HRESULT CryptoGetTextPassword2( Int32* passwordIsDefined
		                              , BSTR* password )
		{
			return _onError.tryCode(
			{
				(*passwordIsDefined)
					= ArchiveUpdateByFilesCallback.passwordIsDefined;
				(*password) = ArchiveUpdateByFilesCallback._password.ptr;
			});
		}

		HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
		{return ArchiveUpdateByFilesCallback.QueryInterface(riid, pvObject); }

		ULONG AddRef(){return ++_refCount; }
		ULONG Release(){return --_refCount; }
	}
	private CryptoGetTextPassword2 cryptoGetTextPasswordImpl;

	// IUnknown
	HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
	{
		return _onError.tryCode(
		{
			if      ((*riid) == IID_IUnknown)
				(*pvObject) = cast(void*)cast(IUnknown)this;
			else if ((*riid) == IID_IProgress)
				(*pvObject) = cast(void*)cast(IProgress)this;
			else if ((*riid) == IID_IArchiveUpdateCallback)
				(*pvObject) = cast(void*)cast(IArchiveUpdateCallback)this;
			else if ((*riid) == IID_ICryptoGetTextPassword2)
			{
				if (cryptoGetTextPasswordImpl is null)
					cryptoGetTextPasswordImpl = new CryptoGetTextPassword2;
				(*pvObject) = cast(void*)cast(ICryptoGetTextPassword2)
					cryptoGetTextPasswordImpl;
			}
			else return E_NOINTERFACE;
			return S_OK;
		});
	}

	ULONG AddRef(){return ++_refCount; }
	ULONG Release(){return --_refCount; }

	//--------------------------------------
	//
	private:
	enum kEmptyFileAlias = "[Contents]";

	OnErrorCallback _onError;
	DirItem[] dirItems;

	int passwordIsDefined;
	BSTRIMPL _password;

	InFileStream inStream;
	int _refCount;
}


//==============================================================================
//
// memory
//
//==============================================================================

/**
 *
**/
class ArchiveExtractToMemCallback : IArchiveExtractCallback
{
	import std.traits : isSomeChar;
	///
	this(T)(IInArchive acv, const(T)[] password, OnErrorCallback cb = null)
		if (isSomeChar!T)
	{
		_archive = acv;
		_archive.AddRef;
		_onError = cb;
		_password = BSTRIMPL(password);
	}

	///
	void clear()
	{
		if (_archive) _archive.Release;
		_archive = null;
		if (_outStream) _outStream.clear;
		_outStream = null;
		_onError = null;
		_password.clear;
	}

	///
	@property @trusted @nogc pure nothrow
	int refCount() const { return _refCount; }

	///
	@property @trusted pure
	const(void)[] data(){ return _outStream is null ? null : _outStream.data; }

	// IProgress
	HRESULT SetTotal(UInt64) { return S_OK; }
	HRESULT SetCompleted(const(UInt64)* completeValue){ return S_OK; }

	// IArchiveExtractCallback
	HRESULT GetStream( UInt32 index, ISequentialOutStream* outStream
	                 , Int32 askExtractMode )
	{
		return _onError.tryCode(
		{
			if (askExtractMode != NArchive.NExtract.NAskMode.kExtract)
				return S_OK;

			if (_archive.IsArchiveItemFolder(index)) return S_OK;

			PropVariant prop;
			_archive.GetProperty(index, kpidSize, prop.ptr);
			auto exSize = prop.toUInt64;

			if (_outStream is null) _outStream = new OutMemStream(_onError);
			else _outStream.clear;
			assert(outStream);
			_outStream.SetSize(exSize);

			(*outStream) = _outStream;
			return S_OK;
		});
	}

	HRESULT PrepareOperation(Int32){ return S_OK; }
	HRESULT SetOperationResult(Int32 operationResult)
	{
		return _onError.tryCode(
		{
			import std.conv : to;
			alias R = NArchive.NExtract.NOperationResult;
			if (R.kOK != operationResult)
				throw new Exception((cast(R)operationResult).to!string);
		});
	}

	// ICryptoGetTextPassword2
	class CryptoGetTextPassword : ICryptoGetTextPassword
	{
		HRESULT CryptoGetTextPassword(BSTR* password)
		{
			return _onError.tryCode(
			{
				if (_password.ptr is null || _password.ptr[0] == '\0')
					throw new Exception("a PASSWORD is needed.");
				(*password) = _password.ptr;
			});
		}

		HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
		{ return ArchiveExtractToMemCallback.QueryInterface(riid, pvObject); }

		ULONG AddRef(){ return ++_refCount; }
		ULONG Release(){ return --_refCount; }
	}
	private CryptoGetTextPassword passwordImpl;

	// IUnknown
	HRESULT QueryInterface(const(GUID)* riid, void** pvObject)
	{
		if      ((*riid) == IID_IUnknown)
			(*pvObject) = cast(void*)cast(IUnknown)this;
		else if ((*riid) == IID_IProgress)
			(*pvObject) = cast(void*)cast(IProgress)this;
		else if ((*riid) == IID_IArchiveExtractCallback)
			(*pvObject) = cast(void*)cast(IArchiveExtractCallback)this;
		else if ((*riid) == IID_ICryptoGetTextPassword)
		{
			if (passwordImpl is null)
				passwordImpl = new CryptoGetTextPassword;
			(*pvObject) = cast(void*)cast(ICryptoGetTextPassword)passwordImpl;
		}
		else
			return E_NOINTERFACE;
		return S_OK;
	}

	ULONG AddRef(){ return ++_refCount; }
	ULONG Release(){ return --_refCount;; }

	//----------------------------------------------------------
	private:
	IInArchive _archive;
	BSTRIMPL _password;
	OutMemStream _outStream;
	OnErrorCallback _onError;
	int _refCount;
}
