/**
 * Version:      UC(dmd2.069.0)
 * Date:         2015-Dec-01 23:05:36
 * Authors:      KUMA
 * License:      CC0
*/
module d7z.binding.functions;

private import d7z.binding.types;

extern(C) @nogc nothrow {
	alias da_CreateDecoder
		= HRESULT function(UInt32 index, const(GUID)* iid, void** outObject);
	alias da_CreateEncoder
		= HRESULT function(UInt32 index, const(GUID)* iid, void** outObject);
	alias da_CreateObject
		= HRESULT function( const(GUID)* clsID, const(GUID)* iid
		                  , void** outObject );
	alias da_GetHandlerProperty
		= HRESULT function( PROPID propID, PROPVARIANT* value );
	alias da_GetHandlerProperty2
		= HRESULT function(UInt32 index, PROPID propID, PROPVARIANT* value);
	alias da_GetHashers
		= HRESULT function(IHashers* hashers);
	alias da_GetIsArc
		= UInt32 function(UInt32 formatIndex, Func_IsArc* isArc);
	alias da_GetMethodProperty
		= HRESULT function(UInt32 index, PROPID propID, PROPVARIANT* value);
	alias da_GetNumberOfFormats
		= HRESULT function(UInt32* numFormats);
	alias da_GetNumberOfMethods
		= HRESULT function(UInt32* numMethods);
	alias da_SetCaseSensitive
		= HRESULT function(Int32 caseSensitive);
	alias da_SetCodecs
		= HRESULT function(ICompressCodecsInfo compressCI);
	alias da_SetLargePageMode
		= HRESULT function();
}

__gshared {
	da_CreateDecoder CreateDecoder;
	da_CreateEncoder CreateEncoder;
	da_CreateObject CreateObject;
	da_GetHandlerProperty GetHandlerProperty;
	da_GetHandlerProperty2 GetHandlerProperty2;
	da_GetHashers GetHashers;
	da_GetIsArc GetIsArc;
	da_GetMethodProperty GetMethodProperty;
	da_GetNumberOfFormats GetNumberOfFormats;
	da_GetNumberOfMethods GetNumberOfMethods;
	da_SetCaseSensitive SetCaseSensitive;
	da_SetCodecs SetCodecs;
	da_SetLargePageMode SetLargePageMode;
}



