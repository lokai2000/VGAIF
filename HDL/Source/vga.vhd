library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.vga_pkg.all;

entity vga is
  generic(
     videoMode          :T_VGA_Record;
     rBits              :natural := 1;
     gBits              :natural := 1;
     bBits              :natural := 1
  );
  port(
     vgaClk             :in   std_logic;
     vgaRst             :in   std_logic;
     sysClk             :in   std_logic;
     sysRst             :in   std_logic;
     sysRDatIn          :in   std_logic_vector(7 downto 0);
     sysGDatIn          :in   std_logic_vector(7 downto 0);
     sysBDatIn          :in   std_logic_vector(7 downto 0);
     sysDatInValid      :in   std_logic;
     sysDatReady        :out  std_logic;

     sysHorzFrontPorch  :out  std_logic;
     sysHorzSyncPulse   :out  std_logic; 
     sysHorzBackPorch   :out  std_logic;
     sysHorzVideoActive :out  std_logic; 

     sysVertFrontPorch  :out  std_logic;
     sysVertSyncPulse   :out  std_logic; 
     sysVertBackPorch   :out  std_logic;
     sysVertVideoActive :out  std_logic; 

     sysHSync           :out  std_logic;
     sysVSync           :out  std_logic;

     rPin               :out  std_logic_vector(rBits-1 downto 0);
     gPin               :out  std_logic_vector(gBits-1 downto 0);
     bPin               :out  std_logic_vector(bBits-1 downto 0);
     hSync              :out  std_logic;
     vSync              :out  std_logic
  );
end entity vga;

architecture rtl_vga of vga is


  constant hSize          :natural := videoMode.horzVisible    + 
                                      videoMode.horzFrontPorch + 
                                      videoMode.horzSyncPulse  + 
                                      videoMode.horzBackPorch; 
                          
  constant vSize          :natural := videoMode.vertVisible    + 
                                      videoMode.vertFrontPorch + 
                                      videoMode.vertSyncPulse  + 
                                      videoMode.vertBackPorch; 
                          
  constant hDepth         :natural := ceilLogTwo(hSize);
  constant vDepth         :natural := ceilLogTwo(vSize);
                          
  constant HFP            :natural := videoMode.horzFrontPorch;
  constant HSN            :natural := HFP + videoMode.horzSyncPulse;
  constant HBP            :natural := HSN + videoMode.horzBackPorch;
  constant HAC            :natural := HBP + videoMode.horzVisible;
                          
  constant VFP            :natural := videoMode.vertFrontPorch;
  constant VSN            :natural := VFP + videoMode.vertSyncPulse;
  constant VBP            :natural := VSN + videoMode.vertBackPorch;
  constant VAC            :natural := VBP + videoMode.vertVisible;

  signal vgaVertFP        :std_logic;
  signal vgaVertSync      :std_logic;
  signal vgaVertBP        :std_logic;
  signal vgaVertActive    :std_logic;
  signal vgaVertSyncPulse :std_logic;

  signal vgaHorzFP        :std_logic;
  signal vgaHorzSync      :std_logic;
  signal vgaHorzBP        :std_logic;
  signal vgaHorzActive    :std_logic;    
  signal vgaHorzSyncPulse :std_logic;

  signal rowCnt_D         :unsigned(vDepth-1 downto 0);
  signal rowCnt_Q         :unsigned(vDepth-1 downto 0);
  signal rowCnt_TC        :std_logic;
                          
  signal colCnt_D         :unsigned(hDepth-1 downto 0);
  signal colCnt_Q         :unsigned(hDepth-1 downto 0);
  signal colCnt_TC        :std_logic;

  signal vgahSync_D       :std_logic;
  signal vgavSync_D       :std_logic;
  signal vgahSync_Q       :std_logic;
  signal vgavSync_Q       :std_logic;

  signal vgaRDithdata     :std_logic_vector(7 downto 0);
  signal vgaGDithdata     :std_logic_vector(7 downto 0);
  signal vgaBDithdata     :std_logic_vector(7 downto 0);
  signal vgaRFIFOdata     :std_logic_vector(7 downto 0);
  signal vgaGFIFOdata     :std_logic_vector(7 downto 0);
  signal vgaBFIFOdata     :std_logic_vector(7 downto 0);
  signal vgaFIFOread      :std_logic;
  signal sysFIFOfull      :std_logic;
  signal vgaFIFOempty     :std_logic;
  signal vgaFIFOread_Q    :std_logic;

  signal hSyncPol         :std_logic;
  signal vSyncPol         :std_logic;

  component ccsync is
    port(
      iclk    :in   std_logic;
      irst    :in   std_logic;
      oclk    :in   std_logic;
      orst    :in   std_logic;
      isync   :in   std_logic;
      osync   :out  std_logic
    );
  end component;

  component ccpulse is
    port(
      iclk    :in   std_logic;
      irst    :in   std_logic;
      oclk    :in   std_logic;
      orst    :in   std_logic;
      ipulse  :in   std_logic;
      opulse  :out  std_logic
    );
  end component;

  component vga_fifo is
    port (
      wr_clk      :in  std_logic;
      wr_rst      :in  std_logic;
      rd_clk      :in  std_logic;
      rd_rst      :in  std_logic;
      din         :in  std_logic_vector(7 downto 0);
      wr_en       :in  std_logic;
      rd_en       :in  std_logic;
      dout        :out std_logic_vector(7 downto 0);
      full        :out std_logic;
      almost_full :out std_logic;
      prog_full   :out std_logic;
      empty       :out std_logic
    );
  end component;

  component bayer_dither is
    generic(
      rBits       :natural   := 1;
      gBits       :natural   := 1;
      bBits       :natural   := 1;
      hPol        :std_logic := '0';
      vPol        :std_logic := '0'
    );
    port(
      vgaClk      :in   std_logic;
      vgaRst      :in   std_logic;
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
      vSync_pulse :in   std_logic
    );
  end component;

begin
  -- -----
  sysDatReady      <= not(sysFIFOfull);

  vgavSync_D       <= vgaVertSync;
  vgaVertSyncPulse <= vgavSync_D and not vgavSync_Q;  
  vSyncPol         <= vgaVertSync xor not(videoMode.vertPolarity);
                       
  vgahSync_D       <= vgaHorzSync;
  vgaHorzSyncPulse <= vgahSync_D and not vgahSync_Q;  
  hSyncPol         <= vgaHorzSync xor not(videoMode.horzPolarity);

  vgaVertFP        <= '1' when (rowCnt_Q <  VFP) else '0';
  vgaVertSync      <= '1' when (rowCnt_Q >= VFP  and rowCnt_Q < VSN) else '0';
  vgaVertBP        <= '1' when (rowCnt_Q >= VSN  and rowCnt_Q < VBP) else '0';
  vgaVertActive    <= '1' when (rowCnt_Q >= VBP  and rowCnt_Q < VAC) else '0';
                   
  vgaHorzFP        <= '1' when (colCnt_Q <  HFP) else '0';
  vgaHorzSync      <= '1' when (colCnt_Q >= HFP  and colCnt_Q < HSN) else '0';
  vgaHorzBP        <= '1' when (colCnt_Q >= HSN  and colCnt_Q < HBP) else '0';
  vgaHorzActive    <= '1' when (colCnt_Q >= HBP  and colCnt_Q < HAC) else '0';
                   
  colCnt_D         <= (others=>'0') when (colCnt_TC='1') else
                      colCnt_Q + 1;
  colCnt_TC        <= '1' when (colCnt_Q=(hSize-1)) else '0';
                   
  rowCnt_D         <= (others=>'0' )when (rowCnt_TC='1' and colCnt_TC='1') else
                      rowCnt_Q + 1  when (colCnt_TC='1')  else
                      rowCnt_Q;
  rowCnt_TC        <= '1' when (rowCnt_Q=(vSize-1)) else '0';

  vgaFIFOread      <= vgaVertActive and vgaHorzActive; 


  vgaRDithdata     <= vgaRFIFOdata when (vgaFIFOread='1' and vgaFIFOempty='0') else
                      (others=>'0');
  vgaGDithdata     <= vgaGFIFOdata when (vgaFIFOread='1' and vgaFIFOempty='0') else
                      (others=>'0');
  vgaBDithdata     <= vgaBFIFOdata when (vgaFIFOread='1' and vgaFIFOempty='0') else
                      (others=>'0');

  S_Clk:process(vgaClk, vgaRst)
  begin
    -- -----
    if (vgaRst='1') then
      rowCnt_Q   <= (others=>'0');
      colCnt_Q   <= (others=>'0');
      vgahSync_Q <= '0';
      vgavSync_Q <= '0';
      vgaFIFOread_Q <= '0';
    elsif (vgaClk='1' and vgaClk'event) then
      rowCnt_Q   <= rowCnt_D;
      colCnt_Q   <= colCnt_D;
      vgahSync_Q <= vgahSync_D;
      vgavSync_Q <= vgavSync_D;
      vgaFIFOread_Q <= vgaFIFOread;
    end if;
    -- -----
  end process;

  -- -------------------------------------------------------------------

  U_SrcRFifo: vga_fifo
    port map(
      wr_clk      => sysClk,
      wr_rst      => sysRst,
      rd_clk      => vgaClk,
      rd_rst      => vgaRst,
      din         => sysRDatIn,
      wr_en       => sysDatInValid,
      rd_en       => vgaFIFOread,
      dout        => vgaRFIFOdata,
      full        => open,
      almost_full => open,
      prog_full   => sysFIFOfull,
      empty       => vgaFIFOempty
    );
  
  U_SrcGFifo: vga_fifo
    port map(
      wr_clk      => sysClk,
      wr_rst      => sysRst,
      rd_clk      => vgaClk,
      rd_rst      => vgaRst,
      din         => sysGDatIn,
      wr_en       => sysDatInValid,
      rd_en       => vgaFIFOread,
      dout        => vgaGFIFOdata,
      full        => open,
      almost_full => open,
      prog_full   => open,
      empty       => open
    );
  
  U_SrcBFifo: vga_fifo
    port map(
      wr_clk      => sysClk,
      wr_rst      => sysRst,
      rd_clk      => vgaClk,
      rd_rst      => vgaRst,
      din         => sysBDatIn,
      wr_en       => sysDatInValid,
      rd_en       => vgaFIFOread,
      dout        => vgaBFIFOdata,
      full        => open,
      almost_full => open,
      prog_full   => open,
      empty       => open
    );

 

  U_Dither: bayer_dither
    generic map(
      rBits       => rBits,
      gBits       => gBits,
      bBits       => bBits,
      hPol        => videoMode.horzPolarity,
      vPol        => videoMode.vertPolarity
    )
    port map(
      vgaClk      => vgaClk,
      vgaRst      => vgaRst,
      RDataIn     => vgaRDithdata,
      GDataIn     => vgaGDithdata,
      BDataIn     => vgaBDithdata,
      ValidIn     => vgaFIFOread,
      xCoord      => std_logic_vector(colCnt_Q),
      yCoord      => std_logic_vector(rowCnt_Q),
      RData_Out   => rPin,
      GData_Out   => gPin,
      BData_Out   => bPin,
      Valid_Out   => open,
      hSync_In    => hSyncPol,
      vSync_In    => vSyncPol,
      hSync_Out   => HSync,
      vSync_Out   => VSync,
      vSync_pulse => vgaVertSyncPulse
    );

  U_HFP :ccsync
    port map(
      iclk  => vgaClk,
      irst  => vgaRst,
      oclk  => sysClk,
      orst  => sysRst,
      isync => vgaHorzFP,
      osync => sysHorzFrontPorch
    );

  U_HSN :ccsync
    port map(
      iclk  => vgaClk,
      irst  => vgaRst,
      oclk  => sysClk,
      orst  => sysRst,
      isync => vgaHorzSync,
      osync => sysHorzSyncPulse
    );

  U_HBP :ccsync
    port map(
      iclk  => vgaClk,
      irst  => vgaRst,
      oclk  => sysClk,
      orst  => sysRst,
      isync => vgaHorzBP,
      osync => sysHorzBackPorch
    );

  U_HAC :ccsync
    port map(
      iclk  => vgaClk,
      irst  => vgaRst,
      oclk  => sysClk,
      orst  => sysRst,
      isync => vgaHorzActive,
      osync => sysHorzVideoActive
    );

  U_VFP :ccsync
    port map(
      iclk  => vgaClk,
      irst  => vgaRst,
      oclk  => sysClk,
      orst  => sysRst,
      isync => vgaVertFP,
      osync => sysVertFrontPorch
    );

  U_VSN :ccsync
    port map(
      iclk  => vgaClk,
      irst  => vgaRst,
      oclk  => sysClk,
      orst  => sysRst,
      isync => vgaVertSync,
      osync => sysVertSyncPulse
    );

  U_VBP :ccsync
    port map(
      iclk  => vgaClk,
      irst  => vgaRst,
      oclk  => sysClk,
      orst  => sysRst,
      isync => vgaVertBP,
      osync => sysVertBackPorch
    );

  U_VAC :ccsync
    port map(
      iclk  => vgaClk,
      irst  => vgaRst,
      oclk  => sysClk,
      orst  => sysRst,
      isync => vgaVertActive,
      osync => sysVertVideoActive
    );

  U_HSYNC: ccpulse
    port map(
      iclk    => vgaClk,
      irst    => vgaRst,
      oclk    => sysClk,
      orst    => sysRst,
      ipulse  => vgaHorzSyncPulse,
      opulse  => sysHSync 
    );

  U_VSYNC: ccpulse
    port map(
      iclk    => vgaClk,
      irst    => vgaRst,
      oclk    => sysClk,
      orst    => sysRst,
      ipulse  => vgaVertSyncPulse,
      opulse  => sysVSync 
    );

  -- -----
end rtl_vga;
