
# ----------------------------------------------------------------------------
## OLED Display - Bank 13
## ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN U10  [get_ports {o_DC}];  # "OLED-DC"
set_property PACKAGE_PIN U9   [get_ports {o_RES}];  # "OLED-RES"
set_property PACKAGE_PIN AB12 [get_ports {o_SPI_CLK}];  # "OLED-SCLK"
set_property PACKAGE_PIN AA12 [get_ports {o_SPI_MOSI}];  # "OLED-SDIN"
set_property PACKAGE_PIN U11  [get_ports {o_VBAT}];  # "OLED-VBAT"
set_property PACKAGE_PIN U12  [get_ports {o_VDD}];  # "OLED-VDD"


# JA Pmod - Bank 13 
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN Y11  [get_ports {o_COLS[3]}];  # "JA1"
set_property PACKAGE_PIN AA11 [get_ports {o_COLS[2]}];  # "JA2"
set_property PACKAGE_PIN Y10  [get_ports {o_COLS[1]}];  # "JA3"
set_property PACKAGE_PIN AA9  [get_ports {o_COLS[0]}];  # "JA4"
set_property PACKAGE_PIN AB11 [get_ports {i_ROWS[3]}];  # "JA7"
set_property PACKAGE_PIN AB10 [get_ports {i_ROWS[2]}];  # "JA8"
set_property PACKAGE_PIN AB9  [get_ports {i_ROWS[1]}];  # "JA9"
set_property PACKAGE_PIN AA8  [get_ports {i_ROWS[0]}];  # "JA10"

#set_property PACKAGE_PIN T22 [get_ports {leds[0]}];  # "LD0"
#set_property PACKAGE_PIN T21 [get_ports {leds[1]}];  # "LD1"
#set_property PACKAGE_PIN U22 [get_ports {leds[2]}];  # "LD2"
#set_property PACKAGE_PIN U21 [get_ports {leds[3]}];  # "LD3"
#set_property PACKAGE_PIN V22 [get_ports {leds[4]}];  # "LD4"
#set_property PACKAGE_PIN W22 [get_ports {leds[5]}];  # "LD5"
#set_property PACKAGE_PIN U19 [get_ports {leds[6]}];  # "LD6"
#set_property PACKAGE_PIN U14 [get_ports {leds[7]}];  # "LD7"



# ----------------------------------------------------------------------------
# Clock Source - Bank 13
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN Y9 [get_ports {i_CLK}];  # "GCLK"

# Note that the bank voltage for IO Bank 13 is fixed to 3.3V on ZedBoard. 
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];
#set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];

# ----------------------------------------------------------------------------
# User Push Buttons - Bank 34
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN P16 [get_ports {i_RST}];  # "BTNC"
set_property PACKAGE_PIN N15 [get_ports {i_CLEAR}];  # "BTNL"


# Set the bank voltage for IO Bank 34 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
