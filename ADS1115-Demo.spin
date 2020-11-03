{
    --------------------------------------------
    Filename: ADS1115-Demo.spin
    Author: Jesse Burt
    Description: Demo of the ADS1115 driver
    Copyright (c) 2020
    Started Dec 29, 2019
    Updated Nov 2, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode = cfg#_clkmode
    _xinfreq = cfg#_xinfreq

' -- User-definable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    I2C_SCL     = 26
    I2C_SDA     = 27
    I2C_HZ      = 400_000
    ADDR_BITS   = %00                           ' Alternate slave addresses:
                                                ' %00 (default), %01, %10, %11
' --

OBJ

    cfg     : "core.con.boardcfg.parraldev"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    ads1115 : "signal.adc.ads1115.i2c"

PUB Main{} | range, raw, mV, opmode, ch

    setup{}
    ads1115.opmode(ads1115#SINGLE)              ' SINGLE or CONT
    ads1115.range(2_048)                        ' 256, 512, 1024, 2048, 4096, 6144 (mV)
    ads1115.samplerate(128)                     ' 8, 16, 32, 64, 128, 250, 475, 860 (Hz)

    ser.position(0, 4)
    ser.str(string("Operation mode: "))
    ser.str(lookupz(opmode := ads1115.opmode(-2): string("Continuous"), string("Single-shot")))
    ser.newline{}

    ser.str(string("Range: "))
    ser.dec(range := ads1115.range(-2))
    ser.str(string("mV"))
    ser.newline{}

    ser.str(string("Sample rate: "))
    ser.dec(ads1115.samplerate(-2))
    ser.strln(string("sps"))

    repeat
        repeat ch from 0 to 3
            if opmode == ads1115#SINGLE
                ads1115.measure{}
                repeat until ads1115.ready{}    ' NOTE: This would hang in continuous meas. mode

            raw := ads1115.readadc(ch)
            mv := ads1115.lastvoltage{}

            ser.position(0, 8 + ch)
            ser.str(string("Ch"))
            ser.dec(ch)
            ser.str(string(" raw ADC: "))
            ser.str(int.hex(raw, 8))

            ser.str(string("   Voltage: "))
            ser.str(int.decpadded(mV, 9))
            ser.str(string("mV"))

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if ads1115.startx(I2C_SCL, I2C_SDA, I2C_HZ, ADDR_BITS)
        ser.strln(string("ADS1115 driver started"))
    else
        ser.strln(string("ADS1115 driver failed to start - halting"))
        ads1115.stop{}
        time.msleep(5)
        ser.stop{}

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
