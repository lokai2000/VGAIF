library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

entity tb_dg is
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
end entity tb_dg;

architecture rtl_tb_dg of tb_dg is

  signal cntA : unsigned(7 downto 0);

begin
  -- -----

  m_tvalid <= '1';
  m_tstrb  <= (others=>'1');
  m_tkeep  <= (others=>'1');
  m_tid    <= (others=>'0');
  m_tdest  <= (others=>'0');
  m_tdata  <= std_logic_vector(cntA)&std_logic_vector(cntA)&std_logic_vector(cntA)&std_logic_vector(cntA);
  m_tlast  <= '0';
 
  S_clk : process (
    clk,
    reset
  )
  begin 
    -- -----
    if ( reset = '1' ) then

      cntA <= x"01";

    elsif ( rising_edge(clk) ) then

      if ( m_tready = '1' ) then
        cntA <= cntA + 1;        
      end if;
      
    end if;
    -- -----
  end process S_clk;

  -- -----
end architecture rtl_tb_dg;
