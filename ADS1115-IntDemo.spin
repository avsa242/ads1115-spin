{
    --------------------------------------------
    Filename: ADS1115-IntDemo.spin
    Author: Jesse Burt
    Description: Demo of the ADS1115 driver
        interrupt functionality
    Copyright (c) 2022
    Started Nov 13, 2021
    Updated Sep 27, 2022
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
    I2C_FREQ    = 400_000
    ADDR_BITS   = %00                           ' Alternate I2C addresses:
                                                ' %00 (default), %01, %10, %11

    INT1        = 24
' --

    VF          = 1_000_000

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    adc : "signal.adc.ads1115"

VAR

    long _isr_stack[50]                         ' stack space for ISR
    long _intflag

PUB main{} | uV

    setup{}
    adc.defaults{}

    adc.adc_chan_ena(0)                         ' 0..3
    adc.adc_scale(4_096)                        ' 256, 512, 1024, 2048, 4096,
                                                '   6144 (mV)
    adc.int_duration(1)                         ' 1, 2, 4 (interrupt cycles)
    adc.int_set_lo_thresh(1_200000)             ' 0 .. 5_800000 (0..5.8V)
    adc.int_set_hi_thresh(2_000000)             ' int_thresh_low() .. 5_800000
    adc.int_polarity(adc#HIGH)                  ' LOW, HIGH
    dira[LED] := 1

    ' The demo continuously reads the ADC's channel 0
    ' Interrupt thresholds are set above: 1.2V low, 2.0V high
    ' A reading above the high threshold should light the P1 board's 1st LED
    ' A reading below the low threshold should turn it off
    ' Testing is done with a 2-axis joystick
    '   (Parallax #27800, https://www.parallax.com/product/2-axis-joystick/)
    '   L/R+ (or U/D+) connected to supply voltage (3.3v)
    '   GND connected to GND
    '   L/R (or U/D) connected to ADC channel 0
    repeat
        adc.measure{}
        repeat until adc.adc_data_rdy{}
        uV := adc.voltage{}
        ser.position(0, 3)
        ser.str(string("ADC: "))
        ser.printf2(string("Voltage: %d.%06.6dv\n\r"), (adc.voltage{} / VF), {
}       ||(adc.voltage{} // VF))
        ser.clearline{}

        if (_intflag)
            outa[LED] := 1
        else
            outa[LED] := 0

PRI isr{}
' Interrupt service routine
    dira[INT1] := 0                             ' INT1 as input
    repeat
        waitpeq(|< INT1, |< INT1, 0)            ' wait for INT1 (active high)
        _intflag := 1                           '   set flag
        waitpne(|< INT1, |< INT1, 0)            ' now wait for it to clear
        _intflag := 0                           '   clear flag

PRI setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if adc.startx(I2C_SCL, I2C_SDA, I2C_FREQ, ADDR_BITS)
        ser.strln(string("ADS1115 driver started"))
    else
        ser.strln(string("ADS1115 driver failed to start - halting"))
        repeat

    cognew(isr{}, @_isr_stack)

DAT
{
Copyright 2022 Jesse Burt

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

