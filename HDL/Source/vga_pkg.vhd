library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

package vga_pkg is
  -- -----

  -- Common Dot Clock 25.175 MHz
  -- Easy to alter design to dynamically change between these.
  -- -------------------------------------------------------------------
  -- video_VGA_640x350_70Hz
  -- video_VGA_640x400_70Hz
  -- video_VGA_640x480_60Hz

  -- Common Dot Clock 31.5 MHz
  -- Easy to alter design to dynamically change between these.
  -- -------------------------------------------------------------------
  -- video_VESA_640x350_85Hz
  -- video_VESA_640x400_85Hz
  -- video_VESA_640x480_75Hz

  -- Not so easy to dynamically change between the rest...
  -- Spartan6 and later FPGA devices can dynamically program PLL.
  -- Not an option for Spartan3.  So video mode will be fixed at 
  -- compile time for  now.

  -- NOTE: Many more modes exist.  

  -- Expected Clock Indexes (assuming frequency field not used)
  -- -------------------------------------------------------------------
  -- 
  -- 0  - 21.5  MHz
  -- 1  - 31.5  MHz
  -- 2  - 34.96 MHz
  -- 3  - 35.5  MHz
  -- 4  - 40.0  MHz
  -- 5  - 50.0  MHz
  -- 6  - 65.0  MHz
  -- 7  - 75.0  MHz
  -- 8  - 108.0 MHz
  -- 9  - 162.0 MHz

  type T_VGA_Record is
    record
      -- -----
      clkIndex       :natural;
      refreshHz      :real;
      vertRefreshKHz :real;
      dotClockHz     :real;
      horzVisible    :natural;
      horzFrontPorch :natural;
      horzSyncPulse  :natural;
      horzBackPorch  :natural;
      vertVisible    :natural;
      vertFrontPorch :natural;
      vertSyncPulse  :natural;
      vertBackPorch  :natural;
      horzPolarity   :std_logic;
      vertPolarity   :std_logic;
      -- -----
    end record;

  -- -------------------------------------------------------------------
  constant video_VGA_640x350_70Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 0,
      refreshHz      => 70.0,
      vertRefreshKHz => 31.46875,
      dotClockHz     => 1.0e6*25.175,
      horzVisible    => 640,
      horzFrontPorch => 16,
      horzSyncPulse  => 96,
      horzBackPorch  => 48,
      vertVisible    => 350,
      vertFrontPorch => 37,
      vertSyncPulse  => 2,
      vertBackPorch  => 60,
      horzPolarity   => '1',
      vertPolarity   => '0'
      -- -----
    );

  constant video_VGA_640x400_70Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 0,
      refreshHz      => 70.0,
      vertRefreshKHz => 31.46875,
      dotClockHz     => 1.0e6*25.175,
      horzVisible    => 640,
      horzFrontPorch => 16,
      horzSyncPulse  => 96,
      horzBackPorch  => 48,
      vertVisible    => 400,
      vertFrontPorch => 12,
      vertSyncPulse  => 2,
      vertBackPorch  => 35,
      horzPolarity   => '0',
      vertPolarity   => '1'
      -- -----
    );

  constant video_VGA_640x480_60Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 0,
      refreshHz      => 60.0,
      vertRefreshKHz => 31.46875,
      dotClockHz     => 1.0e6*25.175,
      horzVisible    => 640,
      horzFrontPorch => 16,
      horzSyncPulse  => 96,
      horzBackPorch  => 48,
      vertVisible    => 480,
      vertFrontPorch => 10,
      vertSyncPulse  => 2,
      vertBackPorch  => 33,
      horzPolarity   => '0',
      vertPolarity   => '0'
      -- -----
    );

  constant video_SVGA_800x600_60Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 4,
      refreshHz      => 60.0,
      vertRefreshKHz => 37.878787878788,
      dotClockHz     => 1.0e6*40.0,
      horzVisible    => 800,
      horzFrontPorch => 40,
      horzSyncPulse  => 128,
      horzBackPorch  => 88,
      vertVisible    => 600,
      vertFrontPorch => 1,
      vertSyncPulse  => 4,
      vertBackPorch  => 23,
      horzPolarity   => '1',
      vertPolarity   => '1'
      -- -----
    );

  constant video_XGA_1024x768_60Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 6,
      refreshHz      => 60.0,
      vertRefreshKHz => 48.363095238095,
      dotClockHz     => 1.0e6*65.0,
      horzVisible    => 1024,
      horzFrontPorch => 24,
      horzSyncPulse  => 136,
      horzBackPorch  => 160,
      vertVisible    => 768,
      vertFrontPorch => 3,
      vertSyncPulse  => 6,
      vertBackPorch  => 29,
      horzPolarity   => '0',
      vertPolarity   => '0'
      -- -----
    );

  -- -------------------------------------------------------------------
  constant video_VESA_640x350_85Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 1,
      refreshHz      => 85.0,
      vertRefreshKHz => 37.860576923077,
      dotClockHz     => 1.0e6*31.5,
      horzVisible    => 640,
      horzFrontPorch => 32,
      horzSyncPulse  => 64,
      horzBackPorch  => 96,
      vertVisible    => 350,
      vertFrontPorch => 32,
      vertSyncPulse  => 3,
      vertBackPorch  => 60,
      horzPolarity   => '1',
      vertPolarity   => '0'
      -- -----
    );

  constant video_VESA_640x400_85Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 1,
      refreshHz      => 85.0,
      vertRefreshKHz => 37.860576923077,
      dotClockHz     => 1.0e6*31.5,
      horzVisible    => 640,
      horzFrontPorch => 32,
      horzSyncPulse  => 64,
      horzBackPorch  => 96,
      vertVisible    => 400,
      vertFrontPorch => 1,
      vertSyncPulse  => 3,
      vertBackPorch  => 41,
      horzPolarity   => '0',
      vertPolarity   => '1'
      -- -----
    );

  constant video_VESA_640x480_75Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 1,
      refreshHz      => 75.0,
      vertRefreshKHz => 37.54,
      dotClockHz     => 1.0e6*31.5,
      horzVisible    => 640,
      horzFrontPorch => 16,
      horzSyncPulse  => 64,
      horzBackPorch  => 120,
      vertVisible    => 480,
      vertFrontPorch => 1,
      vertSyncPulse  => 3,
      vertBackPorch  => 16,
      horzPolarity   => '0',
      vertPolarity   => '0'
      -- -----
    );

  constant video_VESA_720x400_85Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 3,
      refreshHz      => 85.0,
      vertRefreshKHz => 37.92735042735,
      dotClockHz     => 1.0e6*35.5,
      horzVisible    => 720,
      horzFrontPorch => 36,
      horzSyncPulse  => 72,
      horzBackPorch  => 108,
      vertVisible    => 400,
      vertFrontPorch => 1,
      vertSyncPulse  => 3,
      vertBackPorch  => 42,
      horzPolarity   => '0',
      vertPolarity   => '1'
      -- -----
    );

  constant video_VESA_768x576_60Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 2,
      refreshHz      => 60.0,
      vertRefreshKHz => 35.819672131148,
      dotClockHz     => 1.0e6*34.96,
      horzVisible    => 768,
      horzFrontPorch => 24,
      horzSyncPulse  => 80,
      horzBackPorch  => 104,
      vertVisible    => 576,
      vertFrontPorch => 1,
      vertSyncPulse  => 3,
      vertBackPorch  => 17,
      horzPolarity   => '0',
      vertPolarity   => '1'
      -- -----
    );

  constant video_VESA_800x600_72Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 5,
      refreshHz      => 72.0,
      vertRefreshKHz => 48.076923076923,
      dotClockHz     => 1.0e6*50.0,
      horzVisible    => 800,
      horzFrontPorch => 56,
      horzSyncPulse  => 120,
      horzBackPorch  => 64,
      vertVisible    => 600,
      vertFrontPorch => 37,
      vertSyncPulse  => 6,
      vertBackPorch  => 23,
      horzPolarity   => '1',
      vertPolarity   => '1'
      -- -----
    );

  constant video_VESA_1024x768_70Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 7,
      refreshHz      => 70.0,
      vertRefreshKHz => 56.475903614458,
      dotClockHz     => 1.0e6*75.0,
      horzVisible    => 1024,
      horzFrontPorch => 24,
      horzSyncPulse  => 136,
      horzBackPorch  => 144,
      vertVisible    => 768,
      vertFrontPorch => 3,
      vertSyncPulse  => 6,
      vertBackPorch  => 29,
      horzPolarity   => '0',
      vertPolarity   => '0'
      -- -----
    );

  constant video_VESA_1152x864_75Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 8,
      refreshHz      => 75.0,
      vertRefreshKHz => 67.5,
      dotClockHz     => 1.0e6*108.0,
      horzVisible    => 1152,
      horzFrontPorch => 64,
      horzSyncPulse  => 128,
      horzBackPorch  => 256,
      vertVisible    => 864,
      vertFrontPorch => 1,
      vertSyncPulse  => 3,
      vertBackPorch  => 32,
      horzPolarity   => '1',
      vertPolarity   => '1'
      -- -----
    );

  constant video_VESA_1280x1024_60Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 8,
      refreshHz      => 60.0,
      vertRefreshKHz => 63.981042654028,
      dotClockHz     => 1.0e6*108.0,
      horzVisible    => 1280,
      horzFrontPorch => 48,
      horzSyncPulse  => 112,
      horzBackPorch  => 248,
      vertVisible    => 1024,
      vertFrontPorch => 1,
      vertSyncPulse  => 3,
      vertBackPorch  => 38,
      horzPolarity   => '1',
      vertPolarity   => '1'
      -- -----
    );

  constant video_VESA_1600x1200_60Hz :T_VGA_Record := (
      -- -----
      clkIndex       => 9,
      refreshHz      => 60.0,
      vertRefreshKHz => 75.0,
      dotClockHz     => 1.0e6*162.0,
      horzVisible    => 1600,
      horzFrontPorch => 64,
      horzSyncPulse  => 192,
      horzBackPorch  => 304,
      vertVisible    => 1200,
      vertFrontPorch => 1,
      vertSyncPulse  => 3,
      vertBackPorch  => 46,
      horzPolarity   => '1',
      vertPolarity   => '1'
      -- -----
    );


  -- -------------------------------------------------------------------
  constant video_Default :T_VGA_Record :=video_VGA_640x480_60Hz;

  function ceilLogTwo(N:natural) return natural;

  -- -----
end vga_pkg;

package body vga_pkg is
  -- -----

  function ceilLogTwo(N:natural) return natural is
  begin
    -- -----
    return natural(ceil(log2(real(N))));
    -- -----
  end ceilLogTwo;

  -- -----
end vga_pkg;
