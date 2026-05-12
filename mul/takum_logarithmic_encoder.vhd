library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utility_pkg.all;

entity takum_logarithmic_encoder is
    generic(
        G_N : integer := 32
    );
    port(
        i_sign  : in  std_logic;
        i_l     :     std_logic_vector(G_N + 3 downto 0);
        o_takum : out std_logic_vector(G_N - 1 downto 0)
    );
end entity takum_logarithmic_encoder;

architecture RTL of takum_logarithmic_encoder is
    signal s_c_raw    : std_logic_vector(8 downto 0); -- c with sign 
    signal s_c_wo_d   : std_logic_vector(7 downto 0);
    signal s_mant_raw : std_logic_vector(G_N + 3 - 9 downto 0); -- mantissa cutut from input
    signal s_dir      : std_logic;

    signal s_cond_inv_c : std_logic_vector(7 downto 0);
    signal s_precursor  : std_logic_vector(7 downto 0); -- precursor has  first 1 at value 2^r

    signal s_regime_tmp : std_logic_vector(2 downto 0);
    signal s_regime     : std_logic_vector(2 downto 0);

    signal s_precursor_cond_inv : std_logic_vector(7 downto 0); 

    signal s_characteristic : std_logic_vector(6 downto 0);

    signal s_vld : std_logic;

    signal s_c_mant_pre_shift : std_logic_vector(s_mant_raw'length + 8-1 downto 0); -- append characteristics to mantissa for shift
    signal s_c_mant_shftd : std_logic_vector(s_mant_raw'length + 8-1 downto 0);
    signal s_c_m : std_logic_vector(s_mant_raw'length downto 0);

    signal s_pre_round : std_logic_vector(G_N downto 0);
begin

    s_c_raw    <= i_l(G_N + 3 - 1 downto G_N + 3 - 9);
    s_mant_raw <= i_l(G_N + 3 - 9 downto 0);
    s_dir      <= i_l(i_l'high);

    -- throw away sign, only used for d calculation
    s_c_wo_d <= s_c_raw(7 downto 0);

    s_cond_inv_c <= cond_invert(s_c_wo_d, not(s_dir));

    s_precursor <= std_logic_vector(unsigned(s_cond_inv_c) + 1); 

    LOD : entity work.LOD
        generic map(
            G_DATA_WIDTH => 8
        )
        port map(
            i_x   => s_precursor,
            o_K   => s_regime_tmp,
            o_vld => s_vld
        );

    s_regime <= s_regime_tmp when s_vld = '1' else "111";

    s_precursor_cond_inv <= cond_invert(s_precursor, not(s_dir));
    s_c_mant_pre_shift <= s_precursor_cond_inv & s_mant_raw;

    right_shift : entity work.takum_shift_right
        generic map(
            G_N         => s_c_mant_pre_shift'length,
            G_MAX_SHIFT => 3
        )
        port map(
            i_vec          => s_c_mant_pre_shift,
            i_fill_bit     => '0',
            i_shift_amount => s_regime,
            o_vec          => s_c_mant_shftd
        );
    s_c_m <= s_c_mant_shftd(s_c_mant_shftd'high-7 downto 0); -- take lower bits

    s_pre_round <= i_sign & s_dir & s_regime & s_c_m;

end architecture RTL;
