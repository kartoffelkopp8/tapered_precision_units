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
        constant C_TEST_SINGLE  : boolean := FALSE;
        file     f_test_vectors : text open read_mode is C_FILE_NAME;
        variable l              : line;

        variable v_expected, v_op0, v_op1 : std_logic_vector(C_N - 1 downto 0);

        variable v_error_num : integer := 0; -- error number for final recap
        variable v_test_num  : integer := 0; -- current test number to check inputs expecteds
    begin
        report "    initialize  " severity note;
        op0 <= (others => '0');
        op1 <= (others => '0');

        wait for C_CLK_PERIOD * 2;

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
            -- Test 288 FAILED
            -- with expected: 00000001 and received: 00001000
            op0 <= "00000001";
            op1 <= "00011111";
            wait for 1 * C_CLK_PERIOD;

            -- Test 482 FAILED
            -- with expected: 11111111 and received: 11111000
            op0 <= "00000001";
            op1 <= "11100001";
            wait for 1 * C_CLK_PERIOD;

            -- Test 7938 FAILED
            -- with expected: 00000001 and received: 00001000
            op0 <= "00011111";
            op1 <= "00000001";
            wait for 1 * C_CLK_PERIOD;

            -- Test 8192 FAILED
            -- with expected: 11111111 and received: 11111000
            op0 <= "00011111";
            op1 <= "11111111";
            wait for 1 * C_CLK_PERIOD;

            -- Test 57602 FAILED
            -- with expected: 11111111 and received: 11111000
            op0 <= "11100001";
            op1 <= "00000001";
            wait for 1 * C_CLK_PERIOD;

            -- Test 57856 FAILED
            -- with expected: 00000001 and received: 00001000
            op0 <= "11100001";
            op1 <= "11111111";
            wait for 1 * C_CLK_PERIOD;

            -- Test 65312 FAILED
            -- with expected: 11111111 and received: 11111000
            op0 <= "11111111";
            op1 <= "00011111";
            wait for 1 * C_CLK_PERIOD;

            -- Test 65506 FAILED
            -- with expected: 00000001 and received: 00001000
            op0 <= "11111111";
            op1 <= "11100001";
            wait for 1 * C_CLK_PERIOD;

            wait for 1 * C_CLK_PERIOD;
            report to_string(res);
        end if;
        wait for 2 * C_CLK_PERIOD;
        std.env.stop;
    end process stimulus;

end architecture Test;
