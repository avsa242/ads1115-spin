{
    --------------------------------------------
    Filename: core.con.ads1115.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started Dec 29, 2019
    Updated Dec 30, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ        = 400_000
    I2C_MAX_FREQ_HS     = 3_400_000

    SLAVE_ADDR          = $48 << 1

' Register definitions
    CONVERSION          = $00

    CONFIG              = $01
    CONFIG_MASK         = $FFFF
        FLD_OS          = 15
        FLD_MUX         = 12
        FLD_PGA         = 9
        FLD_MODE        = 8
        FLD_DR          = 5
        FLD_COMP_MODE   = 4
        FLD_COMP_POL    = 3
        FLD_COMP_LAT    = 2
        FLD_COMP_QUE    = 0
        BITS_MUX        = %111
        BITS_PGA        = %111
        BITS_DR         = %111
        BITS_COMP_QUE   = %11
        MASK_OS         = CONFIG_MASK ^ (1 << FLD_OS)
        MASK_MUX        = CONFIG_MASK ^ (BITS_MUX << FLD_MUX)
        MASK_PGA        = CONFIG_MASK ^ (BITS_PGA << FLD_PGA)
        MASK_MODE       = CONFIG_MASK ^ (1 << FLD_MODE)
        MASK_DR         = CONFIG_MASK ^ (BITS_DR << FLD_DR)
        MASK_COMP_MODE  = CONFIG_MASK ^ (1 << FLD_COMP_MODE)
        MASK_COMP_POL   = CONFIG_MASK ^ (1 << FLD_COMP_POL)
        MASK_COMP_LAT   = CONFIG_MASK ^ (1 << FLD_COMP_LAT)
        MASK_COMP_QUE   = CONFIG_MASK ^ (BITS_COMP_QUE << FLD_COMP_QUE)

    LO_THRESH           = $02

    HI_THRESH           = $03

PUB Null
'' This is not a top-level object
