library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_takum_log_decoder is
end entity tb_takum_log_decoder;

architecture Test of tb_takum_log_decoder is
    constant G_N   : integer := 13;
    signal   i_vec : std_logic_vector(G_N - 1 downto 0);
    -- signal   o_l   : std_logic_vector(G_N - 5 downto 0);

    -- signal s_sign : std_logic;
    -- signal s_l2 : std_logic_vector(G_N+3 downto 0);
    -- signal s_prec : natural range 0 to G_N - 5;
    -- signal s_is_nar, s_is_zero : std_logic;

    signal s_c : std_logic_vector(8 downto 0);
    signal s_mant: std_logic_vector(G_N - 5 - 1 downto 0);
begin
    -- dut : entity work.takum_log_decoder
    --     generic map(
    --         G_N => G_N
    --     )
    --     port map(
    --         i_vec => i_vec,
    --         o_l   => o_l
    --     );

    -- dur_ref : entity work.decoder_logarithmic
    --     generic map(
    --         n => G_N
    --     )
    --     port map(
    --         takum                    => i_vec,
    --         sign_bit                 => s_sign,
    --         barred_logarithmic_value => s_l2,
    --         precision                => s_prec,
    --         is_zero                  => s_is_zero,
    --         is_nar                   => s_is_nar
    --     );
    
    dut : entity work.takum_logarithmic_decoder
        generic map(
            G_N => G_N
        )
        port map(
            i_takum => i_vec,
            o_c     => s_c,
            o_mant  => s_mant
        );
    
    

    stimulus : process
    begin
        i_vec <= "1000000000001";
        wait for 10 ns;
        assert s_c = "100000001" report "wrong s_c on test 1";
        assert s_mant = x"80" report "error on s_mant extraction Test 1"; -- mantissa is 1, but we have to use max mantissa width for asic

        i_vec <= "1111111111111";
        wait for 10 ns;
        assert s_c = "111111110" report "wrong s_c on test 2";
        assert s_mant = x"80" report "error on s_mant extraction Test 2";
        

        i_vec <= "0000000000001";
        wait for 10 ns;
        i_vec <= "0111111111111";
        assert s_c = "100000001" report "wrong s_c on test 3";
        assert s_mant = x"80" report "error on s_mant extraction Test 3";

        wait for 20 ns;

        std.env.stop;
    end process;

end architecture Test;
