library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.std_logic_misc.all;


library work;
use work.vga_pkg.all;


entity car is
 generic(
   videoMode    : T_VGA_Record;
   sysClockFreq : real;
   sysAltClkSel : boolean := false 
 );
 port(
   extClk    :in  std_logic;
   vgaClk    :out std_logic;
   vgaRst    :out std_logic;
   sysClk    :out std_logic;
   sysRst    :out std_logic;
   extRst    :in  std_logic
 );
end entity car;

architecture rtl_car of car is

  signal rst_D         :std_logic_vector(4 downto 0):=(others=>'1');
  signal rst_Q         :std_logic_vector(4 downto 0):=(others=>'1');
  signal sysrst_D      :std_logic_vector(4 downto 0):=(others=>'1');
  signal sysrst_Q      :std_logic_vector(4 downto 0):=(others=>'1');

  signal pll_clock     :std_logic;
  signal pll_sysclock  :std_logic;
  signal pll_locked    :std_logic;

  signal rst_ext_D : std_logic_vector(7 downto 0);
  signal rst_ext_Q : std_logic_vector(7 downto 0);

  component zeddcm is
    generic(
      videoMode    : T_VGA_Record;
      sysClockFreq : real;
      sysAltClkSel : boolean := false 
    );
    port(
      clk_in     : in  std_logic;
      clk_out    : out std_logic;
      clkfx_out  : out std_logic; 
      reset      : in  std_logic;
      locked_out : out std_logic
    );
  end component;

begin
  -- -----

  sysClk   <= pll_sysclock;
  sysRst   <= sysrst_Q(sysrst_Q'left);
           
  vgaClk   <= pll_clock;
  vgaRst   <= rst_Q(rst_Q'left);

  rst_D    <= rst_Q(rst_Q'left-1 downto 0)    & (not(pll_locked) or or_reduce(rst_ext_Q));
  sysrst_D <= sysrst_Q(sysrst_Q'left-1 downto 0) & (not(pll_locked) or or_reduce(rst_ext_Q));
  
  rst_ext_D <= rst_ext_Q(rst_ext_Q'left-1 downto 0) & '0';


  S_extRst : process(extRst, pll_sysclock)
  begin
    -- -----
    if ( extRst = '1' ) then
      rst_ext_Q <= (others=>'1');
    elsif ( rising_edge(pll_sysclock) ) then
      rst_ext_Q <= rst_ext_D;
    end if;
    -- -----
  end process;


  S_Rst:process(pll_clock)
  begin
    -- -----
    if (pll_clock='1' and pll_clock'event) then
        rst_Q <= rst_D;
    end if;
    -- -----
  end process;

  S_SysRst:process(pll_sysclock)
  begin
    -- -----
    if (pll_sysclock='1' and pll_sysclock'event) then
        sysrst_Q <= sysrst_D;
    end if;
    -- -----
  end process;

  U_DCM : zeddcm 
    generic map (
      videoMode    => videoMode,
      sysClockFreq => sysClockFreq,
      sysAltClkSel => sysAltClkSel
    )
    port map (
      clk_in     => extClk,
      clk_out    => pll_sysclock,
      clkfx_out  => pll_clock, 
      reset      => '0',
      locked_out => pll_locked
    );

  -- -----
end rtl_car;
