library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

entity tb_addr is
end entity tb_addr;

architecture sim_tb_addr of tb_addr is 

  signal aclk             : std_logic;
  signal areset_n         : std_logic;

  
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

  signal ma_tdata  : std_logic_vector(71 downto 0);
  signal ma_tstrb  : std_logic_vector(8 downto 0);
  signal ma_tkeep  : std_logic_vector(8 downto 0);
  signal ma_tvalid : std_logic;
  signal ma_tready : std_logic;
  signal ma_tlast  : std_logic;
  signal ma_tid    : std_logic_vector(3 downto 0);
  signal ma_tdest  : std_logic_vector(3 downto 0);

  signal screen_ena   : std_logic;
  signal screen_ptr   : std_logic_vector(31 downto 0);
  signal screen_ofsx  : std_logic_vector(15 downto 0);
  signal screen_ofsy  : std_logic_vector(15 downto 0);
  signal screen_cmplt : std_logic;

begin

  ma_tready <= '1';

  U_uut : vga_addrgen 
    generic map(
      G_VIDEOX  => 128,
      G_VIDEOY  => 128,
      G_SCREENX => 16,
      G_SCREENY => 16,
      G_MATID   => 6,
      G_MATDEST => 7
    )
    port map (
      aclk      => aclk,
      areset_n  => areset_n,
      
      ma_tdata  => ma_tdata,
      ma_tstrb  => ma_tstrb,
      ma_tkeep  => ma_tkeep,
      ma_tvalid => ma_tvalid,
      ma_tready => ma_tready,
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

      screen_ena   => screen_ena,
      screen_ptr   => screen_ptr,
      screen_ofsx  => screen_ofsx,
      screen_ofsy  => screen_ofsy,
      screen_cmplt => screen_cmplt

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

      screen_ena   <= '0';
      screen_ptr   <= x"00000000";
      screen_ofsx  <= x"0000";
      screen_ofsy  <= x"0000";

      wait for 200 ns;
      wait until aclk='1';
      screen_ena   <= '1';

      wait for 200 ns;
      wait until aclk='1';
      screen_ofsx  <= x"000A";
      screen_ofsy  <= x"0001";
      screen_ena   <= '1';

    wait;

  end process;



end architecture sim_tb_addr;
