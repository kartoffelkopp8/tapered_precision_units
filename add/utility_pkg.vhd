library ieee;
use ieee.std_logic_1164.ALL;
use ieee.math_real.all;

package pkg_utility is
    function next_power_of_two(n : positive) return positive; -- returns next power of 2 after n
    function or_reduce(input_vec : std_logic_vector) return std_logic;
    function clog2(n : integer) return integer;
end package;

package body pkg_utility is
    function next_power_of_two(n : positive) return positive is
        variable res : positive := 1;
    begin
        while res < n loop
            res := res * 2;
        end loop;
        return res;
    end function;

    function or_reduce(input_vec : std_logic_vector) return std_logic is
        constant N      : positive  := input_vec'length;
        variable result : std_logic := '0';
    begin
        for i in 0 to N - 1 loop
            result := result or input_vec(i);
        end loop;

        return result;
    end function;

-- Funktion: ceil(log2(n)) für n >= 1
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
end package body pkg_utility;
