import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef DecodeWrapperC = Pointer<Void> Function(
    Pointer<Pointer<Utf8>> input, Int32 length);

typedef DecodeWrapperDart = Pointer<Void> Function(
    Pointer<Pointer<Utf8>> input, int length);

typedef FreePtrC = Void Function(Pointer<Utf8> ptr);
typedef FreePtrDart = void Function(Pointer<Utf8> ptr);

void main() {
  final dylib = DynamicLibrary.open("libdecode_wrapper.dll");

  final decodeWrapper =
      dylib.lookupFunction<DecodeWrapperC, DecodeWrapperDart>("decode_wrapper");

  final freePtr = dylib.lookupFunction<FreePtrC, FreePtrDart>("free_string");

  final input = [
    "  x0196",
    "  m109",
    " xdd",
    "  x0162",
    "  x01b6",
    "#",
    "102",
    "ev3uamc"
  ];

  final pointers = input.map((str) => str.toNativeUtf8()).toList();
  final pointerList = calloc<Pointer<Utf8>>(input.length);
  for (int i = 0; i < input.length; i++) {
    pointerList[i] = pointers[i];
  }

  final resultPointer = decodeWrapper(pointerList, input.length).cast<Utf8>();

  final result = resultPointer.toDartString();
  print('Decoded result: $result');

  freePtr(resultPointer);

  for (var ptr in pointers) {
    calloc.free(ptr);
  }
  calloc.free(pointerList);
}
