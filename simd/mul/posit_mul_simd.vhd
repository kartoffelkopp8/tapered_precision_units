library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utility_pkg.all;

entity posit_mul_simd is
    generic(
        G_N           : integer := 32;  -- total bitwidth of input and output vectors 
        G_MAX_ES      : integer := 4;   -- maximal number of exponent bits per posit
        G_SIMD_FACTOR : integer := 4    -- maximal number of parts, power of 2
    );
    port(
        i_clk           : in  std_logic;
        i_simd          : in  std_logic_vector(clog2(G_SIMD_FACTOR) - 1 downto 0); -- selector for simd state 0=1 lane, 1=2 lanes, 2=4 lanes, etc.
        i_dyn_exp       : in  std_logic_vector(clog2(G_MAX_ES) downto 0); -- selector for dynamic exp size selectioon at runtime
        i_operand_vec_0 : in  std_logic_vector(G_N - 1 downto 0);
        i_operand_vec_1 : in  std_logic_vector(G_N - 1 downto 0);
        o_result_vec    : out std_logic_vector(G_N - 1 downto 0)
    );
end entity posit_mul_simd;

architecture Behavioral of posit_mul_simd is

    constant C_IND_LEN : integer := G_N / G_SIMD_FACTOR;

    ----------------------------------------
    --              Preprocess            --
    ----------------------------------------
    signal s_normalized_operand_0, s_normalized_operand_1 : std_logic_vector(G_N - 1 downto 0); -- at least -1, if higher simd, also less bits !!!
    signal s_regime_0, s_regime_1                         : std_logic_vector((clog2(G_N - 1) * G_SIMD_FACTOR) - 1 downto 0);
    signal s_rc_0, s_rc_1                                 : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
    signal s_exp_0, s_exp_1                               : std_logic_vector((G_MAX_ES * G_SIMD_FACTOR) - 1 downto 0);
    signal s_mantissa_0, s_mantissa_1                     : std_logic_vector(((G_N - G_MAX_ES - 3) * G_SIMD_FACTOR) - 1 downto 0);

    signal s_mask : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);

    signal s_res_sign                   : std_logic(G_SIMD_FACTOR - 1 downto 0);
    signal s_is_nar                     : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
    ----------------------------------------
    --              Stage 0               --
    ----------------------------------------
    signal s_sign_0, s_sign_1           : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
    signal r0_regime_0, r0_regime_1     : std_logic_vector((clog2(G_N - 1) * G_SIMD_FACTOR) - 1 downto 0);
    signal r0_rc_0, r0_rc_1             : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
    signal r0_exp_0, r0_exp_1           : std_logic_vector((G_MAX_ES * G_SIMD_FACTOR) - 1 downto 0);
    signal r0_mantissa_0, r0_mantissa_1 : std_logic_vector(((G_N - G_MAX_ES - 3) * G_SIMD_FACTOR) - 1 downto 0);
begin
    
    -- encodingh generation of the mask used for future ops (stolen from the adder module)
    process(i_simd)
        variable v_lanes_count       : integer;
        variable v_segments_per_lane : integer;
        variable v_flipped_idx       : integer;
    begin
        v_lanes_count       := 2 ** to_integer(unsigned(i_simd));
        v_segments_per_lane := G_SIMD_FACTOR / v_lanes_count;

        for i in 0 to G_SIMD_FACTOR - 1 loop
            -- Wir berechnen den Abstand vom "linken" Rand (G_SIMD_FACTOR-1)
            v_flipped_idx := (G_SIMD_FACTOR - 1) - i;

            -- Ein Lane-Start ist nun dort, wo vom linken Rand aus gesehen 
            -- eine neue Lane-Länge beginnt.
            if (v_flipped_idx mod v_segments_per_lane = 0) then
                s_mask(i) <= '1';
            else
                s_mask(i) <= '0';
            end if;
        end loop;
    end process;

    gen_sign_0 : for i in 0 to G_SIMD_FACTOR - 1 generate
        s_sign_0(i) <= i_operand_vec_0((i + 1) * C_IND_LEN - 1);
    end generate;

    gen_sign_1 : for i in 0 to G_SIMD_FACTOR - 1 generate
        s_sign_1(i) <= i_operand_vec_1((i + 1) * C_IND_LEN - 1);
    end generate;

    -- TODO signs calculate signs here

    -- check for NaR TODO zero check not there for now
    special_check : entity work.posit_special_ckeck_simd
        generic map(
            G_N           => G_N,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_simd_mask => s_mask,
            i_sign_0    => s_sign_0,
            i_sign_1    => s_sign_1,
            i_vec_0     => i_operand_vec_0,
            i_vec_1     => i_operand_vec_1,
            o_is_nar    => s_is_nar
        );

    twos_comp_0 : entity work.twos_complement_simd
        generic map(
            G_N           => G_N,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_simd_mask => s_mask,
            i_sign      => s_sign_0,
            i_vec       => i_operand_vec_0,
            o_vec       => s_normalized_operand_0
        );

    twos_comp_1 : entity work.twos_complement_simd
        generic map(
            G_N           => G_N,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_simd_mask => s_mask,
            i_sign      => s_sign_1,
            i_vec       => i_operand_vec_1,
            o_vec       => s_normalized_operand_1
        );

    -- decode posits 
    inst_decoder_0 : entity work.posit_decode_simd
        generic map(
            G_N           => G_N - 1,
            G_MAX_ES      => G_MAX_ES,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_val       => s_normalized_operand_0,
            i_simd_mode => i_simd,
            i_simd_mask => s_mask,
            i_dyn_exp   => i_dyn_exp,
            o_rc        => s_rc_0,
            o_regime    => s_regime_0,
            o_exp       => s_exp_0,
            o_mant      => s_mantissa_0
        );

    inst_decoder_1 : entity work.posit_decode_simd
        generic map(
            G_N           => G_N - 1,
            G_MAX_ES      => G_MAX_ES,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_val       => s_normalized_operand_1,
            i_simd_mode => i_simd,
            i_simd_mask => s_mask,
            i_dyn_exp   => i_dyn_exp,
            o_rc        => s_rc_1,
            o_regime    => s_regime_1,
            o_exp       => s_exp_1,
            o_mant      => s_mantissa_1
        );

    -- TODO calculate exponent stupff here maybe??

    -- maybe a pipeline here

    pipe0 : process(i_clk) is
    begin
        if (rising_edge(i_clk)) then
        end if;
    end process pipe0;

    -- do calculation

    -- recode posit format
end architecture Behavioral;
