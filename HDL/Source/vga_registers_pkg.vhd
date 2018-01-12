library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package vga_registers_pkg is

  constant K_REG_WIDTH : positive := 32;

  type E_reg_enum is (
    E_SCREENOFSX,
    E_SCREENOFSY,
    E_KEYSTATUS,
    E_SCREENY,
    E_SCREENX,
    E_VIDEOY,
    E_VIDEOX,
    E_REVID,
    E_WRAPBACK,
    E_SYSID,
    E_KEYACTIVE,
    E_KEYLABEL,
    E_VIDEOPTR,
    E_IFID,
    E_VIDEOCTRL,
    E_KEYREMAIN,
    E_KEYCTRL,
    E_KEYSIZE
  );

  constant K_REG_ADDR_LOBIT : natural := 2;
  constant K_REG_ADDR_HIBIT : natural := 7;

  type T_enum_array is array(E_reg_enum) of std_logic_vector(K_REG_WIDTH-1 downto 0);

  constant K_register_addresses : T_enum_array := (
    E_SCREENOFSX => x"00000048",
    E_SCREENOFSY => x"0000004C",
    E_KEYSTATUS => x"00000020",
    E_SCREENY => x"00000044",
    E_SCREENX => x"00000040",
    E_VIDEOY => x"0000003C",
    E_VIDEOX => x"00000038",
    E_REVID => x"00000008",
    E_WRAPBACK => x"0000000C",
    E_SYSID => x"00000000",
    E_KEYACTIVE => x"00000024",
    E_KEYLABEL => x"00000010",
    E_VIDEOPTR => x"00000030",
    E_IFID => x"00000004",
    E_VIDEOCTRL => x"00000034",
    E_KEYREMAIN => x"0000001C",
    E_KEYCTRL => x"00000014",
    E_KEYSIZE => x"00000018"
  );

  constant K_register_write_mask : T_enum_array := (
    E_SCREENOFSX => x"0000FFFF",
    E_SCREENOFSY => x"0000FFFF",
    E_KEYSTATUS => x"00000000",
    E_SCREENY => x"00000000",
    E_SCREENX => x"00000000",
    E_VIDEOY => x"00000000",
    E_VIDEOX => x"00000000",
    E_REVID => x"00000000",
    E_WRAPBACK => x"FFFFFFFF",
    E_SYSID => x"00000000",
    E_KEYACTIVE => x"00000000",
    E_KEYLABEL => x"FFFFFFFF",
    E_VIDEOPTR => x"FFFFFFFF",
    E_IFID => x"00000000",
    E_VIDEOCTRL => x"80000001",
    E_KEYREMAIN => x"00000000",
    E_KEYCTRL => x"00000001",
    E_KEYSIZE => x"00000000"
  );

  constant K_register_onetoset_mask : T_enum_array := (
    E_SCREENOFSX => x"00000000",
    E_SCREENOFSY => x"00000000",
    E_KEYSTATUS => x"00000000",
    E_SCREENY => x"00000000",
    E_SCREENX => x"00000000",
    E_VIDEOY => x"00000000",
    E_VIDEOX => x"00000000",
    E_REVID => x"00000000",
    E_WRAPBACK => x"00000000",
    E_SYSID => x"00000000",
    E_KEYACTIVE => x"00000000",
    E_KEYLABEL => x"00000000",
    E_VIDEOPTR => x"00000000",
    E_IFID => x"00000000",
    E_VIDEOCTRL => x"00000000",
    E_KEYREMAIN => x"00000000",
    E_KEYCTRL => x"00000000",
    E_KEYSIZE => x"00000000"
  );

  constant K_register_onetoclr_mask : T_enum_array := (
    E_SCREENOFSX => x"00000000",
    E_SCREENOFSY => x"00000000",
    E_KEYSTATUS => x"00000000",
    E_SCREENY => x"00000000",
    E_SCREENX => x"00000000",
    E_VIDEOY => x"00000000",
    E_VIDEOX => x"00000000",
    E_REVID => x"00000000",
    E_WRAPBACK => x"00000000",
    E_SYSID => x"00000000",
    E_KEYACTIVE => x"00000000",
    E_KEYLABEL => x"00000000",
    E_VIDEOPTR => x"00000000",
    E_IFID => x"00000000",
    E_VIDEOCTRL => x"00000000",
    E_KEYREMAIN => x"00000000",
    E_KEYCTRL => x"00000000",
    E_KEYSIZE => x"00000000"
  );

  constant K_register_autoclr_mask : T_enum_array := (
    E_SCREENOFSX => x"00000000",
    E_SCREENOFSY => x"00000000",
    E_KEYSTATUS => x"00000000",
    E_SCREENY => x"00000000",
    E_SCREENX => x"00000000",
    E_VIDEOY => x"00000000",
    E_VIDEOX => x"00000000",
    E_REVID => x"00000000",
    E_WRAPBACK => x"00000000",
    E_SYSID => x"00000000",
    E_KEYACTIVE => x"00000000",
    E_KEYLABEL => x"00000000",
    E_VIDEOPTR => x"00000000",
    E_IFID => x"00000000",
    E_VIDEOCTRL => x"80000000",
    E_KEYREMAIN => x"00000000",
    E_KEYCTRL => x"00000001",
    E_KEYSIZE => x"00000000"
  );

  constant K_register_autoset_mask : T_enum_array := (
    E_SCREENOFSX => x"00000000",
    E_SCREENOFSY => x"00000000",
    E_KEYSTATUS => x"00000000",
    E_SCREENY => x"00000000",
    E_SCREENX => x"00000000",
    E_VIDEOY => x"00000000",
    E_VIDEOX => x"00000000",
    E_REVID => x"00000000",
    E_WRAPBACK => x"00000000",
    E_SYSID => x"00000000",
    E_KEYACTIVE => x"00000000",
    E_KEYLABEL => x"00000000",
    E_VIDEOPTR => x"00000000",
    E_IFID => x"00000000",
    E_VIDEOCTRL => x"00000000",
    E_KEYREMAIN => x"00000000",
    E_KEYCTRL => x"00000000",
    E_KEYSIZE => x"00000000"
  );

  constant K_register_defaults : T_enum_array := (
    E_SCREENOFSX => x"00000000",
    E_SCREENOFSY => x"00000000",
    E_KEYSTATUS => x"00000000",
    E_SCREENY => x"00000000",
    E_SCREENX => x"00000000",
    E_VIDEOY => x"00000000",
    E_VIDEOX => x"00000000",
    E_REVID => x"00000000",
    E_WRAPBACK => x"00000000",
    E_SYSID => x"56474149",
    E_KEYACTIVE => x"00000000",
    E_KEYLABEL => x"00000000",
    E_VIDEOPTR => x"00000000",
    E_IFID => x"00000000",
    E_VIDEOCTRL => x"00000000",
    E_KEYREMAIN => x"00000000",
    E_KEYCTRL => x"00000000",
    E_KEYSIZE => x"00000000"
  );

  constant K_register_external_mask : T_enum_array := (
    E_SCREENOFSX => x"00000000",
    E_SCREENOFSY => x"00000000",
    E_KEYSTATUS => x"00000001",
    E_SCREENY => x"0000FFFF",
    E_SCREENX => x"0000FFFF",
    E_VIDEOY => x"0000FFFF",
    E_VIDEOX => x"0000FFFF",
    E_REVID => x"FFFFFFFF",
    E_WRAPBACK => x"FFFFFFFF",
    E_SYSID => x"00000000",
    E_KEYACTIVE => x"FFFFFFFF",
    E_KEYLABEL => x"00000000",
    E_VIDEOPTR => x"00000000",
    E_IFID => x"FFFFFFFF",
    E_VIDEOCTRL => x"00000000",
    E_KEYREMAIN => x"FFFFFFFF",
    E_KEYCTRL => x"00000000",
    E_KEYSIZE => x"FFFFFFFF"
  );

  type T_reg_base is
    record
      address : std_logic_vector(K_REG_WIDTH-1 downto 0);
      default : std_logic_vector(K_REG_WIDTH-1 downto 0);
      raw : std_logic_vector(K_REG_WIDTH-1 downto 0);
      update : std_logic;
      accessed : std_logic;
    end record;

  type T_reg_screenofsx is
    record
      base : T_reg_base;
      ofsX : std_logic_vector(15 downto 0);
    end record;

  type T_reg_screenofsy is
    record
      base : T_reg_base;
      ofsY : std_logic_vector(15 downto 0);
    end record;

  type T_reg_keystatus is
    record
      base : T_reg_base;
      lblActive : std_logic_vector(0 downto 0);
    end record;

  type T_reg_screeny is
    record
      base : T_reg_base;
      ySize : std_logic_vector(15 downto 0);
    end record;

  type T_reg_screenx is
    record
      base : T_reg_base;
      xSize : std_logic_vector(15 downto 0);
    end record;

  type T_reg_videoy is
    record
      base : T_reg_base;
      ySize : std_logic_vector(15 downto 0);
    end record;

  type T_reg_videox is
    record
      base : T_reg_base;
      xSize : std_logic_vector(15 downto 0);
    end record;

  type T_reg_revid is
    record
      base : T_reg_base;
      hour : std_logic_vector(4 downto 0);
      month : std_logic_vector(13 downto 10);
      class : std_logic_vector(31 downto 25);
      day : std_logic_vector(9 downto 5);
      year : std_logic_vector(24 downto 14);
    end record;

  type T_reg_wrapback is
    record
      base : T_reg_base;
      wrapData : std_logic_vector(31 downto 0);
    end record;

  type T_reg_sysid is
    record
      base : T_reg_base;
      systemID : std_logic_vector(31 downto 0);
    end record;

  type T_reg_keyactive is
    record
      base : T_reg_base;
      lastLbl : std_logic_vector(31 downto 0);
    end record;

  type T_reg_keylabel is
    record
      base : T_reg_base;
      keyLabel : std_logic_vector(31 downto 0);
    end record;

  type T_reg_videoptr is
    record
      base : T_reg_base;
      ptr : std_logic_vector(31 downto 0);
    end record;

  type T_reg_ifid is
    record
      base : T_reg_base;
      interfaceID : std_logic_vector(31 downto 0);
    end record;

  type T_reg_videoctrl is
    record
      base : T_reg_base;
      rst : std_logic_vector(31 downto 31);
      ena : std_logic_vector(0 downto 0);
    end record;

  type T_reg_keyremain is
    record
      base : T_reg_base;
      lblRemain : std_logic_vector(31 downto 0);
    end record;

  type T_reg_keyctrl is
    record
      base : T_reg_base;
      acquire : std_logic_vector(0 downto 0);
    end record;

  type T_reg_keysize is
    record
      base : T_reg_base;
      lblSize : std_logic_vector(31 downto 0);
    end record;

  type T_registers is
    record
      SCREENOFSX : T_reg_screenofsx;
      SCREENOFSY : T_reg_screenofsy;
      KEYSTATUS : T_reg_keystatus;
      SCREENY : T_reg_screeny;
      SCREENX : T_reg_screenx;
      VIDEOY : T_reg_videoy;
      VIDEOX : T_reg_videox;
      REVID : T_reg_revid;
      WRAPBACK : T_reg_wrapback;
      SYSID : T_reg_sysid;
      KEYACTIVE : T_reg_keyactive;
      KEYLABEL : T_reg_keylabel;
      VIDEOPTR : T_reg_videoptr;
      IFID : T_reg_ifid;
      VIDEOCTRL : T_reg_videoctrl;
      KEYREMAIN : T_reg_keyremain;
      KEYCTRL : T_reg_keyctrl;
      KEYSIZE : T_reg_keysize;
    end record;

end package vga_registers_pkg;

package body vga_registers_pkg is
end package body vga_registers_pkg;
