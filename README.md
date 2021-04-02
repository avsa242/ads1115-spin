# ads1115-spin 
--------------

This is a P8X32A/Propeller driver object for the TI ADS1115 ADC

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz
* Read in continuous or single-shot measurement modes
* Measurement ready flag for single-shot mode
* Set full-scale range and sampling rate
* Read raw data or scaled to mV
* Supports alternate slave addresses

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C engine

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81), FlexSpin (tested with 5.3.0)
* P2/SPIN2: FlexSpin (tested with 5.3.0)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Doesn't support the high-speed (3.4MHz) I2C mode
* Doesn't support comparator modes/interrupts (for under/over-voltage detection)

## TODO

- [x] Port to SPIN2
- [ ] Add support for under/over-voltage detection
- [ ] Add interrupt support
- [ ] Add differential input support
- [ ] Add support for 3.4MHz HS I2C mode
