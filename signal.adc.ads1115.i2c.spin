{
    --------------------------------------------
    Filename: signal.adc.ads1115.i2c.spin
    Author: Jesse Burt
    Description: Driver for the TI ADS1115 ADC
    Copyright (c) 2020
    Started Dec 29, 2019
    Updated Nov 3, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 100_000
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

' Operation modes
    CONT                = 0
    SINGLE              = 1

VAR

    long _range
    long _last_adc
    byte _addr_bits

OBJ

    i2c : "com.i2c"                             ' PASM I2C Driver
    core: "core.con.ads1115.spin"
    time: "time"                                ' Basic timing functions

PUB Null{}
' This is not a top-level object

PUB Start{}: okay
' Start with "standard" Propeller I2C pins, default slave address, and 100kHz
    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ, %00)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if lookdown(ADDR_BITS: %00, %01, %10, %11)
                if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)
                    time.msleep(1)
                    _addr_bits := ADDR_BITS << 1
                    if i2c.present(SLAVE_WR | _addr_bits)
                        defaults{}
                        return okay

    return FALSE                                ' Something above went wrong

PUB Stop{}

    i2c.terminate{}

PUB Defaults{}
' Set factory defaults
    opmode(SINGLE)
    range(2_048)
    samplerate(128)

PUB LastVoltage{}: mV
' Return last ADC reading, in milli-volts
    return ((_last_adc * 1_000) / 32767) * (_range / 1_000)

PUB Measure{} | tmp
' Trigger a measurement, when in single-shot mode
    tmp := 0
    readreg(core#CONFIG, 2, @tmp)
    tmp |= (1 << core#OS)
    writereg(core#CONFIG, 2, @tmp)

PUB OpMode(mode): curr_mode
' Set operation mode
'   Valid values:
'       OPMODE_CONT (0): Continuous measurement mode
'      *OPMODE_SINGLE (1): Single-shot measurement mode
    curr_mode := 0
    readreg(core#CONFIG, 2, @curr_mode)
    case mode
        CONT, SINGLE:
            mode <<= core#MODE
        other:
            return (curr_mode >> core#MODE) & %1

    mode := ((curr_mode & core#MODE_MASK) | mode) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @mode)

PUB Range(mV): curr_rng
' Set full-scale range of the ADC, in millivolts
'   Valid values:
'       256, 512, 1024, *2048, 4096, 6144
'   Any other value polls the chip and returns the current setting
'   NOTE: This merely affects the scaling of values returned in measurements. It doesn't
'       affect the maximum allowable input range of the chip. Per the datasheet,
'       do NOT exceed VDD + 0.3V on the inputs.
    curr_rng := 0
    readreg(core#CONFIG, 2, @curr_rng)
    case mV
        256, 512, 1_024, 2_048, 4_096, 6_144:
            _range := mV
            mV := lookdownz(mV: 6_144, 4_096, 2_048, 1_024, 0_512, 0_256) << core#PGA
        other:
            curr_rng := (curr_rng >> core#PGA) & core#PGA_BITS
            return lookupz(curr_rng: 6_144, 4_096, 2_048, 1_024, 0_512, 0_256, 0_256, 0_256)

    mV := ((curr_rng & core#PGA_MASK) | mV) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_rng)

PUB ReadADC(ch): adc_word | tmp
' Read measurement from channel ch
'   Valid values: *0, 1, 2, 3
'   Any other value is ignored
    tmp := 0
    readreg(core#CONFIG, 2, @tmp)
    case ch
        0..3:
            ch := (ch + %100) << core#MUX
        other:
            return FALSE

    tmp &= core#MUX_MASK
    tmp := (tmp | ch) & core#CONFIG_MASK

    writereg(core#CONFIG, 2, @tmp)
    readreg(core#CONVERSION, 2, @adc_word)
    ~~adc_word                                  ' Extend sign of result
    _last_adc := adc_word

PUB Ready{}: flag 'XXX rename to ADCDataReady()
' Flag indicating measurement is complete
'   Returns: TRUE (-1) if measurement is complete, FALSE otherwise
    flag := 0
    readreg(core#config, 2, @flag)
    return ((flag >> core#OS) & 1) == 1

PUB SampleRate(sps): curr_rate
' Set ADC sample rate, in samples per second
'   Valid values: 8, 16, 32, 64, *128, 250, 475, 860
'   Any other value polls the chip and returns the current setting
    curr_rate := 0
    readreg(core#CONFIG, 2, @curr_rate)
    case sps
        8, 16, 32, 64, 128, 250, 475, 860:
            sps := lookdownz(sps: 8, 16, 32, 64, 128, 250, 475, 860) << core#DR
        other:
            curr_rate := (curr_rate >> core#DR) & core#DR_BITS
            return lookupz(curr_rate: 8, 16, 32, 64, 128, 250, 475, 860)

    sps := ((curr_rate & core#DR_MASK & core#OS_MASK) | sps) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @sps)

PUB Voltage(ch): mV
' Return ADC reading, in milli-volts
    return ((readadc(ch) * 1_000) / 32767) * (_range / 1_000)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Read nr_bytes from reg_nr into ptr_buff
    case reg_nr
        $00..$03:
            cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
            cmd_pkt.byte[1] := reg_nr
            i2c.start
            i2c.wr_block (@cmd_pkt, 2)

            i2c.start
            i2c.write (SLAVE_RD | _addr_bits)
            repeat tmp from nr_bytes-1 to 0
                byte[ptr_buff][tmp] := i2c.read(tmp == 0)
            i2c.stop
        other:
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Write nr_bytes from ptr_buff to the slave device
    case reg_nr
        $01..$03:
            cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
            cmd_pkt.byte[1] := reg_nr
            i2c.start
            i2c.wr_block (@cmd_pkt, 2)

            repeat tmp from nr_bytes-1 to 0
                i2c.write (byte[ptr_buff][tmp])
            i2c.stop
        other:
            return

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
