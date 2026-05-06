library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package utility_pkg is
    function next_power_of_two(n : positive) return positive;
    function or_reduce(V: std_logic_vector) return std_logic;
    function clog2(n : integer) return integer;
    function is_power_of_two(i: integer) return boolean;
end package utility_pkg;

package body utility_pkg is
    function next_power_of_two(n : positive) return positive is
        variable res : positive := 1;
    begin
        while res < n loop
            res := res * 2;
        end loop;
        return res;
    end function;

	function is_power_of_two(i: integer) return boolean is
		variable val : unsigned(30 downto 0); -- Standard integer width
	begin
		if i <= 0 then
			return False;
		end if;

		val := to_unsigned(i, 31);
		-- The classic (x & (x-1)) trick
		if (val and (val - 1)) = 0 then
			return True;
		else
			return False;
		end if;
	end function;

	function or_reduce(V: std_logic_vector)
	return std_logic is
		variable result: std_logic := '0';
	begin
		for i in V'range loop
			result := result or V(i);
		end loop;
		return result;
	end or_reduce;


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
end package body utility_pkg;
