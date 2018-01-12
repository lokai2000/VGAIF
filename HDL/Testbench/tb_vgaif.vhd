library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

entity tb_reg is
end entity tb_reg;

architecture sim_tb_reg of tb_reg is 

  signal aclk             : std_logic;
  signal areset_n         : std_logic;
  signal lclk             : std_logic;
  signal lreset_n         : std_logic;
  signal lreset           : std_logic;
  signal ctrl_araddr      : std_logic_vector(31 downto 0);
  signal ctrl_arready     : std_logic;
  signal ctrl_arvalid     : std_logic;
  signal ctrl_awaddr      : std_logic_vector(31 downto 0);
  signal ctrl_awready     : std_logic;
  signal ctrl_awvalid     : std_logic;
  signal ctrl_bready      : std_logic;
  signal ctrl_bresp       : std_logic_vector(1 downto 0);
  signal ctrl_bvalid      : std_logic;
  signal ctrl_rdata       : std_logic_vector(31 downto 0);
  signal ctrl_rready      : std_logic;
  signal ctrl_rresp       : std_logic_vector(1 downto 0);
  signal ctrl_rvalid      : std_logic;
  signal ctrl_wdata       : std_logic_vector(31 downto 0);
  signal ctrl_wready      : std_logic;
  signal ctrl_wstrb       : std_logic_vector(3 downto 0);
  signal ctrl_wvalid      : std_logic;

  signal ma_tdata  : std_logic_vector(71 downto 0);
  signal ma_tstrb  : std_logic_vector(8 downto 0);
  signal ma_tkeep  : std_logic_vector(8 downto 0);
  signal ma_tvalid : std_logic;
  signal ma_tlast  : std_logic;
  signal ma_tid    : std_logic_vector(3 downto 0);
  signal ma_tdest  : std_logic_vector(3 downto 0);

  signal R_Pin  : std_logic_vector(3 downto 0);
  signal G_Pin  : std_logic_vector(3 downto 0);
  signal B_Pin  : std_logic_vector(3 downto 0);
  signal H_Sync : std_logic;
  signal V_Sync : std_logic;

  signal data_tdata  : std_logic_vector(31 downto 0);
  signal data_tstrb  : std_logic_vector(3 downto 0);
  signal data_tkeep  : std_logic_vector(3 downto 0);
  signal data_tvalid : std_logic;
  signal data_tready : std_logic;
  signal data_tlast  : std_logic;
  signal data_tid    : std_logic_vector(3 downto 0);
  signal data_tdest  : std_logic_vector(3 downto 0);
  
  component tb_dg is
    port (
      clk      : in  std_logic;
      reset    : in  std_logic;
      m_tdata  : out std_logic_vector(31 downto 0);
      m_tstrb  : out std_logic_vector(3 downto 0);
      m_tkeep  : out std_logic_vector(3 downto 0);
      m_tvalid : out std_logic;
      m_tready : in  std_logic;
      m_tlast  : out std_logic;
      m_tid    : out std_logic_vector(3 downto 0);
      m_tdest  : out std_logic_vector(3 downto 0)
    );
  end component tb_dg;

  component vgaif is
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
  end component vgaif;

  procedure axi4l_write(
    waddr : in std_logic_vector(31 downto 0);
    wdata : in std_logic_vector(31 downto 0);
    wstrb : in std_logic_vector(3 downto 0);
    signal aclk             : in  std_logic;
    signal ctrl_awaddr      : out std_logic_vector(31 downto 0);
    signal ctrl_awready     : in  std_logic;
    signal ctrl_awvalid     : out std_logic;
    signal ctrl_bready      : out std_logic;
    signal ctrl_bresp       : in  std_logic_vector(1 downto 0);
    signal ctrl_bvalid      : in  std_logic;
    signal ctrl_wdata       : out std_logic_vector(31 downto 0);
    signal ctrl_wready      : in  std_logic;
    signal ctrl_wstrb       : out std_logic_vector(3 downto 0);
    signal ctrl_wvalid      : out std_logic
  ) is
  begin

    wait until aclk = '1';
    ctrl_awaddr  <= waddr;
    ctrl_awvalid <= '1';
    ctrl_bready  <= '0';
    ctrl_wdata   <= (others=>'0');
    ctrl_wvalid  <= '0';
    ctrl_wstrb   <= (others=>'0');
    if ctrl_awready = '1' then
      wait until aclk = '1';    
    else
      while ctrl_awready /= '1' loop
        wait until aclk = '1';    
      end loop;
    end if;
    ctrl_awaddr  <= (others=>'0');
    ctrl_awvalid <= '0';
    ctrl_bready  <= '0';
    ctrl_wdata   <= wdata;
    ctrl_wvalid  <= '1';
    ctrl_wstrb   <= wstrb;
    if ctrl_wready = '1' then
      wait until aclk = '1';    
    else
      while ctrl_wready /= '1' loop
        wait until aclk = '1';    
      end loop;
    end if;
    ctrl_awaddr  <= (others=>'0');
    ctrl_awvalid <= '0';
    ctrl_bready  <= '1';
    ctrl_wdata   <= (others=>'0');
    ctrl_wvalid  <= '1';
    ctrl_wstrb   <= (others=>'0');
    if ctrl_bvalid = '1' then
      wait until aclk = '1';    
    else
      while ctrl_bvalid /= '1' loop
        wait until aclk = '1';    
      end loop;
    end if;
    ctrl_bready  <= '0';
    wait until aclk = '1';    
    
  end procedure axi4l_write;



  procedure axi4l_read(
    raddr : in std_logic_vector(31 downto 0);
    rdata : in std_logic_vector(31 downto 0);
    signal aclk             : in  std_logic;
    signal ctrl_araddr      : out std_logic_vector(31 downto 0);
    signal ctrl_arready     : in  std_logic;
    signal ctrl_arvalid     : out std_logic;
    signal ctrl_rdata       : in  std_logic_vector(31 downto 0);
    signal ctrl_rready      : out std_logic;
    signal ctrl_rresp       : in  std_logic_vector(1 downto 0);
    signal ctrl_rvalid      : in  std_logic
  ) is
  begin
    wait until aclk = '1';
    ctrl_araddr  <= raddr;
    ctrl_arvalid <= '1';
    ctrl_rready  <= '0';
    if ctrl_arready = '1' then
      wait until aclk = '1';    
    else
      while ctrl_arready /= '1' loop
        wait until aclk = '1';    
      end loop;
    end if;
    ctrl_arvalid <= '0';
    ctrl_rready  <= '1';
    ctrl_araddr  <= (others=>'0');
    if ctrl_rvalid = '1' then
      wait until aclk = '1';    
    else
      while ctrl_rvalid /= '1' loop
        wait until aclk = '1';    
      end loop;
    end if;
    ctrl_rready  <= '0';

  end procedure axi4l_read;


begin

  lreset <= not(lreset_n);

  U_uut : vgaif 
    generic  map(
      G_VIDEOX     => 1024,
      G_VIDEOY     => 1024,
      G_SCREENX    => 640,
      G_SCREENY    => 480,
      G_EXTCLKFREQ => 100000000
    )
    port map(

      extclk    => aclk,

      aclk      => lclk,
      areset_n  => lreset_n,

      ma_tdata  => ma_tdata,
      ma_tstrb  => ma_tstrb,
      ma_tkeep  => ma_tkeep,
      ma_tvalid => ma_tvalid,
      ma_tready => '1',
      ma_tlast  => ma_tlast,
      ma_tid    => ma_tid,
      ma_tdest  => ma_tdest,

      ms_tdata  => (others=>'0'),
      ms_tstrb  => (others=>'0'),
      ms_tkeep  => (others=>'0'),
      ms_tvalid => '0',
      ms_tready => open,
      ms_tlast  => '0',
      ms_tid    => (others=>'0'),
      ms_tdest  => (others=>'0'),

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

      data_tdata  => data_tdata,
      data_tstrb  => data_tstrb,
      data_tkeep  => data_tkeep,
      data_tvalid => data_tvalid,
      data_tready => data_tready,
      data_tlast  => data_tlast,
      data_tid    => data_tid,
      data_tdest  => data_tdest,

      R_Pin  => R_Pin,
      G_Pin  => G_Pin,
      B_Pin  => B_Pin,
      H_Sync => H_Sync,
      V_Sync => V_Sync

    );

  U_db : tb_dg 
    port map(
      clk      => lclk,
      reset    => lreset,
      m_tdata  => data_tdata,
      m_tstrb  => data_tstrb,
      m_tkeep  => data_tkeep,
      m_tvalid => data_tvalid,
      m_tready => data_tready,
      m_tlast  => data_tlast,
      m_tid    => data_tid,
      m_tdest  => data_tdest
    );


  process
  begin
    aclk <= '0';
    wait for 5 ns;
    aclk <= '1';
    wait for 5 ns;
  end process;


  process
  begin
    areset_n <= '0';
    wait for 95 ns;
    wait until aclk = '1';
    areset_n <= '1';
    wait;
  end process;


  process
  begin

    ctrl_araddr  <= (others=>'0');
    ctrl_arvalid <= '0';
    ctrl_awaddr  <= (others=>'0');
    ctrl_awvalid <= '0';
    ctrl_bready  <= '0';
    ctrl_rready  <= '0';
    ctrl_wdata   <= (others=>'0');
    ctrl_wstrb   <= (others=>'0');
    ctrl_wvalid  <= '0';
    

    wait for 800 ns;
    wait until aclk = '1';

    axi4l_read(
      raddr        => x"00000000",
      rdata        => x"56474149",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_read(
      raddr        => x"00000004",
      rdata        => x"ABCDEF00",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_read(
      raddr        => x"00000008",
      rdata        => x"01F86FD3",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';


    axi4l_read(
      raddr        => x"0000000C",
      rdata        => x"56474149",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_write(
      waddr         => x"0000000C",
      wdata         => x"FFFFFFFF",
      wstrb         => x"F",
      aclk          => lclk,    
      ctrl_awaddr   => ctrl_awaddr,
      ctrl_awready  => ctrl_awready,
      ctrl_awvalid  => ctrl_awvalid,
      ctrl_bready   => ctrl_bready,
      ctrl_bresp    => ctrl_bresp,
      ctrl_bvalid   => ctrl_bvalid,
      ctrl_wdata    => ctrl_wdata,
      ctrl_wready   => ctrl_wready,
      ctrl_wstrb    => ctrl_wstrb,
      ctrl_wvalid   => ctrl_wvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_read(
      raddr        => x"0000000C",
      rdata        => x"A9B8BEB6",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_write(
      waddr         => x"00000030",
      wdata         => x"88000000",
      wstrb         => x"F",
      aclk          => lclk,    
      ctrl_awaddr   => ctrl_awaddr,
      ctrl_awready  => ctrl_awready,
      ctrl_awvalid  => ctrl_awvalid,
      ctrl_bready   => ctrl_bready,
      ctrl_bresp    => ctrl_bresp,
      ctrl_bvalid   => ctrl_bvalid,
      ctrl_wdata    => ctrl_wdata,
      ctrl_wready   => ctrl_wready,
      ctrl_wstrb    => ctrl_wstrb,
      ctrl_wvalid   => ctrl_wvalid
    );

    wait for 20 ns;
    wait until aclk = '1';


    --axi4l_write(
    --  waddr         => x"00000034",
    --  wdata         => x"80000000",
    --  wstrb         => x"F",
    --  aclk          => lclk,    
    --  ctrl_awaddr   => ctrl_awaddr,
    --  ctrl_awready  => ctrl_awready,
    --  ctrl_awvalid  => ctrl_awvalid,
    --  ctrl_bready   => ctrl_bready,
    --  ctrl_bresp    => ctrl_bresp,
    --  ctrl_bvalid   => ctrl_bvalid,
    --  ctrl_wdata    => ctrl_wdata,
    --  ctrl_wready   => ctrl_wready,
    --  ctrl_wstrb    => ctrl_wstrb,
    --  ctrl_wvalid   => ctrl_wvalid
    --);


    --wait for 100 ns;
    --wait until aclk = '1';

    --axi4l_write(
    --  waddr         => x"00000030",
    --  wdata         => x"88000000",
    --  wstrb         => x"F",
    --  aclk          => lclk,    
    --  ctrl_awaddr   => ctrl_awaddr,
    --  ctrl_awready  => ctrl_awready,
    --  ctrl_awvalid  => ctrl_awvalid,
    --  ctrl_bready   => ctrl_bready,
    --  ctrl_bresp    => ctrl_bresp,
    --  ctrl_bvalid   => ctrl_bvalid,
    --  ctrl_wdata    => ctrl_wdata,
    --  ctrl_wready   => ctrl_wready,
    --  ctrl_wstrb    => ctrl_wstrb,
    --  ctrl_wvalid   => ctrl_wvalid
    --);

    wait for 20 ns;
    wait until aclk = '1';


    axi4l_read(
      raddr        => x"00000030",
      rdata        => x"88000000",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_read(
      raddr        => x"00000038",
      rdata        => x"00000400",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_read(
      raddr        => x"0000003C",
      rdata        => x"00000400",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_read(
      raddr        => x"00000040",
      rdata        => x"00000280",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_read(
      raddr        => x"00000044",
      rdata        => x"000001E0",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_read(
      raddr        => x"00000048",
      rdata        => x"00000000",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_read(
      raddr        => x"0000004C",
      rdata        => x"00000000",
      aclk         => lclk,
      ctrl_araddr  => ctrl_araddr,
      ctrl_arready => ctrl_arready,
      ctrl_arvalid => ctrl_arvalid,
      ctrl_rdata   => ctrl_rdata,
      ctrl_rready  => ctrl_rready,
      ctrl_rresp   => ctrl_rresp,
      ctrl_rvalid  => ctrl_rvalid
    );

    wait for 20 ns;
    wait until aclk = '1';

    axi4l_write(
      waddr         => x"00000034",
      wdata         => x"00000001",
      wstrb         => x"F",
      aclk          => lclk,    
      ctrl_awaddr   => ctrl_awaddr,
      ctrl_awready  => ctrl_awready,
      ctrl_awvalid  => ctrl_awvalid,
      ctrl_bready   => ctrl_bready,
      ctrl_bresp    => ctrl_bresp,
      ctrl_bvalid   => ctrl_bvalid,
      ctrl_wdata    => ctrl_wdata,
      ctrl_wready   => ctrl_wready,
      ctrl_wstrb    => ctrl_wstrb,
      ctrl_wvalid   => ctrl_wvalid
    );

    wait for 20 ns;
    wait until aclk = '1';


    wait;

  end process;



end architecture sim_tb_reg;
