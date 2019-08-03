import 'dart:typed_data';

/// Stores bitmap data, only the actual image data.
class Bitmap
{
  final int pixelLength;
  final int width;
  final int height;
  final Uint8List contentByteData;

  Bitmap(this.width, this.height, this.contentByteData, {this.pixelLength = 4});

  int get size{return (this.width * this.height) * this.pixelLength;}

  Bitmap copy()
  {
    return Bitmap(this.width, this.height, Uint8List.fromList(this.contentByteData), pixelLength: this.pixelLength);
  }
}

/// Represents a complete bitmap file, composed of bitmap data and a bitmap header containing metadata.
class BitmapFile
{
  static const int headerSize = 122;

  Uint8List header;
  Bitmap image;

  set contentByteData(Uint8List contentByteData)
  {
    this.image = new Bitmap(this.content.width, this.content.height, contentByteData, pixelLength: this.content.pixelLength);
  }

  Bitmap get content{return this.content;}
  Uint8List get headerByteData{return this.header;}
  int get length{return BitmapFile.headerSize + this.image.size;}

  Uint8List get data
  {
    return Uint8List.fromList(this.header)..setRange(BitmapFile.headerSize, this.length, this.content.contentByteData);
  }

  BitmapFile(this.image)
  {
    this.header = new Uint8List(length);

    /// ARGB32 header
    final ByteData bd = this.headerByteData.buffer.asByteData();
    bd.setUint8(0x0, 0x42);
    bd.setUint8(0x1, 0x4d);
    bd.setInt32(0x2, this.length, Endian.little);
    bd.setInt32(0xa, BitmapFile.headerSize, Endian.little);
    bd.setUint32(0xe, 108, Endian.little);
    bd.setUint32(0x12, this.content.width, Endian.little);
    bd.setUint32(0x16, -this.content.height, Endian.little);
    bd.setUint16(0x1a, 1, Endian.little);
    bd.setUint32(0x1c, 32, Endian.little); // Pixel size
    bd.setUint32(0x1e, 3, Endian.little); // Bit fields
    bd.setUint32(0x22, this.content.size, Endian.little);
    bd.setUint32(0x36, 0x000000ff, Endian.little);
    bd.setUint32(0x3a, 0x0000ff00, Endian.little);
    bd.setUint32(0x3e, 0x00ff0000, Endian.little);
    bd.setUint32(0x42, 0xff000000, Endian.little);
  }
}