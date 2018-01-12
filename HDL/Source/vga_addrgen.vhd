library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

entity vga_addrgen is
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
end entity vga_addrgen;


architecture rtl_vga_addrgen of vga_addrgen is

  --constant K_ADV : unsigned(31 downto 0) := to_unsigned((G_VIDEOX-G_SCREENX+1)*4,32);
  constant K_ADV : unsigned(31 downto 0) := to_unsigned(G_VIDEOX*4,32);

  type T_state is (
    E_IDLE,
    E_RUN
  );

  signal state_D : T_state;
  signal state_Q : T_state;

  signal addr_D   : unsigned(31 downto 0);
  signal addr_Q   : unsigned(31 downto 0);
  signal addr_ld  : std_logic;
  signal addr_adv : std_logic;

  signal row_D   : unsigned(15 downto 0);
  signal row_Q   : unsigned(15 downto 0);
  signal row_ld  : std_logic;
  signal row_ena : std_logic;
  signal row_tc  : std_logic;

  signal yofs_D : unsigned(31 downto 0);
  signal yofs_Q : unsigned(31 downto 0);
  signal xofs_D : unsigned(31 downto 0);
  signal xofs_Q : unsigned(31 downto 0);

  signal addr_rdy : std_logic;
  signal addr_val : std_logic;

begin

  yofs_D <= unsigned(screen_ofsy) * to_unsigned(G_VIDEOX*4,16);
  xofs_D <= unsigned(screen_ofsx)*4 + yofs_Q;

  addr_val  <= addr_rdy and ma_tready;

  ms_tready <= '1';

  ma_tdata  <= x"0" &             
               std_logic_vector(row_Q(3 downto 0)) & 
               std_logic_vector(addr_Q) &            
               "0" &              
               "1" &              
               "000000" &
               "1" &               
               std_logic_vector(to_unsigned(G_SCREENX*4,23)); --XFR SIZE IN BYTES
               
  ma_tstrb  <= (others=>'1');
  ma_tkeep  <= (others=>'1');
  ma_tvalid <= addr_rdy;
  ma_tlast  <= '1';
  ma_tid    <= std_logic_vector(to_unsigned(G_MATID,ma_tid'length));
  ma_tdest  <= std_logic_vector(to_unsigned(G_MATDEST,ma_tdest'length));

  screen_cmplt <= row_ld;


  C_addr : process (
    addr_Q,
    addr_ld,
    addr_adv,
    screen_ptr,
    xofs_Q
  )
  begin
    -- -----
    if ( addr_ld = '1' ) then
      addr_D <= unsigned(screen_ptr) + xofs_Q;
    elsif ( addr_adv = '1' ) then
      addr_D <= addr_Q + K_ADV;
    else
      addr_D <= addr_Q;
    end if;
    -- -----
  end process C_addr;


  C_row : process (
    row_Q,
    row_ld,
    row_ena
  )
  begin
    -- -----
    if ( row_ld = '1' ) then
      row_D <= to_unsigned(G_SCREENY-1,row_D'length);
    elsif ( row_ena = '1' ) then
      row_D <= row_Q - 1;
    else
      row_D <= row_Q;
    end if;
    -- -----
    if ( row_Q = 0 ) then
      row_tc <= '1';
    else
      row_tc <= '0';
    end if;
    -- -----
  end process C_row;


  C_state : process (
    state_Q,
    screen_ena,
    addr_val,
    row_tc,
    row_ld
  )
  begin
    -- -----
    state_D  <= state_Q;
    addr_ld  <= '0';
    addr_adv <= '0';
    addr_rdy <= '0';
    row_ld   <= '0';
    row_ena  <= '0';
    -- -----
    case ( state_Q ) is


      when E_IDLE =>
        if ( screen_ena = '1' ) then
          state_D <= E_RUN;
          addr_ld <= '1';
          row_ld  <= '1';
        end if;
        

      when E_RUN =>
        addr_rdy <= '1';
        addr_adv <= addr_val;
        row_ena  <= addr_val;
        row_ld   <= addr_val and row_tc;
        addr_ld  <= addr_val and row_tc;

        if ( screen_ena = '0' and row_ld='1' ) then
          state_D <= E_IDLE;
        end if;


      when others => 
        state_D <= E_IDLE;


    end case;
    -- -----
  end process C_state;


  S_clk : process (
    aclk,
    areset_n
  )
  begin
    -- -----
    if ( areset_n = '0' ) then
      state_Q <= E_IDLE;
      addr_Q  <= (others=>'0');
      yofs_Q  <= (others=>'0');
      xofs_Q  <= (others=>'0');
      row_Q   <= (others=>'0');
    elsif ( rising_edge(aclk) ) then
      state_Q <= state_D;
      addr_Q  <= addr_D;
      yofs_Q  <= yofs_D;
      xofs_Q  <= xofs_D;
      row_Q   <= row_D;
    end if;
    -- -----
  end process S_clk;


end architecture rtl_vga_addrgen;



