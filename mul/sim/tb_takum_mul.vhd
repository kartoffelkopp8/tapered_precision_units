library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use std.textio.all;

-- testbench for posit adder using testvectors generated with stillwater-sc/universal in cpp
entity tb_takum_mul is
end entity;

architecture Test of tb_takum_mul is
    -- constants 
    constant C_N          : integer := 8;
    constant C_CLK_PERIOD : time    := 10 ns; -- clock frequency
    constant C_FILE_NAME  : string  := "../sim/testvectors.txt";

    -- signals for dut 
    signal clk           : std_logic := '0';
    signal enable        : std_logic := '1';
    signal op0, op1, res : std_logic_vector(C_N - 1 downto 0);

    -- stuff for the testfile 

begin
    DUT : entity work.takum_mul
        generic map(
            G_N => C_N
        )
        port map(
            i_clk    => clk,
            i_enable => enable,
            i_op_a   => op0,
            i_op_b   => op1,
            o_result => res
        );

    -- clock generation
    clk    <= not clk after C_CLK_PERIOD / 2;
    enable <= '1';

    stimulus : process is
        constant C_TEST_SINGLE  : boolean := TRUE;
        file     f_test_vectors : text open read_mode is C_FILE_NAME;
        variable l              : line;

        variable v_expected, v_op0, v_op1 : std_logic_vector(C_N - 1 downto 0);

        variable v_error_num : integer := 0; -- error number for final recap
        variable v_test_num  : integer := 0; -- current test number to check inputs expecteds
    begin
        report "    initialize  " severity note;
        op0 <= (others => '0');
        op1 <= (others => '0');

        wait for C_CLK_PERIOD * 6;

        report "    Test START  " severity note;
        if C_TEST_SINGLE = FALSE then
            while not endfile(f_test_vectors) loop -- @suppress "Dead code"
                v_test_num := v_test_num + 1;

                readline(f_test_vectors, l);
                hread(l, v_op0);
                hread(l, v_op1);
                hread(l, v_expected);

                op0 <= v_op0;
                op1 <= v_op1;
                -- wait for pipeline stages
                wait for 1 * C_CLK_PERIOD;

                if v_expected = res then
                -- report "    Test " & integer'image(v_test_num) & "  PASSED     " severity note;
                else
                    report "    Test " & integer'image(v_test_num) & "  FAILED     " & lf & "with expected: " & to_string(v_expected) & " and received: " & to_string(res) & " operand A: " & to_string(v_op0) & ", operand B: " & to_string(v_op1) severity error;
                    v_error_num := v_error_num + 1;
                    -- std.env.stop;
                end if;
            end loop;

            -- report when test finished:
            report "#################################" & lf severity note;
            if v_error_num = 0 then
                report "Test fully PASSED without error" & lf severity note;
            else
                report "Test FAILED with " & integer'image(v_error_num) & " errors" & lf severity error;
            end if;
            report "#################################" & lf severity note;
        else                            -- @suppress "Dead code"
            -- with expected: 01111111 and received: 00000001 operand A: 10011110, operand B: 10000001
            op0 <= "10011110";
            op1 <= "10000001";
            -- with expected: 11111111 and received: 10000000 operand A: 11111111, operand B: 00100011
            -- op0 <= "11111111";
            -- op1 <= "00100011";
            -- with expected: 00000001 and received: 00000000 operand A: 11111111, operand B: 11011100
            -- op0 <= "11111111";
            -- op1 <= "11011100";
            --with expected: 00000001 and received: 01101001 operand A: 11111111, operand B: 11111111
            -- op0 <= "11111111";
            -- op1 <= "11111111";
            -- with expected: 00011000 and received: 00011001 operand A: 11101000, operand B: 10111110
            -- op0 <= "11101000";
            -- op1 <= "10111110";
            -- with expected: 10000011 0x83

            -- op0 <= "00011101";          -- 0x1D
            -- op1 <= "10000010";          -- 0x82
            -- op0 <= "10110010";
            -- op1 <= "10111110";
            wait for 1 * C_CLK_PERIOD;
            report to_string(res);
        end if;
        wait for 2 * C_CLK_PERIOD;
        std.env.stop;
    end process stimulus;

end architecture Test;
