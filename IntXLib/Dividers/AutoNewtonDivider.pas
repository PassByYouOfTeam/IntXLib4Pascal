unit AutoNewtonDivider;

{
  * Copyright (c) 2015 Ugochukwu Mmaduekwe ugo4brain@gmail.com

  *   This Source Code Form is subject to the terms of the Mozilla Public License
  * v. 2.0. If a copy of the MPL was not distributed with this file, You can
  * obtain one at http://mozilla.org/MPL/2.0/.

  *   Neither the name of Ugochukwu Mmaduekwe nor the names of its contributors may
  *  be used to endorse or promote products derived from this software without
  *  specific prior written permission.

}

{$POINTERMATH ON}

interface

uses

  IDivider, Constants, DTypes, Enums, DividerBase, DigitHelper, DigitOpHelper;

type
  /// <summary>
  /// Divides using Newton approximation approach.
  /// </summary>

  TAutoNewtonDivider = class sealed(TDividerBase)

  private

    F_classicDivider: IIDivider; // divider to use if Newton approach is
    // unapplicable

  public
    constructor Create(classicDivider: IIDivider);
    destructor Destroy(); Override;
    class function IsClassicAlgorithmNeeded(length1: UInt32; length2: UInt32)
      : Boolean; static; inline;
    function DivMod(digits1: TMyUInt32Array; digitsBuffer1: TMyUInt32Array;
      var length1: UInt32; digits2: TMyUInt32Array;
      digitsBuffer2: TMyUInt32Array; length2: UInt32; digitsRes: TMyUInt32Array;
      resultFlags: TDivModResultFlags; cmpResult: Integer): UInt32;
      overload; override;
    function DivMod(digitsPtr1: PMyUInt32; digitsBufferPtr1: PMyUInt32;
      var length1: UInt32; digitsPtr2: PMyUInt32; digitsBufferPtr2: PMyUInt32;
      length2: UInt32; digitsResPtr: PMyUInt32; resultFlags: TDivModResultFlags;
      cmpResult: Integer): UInt32; overload; override;

  end;

implementation

uses
  NewtonHelper, MultiplyManager, IMultiplier;

/// <summary>
/// Creates new <see cref="AutoNewtonDivider" /> instance.
/// </summary>
/// <param name="classicDivider">Divider to use if Newton approach is unapplicable.</param>

constructor TAutoNewtonDivider.Create(classicDivider: IIDivider);

begin
  inherited Create;
  F_classicDivider := classicDivider;
end;

destructor TAutoNewtonDivider.Destroy();
begin
  F_classicDivider := Nil;
  inherited Destroy;
end;

/// <summary>
/// Returns true if it's better to use classic algorithm for given big integers.
/// </summary>
/// <param name="length1">First big integer length.</param>
/// <param name="length2">Second big integer length.</param>
/// <returns>True if classic algorithm is better.</returns>

class function TAutoNewtonDivider.IsClassicAlgorithmNeeded(length1: UInt32;
  length2: UInt32): Boolean;
begin
  result := ((length1 < TConstants.AutoNewtonLengthLowerBound) or
    (length2 < TConstants.AutoNewtonLengthLowerBound) or
    (length1 > TConstants.AutoNewtonLengthUpperBound) or
    (length2 > TConstants.AutoNewtonLengthUpperBound));
end;

/// <summary>
/// Divides two big integers.
/// Also modifies <paramref name="digits1" /> and <paramref name="length1"/> (it will contain remainder).
/// </summary>
/// <param name="digits1">First big integer digits.</param>
/// <param name="digitsBuffer1">Buffer for first big integer digits. May also contain remainder. Can be null - in this case it's created if necessary.</param>
/// <param name="length1">First big integer length.</param>
/// <param name="digits2">Second big integer digits.</param>
/// <param name="digitsBuffer2">Buffer for second big integer digits. Only temporarily used. Can be null - in this case it's created if necessary.</param>
/// <param name="length2">Second big integer length.</param>
/// <param name="digitsRes">Resulting big integer digits.</param>
/// <param name="resultFlags">Which operation results to return.</param>
/// <param name="cmpResult">Big integers comparsion result (pass -2 if omitted).</param>
/// <returns>Resulting big integer length.</returns>

function TAutoNewtonDivider.DivMod(digits1: TMyUInt32Array;
  digitsBuffer1: TMyUInt32Array; var length1: UInt32; digits2: TMyUInt32Array;
  digitsBuffer2: TMyUInt32Array; length2: UInt32; digitsRes: TMyUInt32Array;
  resultFlags: TDivModResultFlags; cmpResult: Integer): UInt32;
var
  digitsPtr1, digitsBufferPtr1, digitsPtr2, digitsBufferPtr2, digitsResPtr,
    tempA, tempB: PMyUInt32;

begin
  // Maybe immediately use classic algorithm here
  if (IsClassicAlgorithmNeeded(length1, length2)) then
  begin
    result := F_classicDivider.DivMod(digits1, digitsBuffer1, length1, digits2,
      digitsBuffer2, length2, digitsRes, resultFlags, cmpResult);
    Exit;
  end;

  // Create some buffers if necessary
  if (digitsBuffer1 = Nil) then
  begin
    SetLength(digitsBuffer1, length1 + 1);

  end;
  digitsPtr1 := @digits1[0];
  digitsBufferPtr1 := @digitsBuffer1[0];
  digitsPtr2 := @digits2[0];

  if digitsBuffer2 <> Nil then
    digitsBufferPtr2 := @digitsBuffer2[0]
  else
  begin
    digitsBufferPtr2 := @digits1[0];
  end;

  if digitsRes <> Nil then
    digitsResPtr := @digitsRes[0]
  else
  begin
    digitsResPtr := @digits1[0];
  end;

  if digitsBufferPtr2 = digitsPtr1 then
    tempA := Nil
  else
  begin
    tempA := digitsBufferPtr2;
  end;

  if digitsResPtr = digitsPtr1 then
    tempB := Nil
  else
  begin
    tempB := digitsResPtr;
  end;

  result := DivMod(digitsPtr1, digitsBufferPtr1, length1, digitsPtr2, tempA,
    length2, tempB, resultFlags, cmpResult);
  Exit;
end;

/// <summary>
/// Divides two big integers.
/// Also modifies <paramref name="digitsPtr1" /> and <paramref name="length1"/> (it will contain remainder).
/// </summary>
/// <param name="digitsPtr1">First big integer digits.</param>
/// <param name="digitsBufferPtr1">Buffer for first big integer digits. May also contain remainder.</param>
/// <param name="length1">First big integer length.</param>
/// <param name="digitsPtr2">Second big integer digits.</param>
/// <param name="digitsBufferPtr2">Buffer for second big integer digits. Only temporarily used.</param>
/// <param name="length2">Second big integer length.</param>
/// <param name="digitsResPtr">Resulting big integer digits.</param>
/// <param name="resultFlags">Which operation results to return.</param>
/// <param name="cmpResult">Big integers comparsion result (pass -2 if omitted).</param>
/// <returns>Resulting big integer length.</returns>

function TAutoNewtonDivider.DivMod(digitsPtr1: PMyUInt32;
  digitsBufferPtr1: PMyUInt32; var length1: UInt32; digitsPtr2: PMyUInt32;
  digitsBufferPtr2: PMyUInt32; length2: UInt32; digitsResPtr: PMyUInt32;
  resultFlags: TDivModResultFlags; cmpResult: Integer): UInt32;
var
  resultLength, int2OppositeLength, quotLength, shiftOffset, highestLostBit,
    quotDivLength: UInt32;
  int2OppositeRightShift: UInt64;
  int2OppositeDigits, quotDigits, quotDivDigits: TMyUInt32Array;
  multiplier: IIMultiplier;
  oppositePtr, quotPtr, quotDivPtr: PMyUInt32;
  shiftCount, cmpRes: Integer;
begin
  // Maybe immediately use classic algorithm here
  if (IsClassicAlgorithmNeeded(length1, length2)) then
  begin
    result := F_classicDivider.DivMod(digitsPtr1, digitsBufferPtr1, length1,
      digitsPtr2, digitsBufferPtr2, length2, digitsResPtr, resultFlags,
      cmpResult);
    Exit;
  end;

  // Call base (for special cases)

  resultLength := inherited DivMod(digitsPtr1, digitsBufferPtr1, length1,
    digitsPtr2, digitsBufferPtr2, length2, digitsResPtr, resultFlags,
    cmpResult);
  if (resultLength <> TConstants.MaxUInt32Value) then
  begin
    result := resultLength;
    Exit;
  end;


  // First retrieve opposite for the divider

  int2OppositeDigits := TNewtonHelper.GetIntegerOpposite(digitsPtr2, length2,
    length1, digitsBufferPtr1, int2OppositeLength, int2OppositeRightShift);

  // We will need to multiply it by divident now to receive quotient.
  // Prepare digits for multiply result

  SetLength(quotDigits, length1 + int2OppositeLength);

  multiplier := TMultiplyManager.GetCurrentMultiplier();

  // Fix some arrays
  oppositePtr := @int2OppositeDigits[0];
  quotPtr := @quotDigits[0];

  // Multiply
  quotLength := multiplier.Multiply(oppositePtr, int2OppositeLength, digitsPtr1,
    length1, quotPtr);

  // Calculate shift
  shiftOffset := UInt32((int2OppositeRightShift div TConstants.DigitBitCount));
  shiftCount := Integer(int2OppositeRightShift mod TConstants.DigitBitCount);

  // Get the very first bit of the shifted part

  if (shiftCount = 0) then
  begin
    highestLostBit := quotPtr[shiftOffset - 1] shr 31;
  end
  else
  begin
    highestLostBit := quotPtr[shiftOffset] shr (shiftCount - 1) and UInt32(1);
  end;

  // After this result must be shifted to the right - this is required
  quotLength := TDigitOpHelper.ShiftRight(quotPtr + shiftOffset,
    quotLength - shiftOffset, quotPtr, shiftCount, false);

  // Maybe quotient must be corrected
  if (highestLostBit = UInt32(1)) then
  begin
    quotLength := TDigitOpHelper.Add(quotPtr, quotLength, @highestLostBit,
      UInt32(1), quotPtr);
  end;

  // Check quotient - finally it might be too big.
  // For this we must multiply quotient by divider
  SetLength(quotDivDigits, quotLength + length2);

  quotDivPtr := @quotDivDigits[0];

  quotDivLength := multiplier.Multiply(quotPtr, quotLength, digitsPtr2, length2,
    quotDivPtr);

  cmpRes := TDigitOpHelper.Cmp(quotDivPtr, quotDivLength, digitsPtr1, length1);
  if (cmpRes > 0) then
  begin
    highestLostBit := 1;
    quotLength := TDigitOpHelper.Sub(quotPtr, quotLength, @highestLostBit,
      UInt32(1), quotPtr);
    quotDivLength := TDigitOpHelper.Sub(quotDivPtr, quotDivLength, digitsPtr2,
      length2, quotDivPtr);
  end;

  // Now everything is ready and prepared to return results

  // First maybe fill remainder
  if ((Ord(resultFlags) and Ord(TDivModResultFlags.dmrfMod)) <> 0) then
  begin
    length1 := TDigitOpHelper.Sub(digitsPtr1, length1, quotDivPtr,
      quotDivLength, digitsBufferPtr1);
  end;

  // And finally fill quotient
  if ((Ord(resultFlags) and Ord(TDivModResultFlags.dmrfDiv)) <> 0) then
  begin
    TDigitHelper.DigitsBlockCopy(quotPtr, digitsResPtr, quotLength);
  end
  else
  begin
    quotLength := 0;
  end;

  result := quotLength;
end;

end.
