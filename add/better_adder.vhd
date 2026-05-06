library IEEE;
library work;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_utility.all;

entity parallel_prefix_adder is
    generic(
        G_DATA_WIDTH : integer := 32
    );
    port(
        i_op_a   : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        i_op_b   : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        o_result : out std_logic_vector(G_DATA_WIDTH - 1 downto 0)
    );
end entity;

architecture Han_Carlson of parallel_prefix_adder is
    constant C_STAGES : integer := clog2(G_DATA_WIDTH) + 1;
    type stage_array is array (0 to C_STAGES) of std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal s_P, s_G : stage_array;
begin

    -- STAGE 0: Preprocessing
    gen_pre : for i in 0 to G_DATA_WIDTH - 1 generate
        s_P(0)(i) <= i_op_a(i) xor i_op_b(i);
        s_G(0)(i) <= i_op_a(i) and i_op_b(i);
    end generate;

    gen_s1 : for i in 0 to G_DATA_WIDTH - 1 generate
        if_bit0 : if i = 0 generate
            s_G(1)(0) <= s_G(0)(0);
            s_P(1)(0) <= s_P(0)(0);
        elsif (i mod 2 /= 0) generate
            if_grey : if i = 1 generate
                s_G(1)(1) <= s_G(0)(1) or (s_P(0)(1) and s_G(0)(0));
                s_P(1)(1) <= '0';
            else generate 
                s_G(1)(i) <= s_G(0)(i) or (s_P(0)(i) and s_G(0)(i-1));
                s_P(1)(i) <= s_P(0)(i) and s_P(0)(i-1);
            end generate;
        else generate
            s_G(1)(i) <= s_G(0)(i);
            s_P(1)(i) <= s_P(0)(i);
        end generate;
    end generate;

    -- kogge stone adder 
    gen_core : for s in 2 to C_STAGES - 1 generate
        constant dist : integer := 2**(s-2);
    begin
        gen_bits : for i in 0 to G_DATA_WIDTH - 1 generate
            if_black : if (i mod 2 /= 0) and (i >= 2*dist) generate
                s_G(s)(i) <= s_G(s-1)(i) or (s_P(s-1)(i) and s_G(s-1)(i-2*dist));
                s_P(s)(i) <= s_P(s-1)(i) and s_P(s-1)(i-2*dist);
            else generate
                s_G(s)(i) <= s_G(s-1)(i);
                s_P(s)(i) <= s_P(s-1)(i);
            end generate;
        end generate;
    end generate;

    -- gen final; summary
    gen_exp : for i in 0 to G_DATA_WIDTH - 1 generate
        if_fill : if (i > 0) and (i mod 2 = 0) generate
            s_G(C_STAGES)(i) <= s_G(C_STAGES-1)(i) or (s_P(0)(i) and s_G(C_STAGES-1)(i-1));
            s_P(C_STAGES)(i) <= '0'; 
        else generate
            s_G(C_STAGES)(i) <= s_G(C_STAGES-1)(i);
            s_P(C_STAGES)(i) <= s_P(C_STAGES-1)(i);
        end generate;
    end generate;


    o_result(0) <= s_P(0)(0);
    gen_sum : for i in 1 to G_DATA_WIDTH - 1 generate
        o_result(i) <= s_P(0)(i) xor s_G(C_STAGES)(i-1);
    end generate;

end architecture;
