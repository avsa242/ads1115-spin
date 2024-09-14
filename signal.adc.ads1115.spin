{
----------------------------------------------------------------------------------------------------
    Filename:       signal.adc.ads1115.spin
    Description:    Driver for the TI ADS1115 ADC
    Author:         Jesse Burt
    Started:        Feb 8, 2020
    Updated:        Sep 13, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

#include "signal.adc.common.spinh"              ' use code common to all ADC drivers

CON

    { default I/O settings; these can be overridden in the parent object }
    SCL             = 28
    SDA             = 29
    I2C_FREQ        = 100_000
    I2C_ADDR        = 0


    { Operation modes }
    CONT            = 0
    SINGLE          = 1

    { Interrupt active state }
    LOW             = 0
    HIGH            = 1


    SLAVE_WR        = core.SLAVE_ADDR
    SLAVE_RD        = core.SLAVE_ADDR|1
    I2C_MAX_FREQ    = core.I2C_MAX_FREQ


VAR

    long _uvolts_lsb
    long _last_adc
    byte _addr_bits

OBJ

    i2c:    "com.i2c"                             ' PASM I2C engine
    core:   "core.con.ads1115"                    ' HW-specific constants
    time:   "time"                                ' Basic timing functions
    u64:    "math.unsigned64"                     ' unsigned 64-bit int math


PUB null()
' This is not a top-level object


PUB start(): status
' Start using default I/O settings
    return startx(SCL, SDA, I2C_FREQ, I2C_ADDR)


PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start the driver with custom I/O settings
'   SCL_PIN:    I2C clock, 0..31
'   SDA_PIN:    I2C data, 0..31
'   I2C_HZ:     I2C clock speed (max official specification is 400_000 but is unenforced)
'   ADDR_BITS:  I2C alternate address bit, %00..%11
'   Returns:
'       cog ID+1 of I2C engine on success (= calling cog ID+1, if the bytecode I2C engine is used)
'       0 on failure
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( lookdown(ADDR_BITS: %00, %01, %10, %11) )
            if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
                time.usleep(core.T_POR)
                _addr_bits := (ADDR_BITS << 1)
                if ( i2c.present(SLAVE_WR | _addr_bits) )
                    defaults()
                    return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE


PUB stop()
' Stop the driver
    i2c.deinit()
    _uvolts_lsb := _last_adc := _addr_bits := 0


PUB defaults()
' Set factory defaults
    opmode(SINGLE)
    adc_scale(2_048)
    adc_data_rate(128)


PUB adc_channel(): ch
' Get currently active ADC channel
    return adc_chan_ena()


PUB adc_data(): adc_word
' Read measurement from channel ch
'   Valid values: *0, 1, 2, 3
'   Any other value is ignored
    adc_word := readreg(core.CONVERSION)
    ~~adc_word                                  ' extend sign bit
    _last_adc := adc_word


PUB adc_data_rate(rate=-2): curr_rate
' Set ADC sample rate, in Hz
'   Valid values: 8, 16, 32, 64, *128, 250, 475, 860
'   Any other value polls the chip and returns the current setting
    curr_rate := readreg(core.CONFIG)
    case rate
        8, 16, 32, 64, 128, 250, 475, 860:
            rate := lookdownz(rate: 8, 16, 32, 64, 128, 250, 475, 860) << core.DR
            rate := ((curr_rate & core.DR_MASK & core.OS_MASK) | rate)
            writereg(core.CONFIG, rate)
        other:
            curr_rate := ((curr_rate >> core.DR) & core.DR_BITS)
            return lookupz(curr_rate: 8, 16, 32, 64, 128, 250, 475, 860)


PUB adc_data_rdy(): flag
' Flag indicating measurement is complete
'   Returns: TRUE (-1) if measurement is complete, FALSE otherwise
    return ( ( (readreg(core.CONFIG) >> core.OS) & 1) == 1 )


PUB adc_scale(scale=-2): curr_scl
' Set full-scale range of the ADC, in millivolts
'   Valid values:
'       256, 512, 1024, *2048, 4096, 6144
'   Any other value polls the chip and returns the current setting
'   NOTE: This merely affects the scaling of values returned in measurements.
'   It doesn't affect the maximum allowable input range of the chip.
'   Per the datasheet, do NOT exceed VDD + 0.3V on the inputs.
    curr_scl := readreg(core.CONFIG)
    case scale
        256, 512, 1_024, 2_048, 4_096, 6_144:
            scale := lookdownz(scale: 6_144, 4_096, 2_048, 1_024, 0_512, 0_256)
            { set scaling factor }
            _uvolts_lsb := lookupz(scale: 187_5000, 125_0000, 62_5000, 31_2500, 15_6250, 7_8125)
            scale <<= core.PGA
            scale := ((curr_scl & core.PGA_MASK) | scale)
            writereg(core.CONFIG, scale)
        other:
            curr_scl := ((curr_scl >> core.PGA) & core.PGA_BITS)
            return lookupz(curr_scl: 6_144, 4_096, 2_048, 1_024, 0_512, 0_256, 0_256, 0_256)


PUB adc2volts(adc_word): volts
' Scale ADC word to microvolts
    return u64.multdiv(adc_word, _uvolts_lsb, 1_0000)


CON

    { differential measurement modes }
    DIFF_POS0_NEG1  = 0
    DIFF_POS0_NEG3  = 1
    DIFF_POS1_NEG3  = 2
    DIFF_POS2_NEG3  = 3

PUB differential_mode(m=-2): curr_m
' Select differential measurement mode
'   (measure one channel referenced to another)
'   Valid values:
'       Symbol          Value   Pos. channel    Neg. channel
'       DIFF_POS0_NEG1  0       0               1
'       DIFF_POS0_NEG3  1       0               3
'       DIFF_POS1_NEG3  2       1               3
'       DIFF_POS2_NEG3  3       2               3
'   Any other value polls the chip and returns the current setting
    curr_m := readreg(core.CONFIG)
    case m
        0..3:
            m := ((curr_m & core.MUX_MASK) | (m << core.MUX) )
            writereg(core.CONFIG, m)
        other:
            return ((m >> core.MUX) & core.MUX_BITS)


PUB int_polarity(state=-2): curr_state
' Set interrupt pin active state/logic level
'   Valid values: LOW (0), HIGH (1)
'   Any other value polls the chip and returns the current setting
    curr_state := readreg(core.CONFIG)
    case state
        LOW, HIGH:
            state := ((curr_state & core.COMP_POL_MASK) | (state << core.COMP_POL) )
            writereg(core.CONFIG, state)
        other:
            return ((curr_state >> core.COMP_POL) & 1)


PUB int_duration(cycles=-2): curr_cyc
' Set minimum number of measurements beyond threshold required to assert
'   an interrupt
'   Valid values: 1, 2, 4
'   Any other value polls the chip and returns the current setting
    curr_cyc := readreg(core.CONFIG)
    case cycles
        1, 2, 4:
            cycles := lookdownz(cycles: 1, 2, 4) << core.COMP_QUE
            cycles := ((curr_cyc & core.COMP_QUE_MASK) | cycles)
            writereg(core.CONFIG, cycles)
        other:
            curr_cyc := ((curr_cyc >> core.COMP_QUE) & core.COMP_QUE_BITS)
            return lookupz(curr_cyc: 1, 2, 4)


PUB int_latch_ena(state=-2): curr_state
' Enable latching of interrupts
'   Valid values:
'       TRUE (-1 or 1): Active interrupts remain asserted until cleared manually
'       FALSE (0): Active interrupts clear when the measurement returns to
'           within Low and High thresholds
    curr_state := readreg(core.CONFIG)
    case ||(state)
        0, 1:
            state := (||(state) & 1) << core.COMP_LAT
            state := ((curr_state & core.COMP_LAT_MASK) | state)
            writereg(core.CONFIG, state)
        other:
            return (((curr_state >> core.COMP_LAT) & 1) == 1)


PUB int_set_hi_thresh(thresh)
' Set voltage interrupt high threshold, in microvolts
'   Valid values: 0..5_800000 (0..5.8V; clamped to range)
'   NOTE: This value should always be higher than int_thresh_low(), for proper operation
    writereg(core.HI_THRESH, (volts2adc(0 #> thresh <# 5_800000) ) )


PUB int_set_lo_thresh(thresh)
' Set voltage interrupt low threshold, in microvolts
'   Valid values: 0..5_800000 (0..5.8V; clamped to range)
'   NOTE: This value should always be lower than int_thresh_hi(),
'   for proper operation
    writereg(core.LO_THRESH, (volts2adc(0 #> thresh <# 5_800000) ) )


PUB int_hi_thresh(): thresh
' Get voltage interrupt high threshold, in microvolts
    return adc2volts( readreg(core.HI_THRESH) )


PUB int_lo_thresh(): curr_thr
' Get voltage interrupt low threshold, in microvolts
    return adc2volts( readreg(core.LO_THRESH) )


PUB last_voltage(): volts
' Return last ADC reading, in microvolts
    return adc2volts(_last_adc)


PUB measure()
' Trigger a measurement, when in single-shot mode
    writereg(core.CONFIG, ( readreg(core.CONFIG) | core.MEAS_ONE ) )


PUB opmode(mode=-2): curr_mode
' Set operation mode
'   Valid values:
'       CONT (0): Continuous measurement mode
'      *SINGLE (1): Single-shot measurement mode
    curr_mode := readreg(core.CONFIG)
    case mode
        CONT, SINGLE:
            mode := ( (curr_mode & core.MODE_MASK) | (mode << core.MODE) )
            writereg(core.CONFIG, mode)
        other:
            return ((curr_mode >> core.MODE) & 1)


PUB set_adc_channel(ch)
' Set active ADC channel
'   (single-ended measurement mode: selected channel referenced to GND)
'   Valid values: 0..3 (clamped to range)
    adc_chan_ena(0 #> ch <# 3)


PUB volts2adc(volts): adc_word
' Scale microvolts to ADC word
    return u64.multdiv(volts, 1_0000, _uvolts_lsb)


PRI adc_chan_ena(ch=-2): curr_ch
' Set active ADC channel
'   Valid values: 0..3
'   Any other value polls the chip and returns the current setting
    curr_ch := readreg(core.CONFIG)
    case ch
        0..3:
            ch := ( (curr_ch & core.MUX_MASK) | ( (ch + %100) << core.MUX ) )
            writereg(core.CONFIG, ch)
        other:
            return (((ch >> core.MUX) & %111) - %100)


PRI readreg(reg_nr): v | cmd_pkt
' Read nr_bytes from reg_nr into ptr_buff
    case reg_nr
        $00..$03:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr
            i2c.start()
            i2c.wrblock_lsbf(@cmd_pkt, 2)

            i2c.start()
            i2c.write(SLAVE_RD | _addr_bits)
            i2c.rdblock_msbf(@v, 2, i2c.NAK)
            i2c.stop()
        other:
            return


PRI writereg(reg_nr, v) | cmd_pkt
' Write nr_bytes from ptr_buff to the slave device
    case reg_nr
        $01..$03:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr
            i2c.start()
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_msbf(@v, 2)
            i2c.stop()
        other:
            return


DAT
{
Copyright 2024 Jesse Burt

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

