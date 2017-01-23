unit AspenSyntaxTree;

interface

uses SysUtils, Generics.Collections;

type TSingleType = class (TObject)
  protected
    fValue: Single;
  public
    function Value: Single;
    constructor Create(Value: Single);
end;

type
  TAbstractNode = class;
  TAbstractNodeChildrenEnumerator = class;

  { Implemented by the TAbstractNode class so that we can use Delphi's
    for..in loop. We explicitly make the process type stronger by
    requiring a new Add() method to be implemented; }
  IAbstractNodeChildrenEnumerator = interface
  ['{4ACB6E5C-1835-4458-B83F-EC2EDF10A171}']
    function GetCurrent: TAbstractNode;
    function MoveNext: Boolean;
    property Current: TAbstractNode read GetCurrent;
    procedure Add(Element: TAbstractNode);
  end;

  TAbstractNodeChildrenEnumerator = class (TInterfacedObject,
      IAbstractNodeChildrenEnumerator)
    private
      fIndex: Integer;
      fRefList: TList<TAbstractNode>;
    public
      { IAbstractNodeChildrenEnumerator }
      function GetCurrent: TAbstractNode;
      function MoveNext: Boolean;
      property Current: TAbstractNode read GetCurrent;

      procedure Add(Element: TAbstractNode);

      constructor Create;
      destructor Destroy; override;
  end;

  TAbstractNode = class abstract (TInterfacedObject)
    protected
      fParent: TAbstractNode;
    public
      function GetEnumerator: TAbstractNodeChildrenEnumerator;

      procedure PrepareEnumerator(Enumerator: TAbstractNodeChildrenEnumerator); virtual; abstract;

      function HasChildren: Boolean; virtual; abstract;
      function SupportsChildren: Boolean; virtual; abstract;
      function RequiredChildren: Integer; virtual; abstract;
      function Count: Integer; virtual; abstract;

      { Returns an evaluated result not managed by this class! }
      function Evaluate: TSingleType; virtual; abstract;
      procedure Clear; virtual; abstract;

      function HasParent: Boolean;
      function Parent: TAbstractNode;

      destructor Destroy; override;
  end;

type TTerminalNode = class (TAbstractNode)
  protected
    fValue: TSingleType;
    fValueIsManaged: Boolean;
  public
    procedure PrepareEnumerator(Enumerator: TAbstractNodeChildrenEnumerator); override;

    function HasChildren: Boolean; override;
    function SupportsChildren: Boolean; override;
    function RequiredChildren: Integer; override;
    function Count: Integer; override;
    function Evaluate: TSingleType; override;
    procedure Clear; override;

    constructor Create(Value: TSingleType);
    constructor CreateFromPrimitive(Value: Single);
    destructor Destroy; override;
end;

type TBinaryNode = class abstract (TAbstractNode)
    protected
      fLeftNode: TAbstractNode;
      fRightNode: TAbstractNode;
  public
    procedure PrepareEnumerator(Enumerator: TAbstractNodeChildrenEnumerator); override;

    function HasChildren: Boolean; override;
    function SupportsChildren: Boolean; override;
    function RequiredChildren: Integer; override;
    function Count: Integer; override;
    function Evaluate: TSingleType; override;
    procedure Clear; override;

    function ComputeSpecifics(A, B: TSingleType): TSingleType; virtual; abstract;

    procedure AddLeftNode(Node: TAbstractNode);
    procedure AddRightNode(Node: TAbstractNode);
    function LeftNode: TAbstractNode;
    function RightNode: TAbstractNode;

    constructor Create; overload;
    constructor Create(Left, Right: TAbstractNode); overload;
end;

type TAspenEvaluationError = class (Exception);

implementation

function TSingleType.Value: Single;
begin
  Result := fValue;
end;

constructor TSingleType.Create(Value: Single);
begin
  fValue := Value;
end;

function TAbstractNodeChildrenEnumerator.GetCurrent: TAbstractNode;
begin
  Result := fRefList[fIndex];
end;

function TAbstractNodeChildrenEnumerator.MoveNext: Boolean;
begin
  Inc(fIndex);
  Result := fIndex < fRefList.Count;
end;

procedure TAbstractNodeChildrenEnumerator.Add(Element: TAbstractNode);
begin
  fRefList.Add(Element);
end;

constructor TAbstractNodeChildrenEnumerator.Create;
begin
  fRefList := TList<TAbstractNode>.Create;
  fIndex := -1;
end;

destructor TAbstractNodeChildrenEnumerator.Destroy;
begin
  fRefList.Free;
end;

function TAbstractNode.GetEnumerator: TAbstractNodeChildrenEnumerator;
var
  Enumerator: TAbstractNodeChildrenEnumerator;
begin
  Enumerator := TAbstractNodeChildrenEnumerator.Create;
  PrepareEnumerator(Enumerator);

  Result := Enumerator;
end;

function TAbstractNode.HasParent: Boolean;
begin
  Result := nil <> fParent;
end;

function TAbstractNode.Parent: TAbstractNode;
begin
  Result := fParent;
end;

destructor TAbstractNode.Destroy;
begin
  Clear;
  inherited;
end;

procedure TTerminalNode.PrepareEnumerator(Enumerator: TAbstractNodeChildrenEnumerator);
begin
  ;
end;

function TTerminalNode.HasChildren: Boolean;
begin
  Result := False;
end;

function TTerminalNode.SupportsChildren: Boolean;
begin
  Result := False;
end;

function TTerminalNode.RequiredChildren: Integer;
begin
  Result := 0;
end;

function TTerminalNode.Count: Integer;
begin
  Result := 0;
end;

function TTerminalNode.Evaluate: TSingleType;
begin
  Result := TSingleType.Create(fValue.Value);
end;

procedure TTerminalNode.Clear;
begin
  ;
end;

constructor TTerminalNode.Create(Value: TSingleType);
begin
  fValue := Value;
end;

constructor TTerminalNode.CreateFromPrimitive(Value: Single);
var
  NewValue: TSingleType;
begin
  NewValue := TSingleType.Create(Value);
  fValue := NewValue;
  fValueIsManaged := True;
end;

destructor TTerminalNode.Destroy;
begin
  if (fValueIsManaged) then
    fValue.Free;
  inherited;
end;

procedure TBinaryNode.PrepareEnumerator(Enumerator: TAbstractNodeChildrenEnumerator);
begin
  if Assigned(fLeftNode) then
    Enumerator.Add(fLeftNode);

  if Assigned(fRightNode) then
    Enumerator.Add(fRightNode);
end;

function TBinaryNode.HasChildren: Boolean;
begin
  Result := (nil <> fLeftNode) or (nil <> fRightNode);
end;

function TBinaryNode.SupportsChildren: Boolean;
begin
  Result := True;
end;

function TBinaryNode.RequiredChildren: Integer;
begin
  Result := 2;
end;

function TBinaryNode.Count: Integer;
begin
  Result := Ord(nil <> fLeftNode) + Ord(nil <> fRightNode);
end;

function TBinaryNode.Evaluate: TSingleType;
var
  ValueA, ValueB: TSingleType;
  Evaluation: TSingleType;
begin
  if (Self.Count = Self.RequiredChildren) then begin
    { It's very important to note that all Evaluation()
      calls return objects that we are responsible for freeing }
    try
      ValueA := fLeftNode.Evaluate;
      ValueB := fRightNode.Evaluate;

      Evaluation := ComputeSpecifics(ValueA, ValueB);
      Result := Evaluation;
    finally
      ValueA.Free;
      ValueB.Free;
    end;
  end else
    raise TAspenEvaluationError.Create
      ('Not enough nodes are present to evaluate.');
end;

procedure TBinaryNode.Clear;
begin
 if Assigned(fLeftNode) then
    FreeAndNil(fLeftNode);

  if Assigned(fRightNode) then
    FreeAndNil(fRightNode);
end;

procedure TBinaryNode.AddLeftNode(Node: TAbstractNode);
begin
  fLeftNode := Node;
end;

procedure TBinaryNode.AddRightNode(Node: TAbstractNode);
begin
  fRightNode := Node;
end;

function TBinaryNode.LeftNode: TAbstractNode;
begin
  Result := fLeftNode;
end;

function TBinaryNode.RightNode: TAbstractNode;
begin
  Result := fRightNode;
end;

constructor TBinaryNode.Create;
begin
  fLeftNode := nil;
  fRightNode := nil;
end;

constructor TBinaryNode.Create(Left, Right: TAbstractNode);
begin
  fLeftNode := Left;
  fRightNode := Right;
end;

end.
