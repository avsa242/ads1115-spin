{
    --------------------------------------------
    Filename: signal.adc.ads1115.i2c.spin
    Author: Jesse Burt
    Description: Driver for the TI ADS1115 ADC
    Copyright (c) 2020
    Started Dec 29, 2019
    Updated Nov 2, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 400_000
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

' Operation modes
    CONT                = 0
    SINGLE              = 1

VAR

    long _range
    long _last_adc
    byte _slave_bits

OBJ

    i2c : "com.i2c"                                                 'PASM I2C Driver
    core: "core.con.ads1115.spin"
    time: "time"                                                    'Basic timing functions

PUB Null
''This is not a top-level object

PUB Start: okay                                                     'Default to "standard" Propeller I2C pins, default slave address, and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ, %00)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ, SLAVE_BITS): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if lookdown(SLAVE_BITS: %00, %01, %10, %11)
                if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                    time.MSleep (1)
                    _slave_bits := SLAVE_BITS << 1
                    if i2c.present (SLAVE_WR | _slave_bits)         'Response from device?
                        Defaults
                        return okay

    return FALSE                                                    'If we got here, something went wrong

PUB Stop

    i2c.terminate

PUB Defaults

    OpMode(SINGLE)
    Range(2_048)
    SampleRate(128)

PUB LastVoltage
' Return last ADC reading, in milli-volts
    result := (_last_adc * 1_000) / 32767
    result *= _range / 1_000

PUB Measure | tmp
' Trigger a measurement, when in single-shot mode
    tmp := $0000
    readReg(core#CONFIG, 2, @tmp)
    tmp |= (1 << core#OS)
    writeReg(core#CONFIG, 2, @tmp)

PUB OpMode(mode) | tmp
' Set operation mode
'   Valid values:
'       OPMODE_CONT (0): Continuous measurement mode
'      *OPMODE_SINGLE (1): Single-shot measurement mode
'   NOTE: The Ready method should be used to check measurement ready status
'       when using Single-shot measurement mode.
'       When using continuous measurement mode, using the Ready method will hang.
    tmp := $0000
    readReg(core#CONFIG, 2, @tmp)
    case mode
        CONT, SINGLE:
            mode <<= core#MODE
        OTHER:
            tmp := (tmp >> core#MODE) & %1
            return tmp

    tmp &= core#MODE_MASK
    tmp := (tmp | mode) & core#CONFIG_MASK
    writeReg(core#CONFIG, 2, @tmp)

PUB Range(mV) | tmp
' Set full-scale range of the ADC, in millivolts
'   Valid values:
'       256, 512, 1024, *2048, 4096, 6144
'   Any other value polls the chip and returns the current setting
'   NOTE: This merely affects the scaling of values returned in measurements. It doesn't
'       affect the maximum allowable input range of the chip. Per the datasheet,
'       do NOT exceed VDD + 0.3V on the inputs.
    tmp := $0000
    readReg(core#CONFIG, 2, @tmp)
    case mV
        256, 512, 1_024, 2_048, 4_096, 6_144:
            _range := mV
            mV := lookdownz(mV: 6_144, 4_096, 2_048, 1_024, 0_512, 0_256) << core#PGA
        OTHER:
            tmp := (tmp >> core#PGA) & core#PGA_BITS
            result := lookupz(tmp: 6_144, 4_096, 2_048, 1_024, 0_512, 0_256, 0_256, 0_256)
            return

    tmp &= core#PGA_MASK
    tmp := (tmp | mV) & core#CONFIG_MASK
    writeReg(core#CONFIG, 2, @tmp)

PUB ReadADC(ch) | tmp
' Read measurement from channel ch
'   Valid values: *0, 1, 2, 3
'   Any other value is ignored
    tmp := $0000
    readReg(core#CONFIG, 2, @tmp)
    case ch
        0..3:
            ch := (ch + %100) << core#MUX
        OTHER:
            return FALSE

    tmp &= core#MUX_MASK
    tmp := (tmp | ch) & core#CONFIG_MASK

    writeReg(core#CONFIG, 2, @tmp)
    readReg(core#CONVERSION, 2, @result)
    ~~result                                                ' Extend sign of result
    _last_adc := result

PUB Ready
' Flag indicating measurement is complete
'   Returns: TRUE (-1) if measurement is complete, FALSE otherwise
    result := 0
    readreg(core#config, 2, @result)
    result := ((result >> core#OS) & 1) * TRUE

PUB SampleRate(sps) | tmp
' Set ADC sample rate, in samples per second
'   Valid values: 8, 16, 32, 64, *128, 250, 475, 860
'   Any other value polls the chip and returns the current setting
    tmp := $0000
    readReg(core#CONFIG, 2, @tmp)
    case sps
        8, 16, 32, 64, 128, 250, 475, 860:
            sps := lookdownz(sps: 8, 16, 32, 64, 128, 250, 475, 860) << core#DR
        OTHER:
            tmp := (tmp >> core#DR) & core#DR_BITS
            result := lookupz(tmp: 8, 16, 32, 64, 128, 250, 475, 860)
            return result

    tmp &= core#DR_MASK
    tmp &= core#OS_MASK
    tmp := (tmp | sps) & core#CONFIG_MASK

    writeReg(core#CONFIG, 2, @tmp)
    return tmp

PUB Voltage(ch)
' Return ADC reading, in milli-volts
    result := (ReadADC(ch) * 1_000) / 32767
    result *= _range / 1_000

PRI readReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
' Read nr_bytes from the slave device into the address stored in buff_addr
    case reg
        $00..$03:
            cmd_packet.byte[0] := SLAVE_WR | _slave_bits
            cmd_packet.byte[1] := reg
            i2c.start
            i2c.wr_block (@cmd_packet, 2)

            i2c.start
            i2c.write (SLAVE_RD | _slave_bits)
            repeat tmp from nr_bytes-1 to 0
                byte[buff_addr][tmp] := i2c.read(tmp == 0)
            i2c.stop
        OTHER:
            return

PRI writeReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
' Write nr_bytes to the slave device from the address stored in buff_addr
    case reg
        $01..$03:
            cmd_packet.byte[0] := SLAVE_WR | _slave_bits
            cmd_packet.byte[1] := reg
            i2c.start
            i2c.wr_block (@cmd_packet, 2)

            repeat tmp from nr_bytes-1 to 0
                i2c.write (byte[buff_addr][tmp])
            i2c.stop
        OTHER:
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
