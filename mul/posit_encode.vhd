library ieee;
library work;

use ieee.STD_LOGIC_1164.ALL;
use ieee.NUMERIC_STD.ALL;
use ieee.math_real.all;

-- for or_reduce
--use ieee.std_logic_misc.all;
use work.utility_pkg.all;

entity posit_encode is
    generic(
        G_N  : integer := 32;
        G_ES : integer := 1
    );
    port(
        --i_clk       : in  std_logic;
        --i_enable    : in  std_logic;

        i_sign                : in  std_logic;
        i_is_inf              : in  std_logic;
        i_is_zero             : in  std_logic;
        i_sticky              : in  std_logic;
        -- MAX_MANTISSA (G_N-Sign-2xRegime-ES)+ Guard + Sticky
        i_normalized_mantissa : in  std_logic_vector(G_N - G_ES - 3 + 2 - 1 downto 0);
        i_efficient_exponent  : in  std_logic_vector(integer(log2(real(G_N))) + G_ES + 1 downto 0);
        o_result              : out std_logic_vector(G_N - 1 downto 0)
    );
end posit_encode;

architecture Behavioral of posit_encode is

    constant C_Bs                       : integer := clog2(G_N);
    constant C_MAX_MANTISSA_WIDTH       : integer := G_N - G_ES - 3; -- 2 bit regime + 1 bit sign
    -- C_MAX_MANTISSA_WIDTH + Hidden bit + Guard bit + one extra for adjusting/nromalization
    constant C_TRUNCATED_MANTISSA_WIDTH : integer := C_MAX_MANTISSA_WIDTH + 4;

    --constant C_INTERNAL_MANTISSA_WIDTH : integer := C_MAX_MANTISSA_WIDTH + 3; -- mantissa + hidden, guard, rounding (and sticky) bit

    -- Encode Posit
    -- could be one bit smaller? no more sign
    -- constant C_EFFICIENT_EXPONENT_WIDHT    : integer := C_Bs + G_ES + 1;
    signal s_adjusted_efficient_exponent : std_logic_vector(C_Bs + G_ES + 1 downto 0);

    signal s_abs_efficient_exponent : std_logic_vector(C_Bs + G_ES downto 0); -- abs reduces on bit msb

    signal s_exponent : std_logic_vector(G_ES - 1 downto 0);

    signal s_combined_exp_mantissa : std_logic_vector(G_ES + C_TRUNCATED_MANTISSA_WIDTH - 3 downto 0);

    signal s_regime_bit       : std_logic;
    signal s_intermediate_tmp : std_logic_vector(G_ES + C_TRUNCATED_MANTISSA_WIDTH - 3 + 1 downto 0);
    signal s_intermediate     : std_logic_vector(s_intermediate_tmp'length - 2 downto 0);

    --signal s_drs : std_logic_vector(integer(ceil(log2(real((G_N-1)+1+G_ES+C_TRUNCATED_MANTISSA_WIDTH-1))))-1 downto 0);
    signal s_drs : std_logic_vector(integer(ceil(log2(real(s_intermediate'length)))) - 1 downto 0);

    signal s_shift_tmp       : std_logic;
    signal s_sticky_shifted  : std_logic_vector(s_intermediate'length downto 0);
    signal s_sticky_shifted2 : std_logic_vector(s_intermediate'length + 1 downto 0);

    signal s_lsb_bit    : std_logic;
    signal s_guard_bit  : std_logic;
    signal s_sticky_bit : std_logic;
    signal s_round      : std_logic;

    signal s_rounded : std_logic_vector(G_N - 2 downto 0);
    signal s_negated : std_logic_vector(G_N - 2 downto 0);

    constant C_MAX_K        : integer := G_N - 2;
    constant C_MAX_EXP      : integer := C_MAX_K * (2 ** G_ES);
    signal   s_is_overflow  : std_logic;
    signal   s_is_underflow : std_logic;

begin
    s_adjusted_efficient_exponent <= i_efficient_exponent;

    s_is_overflow  <= '1' when signed(s_adjusted_efficient_exponent) >= C_MAX_EXP else '0';
    s_is_underflow <= '1' when signed(s_adjusted_efficient_exponent) <= -C_MAX_EXP else '0';

    -- Result Exponent and Regime Computation

    -- Calculate absolute value of efficient exponent to get regime length
    s_abs_efficient_exponent <= std_logic_vector(unsigned(not s_adjusted_efficient_exponent(C_Bs + G_ES downto 0)) + 1) when s_adjusted_efficient_exponent(C_Bs + G_ES + 1) = '1' else s_adjusted_efficient_exponent(C_Bs + G_ES downto 0);

    -- Extract exponent bits
    s_exponent <= s_adjusted_efficient_exponent(G_ES - 1 downto 0) when s_adjusted_efficient_exponent(C_Bs + G_ES) = '1' and or_reduce(s_abs_efficient_exponent(G_ES - 1 downto 0)) = '1' else s_abs_efficient_exponent(G_ES - 1 downto 0);

    -- Concatinate Exponent and Mantissa
    s_combined_exp_mantissa <= s_exponent & i_normalized_mantissa;
    -- Exponent and Mantissa Packing

    -- Create regime bit
    s_regime_bit <= not s_adjusted_efficient_exponent(C_Bs + G_ES + 1);

    -- Combine Components
    s_intermediate_tmp <= (0 => s_adjusted_efficient_exponent(C_Bs + G_ES + 1)) & s_combined_exp_mantissa;
    -- Shift amount
    --s_drs <= "0" & s_regime_length;
    process(s_adjusted_efficient_exponent)
    begin
        if signed(s_adjusted_efficient_exponent(C_Bs + G_ES + 1 downto G_ES)) >= 0 then
            s_drs <= std_logic_vector(resize(unsigned(s_adjusted_efficient_exponent(C_Bs + G_ES + 1 downto G_ES)), s_drs'length));
        else
            s_drs <= std_logic_vector(resize(unsigned((not s_adjusted_efficient_exponent(C_Bs + G_ES + 1 downto G_ES))), s_drs'length));
        end if;
    end process;

    s_shift_tmp    <= s_intermediate_tmp(0);
    s_intermediate <= s_intermediate_tmp(s_intermediate_tmp'high downto 1);

    inst_sticky_shift_decide : entity work.sticky_shift_det
        generic map(
            C_DATA_WIDTH => s_intermediate_tmp'length - 1
        )
        port map(
            i_number      => s_intermediate,
            i_shift_count => s_drs,
            i_shift_bit   => s_regime_bit,
            o_result      => s_sticky_shifted
        );

    -- Calculate Bits for rounding
    s_sticky_bit <= s_sticky_shifted(0) or i_sticky or s_shift_tmp;
    s_guard_bit  <= s_sticky_shifted(1);
    s_lsb_bit    <= s_sticky_shifted(2);

    -- Check if result would be rounded to zero. (works because the result zero is a special values that is handled specifically)
    -- s_round_to_zero <= or_reduce(s_sticky_shifted(G_N downto 2));

    -- Check if result needs to be rounded
    s_round <= (s_guard_bit and (s_lsb_bit or s_sticky_bit));

    s_sticky_shifted2 <= s_regime_bit & s_sticky_shifted;

    process(s_sticky_shifted2, s_round, s_is_overflow, s_is_underflow)
        -- variable v_round           : std_logic_vector(C_INTERMEDIATE_WIDTH downto 0);
        variable v_round           : std_logic_vector(G_N - 2 downto 0);
        -- variable v_appended_sticky : std_logic_vector(C_INTERMEDIATE_WIDTH downto 0);
        variable v_appended_sticky : std_logic_vector(G_N - 2 downto 0);
        constant C_MAG_MAX         : std_logic_vector(G_N - 2 downto 0) := (others => '1');
        constant C_MAG_MIN         : std_logic_vector(G_N - 2 downto 0) := (0 => '1', others => '0');

    begin
        v_appended_sticky := s_sticky_shifted2(G_N downto 2);
        if s_is_overflow = '1' then
            -- Saturate to MaxPos magnitude: 0111...1
            s_rounded <= C_MAG_MAX;
        elsif s_is_underflow = '1' then
            -- Saturate to MinPos magnitude: 0000...1
            s_rounded <= C_MAG_MIN;
        else
            if s_round = '1' then
                v_round := std_logic_vector(unsigned(v_appended_sticky) + 1);
            else
                v_round := v_appended_sticky;
            end if;
            s_rounded <= v_round;
        end if;
        
    end process;

    -- Apply Sign
    s_negated <= std_logic_vector(unsigned(not s_rounded) + 1) when i_sign = '1' else s_rounded;

    -- Apply Special Result Values
    o_result <= i_is_inf & (G_N - 2 downto 0 => '0') when (i_is_inf = '1' or i_is_zero = '1') else i_sign & s_negated;

end Behavioral;
