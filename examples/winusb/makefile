FLAGS = /EHa /O2 /WX- /W4 /nologo
WDK = "C:\Program Files (x86)\Windows Kits\8.1"
INCLUDES = /I $(WDK)\Include\um

# no addprefix in nmake
LIBS = $(WDK)\Lib\winv6.3\um\x86\winusb.lib \
       $(WDK)\Lib\winv6.3\um\x86\setupapi.lib

a.exe: main.c
	cl $(FLAGS) $(INCLUDES) /Fe$@ /TP $? /link $(LIBS)

clean:
	del a.exe
