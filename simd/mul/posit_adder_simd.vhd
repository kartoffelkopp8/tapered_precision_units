library ieee;
library work;

use ieee.STD_LOGIC_1164.ALL;
use ieee.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity posit_adder_simd is
    generic (
        G_N           : integer := 32;
        G_SIMD_FACTOR : integer := 4
    );
    port(
        i_op_0   : in std_logic_vector(G_N-1 downto 0);
        i_op_1   : in std_logic_vector(G_N-1 downto 0);
        i_mode        : in std_logic_vector(integer(ceil(log2(real(G_SIMD_FACTOR))))-1 downto 0);  -- 0=1 lane, 1=2 lanes, 2=4 lanes, etc.
        i_sub_mask   : in  std_logic_vector(G_SIMD_FACTOR-1 downto 0);                             -- per Lane: '0' for Add, '1' for Sub
        o_sum      : out std_logic_vector(G_N-1 downto 0);
        o_carries     : out std_logic_vector(G_SIMD_FACTOR-1 downto 0)                              -- to interpret carries the used mode is important
    );
end posit_adder_simd;

architecture rtl of posit_adder_simd is
    constant C_BASE_WIDTH : integer := G_N / G_SIMD_FACTOR;
    
    -- Carry signals between C_BASE_WIDTH segments
    signal s_lane_carries : std_logic_vector(G_SIMD_FACTOR downto 0);
    signal s_is_lane_start : std_logic_vector(G_SIMD_FACTOR-1 downto 0);
    
begin

    -- Extract starting point of lanes
    process(i_mode)
        variable v_lanes_count   : integer;
        variable v_segments_per_lane : integer;
    begin
        v_lanes_count := 2**to_integer(unsigned(i_mode));
        v_segments_per_lane := G_SIMD_FACTOR / v_lanes_count;
        
        for i in 0 to G_SIMD_FACTOR-1 loop
            if (i mod v_segments_per_lane = 0) then
                s_is_lane_start(i) <= '1';
            else
                s_is_lane_start(i) <= '0';
            end if;
        end loop;
    end process;

    -- Multi-Segment Adder
    s_lane_carries(0) <= i_sub_mask(0);

    gen_lanes: for i in 0 to G_SIMD_FACTOR-1 generate
        signal s_op_0, s_op_1 : unsigned(C_BASE_WIDTH-1 downto 0);
        signal s_res        : unsigned(C_BASE_WIDTH downto 0);
        signal s_cin        : std_logic;
        signal s_sub_ctrl   : std_logic;
    begin
        -- Determine Add/Sub for this segment
        s_sub_ctrl <= i_sub_mask(i / (G_SIMD_FACTOR / (2**to_integer(unsigned(i_mode)))));

        -- Carry Selection:
        -- If lane start: use the s_sub_ctrl (the +1 for 2s complement).
        -- Else: use the carry-out from the previous 8-bit segment.
        s_cin <= s_sub_ctrl when s_is_lane_start(i) = '1' else s_lane_carries(i);

        s_op_0 <= unsigned(i_op_0((i+1)*C_BASE_WIDTH-1 downto i*C_BASE_WIDTH));
        -- Invert bits for substracting
        s_op_1 <= unsigned(i_op_1((i+1)*C_BASE_WIDTH-1 downto i*C_BASE_WIDTH) xor (C_BASE_WIDTH-1 downto 0 => s_sub_ctrl));

        -- Adder
        s_res <= ("0" & s_op_0) + ("0" & s_op_1) + ("" & s_cin);

        -- Results
        o_sum((i+1)*C_BASE_WIDTH-1 downto i*C_BASE_WIDTH) <= std_logic_vector(s_res(C_BASE_WIDTH-1 downto 0));
        s_lane_carries(i+1) <= s_res(C_BASE_WIDTH);
        
        -- External Carry Output
        -- Add: '1' if result > max (Unsigned Overflow)
        -- Sub: '1' if result < 0   (Borrow / Negative Result)
        o_carries(i) <= s_res(C_BASE_WIDTH) xor s_sub_ctrl;
    end generate;

end architecture;
