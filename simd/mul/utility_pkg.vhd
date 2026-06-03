library ieee;

use ieee.std_logic_1164.all;
use ieee.math_real.all;

package utility_pkg is
    function clog2(n : integer) return integer;
    function or_reduce(n : std_logic_vector) return std_logic;
    function next_power_of_two(n : positive) return positive;
    function next_multiple_of_SIMD(max_len : integer; simd : integer) return integer;

    type t_arr is array (natural range <>) of std_logic_vector;
end package utility_pkg;

package body utility_pkg is
    function clog2(n : integer) return integer is
        variable r : integer := 0;
        variable m : integer := 1;
    begin
        while m < n loop
            m := m * 2;
            r := r + 1;
        end loop;
        return r;
    end function;

    function or_reduce(n : std_logic_vector) return std_logic is
        variable tmp : std_logic := '0';
    begin
        for i in n'high downto n'low loop
            tmp := n(i) or tmp;
        end loop;
        return tmp;
    end function;

    function next_power_of_two(n : positive) return positive is
        variable res : positive := 1;
    begin
        while res < n loop
            res := res * 2;
        end loop;
        return res;
    end function;

    -- function calculates next multiple of simd bigger than max_len
    function next_multiple_of_SIMD(max_len : integer; simd : integer) return integer is
    begin
    if (max_len mod simd) = 0 then
        return max_len;
    else 
        return ((max_len / simd) + 1) * simd;
    end if;
    end function;
end package body utility_pkg;
