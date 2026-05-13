library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utility_pkg.all;

entity takum_mul is
    generic(
        G_N : integer := 32
    );
    port(
        i_clk : in std_logic;
        i_enable : in std_logic;
        i_op_a : in std_logic_vector(G_N-1 downto 0);
        i_op_b : in std_logic_vector(G_N-1 downto 0);
        o_result : out std_logic_vector(G_N-1 downto 0)
    );
end entity takum_mul;

architecture Behavioral of takum_mul is
    signal s_is_zero : std_logic;
    signal s_is_nar : std_logic;
    signal s_result_sign : std_logic;

    signal s_c_1 : std_logic_vector(8 downto 0);
    signal s_c_2 : std_logic_vector(8 downto 0);
    signal s_mant_1 : std_logic_vector(G_N - 5 - 1 downto 0);
    signal s_mant_2 : std_logic_vector(G_N - 5 - 1 downto 0);

    signal s_l_added : std_logic_vector(G_N+3 downto 0);

    signal s_result : std_logic_vector(G_N-1 downto 0);
begin
    -- TODO zero weglassen
    -- check for Nar or zero, for maybe power opt
    special_check : process(i_op_a, i_op_b) is
        variable v_all_zero1 : std_logic;
        variable v_all_zero2 : std_logic;
        variable v_is_nar1 : std_logic;
        variable v_is_nar2 : std_logic;
        variable v_is_zero1 : std_logic;
        variable v_is_zero2: std_logic;
    begin
        v_all_zero1 := or_reduce(i_op_a(G_N-2 downto 0));
        v_all_zero2 := or_reduce(i_op_b(G_N-2 downto 0));

        v_is_nar1 := i_op_a(G_N-1) and (not v_all_zero1);
        v_is_zero1 := not(i_op_a(G_N-1)) and (not v_all_zero1);

        v_is_nar2 := i_op_b(G_N-1) and (not v_all_zero2);
        v_is_zero2 := not(i_op_b(G_N-1)) and (not v_all_zero2);

        s_is_nar <= v_is_nar1 or v_is_nar2;
        s_is_zero <= v_is_zero1 and v_is_zero2;
    end process special_check;
    
    s_result_sign <= i_op_a(i_op_a'high) xor i_op_b(i_op_b'high);


    decoder_a : entity work.takum_logarithmic_decoder
        generic map(
            G_N => G_N
        )
        port map(
            i_takum => i_op_a,
            o_c     => s_c_1,
            o_mant  => s_mant_1
        );

    decoder_b : entity work.takum_logarithmic_decoder
        generic map(
            G_N => G_N
        )
        port map(
            i_takum => i_op_b,
            o_c     => s_c_2,
            o_mant  => s_mant_2
        );
    
    s_l_added <= std_logic_vector(unsigned(s_c_1 & s_mant_1) + unsigned(s_c_2 & s_mant_2));
    
    encoder : entity work.takum_logarithmic_encoder
        generic map(
            G_N => G_N
        )
        port map(
            i_sign  => s_result_sign,
            i_l     => s_l_added,
            o_takum => s_result
        );
    
    o_result <= s_is_nar & (G_N-2 downto 0 => '0') when s_is_nar or s_is_zero else s_result;
    
end architecture Behavioral;
