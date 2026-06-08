library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utility_pkg.all;

entity takum_add is
    generic(
        G_N : integer := 32
    );
    port(
        i_clk    : in  std_logic;
        i_rst    : in  std_logic;
        i_op_a   : in  std_logic_vector(G_N - 1 downto 0);
        i_op_b   : in  std_logic_vector(G_N - 1 downto 0);
        o_result : out std_logic_vector(G_N - 1 downto 0)
    );
end entity takum_add;

architecture RTL of takum_add is
    signal s_is_nar  : std_logic;
    signal s_is_zero : std_logic;

    signal s_exp_a      : std_logic_vector(8 downto 0);
    signal s_exp_b      : std_logic_vector(8 downto 0);
    signal s_fraction_a : std_logic_vector(G_N - 5 - 1 + 2 downto 0);
    signal s_fraction_b : std_logic_vector(G_N - 5 - 1 + 2 downto 0);

    signal s_op0_greater_op1 : std_logic;
    signal s_larger_exp    : std_logic_vector(8 downto 0);
    signal s_larger_fract  : std_logic_vector(G_N - 5 - 1 + 2 downto 0);
    signal s_smaller_fract : std_logic_vector(G_N - 5 - 1 + 2 downto 0);

    signal s_normalisation_ammt : std_logic_vector(8 downto 0);
begin

    -- Check für NaR (Not a Real) oder Zero zur Optimierung
    special_check : process(i_op_a, i_op_b) is
        variable v_all_zero1 : std_logic;
        variable v_all_zero2 : std_logic;
        variable v_is_nar1   : std_logic;
        variable v_is_nar2   : std_logic;
        variable v_is_zero1  : std_logic;
        variable v_is_zero2  : std_logic;
    begin
        v_all_zero1 := or_reduce(i_op_a(G_N - 2 downto 0));
        v_all_zero2 := or_reduce(i_op_b(G_N - 2 downto 0));

        v_is_nar1  := i_op_a(G_N - 1) and (not v_all_zero1);
        v_is_zero1 := not (i_op_a(G_N - 1)) and (not v_all_zero1);

        v_is_nar2  := i_op_b(G_N - 1) and (not v_all_zero2);
        v_is_zero2 := not (i_op_b(G_N - 1)) and (not v_all_zero2);

        s_is_nar  <= v_is_nar1 or v_is_nar2;
        s_is_zero <= v_is_zero1 and v_is_zero2;
    end process special_check;

    decoder_a : entity work.takum_linear_decoder
        generic map(
            G_N => G_N
        )
        port map(
            i_takum    => i_op_a,
            o_exponent => s_exp_a,
            o_fraction => s_fraction_a
        );

    decoder_b : entity work.takum_linear_decoder
        generic map(
            G_N => G_N
        )
        port map(
            i_takum    => i_op_b,
            o_exponent => s_exp_b,
            o_fraction => s_fraction_b
        );

    -- normalize
    s_op0_greater_op1 <= '1' when signed(s_exp_a) > signed(s_exp_b) else '0';

    s_larger_exp <= s_exp_a when s_op0_greater_op1 = '1' else s_exp_b;
    s_larger_fract <= s_fraction_a when s_op0_greater_op1 = '1' else s_fraction_b;
    s_smaller_fract <= s_fraction_b when s_op0_greater_op1 = '1' else s_fraction_a;

    -- s_normalisation_ammt <= std_logic_vector(signed(s_larger_exp) - signed(s_small))
    -- TODO: check cases for comparison/subtraction of signedinteger, -> less mux???
end architecture RTL;
