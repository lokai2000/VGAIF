library ieee;
use ieee.std_logic_1164.all;

entity ccpulse is
  port(
    iclk    :in   std_logic;
    irst    :in   std_logic;
    oclk    :in   std_logic;
    orst    :in   std_logic;
    ipulse  :in   std_logic;
    opulse  :out  std_logic
  );
end entity ccpulse;

architecture rtl_ccpulse of ccpulse is

  signal idiv_D   :std_logic;
  signal idiv_Q   :std_logic;

  signal osync_D  :std_logic_vector(2 downto 0);
  signal osync_Q  :std_logic_vector(2 downto 0);
  signal opulse_D :std_logic;
  signal opulse_Q :std_logic;

begin
  -- -----
   
  idiv_D   <= not(idiv_Q) when (ipulse='1') else
              idiv_Q;

  osync_D  <= osync_Q(1 downto 0) & idiv_Q;

  opulse_D <= osync_Q(2) xor osync_Q(1);

  opulse   <= opulse_Q;

  S_iCLK:process(iclk, irst)
  begin
    -- -----
    if (irst='1') then
      idiv_Q   <= '0';
    elsif (rising_edge(iclk)) then
      idiv_Q   <= idiv_D;
    end if;
    -- -----
  end process;

  S_oCLK:process(oclk, orst)
  begin
    -- -----
    if (orst='1') then
      osync_Q  <= (others=>'0');
      opulse_Q <= '0';
    elsif (rising_edge(oclk)) then
      osync_Q  <= osync_D;
      opulse_Q <= opulse_D;
    end if;
    -- -----
  end process;


  -- -----
end rtl_ccpulse;

