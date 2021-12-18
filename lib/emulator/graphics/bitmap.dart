import 'dart:typed_data';

/// Stores bitmap data, only the actual image data.
class Bitmap
{
  final int pixelSize;
  
  final int width;

  final int height;

  final Uint8List data;

  Bitmap(this.width, this.height, this.data, {this.pixelSize = 4});

  int size()
  {
    return (this.width * this.height) * this.pixelSize;
  }

  Bitmap copy()
  {
    return Bitmap(this.width, this.height, Uint8List.fromList(this.data), pixelSize: this.pixelSize);
  }
}

/// Represents a complete bitmap file, composed of bitmap data and a bitmap header containing metadata.
class BitmapFile
{
  static const int headerSize = 122;

  Uint8List header;
  Bitmap image;

  /// Get the full length of the bitmap file (header and data).
  ///
  int length()
  {
    return BitmapFile.headerSize + this.image.size();
  }

  /// Get the bitmap file byte data
  Uint8List getFile()
  {
    Uint8List data = Uint8List.fromList(this.header);
    data.setRange(BitmapFile.headerSize, this.length(), this.image.data);
    return data;
  }

  BitmapFile(this.image)
  {
    this.header = new Uint8List(this.length());

    // ARGB32 header
    final ByteData bd = this.header.buffer.asByteData();
    bd.setUint8(0x0, 0x42);
    bd.setUint8(0x1, 0x4d);
    bd.setInt32(0x2, this.length(), Endian.little);
    bd.setInt32(0xa, BitmapFile.headerSize, Endian.little);
    bd.setUint32(0xe, 108, Endian.little);
    bd.setUint32(0x12, this.image.width, Endian.little);
    bd.setUint32(0x16, -this.image.height, Endian.little);
    bd.setUint16(0x1a, 1, Endian.little);
    bd.setUint32(0x1c, 32, Endian.little); // Pixel size
    bd.setUint32(0x1e, 3, Endian.little); // Bit fields
    bd.setUint32(0x22, this.image.size(), Endian.little);
    bd.setUint32(0x36, 0x000000ff, Endian.little);
    bd.setUint32(0x3a, 0x0000ff00, Endian.little);
    bd.setUint32(0x3e, 0x00ff0000, Endian.little);
    bd.setUint32(0x42, 0xff000000, Endian.little);
  }
}