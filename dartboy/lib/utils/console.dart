import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Console class stores static method to log information into the development console.
///
/// Provides a more complete output of the data.
class Console
{
  static const bool DEBUG_PRINT = true;

  /// Build a string to represent an object.
  static String build(dynamic obj, {int level = 0})
  {
    try
    {
      JsonEncoder encoder = new JsonEncoder.withIndent('   ');
      return encoder.convert(obj);
    }
    catch(e){}

    return obj.toString();
  }

  /// Log a object value into the console in a JSON like structure.
  ///
  /// @param obj Object to be printed into the console.
  static void log(dynamic obj)
  {
    if(DEBUG_PRINT)
    {
      debugPrintSynchronously(build(obj));
    }
    else
    {
      print(build(obj));
    }
  }
}