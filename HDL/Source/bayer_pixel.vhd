
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

entity bayer_pixel is
  generic(
    bitDepth   :natural := 1
  );
  port(
     vgaClk    :in   std_logic;
     vgaRst    :in   std_logic;
     Data_In   :in   std_logic_vector(7 downto 0);
     xCoord    :in   std_logic_vector;
     yCoord    :in   std_logic_vector;
     Valid_In  :in   std_logic;
     Data_Out  :out  std_logic_vector(bitDepth-1 downto 0);
     Valid_Out :out  std_logic;
     sync      :in   std_logic
  );
end entity bayer_pixel;

architecture rtl_bayer_pixel of bayer_pixel is

  type T_CmpArray is array(natural range 0 to (2**bitDepth)-1) of natural;

  function genTargets(N:natural) return T_CmpArray is
    variable Step:natural;
    variable Res :T_CmpArray;
  begin
    Step := natural(round(255.0/real((2**N)-1)));
    for i in 0 to (2**N)-2 loop
      Res(i) := (i+1) * Step;
    end loop;
    Res((2**N)-1) := 255;
    return Res;
  end genTargets;

  function genAdjusts(N:natural) return T_CmpArray is
    variable Step:natural;
    variable Res :T_CmpArray;
  begin
    Step := natural(round(255.0/real((2**N)-1)));
    for i in 0 to (2**N)-1 loop
      Res(i) := i * Step;
    end loop;
    return Res;
  end genAdjusts;

  type T_Bayer is array(natural range 0 to 255) of unsigned(7 downto 0);

  constant CompareList :T_CmpArray := genTargets(bitDepth);
  constant AdjustList  :T_CmpArray := genAdjusts(bitDepth);

  constant segStep     :real := 255.0/real((2**bitDepth)-1);

  constant BayerMatrix :T_Bayer := (
      to_unsigned(natural(round(segStep*0.0         )),8),
      to_unsigned(natural(round(segStep*0.7529411765)),8),
      to_unsigned(natural(round(segStep*0.1882352941)),8),
      to_unsigned(natural(round(segStep*0.9411764706)),8),
      to_unsigned(natural(round(segStep*0.0470588235)),8),
      to_unsigned(natural(round(segStep*0.8         )),8),
      to_unsigned(natural(round(segStep*0.2352941176)),8),
      to_unsigned(natural(round(segStep*0.9882352941)),8),
      to_unsigned(natural(round(segStep*0.0117647059)),8),
      to_unsigned(natural(round(segStep*0.7647058824)),8),
      to_unsigned(natural(round(segStep*0.2         )),8),
      to_unsigned(natural(round(segStep*0.9529411765)),8),
      to_unsigned(natural(round(segStep*0.0588235294)),8),
      to_unsigned(natural(round(segStep*0.8117647059)),8),
      to_unsigned(natural(round(segStep*0.2470588235)),8),
      to_unsigned(natural(round(segStep*1.0         )),8),
      to_unsigned(natural(round(segStep*0.5019607843)),8),
      to_unsigned(natural(round(segStep*0.2509803922)),8),
      to_unsigned(natural(round(segStep*0.6901960784)),8),
      to_unsigned(natural(round(segStep*0.4392156863)),8),
      to_unsigned(natural(round(segStep*0.5490196078)),8),
      to_unsigned(natural(round(segStep*0.2980392157)),8),
      to_unsigned(natural(round(segStep*0.737254902 )),8),
      to_unsigned(natural(round(segStep*0.4862745098)),8),
      to_unsigned(natural(round(segStep*0.5137254902)),8),
      to_unsigned(natural(round(segStep*0.262745098 )),8),
      to_unsigned(natural(round(segStep*0.7019607843)),8),
      to_unsigned(natural(round(segStep*0.4509803922)),8),
      to_unsigned(natural(round(segStep*0.5607843137)),8),
      to_unsigned(natural(round(segStep*0.3098039216)),8),
      to_unsigned(natural(round(segStep*0.7490196078)),8),
      to_unsigned(natural(round(segStep*0.4980392157)),8),
      to_unsigned(natural(round(segStep*0.1254901961)),8),
      to_unsigned(natural(round(segStep*0.8784313725)),8),
      to_unsigned(natural(round(segStep*0.062745098 )),8),
      to_unsigned(natural(round(segStep*0.8156862745)),8),
      to_unsigned(natural(round(segStep*0.1725490196)),8),
      to_unsigned(natural(round(segStep*0.9254901961)),8),
      to_unsigned(natural(round(segStep*0.1098039216)),8),
      to_unsigned(natural(round(segStep*0.862745098 )),8),
      to_unsigned(natural(round(segStep*0.137254902 )),8),
      to_unsigned(natural(round(segStep*0.8901960784)),8),
      to_unsigned(natural(round(segStep*0.0745098039)),8),
      to_unsigned(natural(round(segStep*0.8274509804)),8),
      to_unsigned(natural(round(segStep*0.1843137255)),8),
      to_unsigned(natural(round(segStep*0.937254902 )),8),
      to_unsigned(natural(round(segStep*0.1215686275)),8),
      to_unsigned(natural(round(segStep*0.8745098039)),8),
      to_unsigned(natural(round(segStep*0.6274509804)),8),
      to_unsigned(natural(round(segStep*0.3764705882)),8),
      to_unsigned(natural(round(segStep*0.5647058824)),8),
      to_unsigned(natural(round(segStep*0.3137254902)),8),
      to_unsigned(natural(round(segStep*0.6745098039)),8),
      to_unsigned(natural(round(segStep*0.4235294118)),8),
      to_unsigned(natural(round(segStep*0.6117647059)),8),
      to_unsigned(natural(round(segStep*0.3607843137)),8),
      to_unsigned(natural(round(segStep*0.6392156863)),8),
      to_unsigned(natural(round(segStep*0.3882352941)),8),
      to_unsigned(natural(round(segStep*0.5764705882)),8),
      to_unsigned(natural(round(segStep*0.3254901961)),8),
      to_unsigned(natural(round(segStep*0.6862745098)),8),
      to_unsigned(natural(round(segStep*0.4352941176)),8),
      to_unsigned(natural(round(segStep*0.6235294118)),8),
      to_unsigned(natural(round(segStep*0.3725490196)),8),
      to_unsigned(natural(round(segStep*0.031372549 )),8),
      to_unsigned(natural(round(segStep*0.7843137255)),8),
      to_unsigned(natural(round(segStep*0.2196078431)),8),
      to_unsigned(natural(round(segStep*0.9725490196)),8),
      to_unsigned(natural(round(segStep*0.0156862745)),8),
      to_unsigned(natural(round(segStep*0.768627451 )),8),
      to_unsigned(natural(round(segStep*0.2039215686)),8),
      to_unsigned(natural(round(segStep*0.9568627451)),8),
      to_unsigned(natural(round(segStep*0.0431372549)),8),
      to_unsigned(natural(round(segStep*0.7960784314)),8),
      to_unsigned(natural(round(segStep*0.231372549 )),8),
      to_unsigned(natural(round(segStep*0.9843137255)),8),
      to_unsigned(natural(round(segStep*0.0274509804)),8),
      to_unsigned(natural(round(segStep*0.7803921569)),8),
      to_unsigned(natural(round(segStep*0.2156862745)),8),
      to_unsigned(natural(round(segStep*0.968627451 )),8),
      to_unsigned(natural(round(segStep*0.5333333333)),8),
      to_unsigned(natural(round(segStep*0.2823529412)),8),
      to_unsigned(natural(round(segStep*0.7215686275)),8),
      to_unsigned(natural(round(segStep*0.4705882353)),8),
      to_unsigned(natural(round(segStep*0.5176470588)),8),
      to_unsigned(natural(round(segStep*0.2666666667)),8),
      to_unsigned(natural(round(segStep*0.7058823529)),8),
      to_unsigned(natural(round(segStep*0.4549019608)),8),
      to_unsigned(natural(round(segStep*0.5450980392)),8),
      to_unsigned(natural(round(segStep*0.2941176471)),8),
      to_unsigned(natural(round(segStep*0.7333333333)),8),
      to_unsigned(natural(round(segStep*0.4823529412)),8),
      to_unsigned(natural(round(segStep*0.5294117647)),8),
      to_unsigned(natural(round(segStep*0.2784313725)),8),
      to_unsigned(natural(round(segStep*0.7176470588)),8),
      to_unsigned(natural(round(segStep*0.4666666667)),8),
      to_unsigned(natural(round(segStep*0.1568627451)),8),
      to_unsigned(natural(round(segStep*0.9098039216)),8),
      to_unsigned(natural(round(segStep*0.0941176471)),8),
      to_unsigned(natural(round(segStep*0.8470588235)),8),
      to_unsigned(natural(round(segStep*0.1411764706)),8),
      to_unsigned(natural(round(segStep*0.8941176471)),8),
      to_unsigned(natural(round(segStep*0.0784313725)),8),
      to_unsigned(natural(round(segStep*0.831372549 )),8),
      to_unsigned(natural(round(segStep*0.168627451 )),8),
      to_unsigned(natural(round(segStep*0.9215686275)),8),
      to_unsigned(natural(round(segStep*0.1058823529)),8),
      to_unsigned(natural(round(segStep*0.8588235294)),8),
      to_unsigned(natural(round(segStep*0.1529411765)),8),
      to_unsigned(natural(round(segStep*0.9058823529)),8),
      to_unsigned(natural(round(segStep*0.0901960784)),8),
      to_unsigned(natural(round(segStep*0.8431372549)),8),
      to_unsigned(natural(round(segStep*0.6588235294)),8),
      to_unsigned(natural(round(segStep*0.4078431373)),8),
      to_unsigned(natural(round(segStep*0.5960784314)),8),
      to_unsigned(natural(round(segStep*0.3450980392)),8),
      to_unsigned(natural(round(segStep*0.6431372549)),8),
      to_unsigned(natural(round(segStep*0.3921568627)),8),
      to_unsigned(natural(round(segStep*0.5803921569)),8),
      to_unsigned(natural(round(segStep*0.3294117647)),8),
      to_unsigned(natural(round(segStep*0.6705882353)),8),
      to_unsigned(natural(round(segStep*0.4196078431)),8),
      to_unsigned(natural(round(segStep*0.6078431373)),8),
      to_unsigned(natural(round(segStep*0.3568627451)),8),
      to_unsigned(natural(round(segStep*0.6549019608)),8),
      to_unsigned(natural(round(segStep*0.4039215686)),8),
      to_unsigned(natural(round(segStep*0.5921568627)),8),
      to_unsigned(natural(round(segStep*0.3411764706)),8),
      to_unsigned(natural(round(segStep*0.0078431373)),8),
      to_unsigned(natural(round(segStep*0.7607843137)),8),
      to_unsigned(natural(round(segStep*0.1960784314)),8),
      to_unsigned(natural(round(segStep*0.9490196078)),8),
      to_unsigned(natural(round(segStep*0.0549019608)),8),
      to_unsigned(natural(round(segStep*0.8078431373)),8),
      to_unsigned(natural(round(segStep*0.2431372549)),8),
      to_unsigned(natural(round(segStep*0.9960784314)),8),
      to_unsigned(natural(round(segStep*0.0039215686)),8),
      to_unsigned(natural(round(segStep*0.7568627451)),8),
      to_unsigned(natural(round(segStep*0.1921568627)),8),
      to_unsigned(natural(round(segStep*0.9450980392)),8),
      to_unsigned(natural(round(segStep*0.0509803922)),8),
      to_unsigned(natural(round(segStep*0.8039215686)),8),
      to_unsigned(natural(round(segStep*0.2392156863)),8),
      to_unsigned(natural(round(segStep*0.9921568627)),8),
      to_unsigned(natural(round(segStep*0.5098039216)),8),
      to_unsigned(natural(round(segStep*0.2588235294)),8),
      to_unsigned(natural(round(segStep*0.6980392157)),8),
      to_unsigned(natural(round(segStep*0.4470588235)),8),
      to_unsigned(natural(round(segStep*0.5568627451)),8),
      to_unsigned(natural(round(segStep*0.3058823529)),8),
      to_unsigned(natural(round(segStep*0.7450980392)),8),
      to_unsigned(natural(round(segStep*0.4941176471)),8),
      to_unsigned(natural(round(segStep*0.5058823529)),8),
      to_unsigned(natural(round(segStep*0.2549019608)),8),
      to_unsigned(natural(round(segStep*0.6941176471)),8),
      to_unsigned(natural(round(segStep*0.4431372549)),8),
      to_unsigned(natural(round(segStep*0.5529411765)),8),
      to_unsigned(natural(round(segStep*0.3019607843)),8),
      to_unsigned(natural(round(segStep*0.7411764706)),8),
      to_unsigned(natural(round(segStep*0.4901960784)),8),
      to_unsigned(natural(round(segStep*0.1333333333)),8),
      to_unsigned(natural(round(segStep*0.8862745098)),8),
      to_unsigned(natural(round(segStep*0.0705882353)),8),
      to_unsigned(natural(round(segStep*0.8235294118)),8),
      to_unsigned(natural(round(segStep*0.1803921569)),8),
      to_unsigned(natural(round(segStep*0.9333333333)),8),
      to_unsigned(natural(round(segStep*0.1176470588)),8),
      to_unsigned(natural(round(segStep*0.8705882353)),8),
      to_unsigned(natural(round(segStep*0.1294117647)),8),
      to_unsigned(natural(round(segStep*0.8823529412)),8),
      to_unsigned(natural(round(segStep*0.0666666667)),8),
      to_unsigned(natural(round(segStep*0.8196078431)),8),
      to_unsigned(natural(round(segStep*0.1764705882)),8),
      to_unsigned(natural(round(segStep*0.9294117647)),8),
      to_unsigned(natural(round(segStep*0.1137254902)),8),
      to_unsigned(natural(round(segStep*0.8666666667)),8),
      to_unsigned(natural(round(segStep*0.6352941176)),8),
      to_unsigned(natural(round(segStep*0.3843137255)),8),
      to_unsigned(natural(round(segStep*0.5725490196)),8),
      to_unsigned(natural(round(segStep*0.3215686275)),8),
      to_unsigned(natural(round(segStep*0.6823529412)),8),
      to_unsigned(natural(round(segStep*0.431372549 )),8),
      to_unsigned(natural(round(segStep*0.6196078431)),8),
      to_unsigned(natural(round(segStep*0.368627451 )),8),
      to_unsigned(natural(round(segStep*0.631372549 )),8),
      to_unsigned(natural(round(segStep*0.3803921569)),8),
      to_unsigned(natural(round(segStep*0.568627451 )),8),
      to_unsigned(natural(round(segStep*0.3176470588)),8),
      to_unsigned(natural(round(segStep*0.6784313725)),8),
      to_unsigned(natural(round(segStep*0.4274509804)),8),
      to_unsigned(natural(round(segStep*0.6156862745)),8),
      to_unsigned(natural(round(segStep*0.3647058824)),8),
      to_unsigned(natural(round(segStep*0.0392156863)),8),
      to_unsigned(natural(round(segStep*0.7921568627)),8),
      to_unsigned(natural(round(segStep*0.2274509804)),8),
      to_unsigned(natural(round(segStep*0.9803921569)),8),
      to_unsigned(natural(round(segStep*0.0235294118)),8),
      to_unsigned(natural(round(segStep*0.7764705882)),8),
      to_unsigned(natural(round(segStep*0.2117647059)),8),
      to_unsigned(natural(round(segStep*0.9647058824)),8),
      to_unsigned(natural(round(segStep*0.0352941176)),8),
      to_unsigned(natural(round(segStep*0.7882352941)),8),
      to_unsigned(natural(round(segStep*0.2235294118)),8),
      to_unsigned(natural(round(segStep*0.9764705882)),8),
      to_unsigned(natural(round(segStep*0.0196078431)),8),
      to_unsigned(natural(round(segStep*0.7725490196)),8),
      to_unsigned(natural(round(segStep*0.2078431373)),8),
      to_unsigned(natural(round(segStep*0.9607843137)),8),
      to_unsigned(natural(round(segStep*0.5411764706)),8),
      to_unsigned(natural(round(segStep*0.2901960784)),8),
      to_unsigned(natural(round(segStep*0.7294117647)),8),
      to_unsigned(natural(round(segStep*0.4784313725)),8),
      to_unsigned(natural(round(segStep*0.5254901961)),8),
      to_unsigned(natural(round(segStep*0.2745098039)),8),
      to_unsigned(natural(round(segStep*0.7137254902)),8),
      to_unsigned(natural(round(segStep*0.462745098 )),8),
      to_unsigned(natural(round(segStep*0.537254902 )),8),
      to_unsigned(natural(round(segStep*0.2862745098)),8),
      to_unsigned(natural(round(segStep*0.7254901961)),8),
      to_unsigned(natural(round(segStep*0.4745098039)),8),
      to_unsigned(natural(round(segStep*0.5215686275)),8),
      to_unsigned(natural(round(segStep*0.2705882353)),8),
      to_unsigned(natural(round(segStep*0.7098039216)),8),
      to_unsigned(natural(round(segStep*0.4588235294)),8),
      to_unsigned(natural(round(segStep*0.1647058824)),8),
      to_unsigned(natural(round(segStep*0.9176470588)),8),
      to_unsigned(natural(round(segStep*0.1019607843)),8),
      to_unsigned(natural(round(segStep*0.8549019608)),8),
      to_unsigned(natural(round(segStep*0.1490196078)),8),
      to_unsigned(natural(round(segStep*0.9019607843)),8),
      to_unsigned(natural(round(segStep*0.0862745098)),8),
      to_unsigned(natural(round(segStep*0.8392156863)),8),
      to_unsigned(natural(round(segStep*0.1607843137)),8),
      to_unsigned(natural(round(segStep*0.9137254902)),8),
      to_unsigned(natural(round(segStep*0.0980392157)),8),
      to_unsigned(natural(round(segStep*0.8509803922)),8),
      to_unsigned(natural(round(segStep*0.1450980392)),8),
      to_unsigned(natural(round(segStep*0.8980392157)),8),
      to_unsigned(natural(round(segStep*0.0823529412)),8),
      to_unsigned(natural(round(segStep*0.8352941176)),8),
      to_unsigned(natural(round(segStep*0.6666666667)),8),
      to_unsigned(natural(round(segStep*0.4156862745)),8),
      to_unsigned(natural(round(segStep*0.6039215686)),8),
      to_unsigned(natural(round(segStep*0.3529411765)),8),
      to_unsigned(natural(round(segStep*0.6509803922)),8),
      to_unsigned(natural(round(segStep*0.4         )),8),
      to_unsigned(natural(round(segStep*0.5882352941)),8),
      to_unsigned(natural(round(segStep*0.337254902 )),8),
      to_unsigned(natural(round(segStep*0.662745098 )),8),
      to_unsigned(natural(round(segStep*0.4117647059)),8),
      to_unsigned(natural(round(segStep*0.6         )),8),
      to_unsigned(natural(round(segStep*0.3490196078)),8),
      to_unsigned(natural(round(segStep*0.6470588235)),8),
      to_unsigned(natural(round(segStep*0.3960784314)),8),
      to_unsigned(natural(round(segStep*0.5843137255)),8),
      to_unsigned(natural(round(segStep*0.3333333333)),8)
    );

  signal xC          :std_logic_vector(3 downto 0);
  signal yC          :std_logic_vector(3 downto 0);
  signal Idx         :std_logic_vector(7 downto 0);
  signal Thres       :unsigned(7 downto 0);

  signal Out_D       :unsigned(bitDepth-1 downto 0);
  signal Out_Q       :unsigned(bitDepth-1 downto 0);
  signal Val_D       :std_logic;
  signal Val_Q       :std_logic;

  signal OutBase     :unsigned(bitDepth-1 downto 0);
  signal OutAdd      :unsigned(bitDepth-1 downto 0);
  signal Res         :unsigned(7 downto 0);

  signal DatIn       :unsigned(7 downto 0);


begin
  -- -----
  DatIn     <= unsigned(Data_In);

  xC        <= xCoord(xC'range);
  yC        <= yCoord(yC'range);
  Idx       <= yC & xC;
  Thres     <= BayerMatrix(to_integer(unsigned(Idx)));

  --THRESHOLD HAS TO ?BE AJDUSTED BY STEP!!!!!
  --NEED TO STATICALLY COMPUTE BAYER MATRIX!!!!

  OutAdd    <= to_unsigned(1,OutAdd'length) when (Res>Thres) else
               (others=>'0');

  Out_D     <= (others=>'1') when (DatIn=255) else
               (others=>'0') when (DatIn=0)   else
               OutBase + OutAdd;
  Val_D     <= Valid_In;

  Data_Out  <= std_logic_vector(Out_Q);
  Valid_Out <= Val_Q;

  C_Base:process(DatIn)
  begin
    -- -----
    -- Loop order implies priority
    -- -----
    -- Find working region
    OutBase <= (others=>'1');
    Res     <= (others=>'0');
    for i in (2**bitDepth)-1 downto 0 loop
      if (DatIn < CompareList(i)) then
        OutBase <= to_unsigned(i, OutBase'length);
      end if;
      if (DatIn < CompareList(i)) then
        Res <= DatIn - AdjustList(i);
      end if;
    end loop;
    -- -----
  end process;

  S_Clk:process(vgaClk, vgaRst)
  begin
    -- -----
    if (vgaRst='1') then
      Out_Q <= (others=>'0');
      Val_Q <= '0';
    elsif (vgaClk='1' and vgaClk'event) then
      Out_Q <= Out_D;
      Val_Q <= Val_D;
    end if;
    -- -----
  end process;

  -- -----
end rtl_bayer_pixel;