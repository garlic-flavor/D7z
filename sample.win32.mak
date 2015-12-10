## MACRO
TARGET = sample.exe
DC = dmd
MAKE = make
MAKEFILE = sample.mak
TO_COMPILE = src\d7z\util.d src\d7z\binding\enums.d src\d7z\binding\functions.d src\d7z\binding\loader.d src\d7z\binding\mywindows.d src\d7z\binding\package.d src\d7z\binding\types.d src\d7z\callbacks.d src\d7z\misc.d src\d7z\propvariant.d src\d7z\streams.d
TO_LINK = src\d7z\util.obj src\d7z\binding\enums.obj src\d7z\binding\functions.obj src\d7z\binding\loader.obj src\d7z\binding\mywindows.obj src\d7z\binding\package.obj src\d7z\binding\types.obj src\d7z\callbacks.obj src\d7z\misc.obj src\d7z\propvariant.obj src\d7z\streams.obj
COMPILE_FLAG = -debug=d7z_util -version=Unicode -version=WindowsVista -Isrc
LINK_FLAG =
EXT_LIB =
DDOC_FILE =
DOC_FILES = src\d7z\util.html src\d7z\binding\enums.html src\d7z\binding\functions.html src\d7z\binding\loader.html src\d7z\binding\mywindows.html src\d7z\binding\package.html src\d7z\binding\types.html src\d7z\callbacks.html src\d7z\misc.html src\d7z\propvariant.html src\d7z\streams.html
DOC_HEADER =
DOC_FOOTER =
DOC_TARGET = index.html
FLAG =

## LINK COMMAND
$(TARGET) : $(TO_LINK)
	$(DC) -g -debug $(LINK_FLAG) $(FLAG) $(EXT_LIB) -of$@ $**

## COMPILE RULE
.d.obj :
	$(DC) -c -g -op -debug $(COMPILE_FLAG) $(FLAG) $<

## DEPENDENCE
$(TO_LINK) : $(MAKEFILE) $(EXT_LIB)
src\d7z\util.obj : src\d7z\binding\package.d src\d7z\streams.d src\d7z\util.d src\d7z\propvariant.d src\d7z\callbacks.d src\d7z\misc.d
src\d7z\binding\enums.obj : src\d7z\binding\enums.d src\d7z\binding\types.d
src\d7z\binding\functions.obj : src\d7z\binding\functions.d src\d7z\binding\types.d
src\d7z\binding\loader.obj : src\d7z\binding\loader.d src\d7z\binding\functions.d src\d7z\binding\types.d
src\d7z\binding\mywindows.obj : src\d7z\binding\mywindows.d
src\d7z\binding\package.obj : src\d7z\binding\package.d src\d7z\binding\enums.d src\d7z\binding\functions.d src\d7z\binding\loader.d src\d7z\binding\mywindows.d src\d7z\binding\types.d
src\d7z\binding\types.obj : src\d7z\binding\mywindows.d src\d7z\binding\types.d
src\d7z\callbacks.obj : src\d7z\binding\package.d src\d7z\streams.d src\d7z\callbacks.d src\d7z\misc.d src\d7z\propvariant.d
src\d7z\misc.obj : src\d7z\misc.d src\d7z\binding\types.d
src\d7z\propvariant.obj : src\d7z\propvariant.d src\d7z\binding\types.d src\d7z\misc.d
src\d7z\streams.obj : src\d7z\streams.d src\d7z\binding\package.d src\d7z\misc.d

## PHONY TARGET
debug-all :
	$(DC) -g -debug -of$(TARGET) $(COMPILE_FLAG) $(LINK_FLAG) $(TO_COMPILE) $(EXT_LIB)  $(FLAG)
release :
	$(DC) -release -O -inline -L/exet:nt/su:windows:6.0 -of$(TARGET) $(COMPILE_FLAG) $(LINK_FLAG) $(TO_COMPILE) $(EXT_LIB)  $(FLAG)
clean :
	del $(TARGET) $(TO_LINK)
clean_obj :
	del $(TO_LINK)
vwrite :
	vwrite -ver="" -prj=$(TARGET) -target=$(TARGET) $(TO_COMPILE)
ddoc :
	$(DC) -c -o- -op -D $(COMPILE_FLAG) $(DDOC_FILE) $(TO_COMPILE) $(FLAG)
	@type $(DOC_HEADER) $(DOC_FILES) $(DOC_FOOTER) > $(DOC_TARGET) 2> nul
	@del $(DOC_FILES)
show :
	@echo ROOT = src\d7z\util.d
	@echo TARGET = $(TARGET)
	@echo VERSION =
run :
	$(TARGET) $(FLAG)
edit :
	emacs $(TO_COMPILE)
remake :
	amm -debug=d7z_util sample.mak sample.exe .\src\d7z\util.d $(FLAG)

debug :
	ddbg $(TARGET)

## generated by amm.