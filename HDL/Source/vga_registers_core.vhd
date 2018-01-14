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
  registers_source.SCREENOFSX.ofsX.data <= reg_records_Q.SCREENOFSX.base.raw(registers_source.SCREENOFSX.ofsX.data'range);

  registers_source.SCREENOFSY.base.raw <= reg_records_Q.SCREENOFSY.base.raw;
  registers_source.SCREENOFSY.base.update <= reg_records_Q.SCREENOFSY.base.update;
  registers_source.SCREENOFSY.base.address <= K_register_addresses(E_SCREENOFSY);
  registers_source.SCREENOFSY.base.default <= K_register_defaults(E_SCREENOFSY);
  registers_source.SCREENOFSY.ofsY.data <= reg_records_Q.SCREENOFSY.base.raw(registers_source.SCREENOFSY.ofsY.data'range);

  registers_source.KEYSTATUS.base.raw <= reg_records_Q.KEYSTATUS.base.raw;
  registers_source.KEYSTATUS.base.update <= reg_records_Q.KEYSTATUS.base.update;
  registers_source.KEYSTATUS.base.address <= K_register_addresses(E_KEYSTATUS);
  registers_source.KEYSTATUS.base.default <= K_register_defaults(E_KEYSTATUS);
  registers_source.KEYSTATUS.lblActive.data <= reg_records_Q.KEYSTATUS.base.raw(registers_source.KEYSTATUS.lblActive.data'range);

  registers_source.SCREENY.base.raw <= reg_records_Q.SCREENY.base.raw;
  registers_source.SCREENY.base.update <= reg_records_Q.SCREENY.base.update;
  registers_source.SCREENY.base.address <= K_register_addresses(E_SCREENY);
  registers_source.SCREENY.base.default <= K_register_defaults(E_SCREENY);
  registers_source.SCREENY.ySize.data <= reg_records_Q.SCREENY.base.raw(registers_source.SCREENY.ySize.data'range);

  registers_source.SCREENX.base.raw <= reg_records_Q.SCREENX.base.raw;
  registers_source.SCREENX.base.update <= reg_records_Q.SCREENX.base.update;
  registers_source.SCREENX.base.address <= K_register_addresses(E_SCREENX);
  registers_source.SCREENX.base.default <= K_register_defaults(E_SCREENX);
  registers_source.SCREENX.xSize.data <= reg_records_Q.SCREENX.base.raw(registers_source.SCREENX.xSize.data'range);

  registers_source.VIDEOY.base.raw <= reg_records_Q.VIDEOY.base.raw;
  registers_source.VIDEOY.base.update <= reg_records_Q.VIDEOY.base.update;
  registers_source.VIDEOY.base.address <= K_register_addresses(E_VIDEOY);
  registers_source.VIDEOY.base.default <= K_register_defaults(E_VIDEOY);
  registers_source.VIDEOY.ySize.data <= reg_records_Q.VIDEOY.base.raw(registers_source.VIDEOY.ySize.data'range);

  registers_source.VIDEOX.base.raw <= reg_records_Q.VIDEOX.base.raw;
  registers_source.VIDEOX.base.update <= reg_records_Q.VIDEOX.base.update;
  registers_source.VIDEOX.base.address <= K_register_addresses(E_VIDEOX);
  registers_source.VIDEOX.base.default <= K_register_defaults(E_VIDEOX);
  registers_source.VIDEOX.xSize.data <= reg_records_Q.VIDEOX.base.raw(registers_source.VIDEOX.xSize.data'range);

  registers_source.REVID.base.raw <= reg_records_Q.REVID.base.raw;
  registers_source.REVID.base.update <= reg_records_Q.REVID.base.update;
  registers_source.REVID.base.address <= K_register_addresses(E_REVID);
  registers_source.REVID.base.default <= K_register_defaults(E_REVID);
  registers_source.REVID.hour.data <= reg_records_Q.REVID.base.raw(registers_source.REVID.hour.data'range);
  registers_source.REVID.month.data <= reg_records_Q.REVID.base.raw(registers_source.REVID.month.data'range);
  registers_source.REVID.class.data <= reg_records_Q.REVID.base.raw(registers_source.REVID.class.data'range);
  registers_source.REVID.day.data <= reg_records_Q.REVID.base.raw(registers_source.REVID.day.data'range);
  registers_source.REVID.year.data <= reg_records_Q.REVID.base.raw(registers_source.REVID.year.data'range);

  registers_source.WRAPBACK.base.raw <= reg_records_Q.WRAPBACK.base.raw;
  registers_source.WRAPBACK.base.update <= reg_records_Q.WRAPBACK.base.update;
  registers_source.WRAPBACK.base.address <= K_register_addresses(E_WRAPBACK);
  registers_source.WRAPBACK.base.default <= K_register_defaults(E_WRAPBACK);
  registers_source.WRAPBACK.wrapData.data <= reg_records_Q.WRAPBACK.base.raw(registers_source.WRAPBACK.wrapData.data'range);

  registers_source.SYSID.base.raw <= reg_records_Q.SYSID.base.raw;
  registers_source.SYSID.base.update <= reg_records_Q.SYSID.base.update;
  registers_source.SYSID.base.address <= K_register_addresses(E_SYSID);
  registers_source.SYSID.base.default <= K_register_defaults(E_SYSID);
  registers_source.SYSID.systemID.data <= reg_records_Q.SYSID.base.raw(registers_source.SYSID.systemID.data'range);

  registers_source.KEYACTIVE.base.raw <= reg_records_Q.KEYACTIVE.base.raw;
  registers_source.KEYACTIVE.base.update <= reg_records_Q.KEYACTIVE.base.update;
  registers_source.KEYACTIVE.base.address <= K_register_addresses(E_KEYACTIVE);
  registers_source.KEYACTIVE.base.default <= K_register_defaults(E_KEYACTIVE);
  registers_source.KEYACTIVE.lastLbl.data <= reg_records_Q.KEYACTIVE.base.raw(registers_source.KEYACTIVE.lastLbl.data'range);

  registers_source.KEYLABEL.base.raw <= reg_records_Q.KEYLABEL.base.raw;
  registers_source.KEYLABEL.base.update <= reg_records_Q.KEYLABEL.base.update;
  registers_source.KEYLABEL.base.address <= K_register_addresses(E_KEYLABEL);
  registers_source.KEYLABEL.base.default <= K_register_defaults(E_KEYLABEL);
  registers_source.KEYLABEL.keyLabel.data <= reg_records_Q.KEYLABEL.base.raw(registers_source.KEYLABEL.keyLabel.data'range);

  registers_source.VIDEOPTR.base.raw <= reg_records_Q.VIDEOPTR.base.raw;
  registers_source.VIDEOPTR.base.update <= reg_records_Q.VIDEOPTR.base.update;
  registers_source.VIDEOPTR.base.address <= K_register_addresses(E_VIDEOPTR);
  registers_source.VIDEOPTR.base.default <= K_register_defaults(E_VIDEOPTR);
  registers_source.VIDEOPTR.ptr.data <= reg_records_Q.VIDEOPTR.base.raw(registers_source.VIDEOPTR.ptr.data'range);

  registers_source.IFID.base.raw <= reg_records_Q.IFID.base.raw;
  registers_source.IFID.base.update <= reg_records_Q.IFID.base.update;
  registers_source.IFID.base.address <= K_register_addresses(E_IFID);
  registers_source.IFID.base.default <= K_register_defaults(E_IFID);
  registers_source.IFID.interfaceID.data <= reg_records_Q.IFID.base.raw(registers_source.IFID.interfaceID.data'range);

  registers_source.VIDEOCTRL.base.raw <= reg_records_Q.VIDEOCTRL.base.raw;
  registers_source.VIDEOCTRL.base.update <= reg_records_Q.VIDEOCTRL.base.update;
  registers_source.VIDEOCTRL.base.address <= K_register_addresses(E_VIDEOCTRL);
  registers_source.VIDEOCTRL.base.default <= K_register_defaults(E_VIDEOCTRL);
  registers_source.VIDEOCTRL.rst.data <= reg_records_Q.VIDEOCTRL.base.raw(registers_source.VIDEOCTRL.rst.data'range);
  registers_source.VIDEOCTRL.ena.data <= reg_records_Q.VIDEOCTRL.base.raw(registers_source.VIDEOCTRL.ena.data'range);

  registers_source.KEYREMAIN.base.raw <= reg_records_Q.KEYREMAIN.base.raw;
  registers_source.KEYREMAIN.base.update <= reg_records_Q.KEYREMAIN.base.update;
  registers_source.KEYREMAIN.base.address <= K_register_addresses(E_KEYREMAIN);
  registers_source.KEYREMAIN.base.default <= K_register_defaults(E_KEYREMAIN);
  registers_source.KEYREMAIN.lblRemain.data <= reg_records_Q.KEYREMAIN.base.raw(registers_source.KEYREMAIN.lblRemain.data'range);

  registers_source.KEYCTRL.base.raw <= reg_records_Q.KEYCTRL.base.raw;
  registers_source.KEYCTRL.base.update <= reg_records_Q.KEYCTRL.base.update;
  registers_source.KEYCTRL.base.address <= K_register_addresses(E_KEYCTRL);
  registers_source.KEYCTRL.base.default <= K_register_defaults(E_KEYCTRL);
  registers_source.KEYCTRL.acquire.data <= reg_records_Q.KEYCTRL.base.raw(registers_source.KEYCTRL.acquire.data'range);

  registers_source.KEYSIZE.base.raw <= reg_records_Q.KEYSIZE.base.raw;
  registers_source.KEYSIZE.base.update <= reg_records_Q.KEYSIZE.base.update;
  registers_source.KEYSIZE.base.address <= K_register_addresses(E_KEYSIZE);
  registers_source.KEYSIZE.base.default <= K_register_defaults(E_KEYSIZE);
  registers_source.KEYSIZE.lblSize.data <= reg_records_Q.KEYSIZE.base.raw(registers_source.KEYSIZE.lblSize.data'range);


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

    V_data := (others=>'0');
    V_data(registers_sink.SCREENOFSX.ofsX.data'range) := registers_sink.SCREENOFSX.ofsX.data;
    if ( registers_sink.SCREENOFSX.ofsX.update = '1' ) then
      for i in registers_sink.SCREENOFSX.ofsX.data'range loop
        if ( K_register_external_mask(E_SCREENOFSX)(i) = '0' ) then
          reg_records_D.SCREENOFSX.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.SCREENOFSY.ofsY.data'range) := registers_sink.SCREENOFSY.ofsY.data;
    if ( registers_sink.SCREENOFSY.ofsY.update = '1' ) then
      for i in registers_sink.SCREENOFSY.ofsY.data'range loop
        if ( K_register_external_mask(E_SCREENOFSY)(i) = '0' ) then
          reg_records_D.SCREENOFSY.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYSTATUS.lblActive.data'range) := registers_sink.KEYSTATUS.lblActive.data;
    if ( registers_sink.KEYSTATUS.lblActive.update = '1' ) then
      for i in registers_sink.KEYSTATUS.lblActive.data'range loop
        if ( K_register_external_mask(E_KEYSTATUS)(i) = '0' ) then
          reg_records_D.KEYSTATUS.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.SCREENY.ySize.data'range) := registers_sink.SCREENY.ySize.data;
    if ( registers_sink.SCREENY.ySize.update = '1' ) then
      for i in registers_sink.SCREENY.ySize.data'range loop
        if ( K_register_external_mask(E_SCREENY)(i) = '0' ) then
          reg_records_D.SCREENY.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.SCREENX.xSize.data'range) := registers_sink.SCREENX.xSize.data;
    if ( registers_sink.SCREENX.xSize.update = '1' ) then
      for i in registers_sink.SCREENX.xSize.data'range loop
        if ( K_register_external_mask(E_SCREENX)(i) = '0' ) then
          reg_records_D.SCREENX.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.VIDEOY.ySize.data'range) := registers_sink.VIDEOY.ySize.data;
    if ( registers_sink.VIDEOY.ySize.update = '1' ) then
      for i in registers_sink.VIDEOY.ySize.data'range loop
        if ( K_register_external_mask(E_VIDEOY)(i) = '0' ) then
          reg_records_D.VIDEOY.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.VIDEOX.xSize.data'range) := registers_sink.VIDEOX.xSize.data;
    if ( registers_sink.VIDEOX.xSize.update = '1' ) then
      for i in registers_sink.VIDEOX.xSize.data'range loop
        if ( K_register_external_mask(E_VIDEOX)(i) = '0' ) then
          reg_records_D.VIDEOX.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.REVID.hour.data'range) := registers_sink.REVID.hour.data;
    V_data(registers_sink.REVID.month.data'range) := registers_sink.REVID.month.data;
    V_data(registers_sink.REVID.class.data'range) := registers_sink.REVID.class.data;
    V_data(registers_sink.REVID.day.data'range) := registers_sink.REVID.day.data;
    V_data(registers_sink.REVID.year.data'range) := registers_sink.REVID.year.data;
    if ( registers_sink.REVID.hour.update = '1' ) then
      for i in registers_sink.REVID.hour.data'range loop
        if ( K_register_external_mask(E_REVID)(i) = '0' ) then
          reg_records_D.REVID.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    if ( registers_sink.REVID.month.update = '1' ) then
      for i in registers_sink.REVID.month.data'range loop
        if ( K_register_external_mask(E_REVID)(i) = '0' ) then
          reg_records_D.REVID.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    if ( registers_sink.REVID.class.update = '1' ) then
      for i in registers_sink.REVID.class.data'range loop
        if ( K_register_external_mask(E_REVID)(i) = '0' ) then
          reg_records_D.REVID.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    if ( registers_sink.REVID.day.update = '1' ) then
      for i in registers_sink.REVID.day.data'range loop
        if ( K_register_external_mask(E_REVID)(i) = '0' ) then
          reg_records_D.REVID.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    if ( registers_sink.REVID.year.update = '1' ) then
      for i in registers_sink.REVID.year.data'range loop
        if ( K_register_external_mask(E_REVID)(i) = '0' ) then
          reg_records_D.REVID.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.WRAPBACK.wrapData.data'range) := registers_sink.WRAPBACK.wrapData.data;
    if ( registers_sink.WRAPBACK.wrapData.update = '1' ) then
      for i in registers_sink.WRAPBACK.wrapData.data'range loop
        if ( K_register_external_mask(E_WRAPBACK)(i) = '0' ) then
          reg_records_D.WRAPBACK.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.SYSID.systemID.data'range) := registers_sink.SYSID.systemID.data;
    if ( registers_sink.SYSID.systemID.update = '1' ) then
      for i in registers_sink.SYSID.systemID.data'range loop
        if ( K_register_external_mask(E_SYSID)(i) = '0' ) then
          reg_records_D.SYSID.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYACTIVE.lastLbl.data'range) := registers_sink.KEYACTIVE.lastLbl.data;
    if ( registers_sink.KEYACTIVE.lastLbl.update = '1' ) then
      for i in registers_sink.KEYACTIVE.lastLbl.data'range loop
        if ( K_register_external_mask(E_KEYACTIVE)(i) = '0' ) then
          reg_records_D.KEYACTIVE.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYLABEL.keyLabel.data'range) := registers_sink.KEYLABEL.keyLabel.data;
    if ( registers_sink.KEYLABEL.keyLabel.update = '1' ) then
      for i in registers_sink.KEYLABEL.keyLabel.data'range loop
        if ( K_register_external_mask(E_KEYLABEL)(i) = '0' ) then
          reg_records_D.KEYLABEL.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.VIDEOPTR.ptr.data'range) := registers_sink.VIDEOPTR.ptr.data;
    if ( registers_sink.VIDEOPTR.ptr.update = '1' ) then
      for i in registers_sink.VIDEOPTR.ptr.data'range loop
        if ( K_register_external_mask(E_VIDEOPTR)(i) = '0' ) then
          reg_records_D.VIDEOPTR.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.IFID.interfaceID.data'range) := registers_sink.IFID.interfaceID.data;
    if ( registers_sink.IFID.interfaceID.update = '1' ) then
      for i in registers_sink.IFID.interfaceID.data'range loop
        if ( K_register_external_mask(E_IFID)(i) = '0' ) then
          reg_records_D.IFID.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.VIDEOCTRL.rst.data'range) := registers_sink.VIDEOCTRL.rst.data;
    V_data(registers_sink.VIDEOCTRL.ena.data'range) := registers_sink.VIDEOCTRL.ena.data;
    if ( registers_sink.VIDEOCTRL.rst.update = '1' ) then
      for i in registers_sink.VIDEOCTRL.rst.data'range loop
        if ( K_register_external_mask(E_VIDEOCTRL)(i) = '0' ) then
          reg_records_D.VIDEOCTRL.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    if ( registers_sink.VIDEOCTRL.ena.update = '1' ) then
      for i in registers_sink.VIDEOCTRL.ena.data'range loop
        if ( K_register_external_mask(E_VIDEOCTRL)(i) = '0' ) then
          reg_records_D.VIDEOCTRL.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYREMAIN.lblRemain.data'range) := registers_sink.KEYREMAIN.lblRemain.data;
    if ( registers_sink.KEYREMAIN.lblRemain.update = '1' ) then
      for i in registers_sink.KEYREMAIN.lblRemain.data'range loop
        if ( K_register_external_mask(E_KEYREMAIN)(i) = '0' ) then
          reg_records_D.KEYREMAIN.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYCTRL.acquire.data'range) := registers_sink.KEYCTRL.acquire.data;
    if ( registers_sink.KEYCTRL.acquire.update = '1' ) then
      for i in registers_sink.KEYCTRL.acquire.data'range loop
        if ( K_register_external_mask(E_KEYCTRL)(i) = '0' ) then
          reg_records_D.KEYCTRL.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;

    V_data := (others=>'0');
    V_data(registers_sink.KEYSIZE.lblSize.data'range) := registers_sink.KEYSIZE.lblSize.data;
    if ( registers_sink.KEYSIZE.lblSize.update = '1' ) then
      for i in registers_sink.KEYSIZE.lblSize.data'range loop
        if ( K_register_external_mask(E_KEYSIZE)(i) = '0' ) then
          reg_records_D.KEYSIZE.base.raw(i) <= V_data(i);
        end if;
      end loop;
    end if;


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
    V_data(registers_sink.SCREENOFSX.ofsX.data'range) := registers_sink.SCREENOFSX.ofsX.data;
    if ( registers_sink.SCREENOFSX.ofsX.update = '1' ) then
      for i in registers_sink.SCREENOFSX.ofsX.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_SCREENOFSX)(i) = '1' ) then
          reg_records_D.SCREENOFSX.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_SCREENOFSX)(i) = '1' ) then
          reg_records_D.SCREENOFSX.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.SCREENOFSY.ofsY.data'range) := registers_sink.SCREENOFSY.ofsY.data;
    if ( registers_sink.SCREENOFSY.ofsY.update = '1' ) then
      for i in registers_sink.SCREENOFSY.ofsY.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_SCREENOFSY)(i) = '1' ) then
          reg_records_D.SCREENOFSY.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_SCREENOFSY)(i) = '1' ) then
          reg_records_D.SCREENOFSY.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.KEYSTATUS.lblActive.data'range) := registers_sink.KEYSTATUS.lblActive.data;
    if ( registers_sink.KEYSTATUS.lblActive.update = '1' ) then
      for i in registers_sink.KEYSTATUS.lblActive.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYSTATUS)(i) = '1' ) then
          reg_records_D.KEYSTATUS.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYSTATUS)(i) = '1' ) then
          reg_records_D.KEYSTATUS.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.SCREENY.ySize.data'range) := registers_sink.SCREENY.ySize.data;
    if ( registers_sink.SCREENY.ySize.update = '1' ) then
      for i in registers_sink.SCREENY.ySize.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_SCREENY)(i) = '1' ) then
          reg_records_D.SCREENY.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_SCREENY)(i) = '1' ) then
          reg_records_D.SCREENY.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.SCREENX.xSize.data'range) := registers_sink.SCREENX.xSize.data;
    if ( registers_sink.SCREENX.xSize.update = '1' ) then
      for i in registers_sink.SCREENX.xSize.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_SCREENX)(i) = '1' ) then
          reg_records_D.SCREENX.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_SCREENX)(i) = '1' ) then
          reg_records_D.SCREENX.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.VIDEOY.ySize.data'range) := registers_sink.VIDEOY.ySize.data;
    if ( registers_sink.VIDEOY.ySize.update = '1' ) then
      for i in registers_sink.VIDEOY.ySize.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_VIDEOY)(i) = '1' ) then
          reg_records_D.VIDEOY.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_VIDEOY)(i) = '1' ) then
          reg_records_D.VIDEOY.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.VIDEOX.xSize.data'range) := registers_sink.VIDEOX.xSize.data;
    if ( registers_sink.VIDEOX.xSize.update = '1' ) then
      for i in registers_sink.VIDEOX.xSize.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_VIDEOX)(i) = '1' ) then
          reg_records_D.VIDEOX.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_VIDEOX)(i) = '1' ) then
          reg_records_D.VIDEOX.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.REVID.hour.data'range) := registers_sink.REVID.hour.data;
    V_data(registers_sink.REVID.month.data'range) := registers_sink.REVID.month.data;
    V_data(registers_sink.REVID.class.data'range) := registers_sink.REVID.class.data;
    V_data(registers_sink.REVID.day.data'range) := registers_sink.REVID.day.data;
    V_data(registers_sink.REVID.year.data'range) := registers_sink.REVID.year.data;
    if ( registers_sink.REVID.hour.update = '1' ) then
      for i in registers_sink.REVID.hour.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
    if ( registers_sink.REVID.month.update = '1' ) then
      for i in registers_sink.REVID.month.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
    if ( registers_sink.REVID.class.update = '1' ) then
      for i in registers_sink.REVID.class.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
    if ( registers_sink.REVID.day.update = '1' ) then
      for i in registers_sink.REVID.day.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
    if ( registers_sink.REVID.year.update = '1' ) then
      for i in registers_sink.REVID.year.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_REVID)(i) = '1' ) then
          reg_records_D.REVID.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.WRAPBACK.wrapData.data'range) := registers_sink.WRAPBACK.wrapData.data;
    if ( registers_sink.WRAPBACK.wrapData.update = '1' ) then
      for i in registers_sink.WRAPBACK.wrapData.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_WRAPBACK)(i) = '1' ) then
          reg_records_D.WRAPBACK.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_WRAPBACK)(i) = '1' ) then
          reg_records_D.WRAPBACK.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.SYSID.systemID.data'range) := registers_sink.SYSID.systemID.data;
    if ( registers_sink.SYSID.systemID.update = '1' ) then
      for i in registers_sink.SYSID.systemID.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_SYSID)(i) = '1' ) then
          reg_records_D.SYSID.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_SYSID)(i) = '1' ) then
          reg_records_D.SYSID.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.KEYACTIVE.lastLbl.data'range) := registers_sink.KEYACTIVE.lastLbl.data;
    if ( registers_sink.KEYACTIVE.lastLbl.update = '1' ) then
      for i in registers_sink.KEYACTIVE.lastLbl.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYACTIVE)(i) = '1' ) then
          reg_records_D.KEYACTIVE.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYACTIVE)(i) = '1' ) then
          reg_records_D.KEYACTIVE.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.KEYLABEL.keyLabel.data'range) := registers_sink.KEYLABEL.keyLabel.data;
    if ( registers_sink.KEYLABEL.keyLabel.update = '1' ) then
      for i in registers_sink.KEYLABEL.keyLabel.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYLABEL)(i) = '1' ) then
          reg_records_D.KEYLABEL.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYLABEL)(i) = '1' ) then
          reg_records_D.KEYLABEL.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.VIDEOPTR.ptr.data'range) := registers_sink.VIDEOPTR.ptr.data;
    if ( registers_sink.VIDEOPTR.ptr.update = '1' ) then
      for i in registers_sink.VIDEOPTR.ptr.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_VIDEOPTR)(i) = '1' ) then
          reg_records_D.VIDEOPTR.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_VIDEOPTR)(i) = '1' ) then
          reg_records_D.VIDEOPTR.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.IFID.interfaceID.data'range) := registers_sink.IFID.interfaceID.data;
    if ( registers_sink.IFID.interfaceID.update = '1' ) then
      for i in registers_sink.IFID.interfaceID.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_IFID)(i) = '1' ) then
          reg_records_D.IFID.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_IFID)(i) = '1' ) then
          reg_records_D.IFID.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.VIDEOCTRL.rst.data'range) := registers_sink.VIDEOCTRL.rst.data;
    V_data(registers_sink.VIDEOCTRL.ena.data'range) := registers_sink.VIDEOCTRL.ena.data;
    if ( registers_sink.VIDEOCTRL.rst.update = '1' ) then
      for i in registers_sink.VIDEOCTRL.rst.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_VIDEOCTRL)(i) = '1' ) then
          reg_records_D.VIDEOCTRL.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_VIDEOCTRL)(i) = '1' ) then
          reg_records_D.VIDEOCTRL.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
    if ( registers_sink.VIDEOCTRL.ena.update = '1' ) then
      for i in registers_sink.VIDEOCTRL.ena.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_VIDEOCTRL)(i) = '1' ) then
          reg_records_D.VIDEOCTRL.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_VIDEOCTRL)(i) = '1' ) then
          reg_records_D.VIDEOCTRL.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.KEYREMAIN.lblRemain.data'range) := registers_sink.KEYREMAIN.lblRemain.data;
    if ( registers_sink.KEYREMAIN.lblRemain.update = '1' ) then
      for i in registers_sink.KEYREMAIN.lblRemain.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYREMAIN)(i) = '1' ) then
          reg_records_D.KEYREMAIN.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYREMAIN)(i) = '1' ) then
          reg_records_D.KEYREMAIN.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.KEYCTRL.acquire.data'range) := registers_sink.KEYCTRL.acquire.data;
    if ( registers_sink.KEYCTRL.acquire.update = '1' ) then
      for i in registers_sink.KEYCTRL.acquire.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYCTRL)(i) = '1' ) then
          reg_records_D.KEYCTRL.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYCTRL)(i) = '1' ) then
          reg_records_D.KEYCTRL.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    V_data(registers_sink.KEYSIZE.lblSize.data'range) := registers_sink.KEYSIZE.lblSize.data;
    if ( registers_sink.KEYSIZE.lblSize.update = '1' ) then
      for i in registers_sink.KEYSIZE.lblSize.data'range loop
        if ( V_data(i) = '1' and K_register_onetoset_mask(E_KEYSIZE)(i) = '1' ) then
          reg_records_D.KEYSIZE.base.raw(i) <= '0';
        elsif ( V_data(i) = '1' and K_register_onetoclr_mask(E_KEYSIZE)(i) = '1' ) then
          reg_records_D.KEYSIZE.base.raw(i) <= '1';
        end if;
      end loop;
    end if;
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
    reg_records_I.SCREENOFSX.base.raw(reg_records_I.SCREENOFSX.ofsX.data'range) <= registers_sink.SCREENOFSX.ofsX.data;
  end process C_SCREENOFSX_base;

  C_SCREENOFSY_base : process (
    registers_sink
  )
  begin
    reg_records_I.SCREENOFSY.base.raw <= (others=>'0');
    reg_records_I.SCREENOFSY.base.raw(reg_records_I.SCREENOFSY.ofsY.data'range) <= registers_sink.SCREENOFSY.ofsY.data;
  end process C_SCREENOFSY_base;

  C_KEYSTATUS_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYSTATUS.base.raw <= (others=>'0');
    reg_records_I.KEYSTATUS.base.raw(reg_records_I.KEYSTATUS.lblActive.data'range) <= registers_sink.KEYSTATUS.lblActive.data;
  end process C_KEYSTATUS_base;

  C_SCREENY_base : process (
    registers_sink
  )
  begin
    reg_records_I.SCREENY.base.raw <= (others=>'0');
    reg_records_I.SCREENY.base.raw(reg_records_I.SCREENY.ySize.data'range) <= registers_sink.SCREENY.ySize.data;
  end process C_SCREENY_base;

  C_SCREENX_base : process (
    registers_sink
  )
  begin
    reg_records_I.SCREENX.base.raw <= (others=>'0');
    reg_records_I.SCREENX.base.raw(reg_records_I.SCREENX.xSize.data'range) <= registers_sink.SCREENX.xSize.data;
  end process C_SCREENX_base;

  C_VIDEOY_base : process (
    registers_sink
  )
  begin
    reg_records_I.VIDEOY.base.raw <= (others=>'0');
    reg_records_I.VIDEOY.base.raw(reg_records_I.VIDEOY.ySize.data'range) <= registers_sink.VIDEOY.ySize.data;
  end process C_VIDEOY_base;

  C_VIDEOX_base : process (
    registers_sink
  )
  begin
    reg_records_I.VIDEOX.base.raw <= (others=>'0');
    reg_records_I.VIDEOX.base.raw(reg_records_I.VIDEOX.xSize.data'range) <= registers_sink.VIDEOX.xSize.data;
  end process C_VIDEOX_base;

  C_REVID_base : process (
    registers_sink
  )
  begin
    reg_records_I.REVID.base.raw <= (others=>'0');
    reg_records_I.REVID.base.raw(reg_records_I.REVID.hour.data'range) <= registers_sink.REVID.hour.data;
    reg_records_I.REVID.base.raw(reg_records_I.REVID.month.data'range) <= registers_sink.REVID.month.data;
    reg_records_I.REVID.base.raw(reg_records_I.REVID.class.data'range) <= registers_sink.REVID.class.data;
    reg_records_I.REVID.base.raw(reg_records_I.REVID.day.data'range) <= registers_sink.REVID.day.data;
    reg_records_I.REVID.base.raw(reg_records_I.REVID.year.data'range) <= registers_sink.REVID.year.data;
  end process C_REVID_base;

  C_WRAPBACK_base : process (
    registers_sink
  )
  begin
    reg_records_I.WRAPBACK.base.raw <= (others=>'0');
    reg_records_I.WRAPBACK.base.raw(reg_records_I.WRAPBACK.wrapData.data'range) <= registers_sink.WRAPBACK.wrapData.data;
  end process C_WRAPBACK_base;

  C_SYSID_base : process (
    registers_sink
  )
  begin
    reg_records_I.SYSID.base.raw <= (others=>'0');
    reg_records_I.SYSID.base.raw(reg_records_I.SYSID.systemID.data'range) <= registers_sink.SYSID.systemID.data;
  end process C_SYSID_base;

  C_KEYACTIVE_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYACTIVE.base.raw <= (others=>'0');
    reg_records_I.KEYACTIVE.base.raw(reg_records_I.KEYACTIVE.lastLbl.data'range) <= registers_sink.KEYACTIVE.lastLbl.data;
  end process C_KEYACTIVE_base;

  C_KEYLABEL_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYLABEL.base.raw <= (others=>'0');
    reg_records_I.KEYLABEL.base.raw(reg_records_I.KEYLABEL.keyLabel.data'range) <= registers_sink.KEYLABEL.keyLabel.data;
  end process C_KEYLABEL_base;

  C_VIDEOPTR_base : process (
    registers_sink
  )
  begin
    reg_records_I.VIDEOPTR.base.raw <= (others=>'0');
    reg_records_I.VIDEOPTR.base.raw(reg_records_I.VIDEOPTR.ptr.data'range) <= registers_sink.VIDEOPTR.ptr.data;
  end process C_VIDEOPTR_base;

  C_IFID_base : process (
    registers_sink
  )
  begin
    reg_records_I.IFID.base.raw <= (others=>'0');
    reg_records_I.IFID.base.raw(reg_records_I.IFID.interfaceID.data'range) <= registers_sink.IFID.interfaceID.data;
  end process C_IFID_base;

  C_VIDEOCTRL_base : process (
    registers_sink
  )
  begin
    reg_records_I.VIDEOCTRL.base.raw <= (others=>'0');
    reg_records_I.VIDEOCTRL.base.raw(reg_records_I.VIDEOCTRL.rst.data'range) <= registers_sink.VIDEOCTRL.rst.data;
    reg_records_I.VIDEOCTRL.base.raw(reg_records_I.VIDEOCTRL.ena.data'range) <= registers_sink.VIDEOCTRL.ena.data;
  end process C_VIDEOCTRL_base;

  C_KEYREMAIN_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYREMAIN.base.raw <= (others=>'0');
    reg_records_I.KEYREMAIN.base.raw(reg_records_I.KEYREMAIN.lblRemain.data'range) <= registers_sink.KEYREMAIN.lblRemain.data;
  end process C_KEYREMAIN_base;

  C_KEYCTRL_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYCTRL.base.raw <= (others=>'0');
    reg_records_I.KEYCTRL.base.raw(reg_records_I.KEYCTRL.acquire.data'range) <= registers_sink.KEYCTRL.acquire.data;
  end process C_KEYCTRL_base;

  C_KEYSIZE_base : process (
    registers_sink
  )
  begin
    reg_records_I.KEYSIZE.base.raw <= (others=>'0');
    reg_records_I.KEYSIZE.base.raw(reg_records_I.KEYSIZE.lblSize.data'range) <= registers_sink.KEYSIZE.lblSize.data;
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

