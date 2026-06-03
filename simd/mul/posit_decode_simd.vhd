library ieee;
library work;

use work.utility_pkg.all;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--decoder entity, decodes simd posit vector according to posit standard 
entity posit_decode_simd is
    generic(
        G_N           : integer := 32;  -- total bitwidth of input value without sign
        G_MAX_ES      : integer := 4;   -- maximal number of exponent bits per posit
        G_SIMD_FACTOR : integer := 4    -- maximal number of parts, power of 2
    );
    port(
        i_val       : in  std_logic_vector(G_N - 1 downto 0);
        i_simd_mask : in  std_logic_vector(G_SIMD_FACTOR - 1 downto 0); -- selector for simd state 
        i_simd_mode : in  std_logic_vector(clog2(G_SIMD_FACTOR) - 1 downto 0); -- TODO dont like it, but needed for shifter
        i_dyn_exp   : in  std_logic_vector(clog2(G_MAX_ES) downto 0); -- selector for dynamic exp size selectioon at runtime

        o_rc        : out std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
        -- o_regime    : out std_logic_vector((clog2(G_N) * G_SIMD_FACTOR) - 1 downto 0);
        o_regime    : out std_logic_vector(G_N - 1 downto 0);
        o_exp       : out std_logic_vector((G_MAX_ES * G_SIMD_FACTOR) - 1 downto 0);
        -- o_mant      : out std_logic_vector(((G_N - G_MAX_ES - 2) * G_SIMD_FACTOR) - 1 downto 0) -- max mantissa length is (without sign) G_N-exponent-at least 2 regime bits
        o_mant      : out std_logic_vector(next_multiple_of_SIMD((G_N - G_MAX_ES - 2), G_SIMD_FACTOR) - 1 downto 0)
    );
end entity posit_decode_simd;

architecture Behavioural of posit_decode_simd is
    constant C_IND_LEN  : integer := G_N / G_SIMD_FACTOR;
    -- constant C_MANT_WIDTH : integer := G_N - G_MAX_ES - 2;
    -- signals for rc extraction
    signal   s_rc       : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
    signal   s_inverted : std_logic_vector(G_N - 1 downto 0);
    signal   s_eff_rc   : std_logic_vector(G_SIMD_FACTOR - 1 downto 0); -- rc with regards to mask

    -- signals for regime calculation
    signal s_k          : std_logic_vector((G_SIMD_FACTOR * clog2(G_N)) - 1 downto 0);
    signal s_k_extended : std_logic_vector(G_N - 1 downto 0);
    signal s_vld        : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);

    signal s_carries     : std_logic_vector(G_SIMD_FACTOR - 1 downto 0); -- should not be important, just for vhdl type check
    signal s_op_a_regime : std_logic_vector(G_N - 1 downto 0);

    -- signal exp and regime extract
    signal s_without_regime : std_logic_vector(G_N - 1 downto 0);
    signal s_without_rc     : std_logic_vector(G_N - 1 downto 0);

    signal s_shift_count          : std_logic_vector((G_SIMD_FACTOR * clog2(G_N)) - 1 downto 0);
    signal s_aligned_exp_mantissa : std_logic_vector(G_N - 1 downto 0);
begin

    -- generate the rc bit vector
    gen_rc : for i in 0 to G_SIMD_FACTOR - 1 generate
        s_rc(i) <= i_val((i + 1) * C_IND_LEN - 2) and i_simd_mask(i);
    end generate;

    o_rc <= s_rc;

    s_eff_rc(G_SIMD_FACTOR - 1) <= s_rc(G_SIMD_FACTOR - 1);
    gen_eff_rc : for i in G_SIMD_FACTOR - 2 downto 0 generate
        s_eff_rc(i) <= s_rc(i) when i_simd_mask(i) = '1' else s_rc(i + 1);
    end generate;

    -- process inverts vectors in preparation of LOD 
    invert : process(i_val, s_eff_rc, i_simd_mask)
    begin
        s_inverted(s_inverted'high) <= '0';
        for i in 0 to G_N - 2 loop
            -- check if we are at sign bit of a lane, if yes make a check if it shhould be inverted
            if ((i + 1) mod C_IND_LEN = 0) and i < G_N then
                s_inverted(i) <= i_val(i) xor (not i_simd_mask(((i + 1) / C_IND_LEN) - 1) and s_eff_rc(((i + 1) / C_IND_LEN) - 1));
            else
                s_inverted(i) <= i_val(i) xor s_eff_rc(i / C_IND_LEN);
            end if;
        end loop;
    end process invert;

    lod : entity work.LOD_simd
        generic map(
            G_N           => G_N,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_vec       => s_inverted,
            i_simd_mask => i_simd_mask,
            o_k         => s_k,
            o_vld       => s_vld
        );

    -- here, because sign bit gets counted also: 1-k, -2+k
    -- o_regime calculations according to standard: -k if rc = 0 else k-1
    op_a : process(s_eff_rc, i_simd_mode)
        variable v_op_a_tmp          : std_logic_vector(G_N - 1 downto 0);
        variable v_start, v_end      : integer;
        variable v_lanes_count       : integer;
        variable v_segments_per_lane : integer;
    begin
        v_op_a_tmp := (others => '0');

        v_lanes_count       := 2 ** to_integer(unsigned(i_simd_mode));
        v_segments_per_lane := G_SIMD_FACTOR / v_lanes_count;

        for i in 0 to G_SIMD_FACTOR - 1 loop
            v_start := i * C_IND_LEN;
            v_end   := v_start + C_IND_LEN - 1;

            if s_eff_rc(i) = '1' then
                v_op_a_tmp(v_end downto v_start) := (others => '1');
            else
                v_op_a_tmp(v_end downto v_start) := (others => '0');
            end if;

            if (i mod v_segments_per_lane = 0) then
                if s_eff_rc(i) = '1' then
                    v_op_a_tmp(v_start) := '0';
                else
                    v_op_a_tmp(v_start) := '1';
                end if;
            end if;
        end loop;

        s_op_a_regime <= v_op_a_tmp;
    end process;

    -- TODO incorrect k+1 
    -- calculate regime value
    s_k_extended <= std_logic_vector(resize(unsigned(s_k), s_k_extended'length));
    calc_reg : entity work.posit_adder_simd
        generic map(
            G_N           => G_N,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_op_0     => s_op_a_regime,
            i_op_1     => s_k_extended,
            i_mode     => i_simd_mode,
            i_sub_mask => not (s_eff_rc),
            o_sum      => o_regime,
            o_carries  => s_carries
        );

    shift_left : entity work.posit_left_shift_simd
        generic map(
            G_N           => G_N,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_data       => s_inverted,
            i_shift_amts => s_k,
            i_mode       => i_simd_mode,
            o_result     => s_without_regime
        );

    -- delete regime sdtopbit bits in preparation for rigth shift to extract mantissa and exp
    zero_out_rc : process(i_simd_mask, s_without_regime)
        variable v_without_rc_tmp : std_logic_vector(G_N - 1 downto 0) := (others => '0');
        variable v_bit_pos        : integer                            := 0;
    begin
        v_without_rc_tmp := s_without_regime;
        for i in 0 to G_SIMD_FACTOR - 1 loop
            v_bit_pos                   := (i + 1) * C_IND_LEN - 1;
            v_without_rc_tmp(v_bit_pos) := s_without_regime(v_bit_pos) xor i_simd_mask(i);
        end loop;

        s_without_rc <= v_without_rc_tmp;
    end process;

    -- shift right for exponent extraction
    s_shift_count <= std_logic_vector(to_unsigned(G_MAX_ES, s_shift_count'length) - unsigned(i_dyn_exp));

    shift_exp : entity work.posit_right_shift_simd
        generic map(
            G_N           => G_N,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_data       => s_without_rc,
            i_shift_amts => s_shift_count,
            i_mode       => i_simd_mode,
            o_result     => s_aligned_exp_mantissa
        );

    -- extract mantissa and exponent from unifies vector
    extract_exp : process(s_aligned_exp_mantissa, i_simd_mask, i_simd_mode)
        variable v_array_exp : t_arr(0 to G_SIMD_FACTOR - 1)(G_MAX_ES - 1 downto 0) := (others => (others => '0'));
        -- variable v_array_mant : t_arr(0 to G_SIMD_FACTOR - 1)(G_N - G_MAX_ES - 2 downto 0);
        variable v_lane_msb  : integer                                              := 0;

        variable v_bits_per_exp : integer;
        variable v_lane_lsb_exp : integer;

        variable v_mant_msb_src  : integer := 0;
        variable v_mant_msb_dst  : integer := 0;
        variable v_mant_lsb_src  : integer := 0;
        variable v_mant_lsb_dst  : integer := 0;
        variable v_bits_per_mant : integer;

    begin
        o_exp  <= (others => '0');
        o_mant <= (others => '0');

        v_bits_per_exp  := o_exp'length / (2 ** to_integer(unsigned(i_simd_mode)));
        v_bits_per_mant := o_mant'length / (2 ** to_integer(unsigned(i_simd_mode)));
        -- exponent extraction
        for i in 0 to G_SIMD_FACTOR - 1 loop
            v_lane_msb     := (C_IND_LEN * (i + 1)) - 1;
            v_array_exp(i) := s_aligned_exp_mantissa(v_lane_msb downto v_lane_msb - G_MAX_ES + 1);
        end loop;

        -- TODO C_MANT_WIDTH should be calculated, not constant depemding on simd factor
        for i in 0 to G_SIMD_FACTOR - 1 loop
            if i_simd_mask(i) = '1' then
                v_mant_msb_src                                             := 0;
                v_mant_lsb_src                                             := 0;
                -- exponent extraction 
                v_lane_lsb_exp                                             := (i + 1) * G_MAX_ES - v_bits_per_exp;
                o_exp(v_lane_lsb_exp + G_MAX_ES - 1 downto v_lane_lsb_exp) <= v_array_exp(i);

                -- mantissa extraction
                -- v_mant_msb_src := (C_IND_LEN * (i + 1)) - G_MAX_ES - 1;
                -- v_mant_lsb_src := v_mant_msb_src - C_MANT_WIDTH + 1;

                -- v_mant_msb_dst := ((i + 1) * C_MANT_WIDTH - 1) -v_bits_per_mant + C_MANT_WIDTH;
                -- v_mant_lsb_dst := (i * C_MANT_WIDTH)-v_bits_per_mant + C_MANT_WIDTH;
                -- report "msb: " & to_string(v_mant_msb_dst) & " lsb: " & to_string(v_mant_lsb_dst);
                -- report to_string(v_bits_per_mant);
                -- o_mant(v_mant_msb_dst downto v_mant_lsb_dst) <= s_aligned_exp_mantissa(v_mant_msb_src downto v_mant_lsb_src); 
            end if;
        end loop;
    end process;

    -- TODO generic generration of mantissa vector from exp_mantissa vector still open, cant get it to work
    extract_mant : process(i_simd_mode)
        variable v_bits_per_mant : integer;
        variable v_mant_msb_dst  : integer;
        variable v_mant_lsb_dst  : integer;
        variable v_active_lane : integer;
    begin
        o_mant          <= (others => '0');
        report to_string(o_mant'length);
        v_bits_per_mant := o_mant'length / (2 ** to_integer(unsigned(i_simd_mode)));
        v_active_lane   := 0;
        for i in 0 to G_SIMD_FACTOR - 1 loop
            if i_simd_mask(i) = '1' then
                -- v_bits_per_mant = o_mant'length / (Anzahl der aktiven Lanes)
                -- z.B. o_mant'length = 32, aktive Lanes = anzahl '1'en in Maske

                v_mant_lsb_dst := v_active_lane * v_bits_per_mant;
                v_active_lane  := v_active_lane + 1;

                report to_string(v_mant_lsb_dst);
            end if;
        end loop;
    end process;
end architecture Behavioural;
