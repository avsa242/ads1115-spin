{
    --------------------------------------------
    Filename: signal.adc.ads1115.spin
    Author: Jesse Burt
    Description: Driver for the TI ADS1115 ADC
    Copyright (c) 2022
    Started Dec 29, 2019
    Updated Aug 4, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#include "signal.adc.common.spinh"

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

    { Operation modes }
    CONT            = 0
    SINGLE          = 1

    { Interrupt active state }
    LOW             = 0
    HIGH            = 1

VAR

    long _uvolts_lsb
    long _last_adc
    byte _addr_bits

OBJ

    i2c : "com.i2c"                             ' PASM I2C engine
    core: "core.con.ads1115"                    ' HW-specific constants
    time: "time"                                ' Basic timing functions
    u64 : "math.unsigned64"                     ' unsigned 64-bit int math

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start with "standard" Propeller I2C pins, default slave address, and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ, %00)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom I/O settings and bus speed
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if lookdown(ADDR_BITS: %00, %01, %10, %11)
            if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
                time.usleep(core#T_POR)
                _addr_bits := ADDR_BITS << 1
                if (i2c.present(SLAVE_WR | _addr_bits))
                    defaults{}
                    return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}
    _uvolts_lsb := _last_adc := _addr_bits := 0

PUB defaults{}
' Set factory defaults
    opmode(SINGLE)
    adc_scale(2_048)
    adc_data_rate(128)

PUB adc_chan_enabled(ch): curr_ch
' Set active ADC channel
'   Valid values: 0..3
'   Any other value polls the chip and returns the current setting
    curr_ch := 0
    readreg(core#CONFIG, 2, @curr_ch)
    case ch
        0..3:
            ch := (ch + %100) << core#MUX
        other:
            return (((ch >> core#MUX) & %111) - %100)

    ch := ((curr_ch & core#MUX_MASK) | ch)
    writereg(core#CONFIG, 2, @ch)

PUB adc_data{}: adc_word
' Read measurement from channel ch
'   Valid values: *0, 1, 2, 3
'   Any other value is ignored
    readreg(core#CONVERSION, 2, @adc_word)
    ~~adc_word                                  ' extend sign bit
    _last_adc := adc_word

PUB adc_data_rate(rate): curr_rate
' Set ADC sample rate, in Hz
'   Valid values: 8, 16, 32, 64, *128, 250, 475, 860
'   Any other value polls the chip and returns the current setting
    curr_rate := 0
    readreg(core#CONFIG, 2, @curr_rate)
    case rate
        8, 16, 32, 64, 128, 250, 475, 860:
            rate := lookdownz(rate: 8, 16, 32, 64, 128, 250, 475, 860) {
}           << core#DR
        other:
            curr_rate := ((curr_rate >> core#DR) & core#DR_BITS)
            return lookupz(curr_rate: 8, 16, 32, 64, 128, 250, 475, 860)

    rate := ((curr_rate & core#DR_MASK & core#OS_MASK) | rate)
    writereg(core#CONFIG, 2, @rate)

PUB adc_data_ready{}: flag
' Flag indicating measurement is complete
'   Returns: TRUE (-1) if measurement is complete, FALSE otherwise
    flag := 0
    readreg(core#CONFIG, 2, @flag)
    return ((flag >> core#OS) & 1) == 1

PUB adc_scale(scale): curr_scl
' Set full-scale range of the ADC, in millivolts
'   Valid values:
'       256, 512, 1024, *2048, 4096, 6144
'   Any other value polls the chip and returns the current setting
'   NOTE: This merely affects the scaling of values returned in measurements.
'   It doesn't affect the maximum allowable input range of the chip.
'   Per the datasheet, do NOT exceed VDD + 0.3V on the inputs.
    curr_scl := 0
    readreg(core#CONFIG, 2, @curr_scl)
    case scale
        256, 512, 1_024, 2_048, 4_096, 6_144:
            scale := lookdownz(scale: 6_144, 4_096, 2_048, 1_024, 0_512, 0_256)
            { set scaling factor }
            _uvolts_lsb := lookupz(scale: 187_5000, 125_0000, 62_5000, {
}           31_2500, 15_6250, 7_8125)
            scale <<= core#PGA
        other:
            curr_scl := ((curr_scl >> core#PGA) & core#PGA_BITS)
            return lookupz(curr_scl: 6_144, 4_096, 2_048, 1_024, 0_512, 0_256,{
}           0_256, 0_256)

    scale := ((curr_scl & core#PGA_MASK) | scale)
    writereg(core#CONFIG, 2, @scale)

PUB adc2volts(adc_word): volts
' Scale ADC word to microvolts
    return u64.multdiv(adc_word, _uvolts_lsb, 1_0000)

PUB int_active_state(state): curr_state
' Set interrupt pin active state/logic level
'   Valid values: LOW (0), HIGH (1)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CONFIG, 2, @curr_state)
    case state
        LOW, HIGH:
            state <<= core#COMP_POL
        other:
            return ((curr_state >> core#COMP_POL) & 1)

    state := ((curr_state & core#COMP_POL_MASK) | state)
    writereg(core#CONFIG, 2, @state)

PUB int_persistence(cycles): curr_cyc
' Set minimum number of measurements beyond threshold required to assert
'   an interrupt
'   Valid values: 1, 2, 4
'   Any other value polls the chip and returns the current setting
    curr_cyc := 0
    readreg(core#CONFIG, 2, @curr_cyc)
    case cycles
        1, 2, 4:
            cycles := lookdownz(cycles: 1, 2, 4) << core#COMP_QUE
        other:
            curr_cyc := ((curr_cyc >> core#COMP_QUE) & core#COMP_QUE_BITS)
            return lookupz(curr_cyc: 1, 2, 4)

    cycles := ((curr_cyc & core#COMP_QUE_MASK) | cycles)
    writereg(core#CONFIG, 2, @cycles)

PUB ints_latched(state): curr_state
' Enable latching of interrupts
'   Valid values:
'       TRUE (-1 or 1): Active interrupts remain asserted until cleared manually
'       FALSE (0): Active interrupts clear when the measurement returns to
'           within Low and High thresholds
    curr_state := 0
    readreg(core#CONFIG, 2, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) & 1) << core#COMP_LAT
        other:
            return (((curr_state >> core#COMP_LAT) & 1) == 1)

    state := ((curr_state & core#COMP_LAT_MASK) | state)
    writereg(core#CONFIG, 2, @state)

PUB int_thresh_hi(thresh): curr_thr
' Set voltage interrupt high threshold, in microvolts
'   Valid values: 0..5_800000 (0..5.8V)
'   Any other value polls the chip and returns the current setting
'   NOTE: This value should always be higher than int_thresh_low(),
'   for proper operation
    case thresh
        0..5_800000:                            ' supply max + input abs. max
            thresh := volts2adc(thresh)
            writereg(core#HI_THRESH, 2, @thresh)
        other:
            curr_thr := 0
            readreg(core#HI_THRESH, 2, @curr_thr)
            return adc2volts(curr_thr)

PUB int_thresh_low(thresh): curr_thr
' Set voltage interrupt low threshold, in microvolts
'   Valid values: 0..5_800000 (0..5.8V)
'   Any other value polls the chip and returns the current setting
'   NOTE: This value should always be lower than int_thresh_hi(),
'   for proper operation
    case thresh
        0..5_800000:                            ' supply max + input abs. max
            thresh := volts2adc(thresh)
            writereg(core#LO_THRESH, 2, @thresh)
        other:
            curr_thr := 0
            readreg(core#LO_THRESH, 2, @curr_thr)
            return adc2volts(curr_thr)

PUB last_voltage{}: volts
' Return last ADC reading, in microvolts
    return adc2volts(_last_adc)

PUB measure{} | tmp
' Trigger a measurement, when in single-shot mode
    tmp := 0
    readreg(core#CONFIG, 2, @tmp)
    tmp |= (1 << core#OS)
    writereg(core#CONFIG, 2, @tmp)

PUB opmode(mode): curr_mode
' Set operation mode
'   Valid values:
'       CONT (0): Continuous measurement mode
'      *SINGLE (1): Single-shot measurement mode
    curr_mode := 0
    readreg(core#CONFIG, 2, @curr_mode)
    case mode
        CONT, SINGLE:
            mode <<= core#MODE
        other:
            return ((curr_mode >> core#MODE) & 1)

    mode := ((curr_mode & core#MODE_MASK) | mode)
    writereg(core#CONFIG, 2, @mode)

PUB volts2adc(volts): adc_word
' Scale microvolts to ADC word
    return u64.multdiv(volts, 1_0000, _uvolts_lsb)

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from reg_nr into ptr_buff
    case reg_nr
        $00..$03:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)

            i2c.start{}
            i2c.write(SLAVE_RD | _addr_bits)
            i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes from ptr_buff to the slave device
    case reg_nr
        $01..$03:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_msbf(ptr_buff, nr_bytes)
            i2c.stop{}
        other:
            return

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

