library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

library work;
use work.vga_registers_pkg.all;

entity vga_registers_core is
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
end entity vga_registers_core;

architecture rtl_vga_registers_core of vga_registers_core is

  signal reg_records_D : T_registers;
  signal reg_records_Q : T_registers;
  signal reg_records_I : T_registers;

  type T_wstate is (E_WADDR, E_WDATA, E_WRESP);

  signal wstate_D : T_wstate;
  signal wstate_Q : T_wstate;

  signal wtimeout_D : unsigned(7 downto 0);
  signal wtimeout_Q : unsigned(7 downto 0);

  signal waddr_D : std_logic_vector(ctrl_awaddr'range);
  signal waddr_Q : std_logic_vector(ctrl_awaddr'range);

  signal wdata_D : std_logic_vector(ctrl_wdata'range);
  signal wdata_Q : std_logic_vector(ctrl_wdata'range);
  signal wstrb_D : std_logic_vector(ctrl_wstrb'range);
  signal wstrb_Q : std_logic_vector(ctrl_wstrb'range);

  signal wupdate_D : std_logic;
  signal wupdate_Q : std_logic;

  type T_rstate is (E_RADDR, E_RDLY, E_RRESP);

  signal rstate_D : T_rstate;
  signal rstate_Q : T_rstate;

  signal rtimeout_D : unsigned(7 downto 0);
  signal rtimeout_Q : unsigned(7 downto 0);

  signal raddr_D : std_logic_vector(ctrl_araddr'range);
  signal raddr_Q : std_logic_vector(ctrl_araddr'range);

  signal rdata_D : std_logic_vector(ctrl_rdata'range);
  signal rdata_Q : std_logic_vector(ctrl_rdata'range);

  signal rupdate_D : std_logic;
  signal rupdate_Q : std_logic;

begin

  ctrl_rresp <= (others=>'0');
  ctrl_bresp <= (others=>'0');
  ctrl_rdata <= rdata_Q;


  C_wstate : process (
    wstate_Q,
    ctrl_awvalid,
    ctrl_wvalid,
    ctrl_bready,
    wtimeout_Q,
    waddr_Q,
    ctrl_awaddr,
    ctrl_wdata,
    wdata_Q,
    ctrl_wstrb,
    wstrb_Q
  )
  begin

    wstate_D     <= wstate_Q;
    ctrl_awready <= '0';
    ctrl_bvalid  <= '0';
    ctrl_wready  <= '0';
    waddr_D      <= waddr_Q;
    wupdate_D    <= '0';
    wstrb_D      <= wstrb_Q;
    wdata_D      <= wdata_Q;

    if ( wtimeout_Q > 0 ) then
      wtimeout_D <= wtimeout_Q - 1;
    else
      wtimeout_D <= wtimeout_Q;
    end if;

    case ( wstate_Q ) is

      when E_WADDR =>
        ctrl_awready <= '1';
        if ( ctrl_awvalid = '1' ) then
          wstate_D   <= E_WDATA;
          wtimeout_D <= (others=>'1');
          waddr_D    <= ctrl_awaddr;
        end if;

      when E_WDATA =>
        ctrl_wready <= '1';
        if ( ctrl_wvalid = '1' ) then
          wstate_D   <= E_WRESP;
          wtimeout_D <= (others=>'1');
          wupdate_D  <= '1';
          wdata_D    <= ctrl_wdata;
          wstrb_D    <= ctrl_wstrb;
        elsif ( wtimeout_Q = 0 ) then
          wstate_D   <= E_WADDR;
        end if;

      when E_WRESP =>
        ctrl_bvalid <= '1';
        if ( ctrl_bready = '1' ) then
          wstate_D  <= E_WADDR;
        elsif ( wtimeout_Q = 0 ) then
          wstate_D  <= E_WADDR;
        end if;

      when others =>
        wstate_D <= E_WADDR;

    end case;

  end process C_wstate;


  S_wclk : process (
    aclk,
    areset_n
  )

  begin

    if ( areset_n = '0' ) then
      wstate_Q   <= E_WADDR;
      waddr_Q    <= (others=>'0');
      wupdate_Q  <= '0';
      wstrb_Q    <= (others=>'0');
      wdata_Q    <= (others=>'0');
      wtimeout_Q <= (others=>'0');
    elsif ( rising_edge(aclk) ) then
      wstate_Q   <= wstate_D;
      waddr_Q    <= waddr_D;
      wupdate_Q  <= wupdate_D;
      wstrb_Q    <= wstrb_D;
      wdata_Q    <= wdata_D;
      wtimeout_Q <= wtimeout_D;
    end if;

  end process S_wclk;


  C_rstate : process (
    rstate_Q,
    ctrl_arvalid,
    ctrl_rready,
    rtimeout_Q,
    ctrl_araddr,
    raddr_Q
  )
  begin

    rstate_D     <= rstate_Q;
    ctrl_arready <= '0';
    ctrl_rvalid  <= '0';
    raddr_D      <= raddr_Q;
    rupdate_D    <= '0';

    if ( rtimeout_Q > 0 ) then
      rtimeout_D <= rtimeout_Q - 1;
    else
      rtimeout_D <= rtimeout_Q;
    end if;

    case ( rstate_Q ) is

      when E_RADDR =>
        ctrl_arready <= '1';
        if ( ctrl_arvalid = '1' ) then
          rstate_D <= E_RDLY;
          raddr_D  <= ctrl_araddr;
        end if;

      when E_RDLY =>
        rstate_D   <= E_RRESP;
        rtimeout_D <= (others=>'1');
      when E_RRESP =>
        ctrl_rvalid  <= '1';
        if ( ctrl_rready = '1' ) then
          rstate_D   <= E_RADDR;
          rupdate_D  <= '1';
        elsif ( rtimeout_Q = 0 ) then
          rstate_D   <= E_RADDR;
        end if;

      when others =>
          rstate_D   <= E_RADDR;

    end case;

  end process;


  S_rclk : process (
    aclk,
    areset_n
  )
  begin

    if ( areset_n = '0' ) then
      rstate_Q   <= E_RADDR;
      raddr_Q    <= (others=>'0');
      rdata_Q    <= (others=>'0');
      rtimeout_Q <= (others=>'0');
      rupdate_Q  <= '0';
    elsif ( rising_edge(aclk) ) then
      rstate_Q   <= rstate_D;
      raddr_Q    <= raddr_D;
      rdata_Q    <= rdata_D;
      rtimeout_Q <= rtimeout_D;
      rupdate_Q  <= rupdate_D;
    end if;

  end process S_rclk;


  registers_source.SCREENOFSX.base.raw <= reg_records_Q.SCREENOFSX.base.raw;
  registers_source.SCREENOFSX.base.update <= reg_records_Q.SCREENOFSX.base.update;
  registers_source.SCREENOFSX.base.address <= K_register_addresses(E_SCREENOFSX);
  registers_source.SCREENOFSX.base.default <= K_register_defaults(E_SCREENOFSX);
  registers_source.SCREENOFSX.ofsX <= reg_records_Q.SCREENOFSX.base.raw(registers_source.SCREENOFSX.ofsX'range);

  registers_source.SCREENOFSY.base.raw <= reg_records_Q.SCREENOFSY.base.raw;
  registers_source.SCREENOFSY.base.update <= reg_records_Q.SCREENOFSY.base.update;
  registers_source.SCREENOFSY.base.address <= K_register_addresses(E_SCREENOFSY);
  registers_source.SCREENOFSY.base.default <= K_register_defaults(E_SCREENOFSY);
  registers_source.SCREENOFSY.ofsY <= reg_records_Q.SCREENOFSY.base.raw(registers_source.SCREENOFSY.ofsY'range);

  registers_source.KEYSTATUS.base.raw <= reg_records_Q.KEYSTATUS.base.raw;
  registers_source.KEYSTATUS.base.update <= reg_records_Q.KEYSTATUS.base.update;
  registers_source.KEYSTATUS.base.address <= K_register_addresses(E_KEYSTATUS);
  registers_source.KEYSTATUS.base.default <= K_register_defaults(E_KEYSTATUS);
  registers_source.KEYSTATUS.lblActive <= reg_records_Q.KEYSTATUS.base.raw(registers_source.KEYSTATUS.lblActive'range);

  registers_source.SCREENY.base.raw <= reg_records_Q.SCREENY.base.raw;
  registers_source.SCREENY.base.update <= reg_records_Q.SCREENY.base.update;
  registers_source.SCREENY.base.address <= K_register_addresses(E_SCREENY);
  registers_source.SCREENY.base.default <= K_register_defaults(E_SCREENY);
  registers_source.SCREENY.ySize <= reg_records_Q.SCREENY.base.raw(registers_source.SCREENY.ySize'range);

  registers_source.SCREENX.base.raw <= reg_records_Q.SCREENX.base.raw;
  registers_source.SCREENX.base.update <= reg_records_Q.SCREENX.base.update;
  registers_source.SCREENX.base.address <= K_register_addresses(E_SCREENX);
  registers_source.SCREENX.base.default <= K_register_defaults(E_SCREENX);
  registers_source.SCREENX.xSize <= reg_records_Q.SCREENX.base.raw(registers_source.SCREENX.xSize'range);

  registers_source.VIDEOY.base.raw <= reg_records_Q.VIDEOY.base.raw;
  registers_source.VIDEOY.base.update <= reg_records_Q.VIDEOY.base.update;
  registers_source.VIDEOY.base.address <= K_register_addresses(E_VIDEOY);
  registers_source.VIDEOY.base.default <= K_register_defaults(E_VIDEOY);
  registers_source.VIDEOY.ySize <= reg_records_Q.VIDEOY.base.raw(registers_source.VIDEOY.ySize'range);

  registers_source.VIDEOX.base.raw <= reg_records_Q.VIDEOX.base.raw;
  registers_source.VIDEOX.base.update <= reg_records_Q.VIDEOX.base.update;
  registers_source.VIDEOX.base.address <= K_register_addresses(E_VIDEOX);
  registers_source.VIDEOX.base.default <= K_register_defaults(E_VIDEOX);
  registers_source.VIDEOX.xSize <= reg_records_Q.VIDEOX.base.raw(registers_source.VIDEOX.xSize'range);

  registers_source.REVID.base.raw <= reg_records_Q.REVID.base.raw;
  registers_source.REVID.base.update <= reg_records_Q.REVID.base.update;
  registers_source.REVID.base.address <= K_register_addresses(E_REVID);
  registers_source.REVID.base.default <= K_register_defaults(E_REVID);
  registers_source.REVID.hour <= reg_records_Q.REVID.base.raw(registers_source.REVID.hour'range);
  registers_source.REVID.month <= reg_records_Q.REVID.base.raw(registers_source.REVID.month'range);
  registers_source.REVID.class <= reg_records_Q.REVID.base.raw(registers_source.REVID.class'range);
  registers_source.REVID.day <= reg_records_Q.REVID.base.raw(registers_source.REVID.day'range);
  registers_source.REVID.year <= reg_records_Q.REVID.base.raw(registers_source.REVID.year'range);

  registers_source.WRAPBACK.base.raw <= reg_records_Q.WRAPBACK.base.raw;
  registers_source.WRAPBACK.base.update <= reg_records_Q.WRAPBACK.base.update;
  registers_source.WRAPBACK.base.address <= K_register_addresses(E_WRAPBACK);
  registers_source.WRAPBACK.base.default <= K_register_defaults(E_WRAPBACK);
  registers_source.WRAPBACK.wrapData <= reg_records_Q.WRAPBACK.base.raw(registers_source.WRAPBACK.wrapData'range);

  registers_source.SYSID.base.raw <= reg_records_Q.SYSID.base.raw;
  registers_source.SYSID.base.update <= reg_records_Q.SYSID.base.update;
  registers_source.SYSID.base.address <= K_register_addresses(E_SYSID);
  registers_source.SYSID.base.default <= K_register_defaults(E_SYSID);
  registers_source.SYSID.systemID <= reg_records_Q.SYSID.base.raw(registers_source.SYSID.systemID'range);

  registers_source.KEYACTIVE.base.raw <= reg_records_Q.KEYACTIVE.base.raw;
  registers_source.KEYACTIVE.base.update <= reg_records_Q.KEYACTIVE.base.update;
  registers_source.KEYACTIVE.base.address <= K_register_addresses(E_KEYACTIVE);
  registers_source.KEYACTIVE.base.default <= K_register_defaults(E_KEYACTIVE);
  registers_source.KEYACTIVE.lastLbl <= reg_records_Q.KEYACTIVE.base.raw(registers_source.KEYACTIVE.lastLbl'range);

  registers_source.KEYLABEL.base.raw <= reg_records_Q.KEYLABEL.base.raw;
  registers_source.KEYLABEL.base.update <= reg_records_Q.KEYLABEL.base.update;
  registers_source.KEYLABEL.base.address <= K_register_addresses(E_KEYLABEL);
  registers_source.KEYLABEL.base.default <= K_register_defaults(E_KEYLABEL);
  registers_source.KEYLABEL.keyLabel <= reg_records_Q.KEYLABEL.base.raw(registers_source.KEYLABEL.keyLabel'range);

  registers_source.VIDEOPTR.base.raw <= reg_records_Q.VIDEOPTR.base.raw;
  registers_source.VIDEOPTR.base.update <= reg_records_Q.VIDEOPTR.base.update;
  registers_source.VIDEOPTR.base.address <= K_register_addresses(E_VIDEOPTR);
  registers_source.VIDEOPTR.base.default <= K_register_defaults(E_VIDEOPTR);
  registers_source.VIDEOPTR.ptr <= reg_records_Q.VIDEOPTR.base.raw(registers_source.VIDEOPTR.ptr'range);

  registers_source.IFID.base.raw <= reg_records_Q.IFID.base.raw;
  registers_source.IFID.base.update <= reg_records_Q.IFID.base.update;
  registers_source.IFID.base.address <= K_register_addresses(E_IFID);
  registers_source.IFID.base.default <= K_register_defaults(E_IFID);
  registers_source.IFID.interfaceID <= reg_records_Q.IFID.base.raw(registers_source.IFID.interfaceID'range);

  registers_source.VIDEOCTRL.base.raw <= reg_records_Q.VIDEOCTRL.base.raw;
  registers_source.VIDEOCTRL.base.update <= reg_records_Q.VIDEOCTRL.base.update;
  registers_source.VIDEOCTRL.base.address <= K_register_addresses(E_VIDEOCTRL);
  registers_source.VIDEOCTRL.base.default <= K_register_defaults(E_VIDEOCTRL);
  registers_source.VIDEOCTRL.rst <= reg_records_Q.VIDEOCTRL.base.raw(registers_source.VIDEOCTRL.rst'range);
  registers_source.VIDEOCTRL.ena <= reg_records_Q.VIDEOCTRL.base.raw(registers_source.VIDEOCTRL.ena'range);

  registers_source.KEYREMAIN.base.raw <= reg_records_Q.KEYREMAIN.base.raw;
  registers_source.KEYREMAIN.base.update <= reg_records_Q.KEYREMAIN.base.update;
  registers_source.KEYREMAIN.base.address <= K_register_addresses(E_KEYREMAIN);
  registers_source.KEYREMAIN.base.default <= K_register_defaults(E_KEYREMAIN);
  registers_source.KEYREMAIN.lblRemain <= reg_records_Q.KEYREMAIN.base.raw(registers_source.KEYREMAIN.lblRemain'range);

  registers_source.KEYCTRL.base.raw <= reg_records_Q.KEYCTRL.base.raw;
  registers_source.KEYCTRL.base.update <= reg_records_Q.KEYCTRL.base.update;
  registers_source.KEYCTRL.base.address <= K_register_addresses(E_KEYCTRL);
  registers_source.KEYCTRL.base.default <= K_register_defaults(E_KEYCTRL);
  registers_source.KEYCTRL.acquire <= reg_records_Q.KEYCTRL.base.raw(registers_source.KEYCTRL.acquire'range);

  registers_source.KEYSIZE.base.raw <= reg_records_Q.KEYSIZE.base.raw;
  registers_source.KEYSIZE.base.update <= reg_records_Q.KEYSIZE.base.update;
  registers_source.KEYSIZE.base.address <= K_register_addresses(E_KEYSIZE);
  registers_source.KEYSIZE.base.default <= K_register_defaults(E_KEYSIZE);
  registers_source.KEYSIZE.lblSize <= reg_records_Q.KEYSIZE.base.raw(registers_source.KEYSIZE.lblSize'range);


  C_register_write : process (
    waddr_Q,
    wdata_Q,
    wstrb_Q,
    wupdate_Q,
    reg_records_Q,
    registers_sink
  )
    variable V_addr   : std_logic_vector(K_reg_addr_hibit downto K_reg_addr_lobit);
    variable V_data   : std_logic_vector(K_REG_WIDTH-1 downto 0);
  begin
    V_addr := waddr_Q(K_reg_addr_hibit downto K_reg_addr_lobit);

    reg_records_D.SCREENOFSX.base.update   <= '0';
    for i in reg_records_Q.SCREENOFSX.base.raw'range loop
      reg_records_D.SCREENOFSX.base.raw(i) <= (reg_records_Q.SCREENOFSX.base.raw(i) and not(K_register_autoclr_mask(E_SCREENOFSX)(i))) or K_register_autoset_mask(E_SCREENOFSX)(i);
    end loop;

    reg_records_D.SCREENOFSY.base.update   <= '0';
    for i in reg_records_Q.SCREENOFSY.base.raw'range loop
      reg_records_D.SCREENOFSY.base.raw(i) <= (reg_records_Q.SCREENOFSY.base.raw(i) and not(K_register_autoclr_mask(E_SCREENOFSY)(i))) or K_register_autoset_mask(E_SCREENOFSY)(i);
    end loop;

    reg_records_D.KEYSTATUS.base.update   <= '0';
    for i in reg_records_Q.KEYSTATUS.base.raw'range loop
      reg_records_D.KEYSTATUS.base.raw(i) <= (reg_records_Q.KEYSTATUS.base.raw(i) and not(K_register_autoclr_mask(E_KEYSTATUS)(i))) or K_register_autoset_mask(E_KEYSTATUS)(i);
    end loop;

    reg_records_D.SCREENY.base.update   <= '0';
    for i in reg_records_Q.SCREENY.base.raw'range loop
      reg_records_D.SCREENY.base.raw(i) <= (reg_records_Q.SCREENY.base.raw(i) and not(K_register_autoclr_mask(E_SCREENY)(i))) or K_register_autoset_mask(E_SCREENY)(i);
    end loop;

    reg_records_D.SCREENX.base.update   <= '0';
    for i in reg_records_Q.SCREENX.base.raw'range loop
      reg_records_D.SCREENX.base.raw(i) <= (reg_records_Q.SCREENX.base.raw(i) and not(K_register_autoclr_mask(E_SCREENX)(i))) or K_register_autoset_mask(E_SCREENX)(i);
    end loop;

    reg_records_D.VIDEOY.base.update   <= '0';
    for i in reg_records_Q.VIDEOY.base.raw'range loop
      reg_records_D.VIDEOY.base.raw(i) <= (reg_records_Q.VIDEOY.base.raw(i) and not(K_register_autoclr_mask(E_VIDEOY)(i))) or K_register_autoset_mask(E_VIDEOY)(i);
    end loop;

    reg_records_D.VIDEOX.base.update   <= '0';
    for i in reg_records_Q.VIDEOX.base.raw'range loop
      reg_records_D.VIDEOX.base.raw(i) <= (reg_records_Q.VIDEOX.base.raw(i) and not(K_register_autoclr_mask(E_VIDEOX)(i))) or K_register_autoset_mask(E_VIDEOX)(i);
    end loop;

    reg_records_D.REVID.base.update   <= '0';
    for i in reg_records_Q.REVID.base.raw'range loop
      reg_records_D.REVID.base.raw(i) <= (reg_records_Q.REVID.base.raw(i) and not(K_register_autoclr_mask(E_REVID)(i))) or K_register_autoset_mask(E_REVID)(i);
    end loop;

    reg_records_D.WRAPBACK.base.update   <= '0';
    for i in reg_records_Q.WRAPBACK.base.raw'range loop
      reg_records_D.WRAPBACK.base.raw(i) <= (reg_records_Q.WRAPBACK.base.raw(i) and not(K_register_autoclr_mask(E_WRAPBACK)(i))) or K_register_autoset_mask(E_WRAPBACK)(i);
    end loop;

    reg_records_D.SYSID.base.update   <= '0';
    for i in reg_records_Q.SYSID.base.raw'range loop
      reg_records_D.SYSID.base.raw(i) <= (reg_records_Q.SYSID.base.raw(i) and not(K_register_autoclr_mask(E_SYSID)(i))) or K_register_autoset_mask(E_SYSID)(i);
    end loop;

    reg_records_D.KEYACTIVE.base.update   <= '0';
    for i in reg_records_Q.KEYACTIVE.base.raw'range loop
      reg_records_D.KEYACTIVE.base.raw(i) <= (reg_records_Q.KEYACTIVE.base.raw(i) and not(K_register_autoclr_mask(E_KEYACTIVE)(i))) or K_register_autoset_mask(E_KEYACTIVE)(i);
    end loop;

    reg_records_D.KEYLABEL.base.update   <= '0';
    for i in reg_records_Q.KEYLABEL.base.raw'range loop
      reg_records_D.KEYLABEL.base.raw(i) <= (reg_records_Q.KEYLABEL.base.raw(i) and not(K_register_autoclr_mask(E_KEYLABEL)(i))) or K_register_autoset_mask(E_KEYLABEL)(i);
    end loop;

    reg_records_D.VIDEOPTR.base.update   <= '0';
    for i in reg_records_Q.VIDEOPTR.base.raw'range loop
      reg_records_D.VIDEOPTR.base.raw(i) <= (reg_records_Q.VIDEOPTR.base.raw(i) and not(K_register_autoclr_mask(E_VIDEOPTR)(i))) or K_register_autoset_mask(E_VIDEOPTR)(i);
    end loop;

    reg_records_D.IFID.base.update   <= '0';
    for i in reg_records_Q.IFID.base.raw'range loop
      reg_records_D.IFID.base.raw(i) <= (reg_records_Q.IFID.base.raw(i) and not(K_register_autoclr_mask(E_IFID)(i))) or K_register_autoset_mask(E_IFID)(i);
    end loop;

    reg_records_D.VIDEOCTRL.base.update   <= '0';
    for i in reg_records_Q.VIDEOCTRL.base.raw'range loop
      reg_records_D.VIDEOCTRL.base.raw(i) <= (reg_records_Q.VIDEOCTRL.base.raw(i) and not(K_register_autoclr_mask(E_VIDEOCTRL)(i))) or K_register_autoset_mask(E_VIDEOCTRL)(i);
    end loop;

    reg_records_D.KEYREMAIN.base.update   <= '0';
    for i in reg_records_Q.KEYREMAIN.base.raw'range loop
      reg_records_D.KEYREMAIN.base.raw(i) <= (reg_records_Q.KEYREMAIN.base.raw(i) and not(K_register_autoclr_mask(E_KEYREMAIN)(i))) or K_register_autoset_mask(E_KEYREMAIN)(i);
    end loop;

    reg_records_D.KEYCTRL.base.update   <= '0';
    for i in reg_records_Q.KEYCTRL.base.raw'range loop
      reg_records_D.KEYCTRL.base.raw(i) <= (reg_records_Q.KEYCTRL.base.raw(i) and not(K_register_autoclr_mask(E_KEYCTRL)(i))) or K_register_autoset_mask(E_KEYCTRL)(i);
    end loop;

    reg_records_D.KEYSIZE.base.update   <= '0';
    for i in reg_records_Q.KEYSIZE.base.raw'range loop
      reg_records_D.KEYSIZE.base.raw(i) <= (reg_records_Q.KEYSIZE.base.raw(i) and not(K_register_autoclr_mask(E_KEYSIZE)(i))) or K_register_autoset_mask(E_KEYSIZE)(i);
    end loop;

    if ( wupdate_Q = '1' ) then
      case ( V_addr ) is

        when K_register_addresses(E_SCREENOFSX)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.SCREENOFSX.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_SCREENOFSX)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_SCREENOFSX)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.SCREENOFSX.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_SCREENOFSX)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.SCREENOFSX.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.SCREENOFSX.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_SCREENOFSY)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.SCREENOFSY.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_SCREENOFSY)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_SCREENOFSY)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.SCREENOFSY.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_SCREENOFSY)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.SCREENOFSY.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.SCREENOFSY.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_KEYSTATUS)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.KEYSTATUS.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_KEYSTATUS)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_KEYSTATUS)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYSTATUS.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_KEYSTATUS)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYSTATUS.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.KEYSTATUS.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_SCREENY)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.SCREENY.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_SCREENY)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_SCREENY)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.SCREENY.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_SCREENY)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.SCREENY.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.SCREENY.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_SCREENX)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.SCREENX.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_SCREENX)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_SCREENX)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.SCREENX.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_SCREENX)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.SCREENX.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.SCREENX.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_VIDEOY)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.VIDEOY.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_VIDEOY)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_VIDEOY)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.VIDEOY.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_VIDEOY)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.VIDEOY.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.VIDEOY.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_VIDEOX)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.VIDEOX.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_VIDEOX)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_VIDEOX)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.VIDEOX.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_VIDEOX)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.VIDEOX.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.VIDEOX.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_REVID)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.REVID.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_REVID)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_REVID)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.REVID.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_REVID)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.REVID.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.REVID.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_WRAPBACK)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.WRAPBACK.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_WRAPBACK)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_WRAPBACK)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.WRAPBACK.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_WRAPBACK)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.WRAPBACK.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.WRAPBACK.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_SYSID)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.SYSID.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_SYSID)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_SYSID)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.SYSID.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_SYSID)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.SYSID.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.SYSID.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_KEYACTIVE)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.KEYACTIVE.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_KEYACTIVE)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_KEYACTIVE)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYACTIVE.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_KEYACTIVE)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYACTIVE.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.KEYACTIVE.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_KEYLABEL)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.KEYLABEL.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_KEYLABEL)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_KEYLABEL)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYLABEL.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_KEYLABEL)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYLABEL.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.KEYLABEL.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_VIDEOPTR)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.VIDEOPTR.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_VIDEOPTR)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_VIDEOPTR)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.VIDEOPTR.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_VIDEOPTR)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.VIDEOPTR.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.VIDEOPTR.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_IFID)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.IFID.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_IFID)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_IFID)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.IFID.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_IFID)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.IFID.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.IFID.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_VIDEOCTRL)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.VIDEOCTRL.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_VIDEOCTRL)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_VIDEOCTRL)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.VIDEOCTRL.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_VIDEOCTRL)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.VIDEOCTRL.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.VIDEOCTRL.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_KEYREMAIN)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.KEYREMAIN.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_KEYREMAIN)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_KEYREMAIN)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYREMAIN.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_KEYREMAIN)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYREMAIN.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.KEYREMAIN.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_KEYCTRL)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.KEYCTRL.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_KEYCTRL)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_KEYCTRL)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYCTRL.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_KEYCTRL)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYCTRL.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.KEYCTRL.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when K_register_addresses(E_KEYSIZE)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
          reg_records_D.KEYSIZE.base.update <= or_reduce(wstrb_Q);
          for i in 0 to wstrb_Q'left loop
            if ( wstrb_Q(i) = '1' ) then
              for j in (i+1)*8-1 downto i*8 loop
                if ( K_register_write_mask(E_KEYSIZE)(j) = '1' ) then
                  for k in i*8 to (i+1)*8-1 loop
                    if ( K_register_onetoset_mask(E_KEYSIZE)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYSIZE.base.raw(k) <= '1';
                      end if;
                    elsif ( K_register_onetoclr_mask(E_KEYSIZE)(k) = '1' ) then
                      if ( wdata_Q(k) = '1') then
                        reg_records_D.KEYSIZE.base.raw(k) <= '0';
                      end if;
                    else
                      reg_records_D.KEYSIZE.base.raw(k) <= wdata_Q(k);
                    end if;
                  end loop;
                end if;
              end loop;
            end if;
          end loop;

        when others =>
          null;

      end case;
    end if;


    V_data := (others=>'0');
    V_data(registers_sink.SCREENOFSX.ofsX'range) := registers_sink.SCREENOFSX.ofsX;
    if ( registers_sink.SCREENOFSX.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_SCREENOFSX)(i) = '1' ) then
          reg_records_D.SCREENOFSX.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_SCREENOFSX)(i) = '1' ) then
          reg_records_D.SCREENOFSX.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.SCREENOFSY.ofsY'range) := registers_sink.SCREENOFSY.ofsY;
    if ( registers_sink.SCREENOFSY.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_SCREENOFSY)(i) = '1' ) then
          reg_records_D.SCREENOFSY.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_SCREENOFSY)(i) = '1' ) then
          reg_records_D.SCREENOFSY.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYSTATUS.lblActive'range) := registers_sink.KEYSTATUS.lblActive;
    if ( registers_sink.KEYSTATUS.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYSTATUS)(i) = '1' ) then
          reg_records_D.KEYSTATUS.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYSTATUS)(i) = '1' ) then
          reg_records_D.KEYSTATUS.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.SCREENY.ySize'range) := registers_sink.SCREENY.ySize;
    if ( registers_sink.SCREENY.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_SCREENY)(i) = '1' ) then
          reg_records_D.SCREENY.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_SCREENY)(i) = '1' ) then
          reg_records_D.SCREENY.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.SCREENX.xSize'range) := registers_sink.SCREENX.xSize;
    if ( registers_sink.SCREENX.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_SCREENX)(i) = '1' ) then
          reg_records_D.SCREENX.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_SCREENX)(i) = '1' ) then
          reg_records_D.SCREENX.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.VIDEOY.ySize'range) := registers_sink.VIDEOY.ySize;
    if ( registers_sink.VIDEOY.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_VIDEOY)(i) = '1' ) then
          reg_records_D.VIDEOY.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_VIDEOY)(i) = '1' ) then
          reg_records_D.VIDEOY.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.VIDEOX.xSize'range) := registers_sink.VIDEOX.xSize;
    if ( registers_sink.VIDEOX.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_VIDEOX)(i) = '1' ) then
          reg_records_D.VIDEOX.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_VIDEOX)(i) = '1' ) then
          reg_records_D.VIDEOX.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.REVID.hour'range) := registers_sink.REVID.hour;
    V_data(registers_sink.REVID.month'range) := registers_sink.REVID.month;
    V_data(registers_sink.REVID.class'range) := registers_sink.REVID.class;
    V_data(registers_sink.REVID.day'range) := registers_sink.REVID.day;
    V_data(registers_sink.REVID.year'range) := registers_sink.REVID.year;
    if ( registers_sink.REVID.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.WRAPBACK.wrapData'range) := registers_sink.WRAPBACK.wrapData;
    if ( registers_sink.WRAPBACK.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_WRAPBACK)(i) = '1' ) then
          reg_records_D.WRAPBACK.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_WRAPBACK)(i) = '1' ) then
          reg_records_D.WRAPBACK.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.SYSID.systemID'range) := registers_sink.SYSID.systemID;
    if ( registers_sink.SYSID.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_SYSID)(i) = '1' ) then
          reg_records_D.SYSID.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_SYSID)(i) = '1' ) then
          reg_records_D.SYSID.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYACTIVE.lastLbl'range) := registers_sink.KEYACTIVE.lastLbl;
    if ( registers_sink.KEYACTIVE.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYACTIVE)(i) = '1' ) then
          reg_records_D.KEYACTIVE.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYACTIVE)(i) = '1' ) then
          reg_records_D.KEYACTIVE.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYLABEL.keyLabel'range) := registers_sink.KEYLABEL.keyLabel;
    if ( registers_sink.KEYLABEL.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYLABEL)(i) = '1' ) then
          reg_records_D.KEYLABEL.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYLABEL)(i) = '1' ) then
          reg_records_D.KEYLABEL.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.VIDEOPTR.ptr'range) := registers_sink.VIDEOPTR.ptr;
    if ( registers_sink.VIDEOPTR.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_VIDEOPTR)(i) = '1' ) then
          reg_records_D.VIDEOPTR.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_VIDEOPTR)(i) = '1' ) then
          reg_records_D.VIDEOPTR.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.IFID.interfaceID'range) := registers_sink.IFID.interfaceID;
    if ( registers_sink.IFID.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_IFID)(i) = '1' ) then
          reg_records_D.IFID.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_IFID)(i) = '1' ) then
          reg_records_D.IFID.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.VIDEOCTRL.rst'range) := registers_sink.VIDEOCTRL.rst;
    V_data(registers_sink.VIDEOCTRL.ena'range) := registers_sink.VIDEOCTRL.ena;
    if ( registers_sink.VIDEOCTRL.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_VIDEOCTRL)(i) = '1' ) then
          reg_records_D.VIDEOCTRL.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_VIDEOCTRL)(i) = '1' ) then
          reg_records_D.VIDEOCTRL.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYREMAIN.lblRemain'range) := registers_sink.KEYREMAIN.lblRemain;
    if ( registers_sink.KEYREMAIN.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYREMAIN)(i) = '1' ) then
          reg_records_D.KEYREMAIN.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYREMAIN)(i) = '1' ) then
          reg_records_D.KEYREMAIN.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYCTRL.acquire'range) := registers_sink.KEYCTRL.acquire;
    if ( registers_sink.KEYCTRL.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYCTRL)(i) = '1' ) then
          reg_records_D.KEYCTRL.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYCTRL)(i) = '1' ) then
          reg_records_D.KEYCTRL.base.raw(i) <= '1';
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYSIZE.lblSize'range) := registers_sink.KEYSIZE.lblSize;
    if ( registers_sink.KEYSIZE.base.update = '1' ) then
      for i in 0 to K_REG_WIDTH-1 loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYSIZE)(i) = '1' ) then
          reg_records_D.KEYSIZE.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYSIZE)(i) = '1' ) then
          reg_records_D.KEYSIZE.base.raw(i) <= '1';
        end if;
      end loop;
    end if;


  end process C_register_write;


  C_SCREENOFSX_base : process (
    registers_sink
  )
  begin
    reg_records_I.SCREENOFSX.base.raw <= (others=>'0');
    reg_records_I.SCREENOFSX.base.raw(reg_records_I.SCREENOFSX.ofsX'range) <= registers_sink.SCREENOFSX.ofsX;
  end process C_SCREENOFSX_base;

  C_SCREENOFSY_base : process (
    registers_sink
  )
  begin
    reg_records_I.SCREENOFSY.base.raw <= (others=>'0');
    reg_records_I.SCREENOFSY.base.raw(reg_records_I.SCREENOFSY.ofsY'range) <= registers_sink.SCREENOFSY.ofsY;
  end process C_SCREENOFSY_base;

  C_KEYSTATUS_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYSTATUS.base.raw <= (others=>'0');
    reg_records_I.KEYSTATUS.base.raw(reg_records_I.KEYSTATUS.lblActive'range) <= registers_sink.KEYSTATUS.lblActive;
  end process C_KEYSTATUS_base;

  C_SCREENY_base : process (
    registers_sink
  )
  begin
    reg_records_I.SCREENY.base.raw <= (others=>'0');
    reg_records_I.SCREENY.base.raw(reg_records_I.SCREENY.ySize'range) <= registers_sink.SCREENY.ySize;
  end process C_SCREENY_base;

  C_SCREENX_base : process (
    registers_sink
  )
  begin
    reg_records_I.SCREENX.base.raw <= (others=>'0');
    reg_records_I.SCREENX.base.raw(reg_records_I.SCREENX.xSize'range) <= registers_sink.SCREENX.xSize;
  end process C_SCREENX_base;

  C_VIDEOY_base : process (
    registers_sink
  )
  begin
    reg_records_I.VIDEOY.base.raw <= (others=>'0');
    reg_records_I.VIDEOY.base.raw(reg_records_I.VIDEOY.ySize'range) <= registers_sink.VIDEOY.ySize;
  end process C_VIDEOY_base;

  C_VIDEOX_base : process (
    registers_sink
  )
  begin
    reg_records_I.VIDEOX.base.raw <= (others=>'0');
    reg_records_I.VIDEOX.base.raw(reg_records_I.VIDEOX.xSize'range) <= registers_sink.VIDEOX.xSize;
  end process C_VIDEOX_base;

  C_REVID_base : process (
    registers_sink
  )
  begin
    reg_records_I.REVID.base.raw <= (others=>'0');
    reg_records_I.REVID.base.raw(reg_records_I.REVID.hour'range) <= registers_sink.REVID.hour;
    reg_records_I.REVID.base.raw(reg_records_I.REVID.month'range) <= registers_sink.REVID.month;
    reg_records_I.REVID.base.raw(reg_records_I.REVID.class'range) <= registers_sink.REVID.class;
    reg_records_I.REVID.base.raw(reg_records_I.REVID.day'range) <= registers_sink.REVID.day;
    reg_records_I.REVID.base.raw(reg_records_I.REVID.year'range) <= registers_sink.REVID.year;
  end process C_REVID_base;

  C_WRAPBACK_base : process (
    registers_sink
  )
  begin
    reg_records_I.WRAPBACK.base.raw <= (others=>'0');
    reg_records_I.WRAPBACK.base.raw(reg_records_I.WRAPBACK.wrapData'range) <= registers_sink.WRAPBACK.wrapData;
  end process C_WRAPBACK_base;

  C_SYSID_base : process (
    registers_sink
  )
  begin
    reg_records_I.SYSID.base.raw <= (others=>'0');
    reg_records_I.SYSID.base.raw(reg_records_I.SYSID.systemID'range) <= registers_sink.SYSID.systemID;
  end process C_SYSID_base;

  C_KEYACTIVE_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYACTIVE.base.raw <= (others=>'0');
    reg_records_I.KEYACTIVE.base.raw(reg_records_I.KEYACTIVE.lastLbl'range) <= registers_sink.KEYACTIVE.lastLbl;
  end process C_KEYACTIVE_base;

  C_KEYLABEL_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYLABEL.base.raw <= (others=>'0');
    reg_records_I.KEYLABEL.base.raw(reg_records_I.KEYLABEL.keyLabel'range) <= registers_sink.KEYLABEL.keyLabel;
  end process C_KEYLABEL_base;

  C_VIDEOPTR_base : process (
    registers_sink
  )
  begin
    reg_records_I.VIDEOPTR.base.raw <= (others=>'0');
    reg_records_I.VIDEOPTR.base.raw(reg_records_I.VIDEOPTR.ptr'range) <= registers_sink.VIDEOPTR.ptr;
  end process C_VIDEOPTR_base;

  C_IFID_base : process (
    registers_sink
  )
  begin
    reg_records_I.IFID.base.raw <= (others=>'0');
    reg_records_I.IFID.base.raw(reg_records_I.IFID.interfaceID'range) <= registers_sink.IFID.interfaceID;
  end process C_IFID_base;

  C_VIDEOCTRL_base : process (
    registers_sink
  )
  begin
    reg_records_I.VIDEOCTRL.base.raw <= (others=>'0');
    reg_records_I.VIDEOCTRL.base.raw(reg_records_I.VIDEOCTRL.rst'range) <= registers_sink.VIDEOCTRL.rst;
    reg_records_I.VIDEOCTRL.base.raw(reg_records_I.VIDEOCTRL.ena'range) <= registers_sink.VIDEOCTRL.ena;
  end process C_VIDEOCTRL_base;

  C_KEYREMAIN_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYREMAIN.base.raw <= (others=>'0');
    reg_records_I.KEYREMAIN.base.raw(reg_records_I.KEYREMAIN.lblRemain'range) <= registers_sink.KEYREMAIN.lblRemain;
  end process C_KEYREMAIN_base;

  C_KEYCTRL_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYCTRL.base.raw <= (others=>'0');
    reg_records_I.KEYCTRL.base.raw(reg_records_I.KEYCTRL.acquire'range) <= registers_sink.KEYCTRL.acquire;
  end process C_KEYCTRL_base;

  C_KEYSIZE_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYSIZE.base.raw <= (others=>'0');
    reg_records_I.KEYSIZE.base.raw(reg_records_I.KEYSIZE.lblSize'range) <= registers_sink.KEYSIZE.lblSize;
  end process C_KEYSIZE_base;


  C_register_read : process (
    rdata_Q,
    raddr_Q,
    rupdate_Q,
    reg_records_I,
    reg_records_Q
  )
    variable V_addr : std_logic_vector(K_reg_addr_hibit downto K_reg_addr_lobit);
  begin

    V_addr := raddr_Q(K_reg_addr_hibit downto K_reg_addr_lobit);
    registers_source.SCREENOFSX.base.accessed <= '0';
    registers_source.SCREENOFSY.base.accessed <= '0';
    registers_source.KEYSTATUS.base.accessed <= '0';
    registers_source.SCREENY.base.accessed <= '0';
    registers_source.SCREENX.base.accessed <= '0';
    registers_source.VIDEOY.base.accessed <= '0';
    registers_source.VIDEOX.base.accessed <= '0';
    registers_source.REVID.base.accessed <= '0';
    registers_source.WRAPBACK.base.accessed <= '0';
    registers_source.SYSID.base.accessed <= '0';
    registers_source.KEYACTIVE.base.accessed <= '0';
    registers_source.KEYLABEL.base.accessed <= '0';
    registers_source.VIDEOPTR.base.accessed <= '0';
    registers_source.IFID.base.accessed <= '0';
    registers_source.VIDEOCTRL.base.accessed <= '0';
    registers_source.KEYREMAIN.base.accessed <= '0';
    registers_source.KEYCTRL.base.accessed <= '0';
    registers_source.KEYSIZE.base.accessed <= '0';


    case ( V_addr ) is
      when K_register_addresses(E_SCREENOFSX)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.SCREENOFSX.base.accessed <= rupdate_Q;
        for i in reg_records_I.SCREENOFSX.base.raw'range loop
          if ( K_register_external_mask(E_SCREENOFSX)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.SCREENOFSX.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.SCREENOFSX.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_SCREENOFSY)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.SCREENOFSY.base.accessed <= rupdate_Q;
        for i in reg_records_I.SCREENOFSY.base.raw'range loop
          if ( K_register_external_mask(E_SCREENOFSY)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.SCREENOFSY.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.SCREENOFSY.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_KEYSTATUS)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.KEYSTATUS.base.accessed <= rupdate_Q;
        for i in reg_records_I.KEYSTATUS.base.raw'range loop
          if ( K_register_external_mask(E_KEYSTATUS)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.KEYSTATUS.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.KEYSTATUS.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_SCREENY)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.SCREENY.base.accessed <= rupdate_Q;
        for i in reg_records_I.SCREENY.base.raw'range loop
          if ( K_register_external_mask(E_SCREENY)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.SCREENY.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.SCREENY.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_SCREENX)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.SCREENX.base.accessed <= rupdate_Q;
        for i in reg_records_I.SCREENX.base.raw'range loop
          if ( K_register_external_mask(E_SCREENX)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.SCREENX.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.SCREENX.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_VIDEOY)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.VIDEOY.base.accessed <= rupdate_Q;
        for i in reg_records_I.VIDEOY.base.raw'range loop
          if ( K_register_external_mask(E_VIDEOY)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.VIDEOY.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.VIDEOY.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_VIDEOX)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.VIDEOX.base.accessed <= rupdate_Q;
        for i in reg_records_I.VIDEOX.base.raw'range loop
          if ( K_register_external_mask(E_VIDEOX)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.VIDEOX.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.VIDEOX.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_REVID)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.REVID.base.accessed <= rupdate_Q;
        for i in reg_records_I.REVID.base.raw'range loop
          if ( K_register_external_mask(E_REVID)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.REVID.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.REVID.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_WRAPBACK)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.WRAPBACK.base.accessed <= rupdate_Q;
        for i in reg_records_I.WRAPBACK.base.raw'range loop
          if ( K_register_external_mask(E_WRAPBACK)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.WRAPBACK.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.WRAPBACK.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_SYSID)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.SYSID.base.accessed <= rupdate_Q;
        for i in reg_records_I.SYSID.base.raw'range loop
          if ( K_register_external_mask(E_SYSID)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.SYSID.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.SYSID.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_KEYACTIVE)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.KEYACTIVE.base.accessed <= rupdate_Q;
        for i in reg_records_I.KEYACTIVE.base.raw'range loop
          if ( K_register_external_mask(E_KEYACTIVE)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.KEYACTIVE.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.KEYACTIVE.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_KEYLABEL)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.KEYLABEL.base.accessed <= rupdate_Q;
        for i in reg_records_I.KEYLABEL.base.raw'range loop
          if ( K_register_external_mask(E_KEYLABEL)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.KEYLABEL.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.KEYLABEL.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_VIDEOPTR)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.VIDEOPTR.base.accessed <= rupdate_Q;
        for i in reg_records_I.VIDEOPTR.base.raw'range loop
          if ( K_register_external_mask(E_VIDEOPTR)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.VIDEOPTR.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.VIDEOPTR.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_IFID)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.IFID.base.accessed <= rupdate_Q;
        for i in reg_records_I.IFID.base.raw'range loop
          if ( K_register_external_mask(E_IFID)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.IFID.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.IFID.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_VIDEOCTRL)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.VIDEOCTRL.base.accessed <= rupdate_Q;
        for i in reg_records_I.VIDEOCTRL.base.raw'range loop
          if ( K_register_external_mask(E_VIDEOCTRL)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.VIDEOCTRL.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.VIDEOCTRL.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_KEYREMAIN)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.KEYREMAIN.base.accessed <= rupdate_Q;
        for i in reg_records_I.KEYREMAIN.base.raw'range loop
          if ( K_register_external_mask(E_KEYREMAIN)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.KEYREMAIN.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.KEYREMAIN.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_KEYCTRL)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.KEYCTRL.base.accessed <= rupdate_Q;
        for i in reg_records_I.KEYCTRL.base.raw'range loop
          if ( K_register_external_mask(E_KEYCTRL)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.KEYCTRL.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.KEYCTRL.base.raw(i);
          end if;
        end loop;

      when K_register_addresses(E_KEYSIZE)(K_reg_addr_hibit downto K_reg_addr_lobit) =>
        registers_source.KEYSIZE.base.accessed <= rupdate_Q;
        for i in reg_records_I.KEYSIZE.base.raw'range loop
          if ( K_register_external_mask(E_KEYSIZE)(i) = '1' ) then
            rdata_D(i) <= reg_records_I.KEYSIZE.base.raw(i);
          else
            rdata_D(i) <= reg_records_Q.KEYSIZE.base.raw(i);
          end if;
        end loop;


      when others =>
        rdata_D <= (others=>'1');

    end case;

  end process C_register_read;


  S_reg : process (
    aclk,
    areset_n
  )
  begin

    if ( areset_n = '0' ) then

      reg_records_Q.SCREENOFSX.base.raw <= K_register_defaults(E_SCREENOFSX);
      reg_records_Q.SCREENOFSX.base.update <= '0';
      reg_records_Q.SCREENOFSY.base.raw <= K_register_defaults(E_SCREENOFSY);
      reg_records_Q.SCREENOFSY.base.update <= '0';
      reg_records_Q.KEYSTATUS.base.raw <= K_register_defaults(E_KEYSTATUS);
      reg_records_Q.KEYSTATUS.base.update <= '0';
      reg_records_Q.SCREENY.base.raw <= K_register_defaults(E_SCREENY);
      reg_records_Q.SCREENY.base.update <= '0';
      reg_records_Q.SCREENX.base.raw <= K_register_defaults(E_SCREENX);
      reg_records_Q.SCREENX.base.update <= '0';
      reg_records_Q.VIDEOY.base.raw <= K_register_defaults(E_VIDEOY);
      reg_records_Q.VIDEOY.base.update <= '0';
      reg_records_Q.VIDEOX.base.raw <= K_register_defaults(E_VIDEOX);
      reg_records_Q.VIDEOX.base.update <= '0';
      reg_records_Q.REVID.base.raw <= K_register_defaults(E_REVID);
      reg_records_Q.REVID.base.update <= '0';
      reg_records_Q.WRAPBACK.base.raw <= K_register_defaults(E_WRAPBACK);
      reg_records_Q.WRAPBACK.base.update <= '0';
      reg_records_Q.SYSID.base.raw <= K_register_defaults(E_SYSID);
      reg_records_Q.SYSID.base.update <= '0';
      reg_records_Q.KEYACTIVE.base.raw <= K_register_defaults(E_KEYACTIVE);
      reg_records_Q.KEYACTIVE.base.update <= '0';
      reg_records_Q.KEYLABEL.base.raw <= K_register_defaults(E_KEYLABEL);
      reg_records_Q.KEYLABEL.base.update <= '0';
      reg_records_Q.VIDEOPTR.base.raw <= K_register_defaults(E_VIDEOPTR);
      reg_records_Q.VIDEOPTR.base.update <= '0';
      reg_records_Q.IFID.base.raw <= K_register_defaults(E_IFID);
      reg_records_Q.IFID.base.update <= '0';
      reg_records_Q.VIDEOCTRL.base.raw <= K_register_defaults(E_VIDEOCTRL);
      reg_records_Q.VIDEOCTRL.base.update <= '0';
      reg_records_Q.KEYREMAIN.base.raw <= K_register_defaults(E_KEYREMAIN);
      reg_records_Q.KEYREMAIN.base.update <= '0';
      reg_records_Q.KEYCTRL.base.raw <= K_register_defaults(E_KEYCTRL);
      reg_records_Q.KEYCTRL.base.update <= '0';
      reg_records_Q.KEYSIZE.base.raw <= K_register_defaults(E_KEYSIZE);
      reg_records_Q.KEYSIZE.base.update <= '0';

    elsif ( rising_edge(aclk) ) then

      reg_records_Q.SCREENOFSX.base.raw <= reg_records_D.SCREENOFSX.base.raw;
      reg_records_Q.SCREENOFSX.base.update <= reg_records_D.SCREENOFSX.base.update;
      reg_records_Q.SCREENOFSY.base.raw <= reg_records_D.SCREENOFSY.base.raw;
      reg_records_Q.SCREENOFSY.base.update <= reg_records_D.SCREENOFSY.base.update;
      reg_records_Q.KEYSTATUS.base.raw <= reg_records_D.KEYSTATUS.base.raw;
      reg_records_Q.KEYSTATUS.base.update <= reg_records_D.KEYSTATUS.base.update;
      reg_records_Q.SCREENY.base.raw <= reg_records_D.SCREENY.base.raw;
      reg_records_Q.SCREENY.base.update <= reg_records_D.SCREENY.base.update;
      reg_records_Q.SCREENX.base.raw <= reg_records_D.SCREENX.base.raw;
      reg_records_Q.SCREENX.base.update <= reg_records_D.SCREENX.base.update;
      reg_records_Q.VIDEOY.base.raw <= reg_records_D.VIDEOY.base.raw;
      reg_records_Q.VIDEOY.base.update <= reg_records_D.VIDEOY.base.update;
      reg_records_Q.VIDEOX.base.raw <= reg_records_D.VIDEOX.base.raw;
      reg_records_Q.VIDEOX.base.update <= reg_records_D.VIDEOX.base.update;
      reg_records_Q.REVID.base.raw <= reg_records_D.REVID.base.raw;
      reg_records_Q.REVID.base.update <= reg_records_D.REVID.base.update;
      reg_records_Q.WRAPBACK.base.raw <= reg_records_D.WRAPBACK.base.raw;
      reg_records_Q.WRAPBACK.base.update <= reg_records_D.WRAPBACK.base.update;
      reg_records_Q.SYSID.base.raw <= reg_records_D.SYSID.base.raw;
      reg_records_Q.SYSID.base.update <= reg_records_D.SYSID.base.update;
      reg_records_Q.KEYACTIVE.base.raw <= reg_records_D.KEYACTIVE.base.raw;
      reg_records_Q.KEYACTIVE.base.update <= reg_records_D.KEYACTIVE.base.update;
      reg_records_Q.KEYLABEL.base.raw <= reg_records_D.KEYLABEL.base.raw;
      reg_records_Q.KEYLABEL.base.update <= reg_records_D.KEYLABEL.base.update;
      reg_records_Q.VIDEOPTR.base.raw <= reg_records_D.VIDEOPTR.base.raw;
      reg_records_Q.VIDEOPTR.base.update <= reg_records_D.VIDEOPTR.base.update;
      reg_records_Q.IFID.base.raw <= reg_records_D.IFID.base.raw;
      reg_records_Q.IFID.base.update <= reg_records_D.IFID.base.update;
      reg_records_Q.VIDEOCTRL.base.raw <= reg_records_D.VIDEOCTRL.base.raw;
      reg_records_Q.VIDEOCTRL.base.update <= reg_records_D.VIDEOCTRL.base.update;
      reg_records_Q.KEYREMAIN.base.raw <= reg_records_D.KEYREMAIN.base.raw;
      reg_records_Q.KEYREMAIN.base.update <= reg_records_D.KEYREMAIN.base.update;
      reg_records_Q.KEYCTRL.base.raw <= reg_records_D.KEYCTRL.base.raw;
      reg_records_Q.KEYCTRL.base.update <= reg_records_D.KEYCTRL.base.update;
      reg_records_Q.KEYSIZE.base.raw <= reg_records_D.KEYSIZE.base.raw;
      reg_records_Q.KEYSIZE.base.update <= reg_records_D.KEYSIZE.base.update;

    end if;

  end process S_reg;


end architecture rtl_vga_registers_core;

