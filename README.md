# Aspen - an AST evaluator for Delphi
This library is written in Delphi 10.1 (Object Pascal) and the aim is to develop a platform whereby complex mathematical and logical expressions can be expressed and dynamically evaluated. Aspen could be used as a syntax tree for Genetic programming and other algorithms which can dynamcially generate and interact with the structure of an expression.

Oh, and it's very easy to use:
```
var
  AddNode1: TBinAdditionNode;
  SubNode1: TBinSubtractionNode;
  Op1, Op2, Op3: TTerminalNode;
  Evaluation: TSingleType;
begin
  try
    Op1 := TTerminalNode.CreateFromPrimitive(5);
    Op2 := TTerminalNode.CreateFromPrimitive(7);
    Op3 := TTerminalNode.CreateFromPrimitive(3);

    AddNode1 := TBinAdditionNode.Create(Op1, Op2);
    SubNode1 := TBinSubtractionNode.Create(AddNode1, Op3);

    Evaluation := SubNode1.Evaluate;
    ShowMessage('Evaluated to: ' + FloatToStr(Evaluation.Value)); //Evaluates to 9
  finally
    SubNode1.Free;
    Evaluation.Free;
  end;
```

The end goal is to have all standard mathematical functions (log, sin, square-root) and logical/flow control operators (if statements, loops, etc) encodable in an Aspen tree. Eventually, one can then use this to "learn" and "grow" computer programs to various problems, such as classification or regression.

Eventually I want to have this 100% covered in unit tests. For now, I've done a manual test and it all works and is free from memory leaks (yay!). Single-precision only, but double-precision will come later.