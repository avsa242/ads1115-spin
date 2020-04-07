# ads1115-spin 
--------------

This is a P8X32A/Propeller driver object for the TI ADS1115 ADC

## Salient Features

* I2C connection at up to 400kHz
* Read in continuous or single-shot measurement modes
* Measurement ready flag for single-shot mode
* Set full-scale range and sampling rate
* Read raw data or scaled to mV
* Supports alternate slave addresses

## Requirements

* P1/SPIN1: 1 extra core/cog for the PASM I2C driver

## Compiler Compatibility

* OpenSpin (tested with 1.00.81)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Doesn't support the high-speed (3.4MHz) I2C mode
* Doesn't support comparator modes/interrupts (for under/over-voltage detection)

## TODO

- [ ] Add support for under/over-voltage detection
- [ ] Add support for 3.4MHz HS I2C mode
