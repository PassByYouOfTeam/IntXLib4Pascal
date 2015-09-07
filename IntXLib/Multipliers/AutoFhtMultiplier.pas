unit AutoFhtMultiplier;

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
  MultiplierBase, DTypes, DigitOpHelper, IMultiplier, FhtHelper, Constants,
  Math, SysUtils, Strings, IntX;

type
  /// <summary>
  /// Multiplies using FHT.
  /// </summary>

  TAutoFhtMultiplier = class sealed(TMultiplierBase)

  private
    F_classicMultiplier: IIMultiplier;

  public
    constructor Create(classicMultiplier: IIMultiplier);
    destructor Destroy(); Override;
    function Multiply(digitsPtr1: PMyUInt32; length1: UInt32;
      digitsPtr2: PMyUInt32; length2: UInt32; digitsResPtr: PMyUInt32)
      : UInt32; override;

  end;

implementation

/// <summary>
/// Creates new <see cref="TAutoFhtMultiplier" /> instance.
/// </summary>
/// <param name="classicMultiplier">Multiplier to use if FHT is unapplicatible.</param>

constructor TAutoFhtMultiplier.Create(classicMultiplier: IIMultiplier);

begin
  inherited Create;
  F_classicMultiplier := classicMultiplier;
end;

destructor TAutoFhtMultiplier.Destroy();
begin
  F_classicMultiplier := Nil;
  inherited Destroy;
end;

/// <summary>
/// Multiplies two big integers using pointers.
/// </summary>
/// <param name="digitsPtr1">First big integer digits.</param>
/// <param name="length1">First big integer length.</param>
/// <param name="digitsPtr2">Second big integer digits.</param>
/// <param name="length2">Second big integer length.</param>
/// <param name="digitsResPtr">Resulting big integer digits.</param>
/// <returns>Resulting big integer real length.</returns>

function TAutoFhtMultiplier.Multiply(digitsPtr1: PMyUInt32; length1: UInt32;
  digitsPtr2: PMyUInt32; length2: UInt32; digitsResPtr: PMyUInt32): UInt32;
var
  newLength, lowerDigitCount: UInt32;
  data1, data2: TMyDoubleArray;
  slice1: PMyDouble;
  validationResult: TMyUInt32Array;
  validationResultPtr: PMyUInt32;

begin
  // Check length - maybe use classic multiplier instead
  if ((length1 < TConstants.AutoFhtLengthLowerBound) or
    (length2 < TConstants.AutoFhtLengthLowerBound) or
    (length1 > TConstants.AutoFhtLengthUpperBound) or
    (length2 > TConstants.AutoFhtLengthUpperBound)) then
  begin
    result := F_classicMultiplier.Multiply(digitsPtr1, length1, digitsPtr2,
      length2, digitsResPtr);
    Exit;
  end;

  newLength := length1 + length2;

  // Do FHT for first big integer
  data1 := TFhtHelper.ConvertDigitsToDouble(digitsPtr1, length1, newLength);
  TFhtHelper.Fht(data1, UInt32(Length(data1)));

  // Compare digits

  if ((digitsPtr1 = digitsPtr2) or (TDigitOpHelper.Cmp(digitsPtr1, length1,
    digitsPtr2, length2) = 0)) then
  begin
    // Use the same FHT for equal big integers
    data2 := data1;

  end
  else
  begin
    // Do FHT over second digits
    data2 := TFhtHelper.ConvertDigitsToDouble(digitsPtr2, length2, newLength);
    TFhtHelper.Fht(data2, UInt32(Length(data2)));
  end;

  // Perform multiplication and reverse FHT
  TFhtHelper.MultiplyFhtResults(data1, data2, UInt32(Length(data1)));
  TFhtHelper.ReverseFht(data1, UInt32(Length(data1)));

  // Convert to digits
  slice1 := @data1[0];

  TFhtHelper.ConvertDoubleToDigits(slice1, UInt32(Length(data1)), newLength,
    digitsResPtr);

  // Maybe check for validity using classic multiplication
  if (TIntX.GlobalSettings.ApplyFhtValidityCheck) then
  begin
    lowerDigitCount :=
      Min(length2, Min(length1, TConstants.FhtValidityCheckDigitCount));

    // Validate result by multiplying lowerDigitCount digits using classic algorithm and comparing
    SetLength(validationResult, lowerDigitCount * 2);
    validationResultPtr := @validationResult[0];

    F_classicMultiplier.Multiply(digitsPtr1, lowerDigitCount, digitsPtr2,
      lowerDigitCount, validationResultPtr);
    if (TDigitOpHelper.Cmp(validationResultPtr, lowerDigitCount, digitsResPtr,
      lowerDigitCount) <> 0) then
    begin

      raise Exception.Create(Format(Strings.FhtMultiplicationError,
        [length1, length2]));
    end;

  end;

  if digitsResPtr[newLength - 1] = 0 then
  begin

    Dec(newLength);
    result := newLength;
  end
  else
    result := newLength;

end;

end.