library ieee;
use ieee.std_logic_1164.all;

entity ccsync is
  port(
    iclk    :in   std_logic;
    irst    :in   std_logic;
    oclk    :in   std_logic;
    orst    :in   std_logic;
    isync   :in   std_logic;
    osync   :out  std_logic
  );
end entity ccsync;

architecture rtl_ccsync of ccsync is

  signal isync_D  :std_logic;
  signal isync_Q  :std_logic;

  signal osync_D  :std_logic_vector(1 downto 0);
  signal osync_Q  :std_logic_vector(1 downto 0);

begin
  -- -----

  isync_D <= isync;
   
  osync_D <= osync_Q(0) & isync_Q;

  osync   <= osync_Q(1);

  S_iCLK:process(iclk, irst)
  begin
    -- -----
    if (irst='1') then
      isync_Q  <= '0';
    elsif (rising_edge(iclk)) then
      isync_Q  <= isync_D;
    end if;
    -- -----
  end process;

  S_oCLK:process(oclk, orst)
  begin
    -- -----
    if (orst='1') then
      osync_Q  <= (others=>'0');
    elsif (rising_edge(oclk)) then
      osync_Q  <= osync_D;
    end if;
    -- -----
  end process;


  -- -----
end rtl_ccsync;

