/**
 * Version:      UC(dmd2.069.0)
 * Date:         2015-Dec-01 23:05:36
 * Authors:      KUMA
 * License:      CC0
*/
module client7z;

import std.stdio;
import d7z.binding.mywindows;
import d7z.util;

/** これから読み込もうとしているDLLがあるフォルダを指定する。
 *
 * 現在の実行ファイルがあるディレクトリからの相対パスでも可。
**/
void setDLLDir(string dir)
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

//
void main()
{
	setDLLDir("bin64");

	auto mpr = new MountPointRoot;

	mpr.mount("test.7z/test/import_.7z/import_/win32", "/", "password");
	scope(exit) if (mpr) mpr.clear;

	if (auto item = mpr.search("/cguid.d"))
	{
		(cast(char[])item.data).writeln;
	}


	// auto archive = new Archive("test.7z");
	// scope(exit) if (archive) archive.clear;

	// if (auto item = archive.getFile("test.d"))
	// {
	// 	(cast(char[])item.data).writeln;
	// }

	// My7z.load;

	// OnErrorCallback callback = (Throwable t){t.toString.writeln;};

///create new archive.
/*

	auto outFileStreamSpec = new OutFileStream("test.7z"w, callback);


	IOutArchive outArchive;
	CreateObject( &CLSID_CFormat7z, &IID_IOutArchive
	            , cast(void**)&outArchive).enOK;
	assert(outArchive);
	scope(exit) if (outArchive) outArchive.Release();

	auto dirItems = [DirItem("C:\\Users\\nor\\work\\2015-04-12_7z\\client7z.d")];

	auto updateCallbackSpec
		= new ArchiveUpdateByFilesCallback(callback, dirItems);
	scope(exit) if (updateCallbackSpeck) updateCallbackSpec.clear;

	outArchive.UpdateItems( outFileStreamSpec
	                      , cast(uint)dirItems.length
	                      , updateCallbackSpec ).enOK;
*/


	writeln("done.");
}
