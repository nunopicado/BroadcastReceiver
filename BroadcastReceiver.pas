unit BroadcastReceiver;

interface

{$IFDEF ANDROID}
uses
  Androidapi.JNI.Embarcadero, Androidapi.JNI.GraphicsContentViewText, Androidapi.helpers,
  Androidapi.JNIBridge, FMX.Helpers.Android, Androidapi.JNI.JavaTypes,
  System.Classes, System.SysUtils;

type
  TBroadcastReceiver = class;

  TListener = class(TJavaLocal, JFMXBroadcastReceiverListener)
  private
    fOwner: TBroadcastReceiver;
    fReceiver: JFMXBroadcastReceiver;
  public
    constructor Create(aOwner: TBroadcastReceiver);
    destructor Destroy; override;
    procedure onReceive(context: JContext; intent: JIntent); cdecl;
  end;


  TOnReceive = procedure (aContext: JContext; aIntent: JIntent; aResultCode: integer) of object;

  TBroadcastReceiver = class
  private
    fListener : TListener;
    fRegistered: boolean;
    fOnReceive: TOnReceive;
  public
    constructor Create(aOnReceiveProc: TOnReceive);
    destructor Destroy; override;
    procedure AddActions(const Args: array of JString);
    procedure SendBroadcast(const aValue: string);
  end;
{$ENDIF}

implementation

{$IFDEF ANDROID}

{ TBroadcastReceiver }

constructor TBroadcastReceiver.Create(aOnReceiveProc: TOnReceive);
begin
  inherited Create;
  fListener := TListener.Create(Self);
  fOnReceive := aOnReceiveProc;
end;

destructor TBroadcastReceiver.Destroy;
begin
  fListener.Free;
  inherited;
end;

procedure TBroadcastReceiver.AddActions(const Args: array of JString);
var
  vFilter: JIntentFilter;
  i: Integer;
begin
  if fRegistered then
    TAndroidHelper.context.getApplicationContext.UnregisterReceiver(fListener.fReceiver);

  vFilter := TJIntentFilter.JavaClass.init;
  for i := 0 to High(Args) do
    vFilter.addAction(Args[i]);

  TAndroidHelper.context.getApplicationContext.registerReceiver(fListener.fReceiver, vFilter);
  fRegistered := true;
end;

procedure TBroadcastReceiver.SendBroadcast(const aValue: string);
var
  Inx: JIntent;
begin
  Inx := TJIntent.Create;
  Inx.setAction(StringToJString(aValue));
  TAndroidHelper.Context.sendBroadcast(Inx);
end;

constructor TListener.Create(aOwner: TBroadcastReceiver);
begin
  inherited Create;
  fOwner := aOwner;
  fReceiver := TJFMXBroadcastReceiver.JavaClass.init(Self);
end;

destructor TListener.Destroy;
begin
  TAndroidHelper.context.getApplicationContext.unregisterReceiver(fReceiver);
  inherited;
end;

// usually android call it from "UI thread" - it's not main Delphi thread
procedure TListener.onReceive(context: JContext; intent: JIntent);
begin
  if Assigned(fOwner.fOnReceive) then
    fOwner.fOnReceive(Context, Intent, fReceiver.getResultCode);
end;

{$ENDIF}

end.
