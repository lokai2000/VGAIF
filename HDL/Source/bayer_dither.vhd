library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity bayer_dither is
  generic(
    rBits       :natural   := 1;
    gBits       :natural   := 1;
    bBits       :natural   := 1;
    hPol        :std_logic := '0';
    vPol        :std_logic := '0'
  );
  port(
    vgaClk     :in   std_logic;
    vgaRst     :in   std_logic;
    RDataIn     :in   std_logic_vector(7 downto 0);
    GDataIn     :in   std_logic_vector(7 downto 0);
    BDataIn     :in   std_logic_vector(7 downto 0);
    ValidIn     :in   std_logic;
    xCoord      :in   std_logic_vector;
    yCoord      :in   std_logic_vector;
    RData_Out   :out  std_logic_vector(rBits-1 downto 0);
    GData_Out   :out  std_logic_vector(gBits-1 downto 0);
    BData_Out   :out  std_logic_vector(bBits-1 downto 0);
    Valid_Out   :out  std_logic;
    hSync_In    :in   std_logic;
    vSync_In    :in   std_logic;
    hSync_Out   :out  std_logic;
    vSync_Out   :out  std_logic;
    vsync_pulse :in   std_logic
  );
end entity bayer_dither;


architecture rtl_bayer_dither of bayer_dither is

  signal H_Sync_Out_D :std_logic;
  signal H_Sync_Out_Q :std_logic;
  signal V_Sync_Out_D :std_logic;
  signal V_Sync_Out_Q :std_logic;

  component bayer_pixel is
    generic(
      bitDepth   :natural := 1
    );
    port(
       vgaClk   :in   std_logic;
       vgaRst   :in   std_logic;
       Data_In   :in   std_logic_vector(7 downto 0);
       Valid_In  :in   std_logic;
       xCoord    :in   std_logic_vector;
       yCoord    :in   std_logic_vector;
       Data_Out  :out  std_logic_vector(bitDepth-1 downto 0);
       Valid_Out :out  std_logic;
       sync      :in   std_logic
    );
  end component;

begin
  -- -----

  H_Sync_Out_D <= hSync_In;
  V_Sync_Out_D <= vSync_In;
  
  hSync_Out    <= H_Sync_Out_Q;
  vSync_Out    <= V_Sync_Out_Q;
  
  -- -------------------------------------------------------------------
  S_Clk:process(vgaClk, vgaRst)
  begin
    -- -----
    if (vgaRst='1') then
      H_Sync_Out_Q <= hPol;
      V_Sync_Out_Q <= vPol;
    elsif (vgaClk='1' and vgaClk'event) then
      H_Sync_Out_Q <= H_Sync_Out_D;
      V_Sync_Out_Q <= V_Sync_Out_D;
    end if;
    -- -----
  end process;

  -- -------------------------------------------------------------------
  U_RED: bayer_pixel
    generic map(
      bitDepth   => rBits
    )
    port map(
       vgaClk    => vgaClk,
       vgaRst    => vgaRst,
       Data_In   => RDataIn,
       Valid_In  => ValidIn,
       xCoord    => xCoord,
       yCoord    => yCoord,
       Data_Out  => RData_Out,
       Valid_Out => Valid_Out,
       sync      => vsync_pulse
    );

  U_GRN: bayer_pixel
    generic map(
      bitDepth   => gBits
    )
    port map(
       vgaClk    => vgaClk,
       vgaRst    => vgaRst,
       Data_In   => GDataIn,
       Valid_In  => ValidIn,
       xCoord    => xCoord,
       yCoord    => yCoord,
       Data_Out  => GData_Out,
       Valid_Out => open,
       sync      => vsync_pulse
    );

  U_BLU: bayer_pixel
    generic map(
      bitDepth   => bBits
    )
    port map(
       vgaClk    => vgaClk,
       vgaRst    => vgaRst,
       Data_In   => BDataIn,
       Valid_In  => ValidIn,
       xCoord    => xCoord,
       yCoord    => yCoord,
       Data_Out  => BData_Out,
       Valid_Out => open,
       sync      => vsync_pulse
    );

  -- -----
end rtl_bayer_dither;