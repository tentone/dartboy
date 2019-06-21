import '../cartridge.dart';
import '../memory.dart';
import '../memory_addresses.dart';
import '../../cpu/cpu.dart';

/// The MMU (memory management unit) is used to access memory.
///
/// Depending on the cartridge type it may select different data sources and switch memory banks as required.
///
/// This is the base implementation that considers only a single ROM bank in the cartridge and a access to the system memory.
///
/// From address 0x0000 to index 0x00FF is the bootstrap code.
///
/// Address 0x100 until index 0x3FFF include the contents of the cartridge (depending on the cartridge size this memory bank can change totally)
class MMU extends Memory
{
  MMU(CPU cpu, Cartridge cartridge) : super(cpu)
  {
    this.cpu = cpu;
  }

  /// Read a value from the OAM sprite memory.
  ///
  /// The OAM start address is added to the address received as parameter.
  int readOAM(int address)
  {
    if(address > MemoryAddresses.OAM_SIZE)
    {
      throw new Exception('Trying to access invalid OAM address.');
    }

    return this.oam[address]; //this.readByte(MemoryAddresses.OAM_START + address);
  }

  /// Write a value into the OAM sprite memory.
  ///
  /// The OAM start address is added to the address received as parameter.
  void writeOAM(int address, int value)
  {
    if(address > MemoryAddresses.OAM_SIZE)
    {
      throw new Exception('Trying to access invalid OAM address.');
    }

    value &= 0xFF;
    this.oam[address] = value;
  }

  /// Read a value from the Video RAM.
  ///
  /// The video RAM start address is added to the address received as parameter.
  int readVRAM(int address)
  {
    if(address > MemoryAddresses.VIDEO_RAM_SIZE)
    {
      throw new Exception('Trying to access invalid VRAM address.');
    }

    return this.vram[address];
  }

  /// Write a value into the Video RAM.
  ///
  /// The video RAM start address is added to the address received as parameter.
  void writeVRAM(int address, int value)
  {
    if(address > MemoryAddresses.VIDEO_RAM_SIZE)
    {
      throw new Exception('Trying to access invalid VRAM address.');
    }

    value &= 0xFF;
    this.vram[address] = value;
  }

  /// Read a register value, register values are mapped between FF00 to FFFF
  ///
  /// Meaning of the values is stored in the MemoryRegisters class
  int readRegisterByte(int address)
  {
    return this.registers[address];
  }

  /// Read a register value, register values are mapped between FF00 to FFFF
  ///
  /// Meaning of the values is stored in the MemoryRegisters class
  void writeRegisterByte(int address, int value)
  {
    value &= 0xFF;
    this.registers[address] = value;
  }

  /// Reset the memory to default boot values.
  ///
  /// (Check page 17 and 18 of the GB CPU manual)
  void reset()
  {
    this.writeByte(0xFF04, 0xAB);
    this.writeByte(0xFF05, 0x00);
    this.writeByte(0xFF06, 0x00);
    this.writeByte(0xFF07, 0x00);
    this.writeByte(0xFF10, 0x80);
    this.writeByte(0xFF11, 0xBF);
    this.writeByte(0xFF12, 0xF3);
    this.writeByte(0xFF14, 0xBF);
    this.writeByte(0xFF16, 0x3F);
    this.writeByte(0xFF17, 0x00);
    this.writeByte(0xFF19, 0xBF);
    this.writeByte(0xFF1A, 0x7F);
    this.writeByte(0xFF1B, 0xFF);
    this.writeByte(0xFF1C, 0x9F);
    this.writeByte(0xFF1E, 0xBF);
    this.writeByte(0xFF20, 0xFF);
    this.writeByte(0xFF21, 0x00);
    this.writeByte(0xFF22, 0x00);
    this.writeByte(0xFF23, 0xBF);
    this.writeByte(0xFF24, 0x77);
    this.writeByte(0xFF25, 0xF3);
    this.writeByte(0xFF26, this.cpu.cartridge.superGameboy ? 0xF0 : 0xF1);
    this.writeByte(0xFF40, 0x91);
    this.writeByte(0xFF42, 0x00);
    this.writeByte(0xFF43, 0x00);
    this.writeByte(0xFF45, 0x00);
    this.writeByte(0xFF47, 0xFC);
    this.writeByte(0xFF48, 0xFF);
    this.writeByte(0xFF49, 0xFF);
    this.writeByte(0xFF4A, 0x00);
    this.writeByte(0xFF4B, 0x00);
    this.writeByte(0xFFFF, 0x00);
  }
}