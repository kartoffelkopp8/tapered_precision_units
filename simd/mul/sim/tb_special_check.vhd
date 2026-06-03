library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_special_check is
end entity tb_special_check;

architecture sim of tb_special_check is
    constant C_N           : integer := 32;
    constant C_SIMD_FACTOR : integer := 4;

    signal i_simd_mask : std_logic_vector(C_SIMD_FACTOR - 1 downto 0) := (others => '0');
    signal i_sign_0    : std_logic_vector(C_SIMD_FACTOR - 1 downto 0) := (others => '0');
    signal i_sign_1    : std_logic_vector(C_SIMD_FACTOR - 1 downto 0) := (others => '0');
    signal i_vec_0     : std_logic_vector(C_N - 1 downto 0)           := (others => '0');
    signal i_vec_1     : std_logic_vector(C_N - 1 downto 0)           := (others => '0');
    signal o_is_nar    : std_logic_vector(C_SIMD_FACTOR - 1 downto 0);

begin

    dut : entity work.posit_special_ckeck_simd
        generic map (
            G_N           => C_N,
            G_SIMD_FACTOR => C_SIMD_FACTOR
        )
        port map (
            i_simd_mask => i_simd_mask,
            i_sign_0    => i_sign_0,
            i_sign_1    => i_sign_1,
            i_vec_0     => i_vec_0,
            i_vec_1     => i_vec_1,
            o_is_nar    => o_is_nar
        );

    -- Stimuli Process
    stim_proc: process
    begin
        report "Start...";

        i_simd_mask <= "1000";
        i_vec_0  <= x"80000000"; 
        i_sign_0 <= "1000";     
        i_vec_1  <= x"00000000";
        i_sign_1 <= "0000";
        wait for 10 ns;
        assert (o_is_nar = "1000") report "Error Test 1: 32-Bit NaR not okay" severity error;


        i_simd_mask <= "1010";
       
        i_vec_0  <= x"80000000";
        i_sign_0 <= "1000";      
        i_vec_1  <= x"00008000";
        i_sign_1 <= "0010";      
        wait for 10 ns;
      
        assert (o_is_nar = "1010") report "Error Test 2: 16-Bit NaR Splits not okay" severity error;


        i_simd_mask <= "1111";
       
        i_vec_0  <= x"00800080"; 
        i_sign_0 <= "0101"; 
        i_vec_1  <= x"00000000";
        i_sign_1 <= "0000";
        wait for 10 ns;
        assert (o_is_nar = "0101") report "Error Test 3: 8-Bit Lane 2 NaR not okay" severity error;

        i_vec_0  <= x"80000001"; 
        i_sign_0 <= "1000";
        wait for 10 ns;
        assert (o_is_nar = "1000") report "Error Test 4: False Positive NaR discovered" severity error;

        report "stop!";
        std.env.stop;
    end process;

end architecture sim;