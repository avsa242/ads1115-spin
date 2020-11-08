{
    --------------------------------------------
    Filename: ADS1115-Demo.spin
    Author: Jesse Burt
    Description: Demo of the ADS1115 driver
    Copyright (c) 2020
    Started Dec 29, 2019
    Updated Nov 8, 2020
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

    DAT_COL     = 20
    DAT_ROW     = 14

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    ads1115 : "signal.adc.ads1115.i2c"

PUB Main{} | dispmode, ch

    setup{}
    ads1115.adcscale(4_096)                     ' 256, 512, 1024, 2048, 4096, 6144 (mV)
    ads1115.adcdatarate(128)                    ' 8, 16, 32, 64, 128, 250, 475, 860 (Hz)

    ser.hidecursor{}
    dispmode := 0
    ch := 0
    displaysettings{}

    repeat
        case ser.rxcheck{}
            "q", "Q":                           ' Quit the demo
                ser.position(0, 17)
                ser.str(string("Halting"))
                ads1115.stop{}
                time.msleep(5)
                quit
            "r", "R":                           ' Display mode: raw, calc'd
                ser.position(0, 14)
                repeat 2
                    ser.clearline{}
                    ser.newline{}
                dispmode ^= 1

        case dispmode
            0:
                ser.position(0, DAT_ROW+ch)
                adcraw(ch)
            1:
                ser.position(0, DAT_ROW+ch)
                adccalc(ch)
        ch++
        if ch > 3
            ch := 0

    ser.showcursor{}
    repeat

PUB ADCRaw(ch) | raw
' Display ADC data (raw word)
    ser.str(string("ADC raw:  "))
    ads1115.adcchannelenabled(ch)
    ads1115.measure{}
    repeat until ads1115.adcdataready{}
    raw := ads1115.adcdata{}

    ser.position(DAT_COL, DAT_ROW+ch)
    ser.str(string("Ch"))
    ser.dec(ch)
    ser.chars(32, 5)
    ser.str(int.hex(raw, 8))
    ser.clearline{}

PUB ADCCalc(ch) | uvolts
' Display ADC data (voltage, microvolts)
    ser.str(string("ADC volts:  "))
    ads1115.adcchannelenabled(ch)
    ads1115.measure{}
    repeat until ads1115.adcdataready{}
    uvolts := ads1115.voltage(ch)

    ser.position(DAT_COL, DAT_ROW+ch)
    ser.str(string("Ch"))
    ser.dec(ch)
    ser.chars(32, 5)
    decimal(uvolts, 1_000_000)
    ser.clearline{}

PUB DisplaySettings{}

    ser.position(0, 4)
    ser.str(string("ADCScale: "))
    ser.dec(ads1115.adcscale(-2))
    ser.str(string("mV"))
    ser.newline{}

    ser.str(string("ADCDataRate: "))
    ser.dec(ads1115.adcdatarate(-2))
    ser.strln(string("Hz"))

PRI Decimal(scaled, divisor) | whole[4], part[4], places, tmp, sign
' Display a scaled up number as a decimal
'   Scale it back down by divisor (e.g., 10, 100, 1000, etc)
    whole := scaled / divisor
    tmp := divisor
    places := 0
    part := 0
    sign := 0
    if scaled < 0
        sign := "-"
    else
        sign := " "

    repeat
        tmp /= 10
        places++
    until tmp == 1
    scaled //= divisor
    part := int.deczeroed(||(scaled), places)

    ser.char(sign)
    ser.dec(||(whole))
    ser.char(".")
    ser.str(part)

PRI Setup{}

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
