# ads1115-spin 
--------------

This is a P8X32A/Propeller driver object for the TI ADS1115 ADC

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz
* Alternate I2C addresses supported
* Read in continuous or single-shot measurement modes
* Measurement ready flag for single-shot mode
* Set full-scale range and sampling rate
* Read data as ADC words or microvolts
* Read current or previous measurement
* Set interrupt (low, high) thresholds, persistence

## Requirements

P1/SPIN1:
* 1 extra core/cog for the PASM I2C engine (none if bytecode engine is used)
* signal.adc.common.spinh (provided by spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* signal.adc.common.spin2h (provided by p2-spin-standard-library)

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Bytecode    | OK                    |
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | NuCode      | FTBFS                 |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | Native code | Not yet implemented   |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Limitations

* Doesn't support the high-speed (3.4MHz) I2C mode
* Differential measurements not supported yet

