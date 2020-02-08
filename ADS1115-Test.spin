{
    --------------------------------------------
    Filename: ADS1115-Test.spin
    Author: Jesse Burt
    Description: Test of the ADS1115 driver
    Copyright (c) 2020
    Started Dec 30, 2019
    Updated Feb 8, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    COL_REG     = 0
    COL_SET     = COL_REG+17
    COL_READ    = COL_SET+12
    COL_PF      = COL_READ+12

    LED         = cfg#LED1

    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

' For I2C devices
    SCL_PIN     = 12
    SDA_PIN     = 13
    I2C_HZ      = 400_000

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    ads1115 : "signal.adc.ads1115.i2c"

VAR

    long _fails, _expanded
    byte _ser_cog, _row

PUB Main

    Setup
    _row := 3

    ser.Position (0, _row)
    _expanded := TRUE          'Uncomment to show each individual result of tests
    OPMODE(1)
    DR(1)
    PGA(1)
    OPMODE(1)

    FlashLED (LED, 100)

PUB DR(reps) | tmp, read, tmp2

    _row++
    repeat reps
        repeat tmp from 1 to 8
            ads1115.SampleRate(lookup(tmp: 8, 16, 32, 64, 128, 250, 475, 860))
            read := ads1115.SampleRate (-2)
            Message (string("DR"), lookup(tmp: 8, 16, 32, 64, 128, 250, 475, 860), read)
        time.Sleep(1)

PUB PGA(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 1 to 6
            ads1115.Range (lookup(tmp: 0_256, 0_512, 1_024, 2_048, 4_096, 6_144))
            read := ads1115.Range (-2)
            Message (string("PGA"), lookup(tmp: 0_256, 0_512, 1_024, 2_048, 4_096, 6_144), read)

PUB OPMODE(reps) | tmp, read

    _row++
    repeat reps
        repeat tmp from 0 to 1
            ads1115.OpMode(tmp)
            read := ads1115.OpMode(-2)
            Message (string("OPMODE"), tmp, read)

PUB TrueFalse(num)

    case num
        0: ser.Str (string("FALSE"))
        -1: ser.Str (string("TRUE"))
        OTHER: ser.Str (string("???"))

PUB Message(field, arg1, arg2)

   case _expanded
        TRUE:
            ser.PositionX (COL_REG)
            ser.Str (field)

            ser.PositionX (COL_SET)
            ser.Str (string("SET: "))
            ser.Dec (arg1)

            ser.PositionX (COL_READ)
            ser.Str (string("READ: "))
            ser.Dec (arg2)
            ser.Chars (32, 3)
            ser.PositionX (COL_PF)
            PassFail (arg1 == arg2)
            ser.NewLine

        FALSE:
            ser.Position (COL_REG, _row)
            ser.Str (field)

            ser.Position (COL_SET, _row)
            ser.Str (string("SET: "))
            ser.Dec (arg1)

            ser.Position (COL_READ, _row)
            ser.Str (string("READ: "))
            ser.Dec (arg2)

            ser.Position (COL_PF, _row)
            PassFail (arg1 == arg2)
            ser.NewLine
        OTHER:
            ser.Str (string("DEADBEEF"))

PUB PassFail(num)

    case num
        0: ser.Str (string("FAIL"))
        -1: ser.Str (string("PASS"))
        OTHER: ser.Str (string("???"))

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(100)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if ads1115.Startx (SCL_PIN, SDA_PIN, I2C_HZ)
        ser.Str (string("ADS1115 driver started", ser#CR, ser#LF))
    else
        ser.Str (string("ADS1115 driver failed to start - halting", ser#CR, ser#LF))
        ads1115.Stop
        time.MSleep (500)
        ser.Stop
        FlashLED (LED, 500)

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
