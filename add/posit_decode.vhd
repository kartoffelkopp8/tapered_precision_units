library work;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- gets a normalized posit without sign as input (always positive)
entity posit_decode is

    generic(
        N  : integer := 7;              -- bitvector of input posit
        Bs : integer := 3;              -- log2(N)bitwidth of decoded regime
        es : integer := 2
    );
    port(
        i_val    : in  std_logic_vector(N - 1 downto 0); --input posit without sign and already in twos complement inverted if negative
        o_rc     : out std_logic;       -- regime sign
        o_regime : out std_logic_vector(Bs - 1 downto 0); -- regime value without sign
        o_exp    : out std_logic_vector(es - 1 downto 0); -- exponent
        o_mant   : out std_logic_vector(N - es - 3 downto 0) -- mantissa = total length -es-2
    );
end posit_decode;

architecture Behavioral of posit_decode is
    signal s_rc_tmp : std_logic;        -- sign of regime 
    signal s_xin    : std_logic_vector(N - 1 downto 0);

    signal s_xin_r     : std_logic_vector(N - 1 downto 0);
    signal s_lod_input : std_logic_vector(N - 1 downto 0);
    signal s_k_tmp     : std_logic_vector(Bs - 1 downto 0);
    signal s_k         : std_logic_vector(Bs - 1 downto 0); -- count of same regime bits
    signal s_k_vld     : std_logic; -- valid bit

    signal s_xin_tmp : std_logic_vector(N - 3 downto 0);
begin

    -- 2's complement conversion already in posit_adder
    s_xin <= i_val;

    -- The Bit after the Sign of XINs depicts the sign of regime value and acts as Regime Check (RC) bit
    s_rc_tmp <= s_xin(N - 1);

    -- Invert if regime has positive value so only one LOD is necessary
    s_xin_r <= (not s_xin) when s_rc_tmp = '1' else s_xin;

    -- RC determines either of K0 or K1 as R[RS-1:0] (absolute regime value) and regime left shift amount (Lshift) of respective operands.
    s_lod_input <= s_xin_r(N - 1 downto 0); -- & (rc_tmp xor '0');

    LOD : entity work.LOD_T
        generic map(
            G_DATA_WIDTH => N
        )
        port map(
            i_x   => s_lod_input,
            o_K   => s_k_tmp,
            o_vld => s_k_vld
        );

    -- Check if LOD has a valid result. Otherwise set k to maximum value
    s_k <= (others => '1') when s_k_vld = '0' else s_k_tmp;
    --k <= k_tmp;

    -- To extract the exponent and mantissa, the respective XIN is dynamically left shifted by k to push-out the entire regime
    -- bits plus stopbit and align exponent and mantissa at MSB. Now the MSB ES bit will act as the exponent and remaining bit would be mantissa bits.
    -- The "00" is used to remove the sign bit and the regime end bit independendly of the value of k
    s_xin_tmp <= std_logic_vector(shift_left(unsigned(s_xin(N - 3 downto 0)), to_integer(unsigned(s_k) - 1)));

    -- Reduce k by 1 if Regime is positive to comply with standard
    o_regime <= std_logic_vector(unsigned(s_k) - 1) when s_rc_tmp = '1' else s_k;

    o_exp  <= s_xin_tmp(N - 3 downto N - 2 - es);
    o_mant <= s_xin_tmp(N - es - 3 downto 0);
    o_rc   <= s_rc_tmp;

end Behavioral;
