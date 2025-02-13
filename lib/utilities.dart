import "dart:io";
import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef DecodeWrapperC = Pointer<Void> Function(
    Pointer<Pointer<Utf8>> input, Int32 length);

typedef DecodeWrapperDart = Pointer<Void> Function(
    Pointer<Pointer<Utf8>> input, int length);

typedef FreePtrC = Void Function(Pointer<Utf8> ptr);
typedef FreePtrDart = void Function(Pointer<Utf8> ptr);

String utilityDecode(List<String> input) {
  final dylib =
      DynamicLibrary.open(Platform.isAndroid ? "libdecoder.so" : "decoder.dll");

  final decodeWrapper =
      dylib.lookupFunction<DecodeWrapperC, DecodeWrapperDart>("decode_wrapper");

  final freePtr = dylib.lookupFunction<FreePtrC, FreePtrDart>("free_string");

  final pointers = input.map((str) => str.toNativeUtf8()).toList();
  final pointerList = calloc<Pointer<Utf8>>(input.length);
  for (int i = 0; i < input.length; i++) {
    pointerList[i] = pointers[i];
  }

  final resultPointer = decodeWrapper(pointerList, input.length).cast<Utf8>();

  final result = resultPointer.toDartString();

  freePtr(resultPointer);

  for (var ptr in pointers) {
    calloc.free(ptr);
  }
  calloc.free(pointerList);

  return result;
}
