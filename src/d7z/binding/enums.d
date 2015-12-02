/**
 * Version:      UC(dmd2.069.0)
 * Date:         2015-Dec-01 23:05:36
 * Authors:      KUMA
 * License:      CC0
*/
module d7z.binding.enums;

private import d7z.binding.types;

//------------------------------------------------------------------------------
//
// PropID.h
//
//------------------------------------------------------------------------------

enum : PROPID
{
	kpidNoProperty = 0,
	kpidMainSubfile,
	kpidHandlerItemIndex,
	kpidPath,
	kpidName,
	kpidExtension,
	kpidIsDir,
	kpidSize,
	kpidPackSize,
	kpidAttrib,
	kpidCTime,
	kpidATime,
	kpidMTime,
	kpidSolid,
	kpidCommented,
	kpidEncrypted,
	kpidSplitBefore,
	kpidSplitAfter,
	kpidDictionarySize,
	kpidCRC,
	kpidType,
	kpidIsAnti,
	kpidMethod,
	kpidHostOS,
	kpidFileSystem,
	kpidUser,
	kpidGroup,
	kpidBlock,
	kpidComment,
	kpidPosition,
	kpidPrefix,
	kpidNumSubDirs,
	kpidNumSubFiles,
	kpidUnpackVer,
	kpidVolume,
	kpidIsVolume,
	kpidOffset,
	kpidLinks,
	kpidNumBlocks,
	kpidNumVolumes,
	kpidTimeType,
	kpidBit64,
	kpidBigEndian,
	kpidCpu,
	kpidPhySize,
	kpidHeadersSize,
	kpidChecksum,
	kpidCharacts,
	kpidVa,
	kpidId,
	kpidShortName,
	kpidCreatorApp,
	kpidSectorSize,
	kpidPosixAttrib,
	kpidSymLink,
	kpidError,
	kpidTotalSize,
	kpidFreeSpace,
	kpidClusterSize,
	kpidVolumeName,
	kpidLocalName,
	kpidProvider,
	kpidNtSecure,
	kpidIsAltStream,
	kpidIsAux,
	kpidIsDeleted,
	kpidIsTree,
	kpidSha1,
	kpidSha256,
	kpidErrorType,
	kpidNumErrors,
	kpidErrorFlags,
	kpidWarningFlags,
	kpidWarning,
	kpidNumStreams,
	kpidNumAltStreams,
	kpidAltStreamsSize,
	kpidVirtualSize,
	kpidUnpackSize,
	kpidTotalPhySize,
	kpidVolumeIndex,
	kpidSubType,
	kpidShortComment,
	kpidCodePage,
	kpidIsNotArcType,
	kpidPhySizeCantBeDetected,
	kpidZerosTailIsAllowed,
	kpidTailSize,
	kpidEmbeddedStubSize,
	kpidNtReparse,
	kpidHardLink,
	kpidINode,
	kpidStreamId,
	kpidReadOnly,
	kpidOutName,
	kpidCopyLink,

	kpid_NUM_DEFINED,

	kpidUserDefined = 0x10000
}

enum Byte[kpid_NUM_DEFINED] k7z_PROPID_To_VARTYPE =
[
	VARENUM.VT_EMPTY,
	VARENUM.VT_UI4,
	VARENUM.VT_UI4,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_BOOL,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_UI4,
	VARENUM.VT_FILETIME,
	VARENUM.VT_FILETIME,
	VARENUM.VT_FILETIME,
	VARENUM.VT_BOOL,
	VARENUM.VT_BOOL,
	VARENUM.VT_BOOL,
	VARENUM.VT_BOOL,
	VARENUM.VT_BOOL,
	VARENUM.VT_UI4,
	VARENUM.VT_UI4,
	VARENUM.VT_BSTR,
	VARENUM.VT_BOOL,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_UI8,
	VARENUM.VT_BSTR,
	VARENUM.VT_UI8,
	VARENUM.VT_BSTR,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_BSTR, // or VT_UI8 kpidUnpackVer
	VARENUM.VT_UI4, // or VT_UI8 kpidVolume
	VARENUM.VT_BOOL,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_UI4,
	VARENUM.VT_BOOL,
	VARENUM.VT_BOOL,
	VARENUM.VT_BSTR,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_UI4, // kpidChecksum
	VARENUM.VT_BSTR,
	VARENUM.VT_UI8,
	VARENUM.VT_BSTR, // or VT_UI8 kpidId
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_UI4,
	VARENUM.VT_UI4,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_UI4,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR, // kpidNtSecure
	VARENUM.VT_BOOL,
	VARENUM.VT_BOOL,
	VARENUM.VT_BOOL,
	VARENUM.VT_BOOL,
	VARENUM.VT_BSTR, // SHA-1
	VARENUM.VT_BSTR, // SHA-256
	VARENUM.VT_BSTR,
	VARENUM.VT_UI8,
	VARENUM.VT_UI4,
	VARENUM.VT_UI4,
	VARENUM.VT_BSTR,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR,
	VARENUM.VT_BOOL,
	VARENUM.VT_BOOL,
	VARENUM.VT_BOOL,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_BSTR, // kpidNtReparse
	VARENUM.VT_BSTR,
	VARENUM.VT_UI8,
	VARENUM.VT_UI8,
	VARENUM.VT_BOOL,
	VARENUM.VT_BSTR,
	VARENUM.VT_BSTR
];

enum UInt32 kpv_ErrorFlags_IsNotArc              = 1 << 0;
enum UInt32 kpv_ErrorFlags_HeadersError          = 1 << 1;
enum UInt32 kpv_ErrorFlags_EncryptedHeadersError = 1 << 2;
enum UInt32 kpv_ErrorFlags_UnavailableStart      = 1 << 3;
enum UInt32 kpv_ErrorFlags_UnconfirmedStart      = 1 << 4;
enum UInt32 kpv_ErrorFlags_UnexpectedEnd         = 1 << 5;
enum UInt32 kpv_ErrorFlags_DataAfterEnd          = 1 << 6;
enum UInt32 kpv_ErrorFlags_UnsupportedMethod     = 1 << 7;
enum UInt32 kpv_ErrorFlags_UnsupportedFeature    = 1 << 8;
enum UInt32 kpv_ErrorFlags_DataError             = 1 << 9;
enum UInt32 kpv_ErrorFlags_CrcError              = 1 << 10;
// const UInt32 kpv_ErrorFlags_Unsupported           = 1 << 11;

//------------------------------------------------------------------------------
//
// IArchive.h
//
//------------------------------------------------------------------------------
struct NFileTimeType
{
	enum EEnum
	{
		kWindows,
		kUnix,
		kDOS
	}
}

enum NArcInfoFlags : UInt32
{
	kKeepName        = 1 << 0,  // keep name of file in archive name
	kAltStreams      = 1 << 1,  // the handler supports alt streams
	kNtSecure        = 1 << 2,  // the handler supports NT security
	kFindSignature   = 1 << 3,  // the handler can find start of archive
	kMultiSignature  = 1 << 4,  // there are several signatures
	kUseGlobalOffset = 1 << 5,  // the seek position of stream must be set as global offset
	kStartOpen       = 1 << 6,  // call handler for each start position
	kPureStartOpen   = 1 << 7,  // call handler only for start of file
	kBackwardOpen    = 1 << 8,  // archive can be open backward
	kPreArc          = 1 << 9,  // such archive can be stored before real archive (like SFX stub)
	kSymLinks        = 1 << 10, // the handler supports symbolic links
	kHardLinks       = 1 << 11, // the handler supports hard links
}

struct NArchive
{
	enum NHandlerPropID
	{
		kName = 0,        // VT_BSTR
		kClassID,         // binary GUID in VT_BSTR
		kExtension,       // VT_BSTR
		kAddExtension,    // VT_BSTR
		kUpdate,          // VT_BOOL
		kKeepName,        // VT_BOOL
		kSignature,       // binary in VT_BSTR
		kMultiSignature,  // binary in VT_BSTR
		kSignatureOffset, // VT_UI4
		kAltStreams,      // VT_BOOL
		kNtSecure,        // VT_BOOL
		kFlags            // VT_UI4
		// kVersion          // VT_UI4 ((VER_MAJOR << 8) | VER_MINOR)
	}

	struct NExtract
	{
		enum NAskMode
		{
			kExtract = 0,
			kTest,
			kSkip,
		}

		enum NOperationResult
		{
			kOK = 0,
			kUnsupportedMethod,
			kDataError,
			kCRCError,
			kUnavailable,
			kUnexpectedEnd,
			kDataAfterEnd,
			kIsNotArc,
			kHeadersError,
			kWrongPassword
		}
	}

	enum NEventIndexType
	{
		kNoIndex = 0,
		kInArcIndex,
		kBlockIndex,
		kOutArcIndex
	}

	struct NUpdate
	{
		enum NOperationResult
		{
			kOK = 0
			, // kError
		}
	}
}



//==============================================================================
//
// about GUID
//
//==============================================================================
auto IID_IHasher = CODER_INTERFACE_GUID(0xC0);
auto IID_IHashers = CODER_INTERFACE_GUID(0xC1);
auto IID_ICopressCodecsInfo = CODER_INTERFACE_GUID(0x60);

auto IID_IProgress = DECL_INTERFACE_GUID(0, 5);

auto IID_IArchiveOpenCallback = ARCHIVE_INTERFACE_GUID(0x10);
auto IID_IArchiveExtractCallback = ARCHIVE_INTERFACE_GUID(0x20);
auto IID_IInArchive = ARCHIVE_INTERFACE_GUID(0x60);
auto IID_IArchiveUpdateCallback = ARCHIVE_INTERFACE_GUID(0x80);
auto IID_IArchiveUpdateCallback2 = ARCHIVE_INTERFACE_GUID(0x82);
auto IID_IOutArchive = ARCHIVE_INTERFACE_GUID(0xA0);

auto IID_ISequentialInStream = STREAM_INTERFACE_GUID(0x01);
auto IID_ISequentialOutStream = STREAM_INTERFACE_GUID(0x02);
auto IID_IInStream  = STREAM_INTERFACE_GUID(0x03);
auto IID_IOutStream = STREAM_INTERFACE_GUID(0x04);
auto IID_IStreamGetSize = STREAM_INTERFACE_GUID(0x06);
auto IID_IStreamGetProps = STREAM_INTERFACE_GUID(0x08);
auto IID_IStreamGetProps2 = STREAM_INTERFACE_GUID(0x09);


auto IID_ICryptoGetTextPassword = PASSWORD_INTERFACE_GUID(0x10);
auto IID_ICryptoGetTextPassword2 = PASSWORD_INTERFACE_GUID(0x11);

auto CLSID_CFormatZip = DECL_HANDLER_GUID(0x01);
auto CLSID_CFormatBZip2 = DECL_HANDLER_GUID(0x02);
auto CLSID_CFormatRar = DECL_HANDLER_GUID(0x03);
auto CLSID_CFormatArj = DECL_HANDLER_GUID(0x04);
auto CLSID_CFormatZ = DECL_HANDLER_GUID(0x05);
auto CLSID_CFormatLzh = DECL_HANDLER_GUID(0x06);
auto CLSID_CFormat7z = DECL_HANDLER_GUID(0x07);
auto CLSID_CFormatCab = DECL_HANDLER_GUID(08);
auto CLSID_CFormatNsis = DECL_HANDLER_GUID(09);
auto CLSID_CFormatLZMA = DECL_HANDLER_GUID(0x0A);
auto CLSID_CFormatlzma86 = DECL_HANDLER_GUID(0x0B);
auto CLSID_CFormatXz = DECL_HANDLER_GUID(0x0C);
auto CLSID_CFormatppmd = DECL_HANDLER_GUID(0x0D);
auto CLSID_CFormatExt = DECL_HANDLER_GUID(0xC7);
auto CLSID_CFormatVMDK = DECL_HANDLER_GUID(0xC8);
auto CLSID_CFormatVDI = DECL_HANDLER_GUID(0xC9);
auto CLSID_CFormatQcow = DECL_HANDLER_GUID(0xCA);
auto CLSID_CFormatGPT = DECL_HANDLER_GUID(0xCB);
auto CLSID_CFormatRar5 = DECL_HANDLER_GUID(0xCC);
auto CLSID_CFormatIHex = DECL_HANDLER_GUID(0xCD);
auto CLSID_CFormatHxs = DECL_HANDLER_GUID(0xCE);
auto CLSID_CFormatTE = DECL_HANDLER_GUID(0xCF);
auto CLSID_CFormatUEFIc = DECL_HANDLER_GUID(0xD0);
auto CLSID_CFormatUEFIs = DECL_HANDLER_GUID(0xD1);
auto CLSID_CFormatSquashFS = DECL_HANDLER_GUID(0xD2);
auto CLSID_CFormatCramFS = DECL_HANDLER_GUID(0xD3);
auto CLSID_CFormatAPM = DECL_HANDLER_GUID(0xD4);
auto CLSID_CFormatMslz = DECL_HANDLER_GUID(0xD5);
auto CLSID_CFormatFlv = DECL_HANDLER_GUID(0xD6);
auto CLSID_CFormatSwf = DECL_HANDLER_GUID(0xD7);
auto CLSID_CFormatSwfc = DECL_HANDLER_GUID(0xD8);
auto CLSID_CFormatNtfs = DECL_HANDLER_GUID(0xD9);
auto CLSID_CFormatFat = DECL_HANDLER_GUID(0xDA);
auto CLSID_CFormatMbr = DECL_HANDLER_GUID(0xDB);
auto CLSID_CFormatVhd = DECL_HANDLER_GUID(0xDC);
auto CLSID_CFormatPe = DECL_HANDLER_GUID(0xDD);
auto CLSID_CFormatElf = DECL_HANDLER_GUID(0xDE);
auto CLSID_CFormatMach_O = DECL_HANDLER_GUID(0xDF);
auto CLSID_CFormatUdf = DECL_HANDLER_GUID(0xE0);
auto CLSID_CFormatXar = DECL_HANDLER_GUID(0xE1);
auto CLSID_CFormatMub = DECL_HANDLER_GUID(0xE2);
auto CLSID_CFormatHfs = DECL_HANDLER_GUID(0xE3);
auto CLSID_CFormatDmg = DECL_HANDLER_GUID(0xE4);
auto CLSID_CFormatCompound = DECL_HANDLER_GUID(0xE5);
auto CLSID_CFormatWim = DECL_HANDLER_GUID(0xE6);
auto CLSID_CFormatIso = DECL_HANDLER_GUID(0xE7);

auto CLSID_CFormatChm = DECL_HANDLER_GUID(0xE9);
auto CLSID_CFormatSplit = DECL_HANDLER_GUID(0xEA);
auto CLSID_CFormatRpm = DECL_HANDLER_GUID(0xEB);
auto CLSID_CFormatDeb = DECL_HANDLER_GUID(0xEC);
auto CLSID_CFormatCpio = DECL_HANDLER_GUID(0xED);
auto CLSID_CFormatTar = DECL_HANDLER_GUID(0xEE);
auto CLSID_CFormatGZip = DECL_HANDLER_GUID(0xEF);


//--------------------------------------
private:

enum
{
	k_7zip_GUID_Data1 = 0x23170F69,
	k_7zip_GUID_Data2 = 0x40C1,

	k_7zip_GUID_Data3_Common  = 0x278A,

	k_7zip_GUID_Data3_Decoder = 0x2790,
	k_7zip_GUID_Data3_Encoder = 0x2791,
	k_7zip_GUID_Data3_Hasher  = 0x2792,
}

@trusted @nogc pure nothrow
{
	GUID DECL_INTERFACE_GUID(BYTE groupId, BYTE subId)
	{
		return GUID( k_7zip_GUID_Data1, k_7zip_GUID_Data2
		           , k_7zip_GUID_Data3_Common
		           , [ 0, 0, 0, groupId, 0, subId, 0, 0 ] );
	}

	GUID STREAM_INTERFACE_GUID(BYTE subId)
	{ return DECL_INTERFACE_GUID(3, subId); }

	GUID CODER_INTERFACE_GUID(BYTE subId)
	{ return DECL_INTERFACE_GUID(4, subId); }

	GUID PASSWORD_INTERFACE_GUID(BYTE subId)
	{ return DECL_INTERFACE_GUID(5, subId); }

	GUID ARCHIVE_INTERFACE_GUID(BYTE subId)
	{ return DECL_INTERFACE_GUID(6, subId); }

	GUID DECL_HANDLER_GUID(BYTE subId)
	{
		return GUID( k_7zip_GUID_Data1, k_7zip_GUID_Data2
		           , k_7zip_GUID_Data3_Common
		           , [0x10, 0, 0, 0x01, 0x10, subId, 0, 0] );
	}
}
