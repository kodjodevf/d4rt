import 'dart:convert';

import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/map.dart'; // For named arguments

class Latin1Convert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define the codec instance
    environment.define('latin1', latin1);

    // Define the types/constructors
    environment.define(
        'Latin1Codec',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor: Latin1Codec({bool allowInvalid = false})
          final allowInvalid =
              namedArguments.get<bool?>('allowInvalid') ?? false;
          return Latin1Codec(allowInvalid: allowInvalid);
        }, arity: 0, name: 'Latin1Codec'));
    environment.define(
        'Latin1Encoder',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor takes no arguments
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError('Latin1Encoder constructor takes no arguments.');
          }
          return Latin1Encoder();
        }, arity: 0, name: 'Latin1Encoder'));
    environment.define(
        'Latin1Decoder',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor: Latin1Decoder({bool allowInvalid = false})
          final allowInvalid =
              namedArguments.get<bool?>('allowInvalid') ?? false;
          return Latin1Decoder(allowInvalid: allowInvalid);
        }, arity: 0, name: 'Latin1Decoder'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Latin1Codec) {
      // Extends Encoding -> Codec<String, List<int>>
      switch (name) {
        case 'encode':
          return target.encode(arguments[0] as String);
        case 'decode':
          final allowInvalid = namedArguments.get<bool?>('allowInvalid');
          return target.decode(arguments[0] as List<int>,
              allowInvalid: allowInvalid);
        case 'encoder':
          return target.encoder;
        case 'decoder':
          return target.decoder;
        case 'name':
          return target.name;
        case 'fuse':
          if (arguments.length != 1 ||
              arguments[0] is! Codec<List<int>, dynamic>) {
            throw RuntimeError(
                'Latin1Codec.fuse requires another Codec<List<int>, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Codec<List<int>, dynamic>);
        case 'inverted':
          return target.inverted;
        default:
          throw RuntimeError('Latin1Codec has no method mapping for "$name"');
      }
    } else if (target is Latin1Encoder) {
      // Extends Converter<String, List<int>>
      switch (name) {
        case 'convert':
          return target.convert(arguments[0] as String);
        case 'startChunkedConversion':
          if (arguments.length != 1 || arguments[0] is! Sink<List<int>>) {
            throw RuntimeError(
                'startChunkedConversion requires a Sink<List<int>> argument.');
          }
          return target.startChunkedConversion(arguments[0] as Sink<List<int>>);
        case 'bind':
          if (arguments.length != 1 || arguments[0] is! Stream<String>) {
            throw RuntimeError('bind requires a Stream<String> argument.');
          }
          return target.bind(arguments[0] as Stream<String>);
        case 'fuse':
          if (arguments.length != 1 ||
              arguments[0] is! Converter<List<int>, dynamic>) {
            throw RuntimeError(
                'Latin1Encoder.fuse requires another Converter<List<int>, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Converter<List<int>, dynamic>);
        case 'cast':
          return target.cast<String, List<int>>();
        default:
          throw RuntimeError('Latin1Encoder has no method mapping for "$name"');
      }
    } else if (target is Latin1Decoder) {
      // Extends Converter<List<int>, String>
      switch (name) {
        case 'convert':
          // allowInvalid is part of the decoder state, not passed here
          return target.convert(arguments[0] as List<int>);
        case 'startChunkedConversion':
          if (arguments.length != 1 || arguments[0] is! Sink<String>) {
            throw RuntimeError(
                'startChunkedConversion requires a Sink<String> argument.');
          }
          return target.startChunkedConversion(arguments[0] as Sink<String>);
        case 'bind':
          if (arguments.length != 1 || arguments[0] is! Stream<List<int>>) {
            throw RuntimeError('bind requires a Stream<List<int>> argument.');
          }
          return target.bind(arguments[0] as Stream<List<int>>);
        case 'fuse':
          if (arguments.length != 1 ||
              arguments[0] is! Converter<String, dynamic>) {
            throw RuntimeError(
                'Latin1Decoder.fuse requires another Converter<String, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Converter<String, dynamic>);
        case 'cast':
          return target.cast<List<int>, String>();
        default:
          throw RuntimeError('Latin1Decoder has no method mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for Latin1Convert: ${target?.runtimeType}');
    }
  }
}
