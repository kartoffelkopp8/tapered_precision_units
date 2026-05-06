library ieee;
library work;

use ieee.STD_LOGIC_1164.ALL;
use ieee.NUMERIC_STD.ALL;
use ieee.math_real.all;

-- for or_reduce
--use ieee.std_logic_misc.all;
use work.utility_pkg.all;

entity posit_mul is
    generic(
        G_N          : integer := 32;
        G_ES         : integer := 1
    );
    port(
        i_clk       : in  std_logic;
        i_enable    : in  std_logic;
        i_operand_0 : in  std_logic_vector(G_N - 1 downto 0);
        i_operand_1 : in  std_logic_vector(G_N - 1 downto 0);
        o_result    : out std_logic_vector(G_N - 1 downto 0)
    );
end posit_mul;

architecture Behavioral of posit_mul is

    constant C_Bs : integer := integer(log2(real(G_N)));

    constant C_MAX_MANTISSA_WIDTH : integer := G_N - G_ES - 3; -- 2 bit regime + 1 bit sign

    -- Signs for both inputs
    signal s_sign_0 : std_logic;
    signal s_sign_1 : std_logic;

    signal is_inf_0         : std_logic;
    signal is_inf_1         : std_logic;
    signal is_zero_0        : std_logic;
    signal is_zero_1        : std_logic;
    signal s_result_is_inf  : std_logic;
    signal s_result_is_zero : std_logic;

    -- Normalized operand values depending on sign -> used of decode
    signal s_normalized_operand_0 : std_logic_vector(G_N - 2 downto 0);
    signal s_normalized_operand_1 : std_logic_vector(G_N - 2 downto 0);

    signal s_result_sign : std_logic;

    -- Data Extraction
    signal s_rc_0, s_rc_1             : std_logic;
    signal s_regime_0, s_regime_1     : std_logic_vector(C_Bs - 1 downto 0);
    signal s_exponent_0, s_exponent_1 : std_logic_vector(G_ES - 1 downto 0);
    signal s_mantissa_0, s_mantissa_1 : std_logic_vector(C_MAX_MANTISSA_WIDTH - 1 downto 0);

    -- Pipeline Register 0
    signal r0_rc_0, r0_rc_1             : std_logic;
    signal r0_regime_0, r0_regime_1     : std_logic_vector(C_Bs - 1 downto 0);
    signal r0_exponent_0, r0_exponent_1 : std_logic_vector(G_ES - 1 downto 0);
    signal r0_mantissa_0, r0_mantissa_1 : std_logic_vector(C_MAX_MANTISSA_WIDTH - 1 downto 0);

    signal r0_result_sign : std_logic;
    signal r0_is_inf      : std_logic;
    signal r0_is_zero     : std_logic;

    signal s_hidden_mantissa_0, s_hidden_mantissa_1 : std_logic_vector(C_MAX_MANTISSA_WIDTH downto 0);

    constant C_PRODUCT_WIDHT : integer := 2 * (C_MAX_MANTISSA_WIDTH + 1);
    signal   s_product       : std_logic_vector(C_PRODUCT_WIDHT - 1 downto 0);

    -- C_MAX_MANTISSA_WIDTH + Hidden bit + Guard bit + one extra for adjusting/nromalization
    constant C_TRUNCATED_MANTISSA_WIDTH : integer := C_MAX_MANTISSA_WIDTH + 4;
    signal   s_upper_product            : std_logic_vector(C_TRUNCATED_MANTISSA_WIDTH - 1 downto 0);
    signal   s_truncated_sticky         : std_logic;

    -- regime value with increased length
    signal s_abs_regime_0 : std_logic_vector(C_Bs downto 0);
    signal s_abs_regime_1 : std_logic_vector(C_Bs downto 0);

    -- actual regime value (depending on regime check)
    signal s_signed_regime_0 : std_logic_vector(C_Bs downto 0);
    signal s_signed_regime_1 : std_logic_vector(C_Bs downto 0);

    signal s_efficient_exponent_0 : std_logic_vector(C_Bs + G_ES downto 0);
    signal s_efficient_exponent_1 : std_logic_vector(C_Bs + G_ES downto 0);

    -- Pipline Register
    -- signal r1_efficient_exponent_0 : std_logic_vector(C_Bs + G_ES downto 0);
    -- signal r1_efficient_exponent_1 : std_logic_vector(C_Bs + G_ES downto 0);

    -- Could be shortend to (C_MAX_MANTISSA_WIDTH downto 0) because of possible shift left by 1
    --signal r1_product : std_logic_vector((2*C_MAX_MANTISSA_WIDTH)-1 downto 0);
    signal r1_product          : std_logic_vector(C_TRUNCATED_MANTISSA_WIDTH - 1 downto 0);
    signal r1_truncated_sticky : std_logic;

    signal r1_result_sign : std_logic;
    signal r1_is_inf      : std_logic;
    signal r1_is_zero     : std_logic;

    -- Normalize Stage
    signal s_msb_mantissa        : std_logic_vector(C_Bs + G_ES + 1 downto 0);
    -- C_MAX_MANTISSA_WIDTH + Guard bit
    signal s_normalized_mantissa : std_logic_vector(C_TRUNCATED_MANTISSA_WIDTH - 3 downto 0);

    signal s_efficient_exponent : std_logic_vector(C_Bs + G_ES + 1 downto 0);

    -- Pipeline Register

    signal r2_normalized_mantissa : std_logic_vector(C_TRUNCATED_MANTISSA_WIDTH - 3 downto 0);
    signal r1_efficient_exponent  : std_logic_vector(C_Bs + G_ES + 1 downto 0);

    signal s_normalize_sticky : std_logic;

    signal r2_result_sign : std_logic;
    signal r2_is_inf      : std_logic;
    signal r2_is_zero     : std_logic;

    -- Encode Posit
    -- could be one bit smaller? no more sign
    -- constant C_EFFICIENT_EXPONENT_WIDHT    : integer := C_Bs + G_ES + 1;
    signal   s_adjusted_efficient_exponent : std_logic_vector(C_Bs + G_ES + 1 downto 0);

    signal s_abs_efficient_exponent : std_logic_vector(C_Bs + G_ES downto 0); -- abs reduces on bit msb

    signal s_exponent : std_logic_vector(G_ES - 1 downto 0);

    signal s_combined_exp_mantissa : std_logic_vector(G_ES + C_TRUNCATED_MANTISSA_WIDTH - 3 downto 0);

    signal s_regime_length : std_logic_vector(C_Bs downto 0);

    -- bitvector which gets shifted in from left to create regime 
    signal s_regime_bits : std_logic_vector(G_N - 2 downto 0);

    -- Intermediate Size: N-1 Regime bits, Regime End bit, ES bits and Mantissa with guard bit
    constant C_INTERMEDIATE_WIDTH : integer := (G_N - 1) + 1 + G_ES + C_MAX_MANTISSA_WIDTH + 2;
    signal   s_intermediate       : std_logic_vector(C_INTERMEDIATE_WIDTH - 1 downto 0);

    --signal s_drs : std_logic_vector(integer(ceil(log2(real((G_N-1)+1+G_ES+C_TRUNCATED_MANTISSA_WIDTH-1))))-1 downto 0);
    signal s_drs : std_logic_vector(integer(ceil(log2(real(C_INTERMEDIATE_WIDTH)))) - 1 downto 0);

    signal s_sticky_shifted : std_logic_vector(C_INTERMEDIATE_WIDTH downto 0);

    signal s_lsb_bit       : std_logic;
    signal s_guard_bit     : std_logic;
    signal s_sticky_bit    : std_logic;
    signal s_round_to_zero : std_logic;
    signal s_round         : std_logic;

    signal s_rounded : std_logic_vector(G_N - 2 downto 0);
    signal s_negated : std_logic_vector(G_N - 2 downto 0);

    constant C_MAX_K        : integer := G_N - 2;
    constant C_MAX_EXP      : integer := C_MAX_K * (2 ** G_ES);
    signal   s_is_overflow  : std_logic;
    signal   s_is_underflow : std_logic;

begin

    -- Extract Signs
    s_sign_0 <= i_operand_0(G_N - 1);
    s_sign_1 <= i_operand_1(G_N - 1);

    -- Check if inputs are Zero or Infinity
    process(i_operand_0, i_operand_1, s_sign_0, s_sign_1)
        variable v_all_zeros_0 : std_logic;
        variable v_all_zeros_1 : std_logic;
    begin
        v_all_zeros_0 := or_reduce(i_operand_0(G_N - 2 downto 0));
        is_inf_0      <= s_sign_0 and (not v_all_zeros_0);
        is_zero_0     <= not (s_sign_0 or v_all_zeros_0);

        v_all_zeros_1 := or_reduce(i_operand_1(G_N - 2 downto 0));
        is_inf_1      <= s_sign_1 and (not v_all_zeros_1);
        is_zero_1     <= not (s_sign_1 or v_all_zeros_1);
    end process;

    -- Calcualte special results
    s_result_is_inf  <= is_inf_0 or is_inf_1;
    s_result_is_zero <= is_zero_0 or is_zero_1;

    -- Invert input if sign indicates negative value
    s_normalized_operand_0 <= std_logic_vector(unsigned(not i_operand_0(G_N - 2 downto 0)) + 1) when s_sign_0 = '1' else i_operand_0(G_N - 2 downto 0);
    s_normalized_operand_1 <= std_logic_vector(unsigned(not i_operand_1(G_N - 2 downto 0)) + 1) when s_sign_1 = '1' else i_operand_1(G_N - 2 downto 0);

    -- Data Extraction Operand 0
    inst_decoder_0 : entity work.posit_decode
        generic map(
            N  => G_N - 1,
            Bs => C_Bs,
            es => G_ES
        )
        port map(
            in_val => s_normalized_operand_0,
            rc     => s_rc_0,
            regime => s_regime_0,
            exp    => s_exponent_0,
            mant   => s_mantissa_0
        );

    -- Data Extraction Operand 1
    inst_decoder_1 : entity work.posit_decode
        generic map(
            N  => G_N - 1,
            Bs => C_Bs,
            es => G_ES
        )
        port map(
            in_val => s_normalized_operand_1,
            rc     => s_rc_1,
            regime => s_regime_1,
            exp    => s_exponent_1,
            mant   => s_mantissa_1
        );

    -- Result Sign Computation
    s_result_sign <= s_sign_0 xor s_sign_1;

    -- Pipeline Stage 0 (After Decode)
    pipe_0_proc : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_enable = '1' then
                r0_rc_0       <= s_rc_0;
                r0_rc_1       <= s_rc_1;
                r0_regime_0   <= s_regime_0;
                r0_regime_1   <= s_regime_1;
                r0_exponent_0 <= s_exponent_0;
                r0_exponent_1 <= s_exponent_1;

                r0_mantissa_0 <= s_mantissa_0;
                r0_mantissa_1 <= s_mantissa_1;

                r0_result_sign <= s_result_sign;
                r0_is_inf      <= s_result_is_inf;
                r0_is_zero     <= s_result_is_zero;
            end if;
        end if;
    end process;

    -- Add the implicit hidden Bit in front of the Mantissa
    s_hidden_mantissa_0 <= '1' & r0_mantissa_0;
    s_hidden_mantissa_1 <= '1' & r0_mantissa_1;

    -- Calcualte Result by Multiply Mantissas
    s_product <= std_logic_vector(unsigned(s_hidden_mantissa_0) * unsigned(s_hidden_mantissa_1));

    -- Reduce Mantisssa product to minimum for furhter processsing
    s_upper_product    <= s_product(C_PRODUCT_WIDHT - 1 downto C_PRODUCT_WIDHT - C_TRUNCATED_MANTISSA_WIDTH);
    -- Calculate cut Bits from Mantissa to be used as sticky
    s_truncated_sticky <= or_reduce(s_product(C_PRODUCT_WIDHT - C_TRUNCATED_MANTISSA_WIDTH - 1 downto 0));

    -- Calculate efficient exponent of Operands
    -- resize unsigned because next operation could overflow
    s_abs_regime_0 <= "0" & r0_regime_0;  --std_logic_vector(resize(unsigned(r0_regime_0), C_Bs+1));
    s_abs_regime_1 <= "0" & r0_regime_1;  --std_logic_vector(resize(unsigned(r0_regime_1), C_Bs+1));

    s_signed_regime_0 <= (s_abs_regime_0) when r0_rc_0 = '1' else std_logic_vector(unsigned(not s_abs_regime_0) + 1);
    s_signed_regime_1 <= (s_abs_regime_1) when r0_rc_1 = '1' else std_logic_vector(unsigned(not s_abs_regime_1) + 1);

    -- Combine regime and exponent to form effective exponent
    s_efficient_exponent_0 <= s_signed_regime_0 & r0_exponent_0;
    s_efficient_exponent_1 <= s_signed_regime_1 & r0_exponent_1;

    s_efficient_exponent <= std_logic_vector(signed((0 => s_efficient_exponent_0(C_Bs + G_ES)) & s_efficient_exponent_0) + signed((0 => s_efficient_exponent_1(C_Bs + G_ES)) & s_efficient_exponent_1)); -- + signed(s_msb_mantissa));

    pipe_1_proc : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_enable = '1' then
                r1_product <= s_upper_product;

                r1_truncated_sticky <= s_truncated_sticky;

                r1_efficient_exponent <= s_efficient_exponent;

                r1_result_sign <= r0_result_sign;
                r1_is_inf      <= r0_is_inf;
                r1_is_zero     <= r0_is_zero;
            end if;
        end if;
    end process;

    -- Calculate effective exponents by Addition

    -- Pipeline Stage 2 (After Efficient Exponent Calculation of Result)
    r2_result_sign <= r1_result_sign;
    r2_is_inf      <= r1_is_inf;
    r2_is_zero     <= r1_is_zero;

    -- Check for mantissa overflow (extended to mantissa size)
    s_msb_mantissa <= (0 => r1_product(C_TRUNCATED_MANTISSA_WIDTH - 1), others => '0');

    -- Compensate for overflow by shifting by one
    s_normalized_mantissa <= r1_product(C_TRUNCATED_MANTISSA_WIDTH - 3 downto 0) when s_msb_mantissa(0) = '0' else r1_product(C_TRUNCATED_MANTISSA_WIDTH - 2 downto 1);

    r2_normalized_mantissa <= s_normalized_mantissa;

    -- Additional sticky bit resulting from mantissa normalization
    s_normalize_sticky <= r1_truncated_sticky when s_msb_mantissa(0) = '0' else r1_product(0) or r1_truncated_sticky;

    s_adjusted_efficient_exponent <= std_logic_vector(signed(r1_efficient_exponent) + signed(s_msb_mantissa));

    encoder : entity work.posit_encode
        generic map(
            G_N  => G_N,
            G_ES => G_ES
        )
        port map(
            i_sign                => r2_result_sign,
            i_is_inf              => r2_is_inf,
            i_is_zero             => r2_is_zero,
            i_sticky              => s_normalize_sticky,
            i_normalized_mantissa => r2_normalized_mantissa,
            i_efficient_exponent  => s_adjusted_efficient_exponent,
            o_result              => o_result
        );
end Behavioral;
