library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;

library unimacro;
use unimacro.vcomponents.all;


entity vga_if_fifo is
  port (
    wr_clk      : in  std_logic;
    wr_rst      : in  std_logic;
    rd_clk      : in  std_logic;
    rd_rst      : in  std_logic;
    din         : in  std_logic_vector(31 downto 0);
    wr_en       : in  std_logic;
    rd_en       : in  std_logic;
    dout        : out std_logic_vector(31 downto 0);
    full        : out std_logic;
    almost_full : out std_logic;
    prog_full   : out std_logic;
    empty       : out std_logic
  );
end entity vga_if_fifo;

architecture rtl_vga_if_fifo of vga_if_fifo is

  signal wcount : std_logic_vector(8 downto 0);

begin

  prog_full <= '1' when unsigned(wcount)>500 else '0';

  U_FIFO : FIFO_DUALCLOCK_MACRO
  generic map (
    DEVICE                  => "7SERIES", 
    ALMOST_FULL_OFFSET      => X"0100",   
    ALMOST_EMPTY_OFFSET     => X"0080",   
    DATA_WIDTH              => 32,         
    FIFO_SIZE               => "18Kb",   
    FIRST_WORD_FALL_THROUGH => true
  )
  port map (
    ALMOSTEMPTY => open,
    ALMOSTFULL  => almost_full,
    DO          => dout,
    EMPTY       => empty,
    FULL        => full,
    RDCOUNT     => open,
    RDERR       => open,
    WRCOUNT     => wcount,
    WRERR       => open,
    DI          => din,
    RDCLK       => rd_clk,
    RDEN        => rd_en, 
    RST         => wr_rst,
    WRCLK       => wr_clk, 
    WREN        => wr_en 
  );

end architecture rtl_vga_if_fifo;
