unit RawImage;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Description:	Reader for Camera Raw images                                  //
// Version:	0.1                                                           //
// Date:	16-FEB-2025                                                   //
// License:     MIT                                                           //
// Target:	Win64, Free Pascal, Delphi                                    //
// Copyright:	(c) 2025 Xelitan.com.                                         //
//		All rights reserved.                                          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

interface

uses Classes, Graphics, SysUtils, Math, Types, Dialogs;

const LIB_RAW = 'libraw_r-23.dll';

type
  PLibRawProcessedImage = ^TLibRawProcessedImage;
  TLibRawProcessedImage = packed record
    imgtype: Integer;
    height: Word;
    width: Word;
    colors: Cardinal;
    bits: Cardinal;
    data_size: Cardinal;
    data: array[0..0] of Byte;
  end;

  function libraw_init: Pointer; cdecl; external LIB_RAW;
  function libraw_open_buffer(lr: Pointer; buffer: Pointer; size: NativeUInt): Integer; cdecl; external LIB_RAW;
  function libraw_unpack(lr: Pointer): Integer; cdecl; external LIB_RAW;
  function libraw_dcraw_process(lr: Pointer): Integer; cdecl; external LIB_RAW;
  function libraw_dcraw_make_mem_image(lr: Pointer; var errcode: Integer): Pointer; cdecl; external LIB_RAW;
  procedure libraw_dcraw_clear_mem(image: Pointer); cdecl; external LIB_RAW;
  procedure libraw_close(lr: Pointer); cdecl; external LIB_RAW;

  { TRawImage }
type
  TRawImage = class(TGraphic)
  private
    FBmp: TBitmap;
    FCompression: Integer;
    procedure DecodeFromStream(Str: TStream);
    //procedure EncodeToStream(Str: TStream);
  protected
    procedure Draw(ACanvas: TCanvas; const Rect: TRect); override;
  //    function GetEmpty: Boolean; virtual; abstract;
    function GetHeight: Integer; override;
    function GetTransparent: Boolean; override;
    function GetWidth: Integer; override;
    procedure SetHeight(Value: Integer); override;
    procedure SetTransparent(Value: Boolean); override;
    procedure SetWidth(Value: Integer);override;
  public
    procedure SetLossyCompression(Value: Cardinal);
    procedure Assign(Source: TPersistent); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

{ TRawImage }

procedure TRawImage.DecodeFromStream(Str: TStream);
var
  Handle: Pointer;
  Ret: Integer;
  Processed: PLibRawProcessedImage;
  ErrorCode: Integer;
  y, x: Integer;
  SrcPtr: PByte;
  P: PByteArray;
  Data: TBytes;
  DataSize: Integer;
begin
  Handle := libraw_init;
  if not Assigned(Handle) then
    raise Exception.Create('Failed to initialize LibRaw.');

  DataSize := Str.Size;
  SetLength(Data, DataSize);
  Str.Read(Data[0], DataSize);

  try
    Ret := libraw_open_buffer(Handle, @Data[0], DataSize);
    if Ret <> 0 then
      raise Exception.CreateFmt('Open_buffer error: %d', [Ret]);

    Ret := libraw_unpack(Handle);
    if Ret <> 0 then
      raise Exception.CreateFmt('Unpack error: %d', [Ret]);

    Ret := libraw_dcraw_process(Handle);
    if Ret <> 0 then
      raise Exception.CreateFmt('Process error: %d', [Ret]);

    Processed := libraw_dcraw_make_mem_image(Handle, ErrorCode);
    if not Assigned(Processed) then
      raise Exception.CreateFmt('Make_mem_image error: %d', [ErrorCode]);

    try
        FBmp.SetSize(Processed^.width, Processed^.height);

        for y:=0 to FBmp.Height-1 do begin
          SrcPtr := @Processed^.data + y * Processed^.width * 3;
          P := FBmp.ScanLine[y];

          for x:=0 to FBmp.Width-1 do begin
            P[4*x  ] := (SrcPtr + 2)^; // B
            P[4*x+1] := (SrcPtr + 0)^; // G
            P[4*x+2] := (SrcPtr + 1)^; // R
            P[4*x+3] := 0;

            Inc(SrcPtr, 3);
          end;
        end;
    finally
      libraw_dcraw_clear_mem(Processed);
    end;
  finally
    libraw_close(Handle);
  end;
end;

procedure TRawImage.Draw(ACanvas: TCanvas; const Rect: TRect);
begin
  ACanvas.StretchDraw(Rect, FBmp);
end;

function TRawImage.GetHeight: Integer;
begin
  Result := FBmp.Height;
end;

function TRawImage.GetTransparent: Boolean;
begin
  Result := False;
end;

function TRawImage.GetWidth: Integer;
begin
  Result := FBmp.Width;
end;

procedure TRawImage.SetHeight(Value: Integer);
begin
  FBmp.Height := Value;
end;

procedure TRawImage.SetTransparent(Value: Boolean);
begin
  //
end;

procedure TRawImage.SetWidth(Value: Integer);
begin
  FBmp.Width := Value;
end;

procedure TRawImage.SetLossyCompression(Value: Cardinal);
begin
  FCompression := Value;
end;

procedure TRawImage.Assign(Source: TPersistent);
var Src: TGraphic;
begin
  if source is tgraphic then begin
    Src := Source as TGraphic;
    FBmp.SetSize(Src.Width, Src.Height);
    FBmp.Canvas.Draw(0,0, Src);
  end;
end;

procedure TRawImage.LoadFromStream(Stream: TStream);
begin
  DecodeFromStream(Stream);
end;

procedure TRawImage.SaveToStream(Stream: TStream);
begin
//
end;

constructor TRawImage.Create;
begin
  inherited Create;

  FBmp := TBitmap.Create;
  FBmp.PixelFormat := pf32bit;
  FBmp.SetSize(1,1);
end;

destructor TRawImage.Destroy;
begin
  FBmp.Free;
  inherited Destroy;
end;

initialization
  TPicture.RegisterFileFormat('3fr', 'Hasselblad Raw', TRawImage);
  TPicture.RegisterFileFormat('arw', 'Sony Raw', TRawImage);
  TPicture.RegisterFileFormat('srf', 'Sony Raw', TRawImage);
  TPicture.RegisterFileFormat('sr2', 'Sony Raw', TRawImage);
  TPicture.RegisterFileFormat('bay', 'Casio Raw', TRawImage);
  TPicture.RegisterFileFormat('cap', 'Capture One Raw', TRawImage);
  TPicture.RegisterFileFormat('cs1', 'Capture One Raw', TRawImage);
  TPicture.RegisterFileFormat('crw', 'Canon Raw', TRawImage);
  TPicture.RegisterFileFormat('cr2', 'Canon Raw', TRawImage);
  TPicture.RegisterFileFormat('cr3', 'Canon Raw', TRawImage);
  TPicture.RegisterFileFormat('dcr', 'Kodak Raw', TRawImage);
  TPicture.RegisterFileFormat('dcs', 'Kodak Raw', TRawImage);
  TPicture.RegisterFileFormat('drf', 'Kodak Raw', TRawImage);
  TPicture.RegisterFileFormat('k25', 'Kodak Raw', TRawImage);
  TPicture.RegisterFileFormat('kdc', 'Kodak Raw', TRawImage);
  TPicture.RegisterFileFormat('dng', 'Camera Raw', TRawImage);
  TPicture.RegisterFileFormat('erf', 'Epson Raw', TRawImage);
  TPicture.RegisterFileFormat('iiq', 'Phase One Raw', TRawImage);
  TPicture.RegisterFileFormat('mef', 'Mamiya Raw', TRawImage);
  TPicture.RegisterFileFormat('mos', 'Leaf Raw', TRawImage);
  TPicture.RegisterFileFormat('mrw', 'Minolta Raw', TRawImage);
  TPicture.RegisterFileFormat('nef', 'Nikon Raw', TRawImage);
  TPicture.RegisterFileFormat('nrw', 'Nikon Raw', TRawImage);
  TPicture.RegisterFileFormat('orf', 'Olympus Raw', TRawImage);
  TPicture.RegisterFileFormat('pef', 'Pentax Raw', TRawImage);
  TPicture.RegisterFileFormat('ptx', 'Pentax Raw', TRawImage);
  TPicture.RegisterFileFormat('raf', 'Fujifilm Raw', TRawImage);
  TPicture.RegisterFileFormat('raw', 'Panasonic Raw', TRawImage);
  TPicture.RegisterFileFormat('rwl', 'Panasonic Raw', TRawImage);
  TPicture.RegisterFileFormat('rw2', 'Panasonic Raw', TRawImage);
  TPicture.RegisterFileFormat('srw', 'Samsung Raw', TRawImage);
  TPicture.RegisterFileFormat('x3f', 'Sigma Raw', TRawImage);

finalization
  TPicture.UnregisterGraphicClass(TRawImage);

end.
