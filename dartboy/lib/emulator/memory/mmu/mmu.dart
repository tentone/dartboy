import '../cartridge.dart';
import '../memory.dart';
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
  MMU(CPU cpu, Cartridge cartridge) : super(cpu);

  /// Read a value from the OAM sprite memory.
  ///
  /// The OAM start address is added to the address received as parameter.
  int readOAM(int address)
  {
    if(address > this.oam.length)
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
    if(address > this.oam.length)
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
    if(address > this.vram.length)
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
    if(address > this.vram.length)
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
    if(address > this.registers.length)
    {
      throw new Exception('Trying to access invalid register address.');
    }

    return this.registers[address];
  }

  /// Read a register value, register values are mapped between FF00 to FFFF
  ///
  /// Meaning of the values is stored in the MemoryRegisters class
  void writeRegisterByte(int address, int value)
  {
    if(address > this.registers.length)
    {
      throw new Exception('Trying to access invalid register address.');
    }

    value &= 0xFF;
    this.registers[address] = value;
  }
}