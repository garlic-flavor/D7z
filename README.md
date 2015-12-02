D7z - a dynamic binding of 7zip for D -
=======================================

WHAT IS THIS?
-------------
This is a dynamic binding of
[7zip](http://7-zip.org/) for [D programming language](http://dlang.org/)
with using COM interface.

and some experimental utilities.

HOW TO USE
----------
use low level interfaces

    import d7z.binding;

    void main()
    {
        My7z.load;

        IInArchive archive;
        CreateObject(&CLSID_CFormat7z, &IID_IInArchive, cast(void**)&archive);

        [... and so on ...]
    }


or, use utilities

    import std.stdio;
    import d7z.util;

    void main()
    {
        (cast(char[])"sample.7z".readArchive("a_file_in_the_archive.txt"))
            .writeln;
    }


or

    import std.stdio;
    import d7z.util;

    void main()
    {
        auto archive = new Archive("sample.7z");
        scope(exit) if (archive) archive.clear;

        if (auto item = archive.getFile("a_file_in_the_archive.txt"))
           (cast(char[])item.data).writeln;
    }


and, a cheap mount system (like [PhysicsFS](https://icculus.org/physfs/)?)

    import std.stdio;
    import d7z.util;

    void main()
    {
        auto mpr = new MountPointRoot;
        scope(exit) if (mpr) mpr.clear;

        mpr.mount("sample.7z", "/");

        if (auto item = mpr.search("/a_file_in_the_archive.txt"))
           (cast(char[])item.data).writeln;
    }

ACKNOWLEDGEMENTS
----------------
* this module is written by [D Programming Language](http://dlang.org/)
* [7zip](http://7-zip.org/) is a famous archiver.


LICENSE
-------
[CC0](https://creativecommons.org/publicdomain/zero/1.0/)

(7zxa.dll itself is under GNU LGPL)

TODO
----
* Currentry, supported OS is only windows. so....

* d7z.util is only for extraction. I wonder how implement to create/update an archive.


VERSION
-------
UNDER CONSTRUCTION.(dmd2.069.0)

History
-------
* 2015-12-01 ver.UC


* * *

これは？
--------
これは、[D言語](http://dlang.org/)から[7zip](http://7-zip.org/)の DLL
を使う為のライブラリです。

使い方
------
COMを直接呼び出す場合

    import d7z.binding;

    void main()
    {
        My7z.load;

        IInArchive archive;
        CreateObject(&CLSID_CFormat7z, &IID_IInArchive, cast(void**)&archive);

        [... and so on ...]
    }

いくつかの補助機能が d7z.util に実装されています。

    import std.stdio;
    import d7z.util;

    void main()
    {
        (cast(char[])"sample.7z".readArchive("a_file_in_the_archive.txt"))
            .writeln;
    }

書庫への接続を再利用する場合。

    import std.stdio;
    import d7z.util;

    void main()
    {
        auto archive = new Archive("sample.7z");
        scope(exit) if (archive) archive.clear;

        if (auto item = archive.getFile("a_file_in_the_archive.txt"))
           (cast(char[])item.data).writeln;
    }

[PhysicsFS](https://icculus.org/physfs/)みたいなの

    import std.stdio;
    import d7z.util;

    void main()
    {
        auto mpr = new MountPointRoot;
        scope(exit) if (mpr) mpr.clear;

        mpr.mount("sample.7z", "/");

        if (auto item = mpr.search("/a_file_in_the_archive.txt"))
           (cast(char[])item.data).writeln;
    }

謝辞
----
* このライブラリは [D Programming Language](http://dlang.org/)
  で記述されています。
* [7zip](http://7-zip.org/) を利用する為のライブラリです。


ライセンス
----------
[CC0](https://creativecommons.org/publicdomain/zero/1.0/)

(7zxa.dll は GNU LGPLです。)

今後の方針
----------
* Windows以外の環境に対応する。

* d7z.util の拡充。(現在できるのは伸張のみ)


ヴァージョン
------------
UNDER CONSTRUCTION.(dmd2.069.0)

履歴
----
* 2015-12-01 ver.UC 初代
