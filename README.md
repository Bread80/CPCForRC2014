CPC For RC2014
===

CPC For RC2014 is a project to run the firmware from an Amstrad CPC on an RC2014.

Initial work done by Mike Sutton - http://bread80.com
Portions copyright © Stephen C Cousins and used with kind permission - https://smallcomputercentral.wordpress.com/small-computer-monitor/
Portions copyright © Amstrad Consumer Electonics plc and Locomotive Software.
'RC2014' is a trademark of RC2795 Ltd - https://rc2014.co.uk

****
NOTICE
This is temporary initial release of the 'pageable ROM' edition. The 512k ROM/RAM still needs tweaking and testing and should be out in a few day
****

Contents
---
1. Introduction
2. Quick Start Guides
    a) Installing: Flat memory model for standard or pageable ROM boards
    b) Installing: Flat memory model for 512Kb ROM/512Kb RAM board
3. Why the Amstrad CPC?
4. Amstrad Hardware Versus RC2014 Hardware
5. Changes to the CPC Firmware
    a) Changes to the Kernel
    b) Changes to the Machine Pack
    c) Changes to the Keyboard Manager
    d) Changes to the Text VDU
    e) The Serial Port
    f) The Mini-Terminal
6. Changes affecting BASIC
7. Uploading Files
8. Building Custom Variants
9. Getting to Known CPC BASIC (aka Links)
10. Known Issues
11. Contact Info
12. Licence


1. Introduction

CPC For RC2014 is a version of the firmware for an Amstrad CPC which has been adapted to run on an RC2014. This enables 'well behaved' software to run unmodified on the RC2014. 'Well behaved' here refers to software which accesses the machine through the firmware 'jumpblocks'. In particular this enables the Amstrad/Locomotive BASIC to run on an RC2014 with zero modifications needed.

The default CPC For RC2014 software maps keyboard input and text output to use the serial ports of the RC2014. Features which are not available on the majority of RC2014s, such as graphics, sound and cassette I/O have been removed. However hooks have been retained to enable such features to be (re)added should you so wish. This would, presumably, require custom driver software to be written.

The current status of the project is as follows:
* All variants use a 'flat' memory model with no banking available. The lower of 15k of memory space is reserved for the firmware ROM, the upper 16k for BASIC (or other) ROM and the middle 32k used as RAM.
* Software which requires RAM below address &4000 will fail (which precludes most software loaded from tape/disc). But ROM software should work.
* There is currently no support for discs (or indeed cassettes) so data can't be loaded or saved. The work around for this is to cut/paste code into the serial terminal and retrieve listings or output from the terminal log file.
* Most commercial games access the hardware directly, especially the video RAM, and will fail.

Full details of the system, included issues to be aware of is given below. But, for now, lets get you up and running.

2. Quick Start Guides
---
This section is aimed at getting you up and running with one of the default configurations. If none of these are suitable, or you want to customise your copy, see the section on building custom variants.

a) Installing: Flat memory model for standard or page-able ROM boards
---
This variant runs on the 'basic' ROM boards. It requires a 16Kb ROM at memory locations &0000 to &3fff for the firmware and the rest of memory space to be occupied by RAM. BASIC (or other software) will need to be downloaded every time the machine is run [On the Amstrad ROMs need to run at addresses &c000 onwards].

The firmware has been patched so that the lowest address used by ROMs is &4000. Since ROMs (i.e. BASIC) occupy memory addresses from &c000 to &ffff this leaves the middle 32Kb available for system variables and user programs. Note that some software may not respect the 'lowmem' value passed by the firmware and still attempt to use memory addresses below &4000 which, of course, will fail :(

This has the additional downside that the BASIC 'ROM' is now located in RAM at the address range normally occupied by the video memory, and anything which writes directly to video memory will trash the ROM! Take care. [The CPC For RC2014 firmware has been patched to remove any writes to video memory. All text goes to the serial port and graphics, screen clearing etc has been removed].

So, the first step is to burn the firmware to your ROM. You'll need the file 'flat.bin'.
Install the ROM and boot your RC2014. You should see the mini-terminal prompt.
Now cut/paste (or drag/drop depending on your terminal software) the 'BASIC1.1.hex' file. This is pre-configured to download to the correct address.

If all went well hit the ESCape key to launch BASIC.

You're now free to explore...

(If you had problems, or if the upload is especially slow see the section on Uploading Files).

Oh, future me here.
You may want to check your hardware setup is correct.
On the Pageable ROM board, you'll need the 16k bank size setting. If you're using a 28C256 (32Kb) EEPROM (recommended) then configure the A14 jumper 'high' and the A15 jumper 'low' (no other address jumpers fitted).
On the 64k ROM board you'll need to configure it for base address of &4000, and paging off. If you have problems here, try a custom build with '-Dmem_base=$8000' (or uncomment in Main.asm). This builds a version which only uses RAM above &8000.
For official documentation see:
https://rc2014.co.uk/modules/64k-ram/
https://rc2014.co.uk/modules/pageable-rom/

b) Installing: Flat memory model for 512Kb ROM/512Kb RAM board
---
This variant runs on the lovely 512Kb RAM/512Kb ROM module. See https://rc2014.co.uk/modules/512k-rom-512k-ram-module/

This 'flat' memory model variant doesn't enable any of the CPCs ROM or RAM paging features. Instead it gives a firmware in ROM permanently loaded at addresses &0000 to &3ffff, a ROM (e.g. BASIC) in either RAM or ROM (with a custom build) at addresses &c000 to &ffff and RAM occupying the central 32Kb of memory.

Beyond the comments here this variant is mostly the same as the flat memory model for standard ROM boards given above and you should read that section as well as this.

The source code contains constants to specify the default memory blocks to use for the ROMs and RAM. These are documented in the Main.asm file.

To install this variant you'll need to burn the file 'k512flat.bin' to your flash ROM, in the ROM bank given in the main.asm file for 'lowrompage' (bank 0 at the time of writing). You could also change this to a RAM bank and upload the firmware before each run.

After this you can download BASIC (or other ROM) to RAM on startup as detailed in section 2a). The RAM bank which will be used is specified in the main.asm file as 'upperromstart'.

You can also burn the BASIC (or other) ROM to a flash ROM page and modify the 'upperromstart' setting to suit.

It's also worth noting the RAM settings in the build. CPC For RC2014 will use four RAM banks starting with that defined as 'ramstart'. (Note that this flat memory version won't actually use the first page, but it is put in place ready for when banking support is added).

3. Why the Amstrad CPC?
---
The CPC used a firmware which is more modular than that on many computers of the era. On the CPCs there were two 16Kb ROMs. The lower ROM handled driving the hardware, the upper ROM contained the BASIC. All calls to ROM where through well documented 'jumpblocks'.

These jumpblocks gave access to almost all of the systems hardware, as well as including many routines for higher level features. This made it easy for developers in machine code, or other languages, to fully use the features available on the computer.

The jumpblocks also mean the the firmware can easily be patched to supplement or replace the built in features.

The RC2014 ecosystem encourages users to install a variety of hardware modules, including developing their own. The Amstrad firmware makes it easy to add code for additional hardware by patching these jumpblocks. The software support can either be built into a custom ROM, patched into jumpblocks at run time, or support added via 'RSX' commands - extension commands which can easily be called from BASIC or other software.

The built in Amstrad/Locomotive BASIC has broad support for the Amstrad hardware such as graphics, sound and interrupts. This makes is feasible for anyone developing such hardware to add support via the ROM/jumpblocks and have it automatically be available in BASIC.

The Amstrad firmware also has built in support for ROM banking, whether as 'foreground' ROMs (such as the built in BASIC), utility ROMs with support routines or 'sideways' ROMs with a single foreground ROM spread over up to four ROMs. In these days of cheap memory this makes it possible to include plenty of software in a system with suitable hardware.

4. Amstrad Hardware Versus RC2014 Hardware
---
There are a few differences between the RC2014 hardware and the Amstrad hardware which it would be wise to understand.

As mentioned above the Amstrad ROMs sit at addresses below &4000 and above &c000. The ROMs can be enabled and disabled independently. When disabled the memory regions they occupy are replaced with RAM. This is obviously at odds with many RC2014 systems which have a fixed ROM starting at &0000 and no higher ROM. Some RC2014 ROM boards have the ability to switch the lower ROM out of the system and use RAM instead but this is not currently supported by CPC For RC2014.

The built in BASIC has support for changing the 'low-memory' (start of available RAM) address (via a parameter sent from the firmware). Other software may not behave correctly with a different low memory address. And, of course, much software will only run if loaded at a lower memory address.

ROM software (such as the BASIC ROM) can be loaded into RAM at a suitable address (above &c000) but care needs to be taken to ensure the code doesn't get trashed by memory writes to these locations. (The RAM in this are is used as video RAM on the CPC, so software which writes directly to video memory is the biggest risk here. And, of course, the standard video memory is not supported by RC2014 hardware anyway).

It's also worth noting that on a CPC writes to areas occupied by ROM *always* write to RAM, even if a ROM is currently enabled. As far as I can tell the only time this is an issue with the firmware is when reading from cassette, so this shouldn't be a big issue. Upper ROMs which write directly to video memory will have an issue as described above.

5. Changes to the CPC Firmware - General
---
This section describes changes made to the CPC Firmware to enable it to run on RC2014 hardware and to remove unsupported features.

Note that unsupported firmware routines have been left as stubs usually with a single RETurn instruction. This allows the code relating to the jumpblocks to be left unmodified, should allow code to call the routines without major issue, and enables replacement code to be patched back in more easily. There may be situations where the code which calls a firmware routine requires a certain return flag or parameter value in order to behave (i.e. not crash). Thus some routines may need some minimal code adding.

The routines for the Graphics VDU, Sound Manager and Cassette Manager have been totally removed (except as described above).

The Screen Pack has been removed except for minimal support for initialising the VT100 serial output and changing screen modes.

a) Changes to the Kernel
---
The Kernel code in ROM has been retained as-is except for the removal of KL_BANK_SWITCH (which handles RAM banking on machines with more than 128Kb of RAM). Most of this Kernel code deals with interrupts, which a default RC2014 build doesn't support, but some of this is used by the CPC, most notably the break-key mechanism in BASIC which uses synchronous interrupts. Since this code only accepts inputs (i.e. the interrupts) leaving the code in place means that it will still be there for anyone who's system does generate them.

If you have an interrupt generator, the CPC generates 300 interrupts per second, which is the recommended frequency to ensure the timer and other operations happen as intended.

The High Kernel Jumpblock - a section of the firmware which is copied into RAM and which mostly handles memory banking - has been patched to remove any code which outputs to the hardware but is otherwise retained intact to avoid any compatibility issues. The other change is a patch to KL_POLL_SYNCRONOUS (sic) such that every invocation calls serial_to_buffer to read the serial port. This is because the keyboard break mechanism makes use of interrupts and would fail without them. KL_POLL_SYNCRONOUS is called by BASIC at the start of every statement. Patching into this routine ensures the break key is handled properly (by BASIC) at the expense of slowing the system slightly. This behaviour can be removed by defining the 'interrupts' symbol.

If modifying the High Kernel Jumpblock bear in mind there are strict size limits for the target code which need to be observed.

b) Changes to the Machine Pack
---
The sections of the Machine Pack which deal directly with the hardware have been removed, which includes keyboard scanning and controlling the gate array. Routines related to printers has also been removed. Other parts deal with booting programs and displaying the start up message and have been modified accordingly. In particular code has been added to initialise the serial ports, boot into the mini-terminal and (on the 512Kb ROM/RAM variant) to initialise the memory model.

c) Changes to the Keyboard Manager
---
The Keyboard Manager has seen some big changes to fetch input from the serial port instead of the keyboard. KM_READ_CHAR has been patched to call serial_to_buffer which reads any characters available on the serial port and translates them into a suitable format for the CPCs existing keyboard buffer (which stores keys rather than characters). Routines which call KM_READ_CHAR, such as KM_WAIT_CHAR, will still work. Routines which operate at a lower level will fail. In particular routines which test whether specific keys are pressed will fail. The chief effect of this is that KM_TEST_KEY will fail, and thus the INKEY function in BASIC will fail (but INKEY$ will still work since it calls KM_READ_CHAR).

This serial port reading code handles a number of escape sequences and other characters send to the serial port (tested using TeraTerm) and maps them to simulate appropriate CPC keys. The tables use for this are found in the Keyboard.asm file starting at char_to_cpc_table and can, of course, be modified to suit your taste.

The escape sequences I've found to be sent by TeraTerm are:
ESC [ c     (where c is an ASCII letter 'A' to 'D') are sent by the cursor keys and mapped to cursor keys
ESC [ n ~   (where n is an ASCII number '1' to '6') are sent by Home, Insert/Overwrite, End, PgUp and PgDn and have been mapped suitably. Note that the '3' variant is sent by certain function keys and not translated.
ESC O c     (where c is an ASCII letter) are sent by numeric keypad NumLock / * - keys. I've mapped them to Shift Lock and the corresponding symbols respectively. They could, of course, be mapped to other keys and I'd suggest the 'expansion tokens' &80 to &8C which are normally CTRL-<numeric keypad> on the CPC (an example of which is the CTRL-Small Enter which expands to RUN"<Enter>).

d) Changes to the Text VDU
---
The Text VDU has also undergone significant change to redirect output to the serial port. Features no longer available relate to changing character matrices (user defined characters), reading characters from the screen, text writing modes (AND, OR, XOR etc) and inverse text. Cursor positioning and cursor enable/disable have been mapped to VT100 commands as have setting pen and paper colours. Streams and windows are still enabled but windows smaller than the entire screen cannot be scrolled. Control codes are still functional where relevant. CPC ink colours are mapped to VT100 colours. I haven't attempted to map all of the CPCs 16 default ink colours. If you want to update this there is a table at cpc_ink_to_serial_ink_table in Text.asm.

e) The Serial Port
---
Text output and keyboard input is redirected to/from the serial port as described above. By default SIO port A is used for both input and output. The labels input_serial_port and output_serial_port in the file Main.asm can be used to change one or both to using serial port B.

The CPC specific serial port code can be found in the file CPCSerial.asm along with a number of utility routines. The actual serial port driver is in the file SerialSIO2.asm which comes from Stephen C Cousin's SCM (Small Computer Monitor) and is used with kind permission.

f) The Mini-Terminal
---
A mini terminal is included which can be used to download binary files onto the machine. The terminal runs at startup, and can also be called from BASIC using the |TERM command. It can also be called from machine code via the KL_FIND_COMMAND system call.

The following options are available in the terminal:
* Drag and drop (or cut and paste depending on your terminal software) an Intel hex file. This will be stored at the location specified in the hex file.
* Type ?<enter> to see help text.
* Press ESCape to return from the terminal. When there terminal is run at start-up ESC continues with the boot up and enters whatever foreground ROM is available (even if running in RAM). So, once you've uploaded a ROM image (as above) just hit ESC to boot into it. If you have suitable hardware, a ROM image installed, and the build options are selected to map it into memory then, again, just hit ESC to boot into it. When called via the |TERM command ESC returns to the caller (eg. BASIC).
* Type r<enter> to boot (or reboot) into the available foreground ROM (similar to using ESC at boot up). Note that, if called via the |TERM command this option will delete any existing programs and data (CPC BASIC has no warm boot option).

To encode and upload other files see the section Uploading Files.

The BASIC ROM image is a large file and you may want to configure your terminal settings to speed things up. See the section Uploading Files for more details.

6. Changes affecting BASIC
---
The CPC For RC2014 firmware can use an existing BASIC ROM image with zero modifications. It is worth, however, bearing a few issues in mind when using it.

Firstly, and most obviously, any features not available on the RC2014 will not be available in BASIC. Details of these is given in the section "Changes to the CPC Firmware". The real effect here is that some features may expect certain return values from the firmware, and not having the firmware routines could cause instability. In other words: be careful using features which aren't available just in case.

Having said that I wouldn't expect problems in the vast majority of cases. Keyboard input routines have been patched, and most other stuff should just be ignored by BASIC.

As mentioned previously there is no way to load and save programs on the RC2014. The best way you 'load' software is to drag/drop (or cut/paste) it into the terminal window. If you do so, the BASIC interpreter is pretty slow at processing the input lines and you'll need to configure your terminal with a delay. See the section Uploading Files for details.

To 'save' software you can retrieve a listing from your terminal logs. Not ideal, but workable. You may find it convenient to write your code in a text editor and paste it across to the RC2014. When editing you can, of course, just paste across sub-sections of code. Any existing lines on the CPC will be replaced. The DELETE command in BASIC can delete a range of lines, or you can delete a single line by entering the line number and pressing <enter>.

7. Uploading Files
---
I find it useful to tweak the Transmit Delay settings in my terminal software (Tear Term) when using CPC For RC2014. The setting can be found under the menu item Setup/Serial port...

When uploading binaries (ie. HEX files) such as the BASIC ROM it's best to change the delay settings to 0 for a faster download.

When uploading BASIC program listing it's best to add a Transmit Delay to give BASIC time to process each character as it arrives. I find a setting of 1msec/char works fine.

BASIC code listings can be uploaded as text files by dragging and dropping them onto the terminal (if using Tera Term). You can also use the menu item File/Send file...

To upload binary files you'll need to convert them to Intel HEX files first.

To build an Intel hex file for uploading you can use the srec_cat software from http://srecord.sourceforge.net

The following line will convert the rasmoutput.bin file to the file output.hex in Intel hex with an upload address of 49152 ($c000) - the appropriate address for an upper ROM image.
srec_cat rasmoutput.bin -binary -offset 49152 -o output.hex -intel

CPC For RC2014 will detect the 'offset' setting in the file and write the uploaded data into memory beginning at that location.

You can, of course, change the 'offset' setting to something more suitable for other files.

Finally, in order to be able to upload a hex file, you'll need to be running the Mini-Term software on the RC2014. This runs at start up or at any other time using the |TERM command. For more details see The Mini-Terminal section.

8. Building Custom Variants
---
CPC For RC2014 has been coded for the RASM assembler. You can download binaries at https://github.com/EdouardBERGE/rasm/releases
For more information see the thread at https://www.cpcwiki.eu/forum/programming/rasm-z80-assembler-in-beta/ 

You may want to add rasm to your search path/environment variables, if so a web search will draw up instructions for your operating system.

Available build settings for CPC For RC2014 are in the file Main.asm

A windows batch file is included, build.bat, which will build all variants. For worked examples of how to pass build setting to the assembler, consult the build.bas file.

To build the project use the command line:
rasm main.asm

This will produce an output file with the default name rasmoutput.bin

To pass in a build setting use the -D parameter. Many build settings are either defined or not. For these any 'value' can be passed, although '1' is recommended. This example also sets the output file name.
rasm main.asm -Dflat=1 -ob flat.bin

Binary files can be burned to ROM in the usual way.

To convert the file to Intel Hex format (for sending over a serial link), use the srec_cat utility. The -offset parameter is the address the file will be uploaded to. Thus, 0x0000 is the appropriate value for a firmware ROM image, 0xc000 would be appropriate for an upper ROM image. (If you intend to move the data once uploaded, adjust the value to suit). The -o parameter specifies the output file name. An example is:
srec_cat flat.bin -binary -offset 0x0000 -o flat.hex -intel

9. Getting to Know CPC BASIC (aka Links)
---
If you're new to the Amstrad and it's flavour of BASIC then it's worthwhile giving a quick introduction and a few pointers to other resources.

The best general resource for anything Amstrad related is https://www.cpcwiki.eu/ which hosts both a wiki and forums. The page https://www.cpcwiki.eu/index.php/Locomotive_BASIC gives a quick primer on Locomotive BASIC and a (mostly complete) command reference.

If you want something more instructional you can find the original user manuals at https://www.cpcwiki.eu/index.php/User_Manual

For machine code programming https://www.cpcwiki.eu/index.php/BIOS_Functions provides a summary of the available routines and https://www.cpcwiki.eu/index.php/Soft968:_CPC_464/664/6128_Firmware is the online OCR'd version of the full, official, firmware guide.

You can also find a primer on the Amstrad firmware and it's capabilities in the original firmware source code repository that this one derives from at https://github.com/Bread80/CPC6128-Firmware-Source

10. Known Issues
---
* When using the BASIC line editor you may notice some flicker as the line is reprinted. This is down to the cursor since, currently, each character is 'drawn' by positioning the cursor (serial port command) and sending the character over the serial port. This is because that's how it's done on the CPC and the added code simply maps any cursor positioning operations to VT100 codes. It may be possible to track the cursor position and only send the terminal command if the new position doesn't match the tracked one? Failing that, possibly the cursor could be turned off during the rewrites.
* Sometimes cursor positioning (i.e. the LOCATE command in BASIC) doesn't give quite the expected output. This is something I've noticed but not investigated so I've no idea why or how badly it affects things.

11. Contact Info
---
If you've made it this far, thank you, and I hope it all made sense.

If you have any feedback (i.e bug reports <g>) the best place to find me is on twitter: @Bread80com
I also hang out on the CPC wiki forum: https://www.cpcwiki.eu/forum/ and the official RC2014 group: https://groups.google.com/g/rc2014-z80



12. Licence
---
The object code in this repository is the copyright of Amstrad Consumer Electronics Plc and Locomotive Software Ltd. I understand that redistributing and modifying the code is allowed, provided that relevant copyright messages are retained and you don't charge for the software.

This repository is built on the work of those who did the original disassembly and reverse engineering. I don't know the names of those individuals or their licensing terms.

My own work is covered by the Unlicence - https://opensource.org/licenses/unlicense


