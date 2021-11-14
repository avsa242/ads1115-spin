{
    --------------------------------------------
    Filename: ADS1115-IntDemo.spin
    Author: Jesse Burt
    Description: Demo of the ADS1115 driver
        interrupt functionality
    Copyright (c) 2021
    Started Nov 13, 2021
    Updated Nov 14, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-definable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 400_000
    ADDR_BITS   = %00                           ' Alternate I2C addresses:
                                                ' %00 (default), %01, %10, %11

    INT1        = 16
' --

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    int : "string.integer"
    adc : "signal.adc.ads1115.i2c"

VAR

    long _isr_stack[50]                         ' stack space for ISR
    long _intflag

PUB Main{} | uV

    setup{}
    adc.defaults{}

    adc.adcchannelenabled(0)                    ' 0..3
    adc.adcscale(4_096)                         ' 256, 512, 1024, 2048, 4096,
                                                '   6144 (mV)
    adc.intpersistence(1)                       ' 1, 2, 4 (interrupt cycles)
    adc.intthreshlow(1_200000)                  ' 0 .. 5_800000 (0..5.8V)
    adc.intthreshhi(2_000000)                   ' IntThreshLow() .. 5_800000
    adc.intactivestate(adc#HIGH)                ' LOW, HIGH
    dira[LED] := 1

    ' The demo continuously reads the ADC's channel 0
    ' Interrupt thresholds are set above: 1.2V low, 2.0V high
    ' A reading above the high threshold should light the P2 board's 1st LED
    ' A reading below the low threshold should turn it off
    ' Testing is done with a 2-axis joystick
    '   (Parallax #27800, https://www.parallax.com/product/2-axis-joystick/)
    '   L/R+ (or U/D+) connected to supply voltage
    '   GND connected to GND
    '   L/R (or U/D) connected to ADC channel 0
    repeat
        adc.measure{}
        repeat until adc.adcdataready{}
        uV := adc.voltage{}
        ser.position(0, 3)
        ser.str(string("ADC: "))
        decimal(uV, 1_000_000)
        ser.char("V")
        ser.clearline{}

        if _intflag
            outa[LED] := 1
        else
            outa[LED] := 0

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

PRI ISR{}
' Interrupt service routine
    dira[INT1] := 0                             ' INT1 as input
    repeat
        waitpeq(|< INT1, |< INT1, 0)            ' wait for INT1 (active high)
        _intflag := 1                           '   set flag
        waitpne(|< INT1, |< INT1, 0)            ' now wait for it to clear
        _intflag := 0                           '   clear flag

PRI Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if adc.startx(I2C_SCL, I2C_SDA, I2C_HZ, ADDR_BITS)
        ser.strln(string("ADS1115 driver started"))
    else
        ser.strln(string("ADS1115 driver failed to start - halting"))
        repeat

    cognew(isr{}, @_isr_stack)

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
