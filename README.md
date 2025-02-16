# LibRAW-for-Delphi-Lazarus-Free-Pascal
Reading Camera RAW using LibRAW withr Delphi, Lazarus, Free Pascal

Requires .DLL files (included). For Linux and MacOS you need to download binaries from libraw project.

## Usage examples

### Using TImage / TPicture

    Image1.Picture.LoadFromFile('test.raw');
    Image1.Picture.LoadFromFile('test.dng');

# Tested under 64 bit Lazarus

Should work under other 64 bit Delphis.
Needs tests under 32 bit Lazarus and 32 bit Delphi.

## This unit uses libraw.DLL

https://www.libraw.org

 LibRaw is distributed for free under two different licenses:
- GNU Lesser General Public License, version 2.1
- COMMON DEVELOPMENT AND DISTRIBUTION LICENSE (CDDL) Version 1.0

## Supported formats
Pretty much every camera raw format should work.

- .3fr (Hasselblad)
- .arw, .srf, .sr2 (Sony)
- .bay (Casio)
- .cap, .cs1 (Capture One)
- .crw, .cr2, .cr3 (Canon)
- .dcr, .dcs, .drf, .k25, .kdc (Kodak)
- .dng (Adobe/Generic, used by Leica, Ricoh, etc.)
- .erf (Epson)
- .iiq (Phase One)
- .mef (Mamiya)
- .mos (Leaf)
- .mrw (Minolta)
- .nef, .nrw (Nikon)
- .orf (Olympus/OM System)
- .pef, .ptx (Pentax)
- .raf (Fujifilm)
- .raw, .rwl (Leica/Panasonic)
- .rw2 (Panasonic/Leica)
- .srw (Samsung)
- .x3f (Sigma)
