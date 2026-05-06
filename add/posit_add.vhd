library IEEE;
library work;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

use work.pkg_utility.all;

-- ideas: enable signal for special cases to reduce switching factore in case of inf or zero es ist laut standart auf 2 begrenzt
-- TODO evtl einbauen eines Leading one anticipators oder aehnliche designs 
entity posit_add is

    generic(
        G_N  : integer := 32;           -- bit count 
        G_ES : integer := 2             -- es of posit
    );
    port(
        i_clk       : in  std_logic;
        i_enable    : in  std_logic;
        -- i_reset : in std_logic;
        i_operand_0 : in  std_logic_vector(G_N - 1 downto 0);
        i_operand_1 : in  std_logic_vector(G_N - 1 downto 0);
        o_result    : out std_logic_vector(G_N - 1 downto 0)
    );
end posit_add;

architecture Behavioral of posit_add is

    constant C_GEN_PIPE_0 : integer := 32;

    constant C_Bs                 : integer := integer(clog2(G_N)); -- bitwidth for maximal decoded !! regime of G_N-1 bits TODO sollte hier nich ceil sien
    constant C_MAX_MANTISSA_WIDTH : integer := G_N - G_ES - 3; -- 2 bit regime + 1 bit sign

    constant C_INTERNAL_MANTISSA_WIDTH : integer := C_MAX_MANTISSA_WIDTH + 3; -- mantissa + hidden, guard, rounding (and sticky) bit 

    -- Signs for both inputs
    signal s_sign_0 : std_logic;
    signal s_sign_1 : std_logic;

    -- flags
    signal is_inf_0         : std_logic;
    signal is_inf_1         : std_logic;
    signal is_zero_0        : std_logic;
    signal is_zero_1        : std_logic;
    signal s_result_is_inf  : std_logic;
    signal s_result_is_zero : std_logic;

    -- Normalized operand values depending on sign -> used of decode
    signal s_normalized_operand_0 : std_logic_vector(G_N - 2 downto 0);
    signal s_normalized_operand_1 : std_logic_vector(G_N - 2 downto 0);

    -- Data Extraction
    signal s_rc_0, s_rc_1             : std_logic; -- regime count => sign of regime
    signal s_regime_0, s_regime_1     : std_logic_vector(C_Bs - 1 downto 0);
    signal s_exponent_0, s_exponent_1 : std_logic_vector(G_ES - 1 downto 0);
    signal s_mantissa_0, s_mantissa_1 : std_logic_vector(C_MAX_MANTISSA_WIDTH - 1 downto 0);

    signal s_op0_greater_op1 : std_logic;
    signal s_result_sign     : std_logic;

    signal s_operation : std_logic;

    -- Pipeline Stage 0 Registers --
    signal r0_rc_0, r0_rc_1             : std_logic;
    signal r0_mantissa_0                : std_logic_vector(s_mantissa_0'range);
    signal r0_mantissa_1                : std_logic_vector(s_mantissa_1'range);
    signal r0_regime_0, r0_regime_1     : std_logic_vector(C_Bs - 1 downto 0);
    signal r0_exponent_0, r0_exponent_1 : std_logic_vector(G_ES - 1 downto 0);

    signal r0_result_sign : std_logic;
    signal r0_is_inf      : std_logic;
    signal r0_is_zero     : std_logic;

    signal r0_op0_greater_op1 : std_logic;
    signal r0_operation       : std_logic;
    ---------------------------------

    signal s_larger_rc, s_smaller_rc             : std_logic;
    signal s_larger_regime, s_smaller_regime     : std_logic_vector(C_Bs - 1 downto 0);
    signal s_larger_exponent, s_smaller_exponent : std_logic_vector(G_ES - 1 downto 0);

    signal s_larger_mantissa         : std_logic_vector(C_MAX_MANTISSA_WIDTH - 1 downto 0);
    signal s_smaller_hidden_mantissa : std_logic_vector(C_MAX_MANTISSA_WIDTH downto 0);

    signal s_larger_signed_regime      : std_logic_vector(C_Bs downto 0);
    signal s_larger_efficient_exponent : std_logic_vector(C_Bs + G_ES downto 0);

    signal s_smaller_signed_regime      : std_logic_vector(C_Bs downto 0);
    signal s_smaller_efficient_exponent : std_logic_vector(C_Bs + G_ES downto 0);

    signal s_efficient_exponent_difference : std_logic_vector(C_Bs + G_ES downto 0);

    signal s_larger_padded_mantissa  : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH - 1 downto 0);
    signal s_smaller_padded_mantissa : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH - 1 downto 0);

    signal s_aligned_mantissa : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH downto 0);

    signal s_alignment_sticky : std_logic;

    signal s_shift_out_of_range    : std_logic;
    signal s_saturated_shift_count : std_logic_vector(C_Bs - 1 downto 0);

    -- Pipeline Stage 1 Registers --
    signal r1_aligned_mantissa  : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH - 1 downto 0);
    signal r1_alignmment_sticky : std_logic;
    -- signal r1_larger_mantissa   : std_logic_vector(C_MAX_MANTISSA_WIDTH - 1 downto 0);

    signal r1_larger_efficient_exponent : std_logic_vector(C_Bs + G_ES downto 0);

    -- signal r1_operation : std_logic;

    signal r1_result_sign                    : std_logic;
    signal r1_is_inf                         : std_logic;
    signal r1_is_zero                        : std_logic;
    signal r1_summed_mantissa                : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH downto 0);
    -- signal r1_signed_aligned_hidden_mantissa : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH downto 0);
    -- signal r1_signed_larger_hidden_mantissa  : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH downto 0);
    ---------------------------------

    signal s_signed_larger_hidden_mantissa  : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH downto 0);
    signal s_signed_aligned_hidden_mantissa : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH downto 0);

    -- overflow bit added
    signal s_summed_mantissa    : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH downto 0);
    signal s_mantissa_overflow  : std_logic;
    signal s_shift_right_sticky : std_logic;
    signal s_shift_tmp          : std_logic;

    signal s_normalized_lod_k     : std_logic_vector(integer(ceil(log2(real(C_INTERNAL_MANTISSA_WIDTH)))) - 1 downto 0);
    signal s_normalized_lod_valid : std_logic; -- just takes k, never read but needed for synthesis
    signal s_valid_adjusted_lod_k : std_logic_vector(integer(ceil(log2(real(C_INTERNAL_MANTISSA_WIDTH)))) - 1 downto 0);

    -- without overflow bit Stage 2 pipeline
    signal r2_summed_mantissa           : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH - 1 downto 0);
    signal r2_normalize_lod_k           : std_logic_vector(integer(ceil(log2(real(C_INTERNAL_MANTISSA_WIDTH)))) - 1 downto 0);
    signal r2_mantissa_overflow         : std_logic;
    signal r2_larger_efficient_exponent : std_logic_vector(C_Bs + G_ES downto 0);

    signal r2_alignmment_sticky : std_logic;

    signal r2_result_sign : std_logic;
    signal r2_is_inf      : std_logic;
    signal r2_is_zero     : std_logic;
    ----------------------------------

    -- signal s_normalize_k : std_logic_vector(C_Bs + G_ES + 1 downto 0); -- unusused

    signal s_normalized_hidden_mantissa : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH - 1 downto 0);
    -- signal s_normalized_mantissa        : std_logic_vector(C_INTERNAL_MANTISSA_WIDTH - 1 downto 0); -- unused

    signal s_extended_mantissa_overflow : std_logic_vector(C_Bs + G_ES + 1 downto 0);

    signal s_efficient_exponent : std_logic_vector(C_Bs + G_ES + 1 downto 0);

    signal s_abs_efficient_exponent : std_logic_vector(C_Bs + G_ES downto 0); -- abs reduces on bit msb

    signal s_exponent : std_logic_vector(G_ES - 1 downto 0);

    -- remove hidden bit
    signal s_combined_exp_mantissa : std_logic_vector(G_ES + C_INTERNAL_MANTISSA_WIDTH - 2 downto 0);

    -- signal s_regime_length : std_logic_vector(C_Bs downto 0); -- never read

    -- bitvector which gets shifted in from left to create regime 
    signal s_regime_bit : std_logic;

    -- use arithmetic shift to create regime (just need one regime bit and termination bit)
    -- THIS IS THE SMART OPTIMIZATION THAT DOES NOT WORK (REPLACES above definition. and in the last shifter the arithmetic right shift must be selected).
    --constant C_INTERMEDIATE_WIDTH : integer := 2+G_ES+C_INTERNAL_MANTISSA_WIDTH-1;

    signal s_intermediate     : std_logic_vector(s_combined_exp_mantissa'length downto 0); -- equal to the combined length + 1 from regime stop bit
    signal s_intermediate_tmp : std_logic_vector(s_combined_exp_mantissa'length - 1 downto 0);
    signal s_sticky_shifted   : std_logic_vector(s_intermediate'length - 1 downto 0); -- intermediate length + 1 bit for sticky
    signal s_sticky_shifted2  : std_logic_vector(s_intermediate'length downto 0); -- intermediate length + 1 bit for sticky

    signal s_drs : std_logic_vector(integer(ceil(log2(real(s_intermediate'length)))) - 1 downto 0);

    signal s_lsb_bit    : std_logic;
    signal s_guard_bit  : std_logic;
    signal s_sticky_bit : std_logic;
    -- signal s_round_to_zero : std_logic; -- unused
    signal s_round      : std_logic;    -- round up

    signal s_rounded : std_logic_vector(G_N - 2 downto 0); -- rounded result without sign
    signal s_negated : std_logic_vector(G_N - 2 downto 0); -- 

begin
    -- Extract Signs
    s_sign_0 <= i_operand_0(G_N - 1);
    s_sign_1 <= i_operand_1(G_N - 1);

    -- Check if inputs are Zero or NaR
    special_check : process(i_operand_0, i_operand_1, s_sign_0, s_sign_1)
        variable v_all_zeros_0 : std_logic;
        variable v_all_zeros_1 : std_logic;
    begin
        v_all_zeros_0 := or_reduce(i_operand_0(G_N - 2 downto 0));
        is_inf_0      <= s_sign_0 and (not v_all_zeros_0);
        is_zero_0     <= not (s_sign_0 or v_all_zeros_0);

        v_all_zeros_1 := or_reduce(i_operand_1(G_N - 2 downto 0));
        is_inf_1      <= s_sign_1 and (not v_all_zeros_1);
        is_zero_1     <= not (s_sign_1 or v_all_zeros_1);
    end process;

    s_result_is_inf  <= is_inf_0 or is_inf_1;
    s_result_is_zero <= is_zero_0 and is_zero_1;

    s_normalized_operand_0 <= std_logic_vector(unsigned(not i_operand_0(G_N - 2 downto 0)) + 1) when s_sign_0 = '1' else i_operand_0(G_N - 2 downto 0); -- overflow not possible, because of NaR, sign always 0
    s_normalized_operand_1 <= std_logic_vector(unsigned(not i_operand_1(G_N - 2 downto 0)) + 1) when s_sign_1 = '1' else i_operand_1(G_N - 2 downto 0);


    -- TODO think about if we can only use one twos complement negation, else ist will be negative so just negate result
    -- Data Extraction Operand 0
    inst_decoder_0 : entity work.posit_decode
        generic map(
            N  => G_N - 1,
            Bs => C_Bs,
            es => G_ES
        )
        port map(
            i_val    => s_normalized_operand_0,
            o_rc     => s_rc_0,
            o_regime => s_regime_0,
            o_exp    => s_exponent_0,
            o_mant   => s_mantissa_0
        );

    -- Data Extraction Operand 1
    inst_decoder_1 : entity work.posit_decode
        generic map(
            N  => G_N - 1,
            Bs => C_Bs,
            es => G_ES
        )
        port map(
            i_val    => s_normalized_operand_1,
            o_rc     => s_rc_1,
            o_regime => s_regime_1,
            o_exp    => s_exponent_1,
            o_mant   => s_mantissa_1
        );

    -- Determine larger number
    s_op0_greater_op1 <= '1' when unsigned(s_normalized_operand_0) > unsigned(s_normalized_operand_1) else '0';

    -- The result gets the sign of the larger number
    s_result_sign <= s_sign_0 when s_op0_greater_op1 = '1' else s_sign_1;

    -- Determine if addition or subtraction
    s_operation <= s_sign_0 xnor s_sign_1;

    -- aligns mantissa
    gen_pipe_0 : if G_N > C_GEN_PIPE_0 generate
        pipe_0_proc : process(i_clk)
        begin
            if rising_edge(i_clk) then
                if (i_enable = '1') then
                    r0_is_inf  <= s_result_is_inf;
                    r0_is_zero <= s_result_is_zero;

                    if s_result_is_inf = '0' and s_result_is_zero = '0' then
                        r0_rc_0            <= s_rc_0;
                        r0_rc_1            <= s_rc_1;
                        r0_regime_0        <= s_regime_0;
                        r0_regime_1        <= s_regime_1;
                        r0_exponent_0      <= s_exponent_0;
                        r0_exponent_1      <= s_exponent_1;
                        r0_mantissa_0      <= s_mantissa_0;
                        r0_mantissa_1      <= s_mantissa_1;
                        r0_result_sign     <= s_result_sign;
                        r0_op0_greater_op1 <= s_op0_greater_op1;

                        r0_operation <= s_operation;

                    end if;
                end if;
            end if;
        end process;
    end generate;

    gen_no_pipe_0 : if G_N <= C_GEN_PIPE_0 generate
        r0_is_inf  <= s_result_is_inf;
        r0_is_zero <= s_result_is_zero;

        r0_rc_0            <= s_rc_0;
        r0_rc_1            <= s_rc_1;
        r0_regime_0        <= s_regime_0;
        r0_regime_1        <= s_regime_1;
        r0_exponent_0      <= s_exponent_0;
        r0_exponent_1      <= s_exponent_1;
        r0_mantissa_0      <= s_mantissa_0;
        r0_mantissa_1      <= s_mantissa_1;
        r0_result_sign     <= s_result_sign;
        r0_op0_greater_op1 <= s_op0_greater_op1;

        r0_operation <= s_operation;
    end generate;

    -- Sort components by larger and smaller operand
    s_larger_rc  <= r0_rc_0 when r0_op0_greater_op1 = '1' else r0_rc_1;
    s_smaller_rc <= r0_rc_1 when r0_op0_greater_op1 = '1' else r0_rc_0;

    s_larger_regime  <= r0_regime_0 when r0_op0_greater_op1 = '1' else r0_regime_1;
    s_smaller_regime <= r0_regime_1 when r0_op0_greater_op1 = '1' else r0_regime_0;

    s_larger_exponent  <= r0_exponent_0 when r0_op0_greater_op1 = '1' else r0_exponent_1;
    s_smaller_exponent <= r0_exponent_1 when r0_op0_greater_op1 = '1' else r0_exponent_0;

    -- only add hidden bits to mantissa for calculations with shifter, for larger one the bit concat can be delayed until after the next register 
    s_larger_mantissa         <= r0_mantissa_0 when r0_op0_greater_op1 = '1' else r0_mantissa_1;
    s_smaller_hidden_mantissa <= '1' & r0_mantissa_1 when r0_op0_greater_op1 = '1' else '1' & r0_mantissa_0;

    -- Calculate efficient exponent of larger operand
    s_larger_signed_regime      <= '0' & s_larger_regime when s_larger_rc = '1' else std_logic_vector(unsigned(not ('0' & s_larger_regime)) + 1);
    s_larger_efficient_exponent <= s_larger_signed_regime & s_larger_exponent;

    -- Calculate efficient exponent of smaller operand
    s_smaller_signed_regime      <= '0' & s_smaller_regime when s_smaller_rc = '1' else std_logic_vector(unsigned(not ('0' & s_smaller_regime)) + 1);
    -- idea: 2^es * r ist equivalent to a shift of es, and exponent is es long => just prepend in front of exponent
    s_smaller_efficient_exponent <= s_smaller_signed_regime & s_smaller_exponent;

    -- Calcualte Difference
    s_efficient_exponent_difference <= std_logic_vector(signed(s_larger_efficient_exponent) - signed(s_smaller_efficient_exponent));

    -- Saturation Logic: If the difference is larger than the number of bits in the posit (or_reduce(diff...)),
    -- it saturates exp_diff to all '1's. This is an optimization: if you shift a 16-bit number right by 40 places,
    -- the result is 0 anyway, so you don't need a 40-bit shifter.
    --    exp_diff <= (others => '1') when or_reduce(diff(G_ES+C_Bs downto C_Bs)) = '1' else diff(C_Bs-1 downto 0);

    --s_smaller_padded_mantissa <= s_smaller_hidden_mantissa & (C_INTERNAL_MANTISSA_WIDTH-C_MAX_MANTISSA_WIDTH-2 downto 0 => '0');--(C_INTERNAL_MANTISSA_WIDTH-2 downto C_INTERNAL_MANTISSA_WIDTH-C_MAX_MANTISSA_WIDTH => '0');
    s_smaller_padded_mantissa <= s_smaller_hidden_mantissa & (1 downto 0 => '0');

    -- Check if shift is >= internal mantissa width (6 bits)
    -- Since G_N=8, C_Bs is 3 (max shift 7). 
    -- If difference is >= 6, we should effectively shift everything into the sticky bit.
    s_shift_out_of_range <= '1' when unsigned(s_efficient_exponent_difference) >= C_INTERNAL_MANTISSA_WIDTH else '0';

    -- Saturate the shift count
    -- If it's out of range, we force a shift that is larger than the width (e.g., 7)
    -- to ensure the result comes out 0, but the sticky logic still works.
    s_saturated_shift_count <= s_efficient_exponent_difference(C_Bs - 1 downto 0) when s_shift_out_of_range = '0' else (others => '1'); -- Shift all bits out

    inst_align_sticky_shift : entity work.sticky_shifter(open_rtl)
        generic map(
            C_DATA_WIDTH => C_INTERNAL_MANTISSA_WIDTH
        )
        port map(
            i_number      => s_smaller_padded_mantissa,
            i_shift_count => s_saturated_shift_count, --s_efficient_exponent_difference(C_Bs-1 downto 0),
            o_result      => s_aligned_mantissa
        );

    -- Correct the Sticky Bit Logic error here, if subtraction: sticky biot is missing from subtraction -> result too vbig, then even 1 by
    -- The sticky bit is 1 if:
    -- a) The shifter itself shifted a '1' into its own sticky output (index 0)
    -- b) OR out of range and the smaller operand was NOT zero
    s_alignment_sticky <= s_aligned_mantissa(0) or s_shift_out_of_range; --or_reduce(s_efficient_exponent_difference(C_Bs+G_ES downto C_Bs));

    r1_aligned_mantissa      <= s_aligned_mantissa(C_INTERNAL_MANTISSA_WIDTH downto 1);
    s_larger_padded_mantissa <= '1' & s_larger_mantissa & (1 downto 0 => '0'); -- ADD GUARD ROUNDING BIT

    s_signed_larger_hidden_mantissa <= "0" & s_larger_padded_mantissa; -- add sign to mantissa

    -- error correction in case of subtraction
    process(r0_operation, r1_aligned_mantissa, s_alignment_sticky)
    begin
        if r0_operation = '0' then
            -- SUBTRAKTION
            if s_alignment_sticky = '1' then
                s_signed_aligned_hidden_mantissa <= std_logic_vector(unsigned(not ("0" & r1_aligned_mantissa(C_INTERNAL_MANTISSA_WIDTH - 1 downto 0))));
            else
                s_signed_aligned_hidden_mantissa <= std_logic_vector(unsigned(not ("0" & r1_aligned_mantissa(C_INTERNAL_MANTISSA_WIDTH - 1 downto 0))) + 1);
            end if;
        else
            s_signed_aligned_hidden_mantissa <= "0" & r1_aligned_mantissa(C_INTERNAL_MANTISSA_WIDTH - 1 downto 0);
        end if;
    end process;

    -- s_summed_mantissa <= std_logic_vector(signed(s_signed_larger_hidden_mantissa) + signed(s_signed_aligned_hidden_mantissa));

    adder : entity work.parallel_prefix_adder
        generic map(
            G_DATA_WIDTH => C_INTERNAL_MANTISSA_WIDTH+1
        )
        port map(
            i_op_a   => s_signed_larger_hidden_mantissa,
            i_op_b   => s_signed_aligned_hidden_mantissa,
            o_result => s_summed_mantissa
        );
    

    pipe_1_proc : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_enable = '1') then
                r1_is_inf  <= r0_is_inf;
                r1_is_zero <= r0_is_zero;

                if r0_is_inf = '0' and r0_is_zero = '0' then
                    -- r1_signed_larger_hidden_mantissa <= s_signed_larger_hidden_mantissa;
                    -- r1_signed_aligned_hidden_mantissa <= s_signed_aligned_hidden_mantissa;\
                    r1_summed_mantissa           <= s_summed_mantissa;
                    r1_result_sign               <= r0_result_sign;
                    r1_larger_efficient_exponent <= s_larger_efficient_exponent; 
                    r1_alignmment_sticky         <= s_alignment_sticky;
                end if;
            end if;
        end if;
    end process;
    -- check overflow of mantissa (highest bit) and hidden bit (both can be cut)
    -- if overflow -> add one to exponent
    s_mantissa_overflow <= r1_summed_mantissa(C_INTERNAL_MANTISSA_WIDTH);

    -- ignore rounding bits before LOD

    inst_normlization_LOD : entity work.LOD_T
        generic map(
            G_DATA_WIDTH => C_INTERNAL_MANTISSA_WIDTH
        )
        port map(
            i_x   => r1_summed_mantissa(C_INTERNAL_MANTISSA_WIDTH - 1 downto 0),
            o_K   => s_normalized_lod_k,
            o_vld => s_normalized_lod_valid
        );

    s_valid_adjusted_lod_k <= s_normalized_lod_k when s_mantissa_overflow = '0' else (others => '0');

    r2_is_inf  <= r1_is_inf;
    r2_is_zero <= r1_is_zero;

    -- summed without overflow and sticky bit
    r2_summed_mantissa   <= r1_summed_mantissa(C_INTERNAL_MANTISSA_WIDTH - 1 downto 0);
    r2_mantissa_overflow <= s_mantissa_overflow;
    r2_normalize_lod_k   <= s_valid_adjusted_lod_k;

    r2_alignmment_sticky <= r1_alignmment_sticky;

    r2_larger_efficient_exponent <= r1_larger_efficient_exponent;

    r2_result_sign <= r1_result_sign;


    -- shift rigth if overflow, because there is a one to the left, else shift left
    -- Shift Mantissa to Normalize
    overflow_shift : process(r2_summed_mantissa, r2_mantissa_overflow, r2_normalize_lod_k) is
    begin
        if r2_mantissa_overflow = '1' then
            s_normalized_hidden_mantissa <= '1' & r2_summed_mantissa(r2_summed_mantissa'high downto 1);
            s_shift_right_sticky         <= r2_summed_mantissa(0);
        else
            s_normalized_hidden_mantissa <= std_logic_vector(shift_left(unsigned(r2_summed_mantissa), to_integer(unsigned(r2_normalize_lod_k))));
            s_shift_right_sticky         <= '0';
        end if;
    end process overflow_shift;

    -- s_normalized_hidden_mantissa <= std_logic_vector(shift_left(unsigned(r2_summed_mantissa), to_integer(unsigned(r2_normalize_lod_k))));

    -- adjust efficient Exponent 
    s_extended_mantissa_overflow <= (0 => r2_mantissa_overflow, others => '0');

    -- Substract Mantissa Shift amount and add Overflow Bit
    process(r2_larger_efficient_exponent, s_extended_mantissa_overflow, r2_normalize_lod_k)
    begin
        -- unsigned addition before
        s_efficient_exponent <= std_logic_vector(signed(r2_larger_efficient_exponent) - signed(std_logic_vector(resize(unsigned(r2_normalize_lod_k), C_Bs + G_ES + 2))) + signed(s_extended_mantissa_overflow));
    end process;

    -- Result Exponent and Regime Computation

    -- Calculate absolute value of efficient exponent to get regime length if overflow occured: 2s complement
    s_abs_efficient_exponent <= std_logic_vector(unsigned(not s_efficient_exponent(C_Bs + G_ES downto 0)) + 1) when s_efficient_exponent(C_Bs + G_ES + 1) = '1' else s_efficient_exponent(C_Bs + G_ES downto 0);

    -- Extract exponent bits
    s_exponent <= s_efficient_exponent(G_ES - 1 downto 0) when s_efficient_exponent(C_Bs + G_ES + 1) = '1' and or_reduce(s_abs_efficient_exponent(G_ES - 1 downto 0)) = '1' else s_abs_efficient_exponent(G_ES - 1 downto 0);

    -- Concatinate Exponent and Mantissa
    s_combined_exp_mantissa <= s_exponent & s_normalized_hidden_mantissa(C_INTERNAL_MANTISSA_WIDTH - 2 downto 0);

    -- Create regime bits for maximum length
    s_regime_bit <= not s_efficient_exponent(C_Bs + G_ES + 1);

    -- Combine Components 
    s_intermediate <= (0 => s_efficient_exponent(C_Bs + G_ES + 1)) & s_combined_exp_mantissa;

    -- Length calculation and correct value of k calculation according to standard
    process(s_efficient_exponent)
    begin
        -- regime positive => 1 bits, and + 1 to compensate -1 from decode step
        if signed(s_efficient_exponent(C_Bs + G_ES + 1 downto G_ES)) >= 0 then
            s_drs <= std_logic_vector(resize(unsigned(s_efficient_exponent(C_Bs + G_ES + 1 downto G_ES)), integer(clog2(s_intermediate'length)))); -- k '1's + '0'
        else
            s_drs <= std_logic_vector(resize(unsigned((not s_efficient_exponent(C_Bs + G_ES + 1 downto G_ES))), integer(clog2(s_intermediate'length)))); -- |k| '0's + '1'
        end if;
    end process;

    -- Idea here: s_drs seems to always be at least one, so shift more efficiently by one, then have a smaller shifter, and no adder needed in s_drs calculation -> in bigger bitranges worth it 
    s_shift_tmp        <= s_intermediate(0);
    s_intermediate_tmp <= s_intermediate(s_intermediate'high downto 1);

    inst_sticky_shifter_decide : entity work.sticky_shift_det(Tree)
        generic map(
            C_DATA_WIDTH => s_intermediate'length - 1
        )
        port map(
            i_number      => s_intermediate_tmp,
            i_shift_count => s_drs,
            i_shift_bit   => s_regime_bit,
            o_result      => s_sticky_shifted
        );

    -- Calculate Bits for rounding
    s_sticky_bit <= s_sticky_shifted(0) or r2_alignmment_sticky or s_shift_right_sticky or s_shift_tmp;
    s_guard_bit  <= s_sticky_shifted(1);
    s_lsb_bit    <= s_sticky_shifted(2);

    -- Check if result needs to be rounded
    s_round <= (s_guard_bit and (s_lsb_bit or s_sticky_bit));

    s_sticky_shifted2 <= s_regime_bit & s_sticky_shifted;

    process(s_sticky_shifted2, s_round)
        -- variable v_round           : std_logic_vector(C_INTERMEDIATE_WIDTH downto 0);
        variable v_round           : std_logic_vector(G_N - 2 downto 0);
        -- variable v_appended_sticky : std_logic_vector(C_INTERMEDIATE_WIDTH downto 0);
        variable v_appended_sticky : std_logic_vector(G_N - 2 downto 0);

    begin
        v_appended_sticky := s_sticky_shifted2(G_N downto 2);

        if s_round = '1' then
            v_round := std_logic_vector(unsigned(v_appended_sticky) + 1);
        else
            v_round := v_appended_sticky;
        end if;
        s_rounded <= v_round;
    end process;

    -- Apply Sign
    s_negated <= (std_logic_vector(unsigned(not s_rounded) + 1)) when r2_result_sign = '1' else s_rounded;

    -- Apply Special Result Values
    o_result <= r2_is_inf & (G_N - 2 downto 0 => '0') when (r2_is_inf = '1' or r2_is_zero = '1') or (s_normalized_hidden_mantissa(C_INTERNAL_MANTISSA_WIDTH - 1) = '0' and r2_mantissa_overflow = '0') else r2_result_sign & s_negated;

end Behavioral;
