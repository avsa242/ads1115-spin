{
    --------------------------------------------
    Filename: ADS1115-Demo.spin
    Author: Jesse Burt
    Description: Demo of the ADS1115 driver
        * Power data output
    Copyright (c) 2023
    Started Feb 8, 2020
    Updated Jul 14, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD        = 115_200

' --

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi"
    adc:    "signal.adc.ads1115" | SCL=28, SDA=29, I2C_FREQ=400_000, I2C_ADDR=%00
    time:   "time"

PUB main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if ( adc.start{} )
        ser.strln(string("ADS1115 driver started"))
    else
        ser.strln(string("ADS1115 driver failed to start - halting"))
        repeat

    adc.adc_scale(4_096)                        ' 256, 512, 1024, 2048, 4096, 6144 (mV)
    adc.adc_data_rate(128)                      ' 8, 16, 32, 64, 128, 250, 475, 860 (Hz)
    adc.opmode(adc#CONT)
    adc.set_adc_channel(0)
    show_adc_data{}

#include "adcdemo.common.spinh"

DAT
{
Copyright (c) 2023 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

