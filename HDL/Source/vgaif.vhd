library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

library work;
use work.vga_registers_pkg.all;
use work.vga_pkg.all;

entity vgaif is
  generic (
    G_VIDEOX     : natural := 1024;
    G_VIDEOY     : natural := 1024;
    G_SCREENX    : natural := 640;
    G_SCREENY    : natural := 480;
    G_MATID      : natural := 0;
    G_MATDEST    : natural := 0;
    G_EXTCLKFREQ : natural := 100000000
  );
  port (

    extclk    : in  std_logic;

    aclk      : out std_logic;
    areset_n  : out std_logic;

    ma_tdata  : out std_logic_vector(71 downto 0);
    ma_tstrb  : out std_logic_vector(8 downto 0);
    ma_tkeep  : out std_logic_vector(8 downto 0);
    ma_tvalid : out std_logic;
    ma_tready : in  std_logic;
    ma_tlast  : out std_logic;
    ma_tid    : out std_logic_vector(3 downto 0);
    ma_tdest  : out std_logic_vector(3 downto 0);

    ms_tdata  : in  std_logic_vector(7 downto 0);
    ms_tstrb  : in  std_logic_vector(0 downto 0);
    ms_tkeep  : in  std_logic_vector(0 downto 0);
    ms_tvalid : in  std_logic;
    ms_tready : out std_logic;
    ms_tlast  : in  std_logic;
    ms_tid    : in  std_logic_vector(3 downto 0);
    ms_tdest  : in  std_logic_vector(3 downto 0);

    ctrl_araddr  : in  std_logic_vector(31 downto 0);
    ctrl_arready : out std_logic;
    ctrl_arvalid : in  std_logic;
    ctrl_awaddr  : in  std_logic_vector(31 downto 0);
    ctrl_awready : out std_logic;
    ctrl_awvalid : in  std_logic;
    ctrl_bready  : in  std_logic;
    ctrl_bresp   : out std_logic_vector(1 downto 0);
    ctrl_bvalid  : out std_logic;
    ctrl_rdata   : out std_logic_vector(31 downto 0);
    ctrl_rready  : in  std_logic;
    ctrl_rresp   : out std_logic_vector(1 downto 0);
    ctrl_rvalid  : out std_logic;
    ctrl_wdata   : in  std_logic_vector(31 downto 0);
    ctrl_wready  : out std_logic;
    ctrl_wstrb   : in  std_logic_vector(3 downto 0);
    ctrl_wvalid  : in  std_logic;

    data_tdata  : in  std_logic_vector(31 downto 0);
    data_tstrb  : in  std_logic_vector(3 downto 0);
    data_tkeep  : in  std_logic_vector(3 downto 0);
    data_tvalid : in  std_logic;
    data_tready : out std_logic;
    data_tlast  : in  std_logic;
    data_tid    : in  std_logic_vector(3 downto 0);
    data_tdest  : in  std_logic_vector(3 downto 0);

    R_Pin  : out std_logic_vector(3 downto 0);
    G_Pin  : out std_logic_vector(3 downto 0);
    B_Pin  : out std_logic_vector(3 downto 0);
    H_Sync : out std_logic;
    V_Sync : out std_logic

  );
end entity vgaif;

architecture rtl_vgaif of vgaif is


  signal registers_source : T_registers;
  signal registers_sink   : T_registers;


  signal screen_ena   : std_logic;
  signal screen_ptr   : std_logic_vector(31 downto 0);
  signal screen_ofsx  : std_logic_vector(15 downto 0);
  signal screen_ofsy  : std_logic_vector(15 downto 0);


  component vga_addrgen is
    generic (
      G_VIDEOX  : natural := 1024;
      G_VIDEOY  : natural := 1024;
      G_SCREENX : natural := 640;
      G_SCREENY : natural := 480;
      G_MATID   : natural := 0;
      G_MATDEST : natural := 0
    );
    port (
      aclk      : in  std_logic;
      areset_n  : in  std_logic;
      
      ma_tdata  : out std_logic_vector(71 downto 0);
      ma_tstrb  : out std_logic_vector(8 downto 0);
      ma_tkeep  : out std_logic_vector(8 downto 0);
      ma_tvalid : out std_logic;
      ma_tready : in  std_logic;
      ma_tlast  : out std_logic;
      ma_tid    : out std_logic_vector(3 downto 0);
      ma_tdest  : out std_logic_vector(3 downto 0);

      ms_tdata  : in  std_logic_vector(7 downto 0);
      ms_tstrb  : in  std_logic_vector(0 downto 0);
      ms_tkeep  : in  std_logic_vector(0 downto 0);
      ms_tvalid : in  std_logic;
      ms_tready : out std_logic;
      ms_tlast  : in  std_logic;
      ms_tid    : in  std_logic_vector(3 downto 0);
      ms_tdest  : in  std_logic_vector(3 downto 0);

      screen_ena   : in  std_logic;
      screen_ptr   : in  std_logic_vector(31 downto 0);
      screen_ofsx  : in  std_logic_vector(15 downto 0);
      screen_ofsy  : in  std_logic_vector(15 downto 0);
      screen_cmplt : out std_logic

    );
  end component vga_addrgen;


  component vga_registers_core is
    port (
      aclk             : in  std_logic;
      areset_n         : in  std_logic;
      ctrl_araddr      : in  std_logic_vector(31 downto 0);
      ctrl_arready     : out std_logic;
      ctrl_arvalid     : in  std_logic;
      ctrl_awaddr      : in  std_logic_vector(31 downto 0);
      ctrl_awready     : out std_logic;
      ctrl_awvalid     : in  std_logic;
      ctrl_bready      : in  std_logic;
      ctrl_bresp       : out std_logic_vector(1 downto 0);
      ctrl_bvalid      : out std_logic;
      ctrl_rdata       : out std_logic_vector(31 downto 0);
      ctrl_rready      : in  std_logic;
      ctrl_rresp       : out std_logic_vector(1 downto 0);
      ctrl_rvalid      : out std_logic;
      ctrl_wdata       : in  std_logic_vector(31 downto 0);
      ctrl_wready      : out std_logic;
      ctrl_wstrb       : in  std_logic_vector(3 downto 0);
      ctrl_wvalid      : in  std_logic;
      registers_source : out T_registers;
      registers_sink   : in  T_registers
    );
  end component vga_registers_core;


  component car is
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
  end component;


  component vga is
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
  end component;


  type T_state is (
    E_IDLE,
    E_PENDING,
    E_SYNC
  );


  constant K_CLASS : std_logic_vector(6 downto 0)  := std_logic_vector(to_unsigned(0,7));
  constant K_YEAR  : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(2017,11));
  constant K_MONTH : std_logic_vector(3 downto 0)  := std_logic_vector(to_unsigned(11,4));
  constant K_DAY   : std_logic_vector(4 downto 0)  := std_logic_vector(to_unsigned(30,5));
  constant K_HOUR  : std_logic_vector(4 downto 0)  := std_logic_vector(to_unsigned(19,5));

  constant K_IFID : std_logic_vector(31 downto 0) := x"ABCDEF00";

  --Remember to set in GENERICS AS WELL!!!
  --constant K_VMODE   : T_VGA_Record := video_VGA_640x480_60Hz;
  constant K_VMODE   : T_VGA_Record := video_SVGA_800x600_60Hz;
  --Remember to set in GENERICS AS WELL!!!

  constant K_VGABITS : natural := 4;
  constant K_SCREENX : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(K_VMODE.horzVisible,16));
  constant K_SCREENY : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(K_VMODE.vertVisible,16));
  constant K_VIDEOX  : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(G_VIDEOX,16));
  constant K_VIDEOY  : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(G_VIDEOY,16));

  signal vgaClk  : std_logic;
  signal vgaRst  : std_logic;
  signal sysClk  : std_logic;
  signal sysRst  : std_logic;
  signal sysRst_n : std_logic;

  signal red_ch    : std_logic_Vector(7 downto 0);
  signal green_ch  : std_logic_Vector(7 downto 0);
  signal blue_ch   : std_logic_Vector(7 downto 0);
  signal valid_ch  : std_logic;
  signal ready_ch  : std_logic;

  signal sysVSync : std_logic;

  signal state_D : T_state;
  signal state_Q : T_state;

  --attribute mark_debug : string; 
  --attribute mark_debug of  ma_tdata : signal is "true";
  --attribute mark_debug of  ma_tvalid: signal is "true";
  --attribute mark_debug of  ma_tready: signal is "true";
  --attribute mark_debug of  ma_tlast : signal is "true";
  --attribute mark_debug of  data_tdata: signal is "true";
  --attribute mark_debug of  data_tvalid: signal is "true";
  --attribute mark_debug of  data_tready: signal is "true";
  --attribute mark_debug of  data_tlast: signal is "true";


begin
  -- -----

  S_clk : process (
    sysClk,
    sysRst
  )
  begin 
    -- -----
    if ( sysRst = '1' ) then
      state_Q        <= E_IDLE;
    elsif ( rising_edge(sysClk) ) then
      state_Q        <= state_D;
    end if;
    -- -----
  end process S_clk;


  aclk     <= sysClk;
  sysRst_n <= not(sysRst);
  areset_n <= not(sysRst);

  U_car : car
   generic map (
     videoMode    => K_VMODE,
     sysClockFreq => 100000000.0,
     sysAltClkSel => false
   )
   port map (
     extClk => extclk,
     vgaClk => vgaClk,
     vgaRst => vgaRst,
     sysClk => sysClk,
     sysRst => sysRst,
     extRst => registers_source.VIDEOCTRL.rst(registers_source.VIDEOCTRL.rst'left)
   );


  registers_sink.REVID.class <= K_CLASS;
  registers_sink.REVID.year  <= K_YEAR;
  registers_sink.REVID.month <= K_MONTH;
  registers_sink.REVID.day   <= K_DAY;
  registers_sink.REVID.hour  <= K_HOUR;

  registers_sink.IFID.interfaceID <= K_IFID;

  registers_sink.WRAPBACK.wrapData <= registers_source.WRAPBACK.base.raw xor registers_source.SYSID.base.raw;

  screen_ena  <= registers_source.VIDEOCTRL.ena(0);
  screen_ptr  <= registers_source.VIDEOPTR.ptr;
  screen_ofsx <= registers_source.SCREENOFSX.ofsX;
  screen_ofsy <= registers_source.SCREENOFSY.ofsY;

  registers_sink.VIDEOX.xSize  <= K_VIDEOX;
  registers_sink.VIDEOY.ySize  <= K_VIDEOX;
  registers_sink.SCREENX.xSize <= K_SCREENX;
  registers_sink.SCREENY.ySize <= K_SCREENY;

  registers_sink.KEYSIZE.lblSize        <= (others=>'0');
  registers_sink.KEYREMAIN.lblRemain    <= (others=>'0');
  registers_sink.KEYSTATUS.lblActive(0) <= '0';
  registers_sink.KEYACTIVE.lastLbl      <= (others=>'0');
  

  U_reg : vga_registers_core 
    port map (
      aclk             => sysClk,
      areset_n         => sysRst_n,
      ctrl_araddr      => ctrl_araddr,
      ctrl_arready     => ctrl_arready,
      ctrl_arvalid     => ctrl_arvalid,
      ctrl_awaddr      => ctrl_awaddr,
      ctrl_awready     => ctrl_awready,
      ctrl_awvalid     => ctrl_awvalid,
      ctrl_bready      => ctrl_bready,
      ctrl_bresp       => ctrl_bresp,
      ctrl_bvalid      => ctrl_bvalid,
      ctrl_rdata       => ctrl_rdata,
      ctrl_rready      => ctrl_rready,
      ctrl_rresp       => ctrl_rresp,
      ctrl_rvalid      => ctrl_rvalid,
      ctrl_wdata       => ctrl_wdata,
      ctrl_wready      => ctrl_wready,
      ctrl_wstrb       => ctrl_wstrb,
      ctrl_wvalid      => ctrl_wvalid,
      registers_source => registers_source,
      registers_sink   => registers_sink
    );


  U_dma : vga_addrgen 
    generic map(
      G_VIDEOX  => G_VIDEOX,
      G_VIDEOY  => G_VIDEOY,
      G_SCREENX => G_SCREENX,
      G_SCREENY => G_SCREENY,
      G_MATID   => G_MATID,
      G_MATDEST => G_MATDEST
    )
    port map (
      aclk      => sysClk,
      areset_n  => sysRst_n,
      
      ma_tdata  => ma_tdata,
      ma_tstrb  => ma_tstrb,
      ma_tkeep  => ma_tkeep,
      ma_tvalid => ma_tvalid,
      ma_tready => ma_tready,
      ma_tlast  => ma_tlast,
      ma_tid    => ma_tid,
      ma_tdest  => ma_tdest,

      ms_tdata  => ms_tdata,
      ms_tstrb  => ms_tstrb,
      ms_tkeep  => ms_tkeep,
      ms_tvalid => ms_tvalid,
      ms_tready => ms_tready,
      ms_tlast  => ms_tlast,
      ms_tid    => ms_tid,
      ms_tdest  => ms_tdest,

      screen_ena   => screen_ena,
      screen_ptr   => screen_ptr,
      screen_ofsx  => screen_ofsx,
      screen_ofsy  => screen_ofsy,
      screen_cmplt => open

    );


  red_ch   <= data_tdata(15 downto 8);
  green_ch <= data_tdata(23 downto 16);
  blue_ch  <= data_tdata(31 downto 24);


  C_state : process (
    state_Q,
    sysVSync,
    screen_ena,
    ready_ch,
    data_tvalid
  )
  begin 
    -- -----
    state_D        <= state_Q;
    data_tready    <= '0';
    valid_ch       <= '0';
    -- -----
    case state_Q is
      
      when E_IDLE =>
        if ( screen_ena = '1' ) then
          state_D <= E_PENDING;
        end if;
        

      when E_PENDING => 
        if ( sysVSync = '1' ) then
          state_D <= E_SYNC;
        end if;
 

      when E_SYNC =>
        data_tready <= ready_ch;
        valid_ch    <= data_tvalid and ready_ch;
        if ( screen_ena = '0' and sysVSync = '1' ) then
          state_D <= E_IDLE;
        end if;
                

      when others =>
        state_D <= E_IDLE;

    end case;
    -- -----
  end process;


  

  U_vga : vga
    generic map(
       videoMode => K_VMODE,
       rBits     => 4,
       gBits     => 4,
       bBits     => 4 
    )
    port map(
       vgaClk         => vgaClk,
       vgaRst         => vgaRst,
       sysClk         => sysClk,
       sysRst         => sysRst,
       sysRDatIn      => red_ch,
       sysGDatIn      => green_ch,
       sysBDatIn      => blue_ch,
       sysDatInValid  => valid_ch,
       sysDatReady    => ready_ch,
  
       sysHorzFrontPorch  => open,
       sysHorzSyncPulse   => open,
       sysHorzBackPorch   => open,
       sysHorzVideoActive => open,
  
       sysVertFrontPorch  => open,
       sysVertSyncPulse   => open,
       sysVertBackPorch   => open,
       sysVertVideoActive => open,
  
       sysHSync           => open,
       sysVSync           => sysVSync,
  
       rPin               => R_Pin,
       gPin               => G_Pin,
       bPin               => B_Pin,
       hSync              => H_Sync,
       vSync              => V_Sync
    );

  -- -----
end architecture rtl_vgaif;
