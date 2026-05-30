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
        i_sign      : in  std_logic;
        i_l         : in  std_logic_vector(G_N + 3 downto 0);
        i_overflow  : in  std_logic;
        i_underflow : in  std_logic;
        o_takum     : out std_logic_vector(G_N - 1 downto 0)
    );
end entity takum_logarithmic_encoder;

architecture RTL of takum_logarithmic_encoder is
    signal s_c_raw    : std_logic_vector(8 downto 0); -- c with sign 
    signal s_c_wo_d   : std_logic_vector(7 downto 0);
    signal s_mant_raw : std_logic_vector(G_N + 3 - 9 downto 0); -- mantissa cutut from input
    signal s_dir      : std_logic;

    signal s_cond_inv_c : std_logic_vector(7 downto 0);
    signal s_precursor  : std_logic_vector(7 downto 0); -- precursor has  first 1 at value 2^r

    signal s_regime_tmp         : std_logic_vector(2 downto 0);
    signal s_regime             : std_logic_vector(2 downto 0);
    signal s_regime_cond_inv    : std_logic_vector(2 downto 0);
    signal s_precursor_cond_inv : std_logic_vector(6 downto 0);

    signal s_vld : std_logic;

    -- signal s_c_mant_pre_shift : std_logic_vector(s_mant_raw'length + 8-1 downto 0); -- append characteristics to mantissa for shift
    signal s_c_mant_pre_shift : std_logic_vector(G_N + 9 - 1 downto 0); -- append characteristics to mantissa for shift
    signal s_c_mant_shftd     : std_logic_vector(G_N + 9 - 1 downto 0);
    signal s_c_m              : std_logic_vector(G_N + 2 - 1 downto 0);

    signal s_pre_round : std_logic_vector(G_N + 7 - 1 downto 0);
    signal s_takum_nr  : std_logic_vector(G_N - 1 downto 0);

    signal s_lsb_bit    : std_logic;
    signal s_guard_bit  : std_logic;
    signal s_sticky_bit : std_logic;

    signal s_round_up_overflow    : std_logic; --marks if round up would overflow the takum
    signal s_round_down_underflow : std_logic; --marks if round down would underflow the takum
    signal s_round_up             : std_logic;

    signal s_takum_rounded : std_logic_vector(G_N - 1 downto 0);
begin

    s_c_raw    <= i_l(G_N + 3 downto G_N - 5);
    s_mant_raw <= i_l(G_N - 5 - 1 downto 0);
    s_dir      <= not (s_c_raw(8));

    -- throw away sign, only used for d calculation
    s_c_wo_d <= s_c_raw(7 downto 0);

    s_cond_inv_c <= cond_invert(s_c_wo_d, not (s_dir));

    s_precursor <= std_logic_vector(unsigned(s_cond_inv_c) + 1); -- ountil here equal

    LOD : entity work.LOD
        generic map(
            G_DATA_WIDTH => 8
        )
        port map(
            i_x   => s_precursor,
            o_K   => s_regime_tmp,
            o_vld => s_vld
        );

    -- s_regime          <= s_regime_tmp when s_vld = '1' else "111"; -- not sure, sollt eghoist bits als 0 annehmen
    s_regime          <= not (s_regime_tmp);
    s_regime_cond_inv <= cond_invert(s_regime, not (s_dir));

    s_precursor_cond_inv <= cond_invert(s_precursor(6 downto 0), not (s_dir));
    s_c_mant_pre_shift   <= s_precursor_cond_inv & s_mant_raw & (6 downto 0 => '0');

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
    s_c_m <= s_c_mant_shftd(s_c_mant_shftd'high - 7 downto 0); -- take lower bits

    s_pre_round <= i_sign & s_dir & s_regime_cond_inv & s_c_m; -- between E3 and E4 in paper

    calculate_ov_un_flow : process(i_l) is
        constant C_UNDERFLOW_THRESHOLD : characteristic := get_underflow_value(G_N);
        constant C_OVERFLOW_THRESHOLD  : characteristic := get_overflow_value(G_N);

        variable v_char_value : integer;
    begin
        v_char_value := to_integer(signed(i_l(G_N + 3 downto G_N - 5)));

        if G_N <= 11 then
            if (v_char_value <= C_UNDERFLOW_THRESHOLD) then
                s_round_down_underflow <= '1';
            else
                s_round_down_underflow <= '0';
            end if;

            if (v_char_value >= C_OVERFLOW_THRESHOLD) then
                s_round_up_overflow <= '1';
            else
                s_round_up_overflow <= '0';
            end if;
        else
            if (i_l(G_N - 6 downto 0) = (i_l(G_N - 6 downto 0)'range => '0')) and (v_char_value = C_UNDERFLOW_THRESHOLD) then
                s_round_down_underflow <= '1';
            else
                s_round_down_underflow <= '0';
            end if;

            if (i_l(G_N - 6 downto 0) = (i_l(G_N - 6 downto 0)'range => '1')) and (v_char_value = C_OVERFLOW_THRESHOLD) then
                s_round_up_overflow <= '1';
            else
                s_round_up_overflow <= '0';
            end if;
        end if;
    end process calculate_ov_un_flow;

    -- rounding logic
    s_takum_nr   <= s_pre_round(G_N + 7 - 1 downto 7);
    s_lsb_bit    <= s_takum_nr(s_takum_nr'low);
    s_guard_bit  <= s_pre_round(6);
    s_sticky_bit <= or_reduce(s_pre_round(5 downto 0));

    -- s_round_up <= (s_guard_bit and (s_lsb_bit or s_sticky_bit));
    s_round_up <= (s_round_down_underflow) or (not (s_round_up_overflow) and s_guard_bit and (s_lsb_bit or s_sticky_bit));

    s_takum_rounded <= std_logic_vector(unsigned(s_takum_nr) + unsigned(std_logic_vector'(0 => s_round_up)));
    
    saturation : process(s_takum_rounded, i_overflow, i_underflow, i_sign) is
        variable v_max_takum : std_logic_vector(G_N - 1 downto 0);
        variable v_min_takum : std_logic_vector(G_N - 1 downto 0);
    begin
        v_max_takum := i_sign & (G_N - 2 downto 0 => '1');
        v_min_takum := i_sign & (G_N - 2 downto 1 => '0') & '1';

        if i_underflow = '1' or (or_reduce(s_takum_rounded(G_N - 2 downto 0)) = '0') then
            o_takum <= v_min_takum;
        elsif i_overflow = '1' then
            o_takum <= v_max_takum;
        else
            o_takum <= s_takum_rounded;
        end if;
    end process saturation;
end architecture RTL;
