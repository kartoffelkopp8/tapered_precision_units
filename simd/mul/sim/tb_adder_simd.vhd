library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity tb_posit_adder_simd is
end tb_posit_adder_simd;

architecture Behavioral of tb_posit_adder_simd is

    constant C_CLK_PERIOD : time := 10 ns;

    constant G_N          : integer := 32;
    constant G_SIMD_FACTOR         : integer := 4;

    signal s_clk : std_logic := '0';

    signal i_op_0   : std_logic_vector(G_N-1 downto 0);
    signal i_op_1   : std_logic_vector(G_N-1 downto 0);
    signal i_mode        : std_logic_vector(integer(ceil(log2(real(G_SIMD_FACTOR))))-1 downto 0);  -- 0=1 lane, 1=2 lanes, 2=4 lanes, etc.
    signal i_sub_mask   :  std_logic_vector(G_SIMD_FACTOR-1 downto 0);                             -- per Lane: '0' for Add, '1' for Subtract/2s Complement
    signal o_sum      : std_logic_vector(G_N-1 downto 0);
    signal o_carries     : std_logic_vector(G_SIMD_FACTOR-1 downto 0);

begin

    s_clk <= not s_clk after C_CLK_PERIOD/2;
    
    uut: entity work.posit_adder_simd
    generic map (
        G_N           => G_N,
        G_SIMD_FACTOR => G_SIMD_FACTOR
    )
    port map(
        i_op_0   => i_op_0,
        i_op_1   => i_op_1,
        i_mode   => i_mode,
        i_sub_mask=> i_sub_mask,
        o_sum  => o_sum,
        o_carries => o_carries
    );
    
    process
    begin
        wait until rising_edge(s_clk);
    
        -- 32 Bit Add
    
        i_op_0 <= x"00000000";
        i_op_1 <= x"00000000";
        i_mode <= "00";
        i_sub_mask <= "0000";
    
        wait until rising_edge(s_clk);
        
        -- 32 Bit Add
    
        i_op_0 <= x"00000001";
        i_op_1 <= x"00000001";
        i_mode <= "00";
        i_sub_mask <= "0000";
    
        wait until rising_edge(s_clk);
        
        -- 16 Bit Add
    
        i_op_0 <= x"00000001";
        i_op_1 <= x"00010000";
        i_mode <= "01";
        i_sub_mask <= "0000";
    
        wait until rising_edge(s_clk);
        
        -- 8 Bit Add
    
        i_op_0 <= x"FF000F01";
        i_op_1 <= x"000100FF";
        i_mode <= "10";
        i_sub_mask <= "0000";
    
        wait until rising_edge(s_clk);
        
        -- 32 Bit Sub
    
        i_op_0 <= x"00000002";
        i_op_1 <= x"00000001";
        i_mode <= "00";
        i_sub_mask <= "0001";
    
        wait until rising_edge(s_clk);
        
        -- 32 Bit Sub
    
        i_op_0 <= x"00000001";
        i_op_1 <= x"00000002";
        i_mode <= "00";
        i_sub_mask <= "0001";
    
        wait until rising_edge(s_clk);
        
        -- 6 Bit Sub
    
        i_op_0 <= x"00010001";
        i_op_1 <= x"000F0002";
        i_mode <= "01";
        i_sub_mask <= "0001";
    
        wait until rising_edge(s_clk);
        
        std.env.stop;
    end process;

end Behavioral;
