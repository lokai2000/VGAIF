library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.vga_pkg.all;
--use work.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity zeddcm is
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
end zeddcm;

architecture rtl_zeddcm of zeddcm is

  type T_Parms is array(natural range 0 to 2) of natural;

  function getParms(sysClockFreq :real; vgaClockFreq :real) return T_Parms is
    variable M        : natural;
    variable D        : natural;
    variable S        : natural;
    variable nClk     : real;
    variable err      : real;
    variable minError : real;
    variable vco      : real;
    variable Res      : T_Parms;
    constant period   : real := (1.0/sysClockFreq) * 1.0E9;
  begin
    -- -----
    minError := sysClockFreq;
    M        := 2;
    D        := 2;
    S        := 1;
    
       
    for j in 2 to 64 loop
      for i in 1 to 128 loop
        -- -----    
        nClk := sysClockFreq * real(j)/real(i);
        err  := vgaClockFreq-nClk;
        err  := err*sign(err);
        vco  := (real(j)*1000.0)/(period*real(S));
        --800 : 1600
        if (err<minError and vco>=800.0 and vco<=1600.0) then
          minError := err;
          M        := j;
          D        := i;
        end if;
        -- -----
      end loop;
    end loop;


    Res(0) := M * S;
    Res(1) := D;
    Res(2) := S;
    
    return Res;
    -- -----
  end getParms;

  constant dcmParms :T_Parms := getParms(sysClockFreq, videoMode.dotClockHz);

  signal dcm_sysclk : std_logic;
  signal dcm_vgaclk : std_logic;

  signal dcm_fbout : std_logic;
  signal dcm_fbin  : std_logic;

  signal clkinbuf : std_logic;
  
  signal clkfx : std_logic;
  
  constant oner   : real := 1.0;
  constant scalar : real := 1.0E9;
  constant period : real := (oner/sysClockFreq)*scalar;
  
begin

  UG_ALT : if sysAltClkSel generate

    dcm_sysclk <= clkfx;
    clkfx_out  <= clkfx;

    U_VGABUF: BUFG
      port map (
        I => dcm_vgaclk,
        O => clkfx
      );

  end generate UG_ALT;


  UG_NOALT : if not(sysAltClkSel) generate

    U_SYSBUF: BUFG
      port map (
        I => dcm_sysclk,
        O => clk_out
      );

    U_VGABUF: BUFG
      port map (
        I => dcm_vgaclk,
        O => clkfx_out
      );

  end generate UG_NOALT;


  U_IBUF: IBUF
    generic map (
      IOSTANDARD => "DEFAULT"
    )
    port map (
      I => clk_in,
      O => clkinbuf
    );

  U_FBBUF: BUFG
    port map (
      I => dcm_fbout,
      O => dcm_fbin
    );


  U_PLL : PLLE2_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLKFBOUT_MULT      => dcmParms(0),
      CLKFBOUT_PHASE     => 0.0,
      CLKIN1_PERIOD      => period,
      CLKOUT0_DIVIDE     => dcmParms(0),
      CLKOUT1_DIVIDE     => dcmParms(1),
      CLKOUT2_DIVIDE     => 1,
      CLKOUT3_DIVIDE     => 1,
      CLKOUT4_DIVIDE     => 1,
      CLKOUT5_DIVIDE     => 1,
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT0_PHASE      => 0.0,
      CLKOUT1_PHASE      => 0.0,
      CLKOUT2_PHASE      => 0.0,
      CLKOUT3_PHASE      => 0.0,
      CLKOUT4_PHASE      => 0.0,
      CLKOUT5_PHASE      => 0.0,
      DIVCLK_DIVIDE      => dcmParms(2),       
      REF_JITTER1        => 0.0,     
      STARTUP_WAIT       => "FALSE"  
    )
    port map (
      CLKOUT0  => dcm_sysclk,
      CLKOUT1  => dcm_vgaclk,
      CLKOUT2  => open,  
      CLKOUT3  => open,  
      CLKOUT4  => open,  
      CLKOUT5  => open,  
      CLKFBOUT => dcm_fbout,
      LOCKED   => locked_out,
      CLKIN1   => clkinbuf,
      PWRDWN   => '0',
      RST      => reset,
      CLKFBIN  => dcm_fbin
    );

end rtl_zeddcm;
