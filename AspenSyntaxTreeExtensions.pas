unit AspenSyntaxTreeExtensions;

interface

uses AspenSyntaxTree;

type TBinAdditionNode = class (TBinaryNode)
  public
    function ComputeSpecifics(A, B: TSingleType): TSingleType; override;
end;

type TBinSubtractionNode = class (TBinaryNode)
  public
    function ComputeSpecifics(A, B: TSingleType): TSingleType; override;
end;

implementation

function TBinAdditionNode.ComputeSpecifics(A, B: TSingleType): TSingleType;
begin
  Result := TSingleType.Create(A.Value + B.Value);
end;

function TBinSubtractionNode.ComputeSpecifics(A, B: TSingleType): TSingleType;
begin
  Result := TSingleType.Create(A.Value - B.Value);
end;

end.
