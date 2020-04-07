{
    --------------------------------------------
    Filename: ADS1115-Demo.spin
    Author: Jesse Burt
    Description: Demo of the ADS1115 driver
    Copyright (c) 2020
    Started Dec 29, 2019
    Updated Feb 8, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode = cfg#_clkmode
    _xinfreq = cfg#_xinfreq

    LED         = cfg#LED1

    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    I2C_SCL     = 14
    I2C_SDA     = 15
    I2C_HZ      = 400_000
    ADDR_BITS   = %00                                       ' Bits to set alternate slave addresses:
'                                                               %00 (default), %01, %10, %11

OBJ

    cfg     : "core.con.boardcfg.parraldev"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    int     : "string.integer"
    ads1115 : "signal.adc.ads1115.i2c"

VAR

    byte _ser_cog

PUB Main | range, raw, mV, opmode

    Setup
    ads1115.OpMode(ads1115#SINGLE)                          ' SINGLE or CONT
    ads1115.Range(4_096)                                    ' Full scale range (mV): 256, 512, 1024, 2048, 4096, 6144
    ads1115.SampleRate(128)                                 ' Samples per sec: 8, 16, 32, 64, 128, 250, 475, 860

    ser.Position(0, 4)
    ser.str(string("Operation mode: "))
    ser.str(lookupz(opmode := ads1115.OpMode(-2): string("Continuous"), string("Single-shot")))
    ser.Newline

    ser.str(string("Range: "))
    ser.dec(range := ads1115.Range(-2))
    ser.str(string("mV"))
    ser.Newline

    ser.str(string("Sample rate: "))
    ser.dec(ads1115.SampleRate(-2))
    ser.str(string("sps", ser#CR, ser#LF))

    repeat
        if opmode == ads1115#SINGLE
            ads1115.Measure
            repeat until ads1115.Ready                      ' NOTE: This would hang in continuous meas. mode

        raw := ads1115.ReadADC(1)
        mv := ads1115.Voltage(1)

        ser.Position(0, 8)
        ser.str(string("Raw ADC: "))
        ser.str(int.hex(raw, 8))
        ser.Newline

        ser.str(string("Voltage: "))
        ser.str(int.decpadded(mV, 9))
        ser.str(string("mV"))

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if ads1115.Startx (I2C_SCL, I2C_SDA, I2C_HZ, ADDR_BITS)
        ser.Str(string("ADS1115 driver started", ser#CR, ser#LF))
    else
        ser.Str(string("ADS1115 driver failed to start - halting", ser#CR, ser#LF))
        ads1115.Stop
        time.MSleep(5)
        ser.Stop
        FlashLED(LED, 500)

#include "lib.utility.spin"

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
