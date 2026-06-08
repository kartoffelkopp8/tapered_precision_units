library ieee;
use ieee.std_logic_1164.all;

package utility_pkg is
	function or_reduce(vec : std_logic_vector) return std_logic;
	function cond_invert(vec : std_logic_vector; inv : std_logic) return std_logic_vector;
	function clog2(n : integer) return integer;
	subtype characteristic is integer range -255 to 254;
	function get_overflow_value(N : integer) return characteristic;
	function get_underflow_value(N : integer) return characteristic;

end package utility_pkg;

package body utility_pkg is
	function or_reduce(vec : std_logic_vector)
	return std_logic is
		variable result : std_logic := '0';
	begin
		for i in vec'range loop
			result := result or vec(i);
		end loop;
		return result;
	end or_reduce;

	function cond_invert(vec : std_logic_vector; inv : std_logic)
	return std_logic_vector is
		variable result : std_logic_vector(vec'range);
	begin
		for i in vec'range loop
			result(i) := inv xor vec(i);
		end loop;
		return result;
	end function;

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

	-- calculated with 2^7-1 + rest of char bytes and lower part of char with 0
	function get_overflow_value(N : integer) return characteristic is
	begin
		case N is
			when 2      => return 0;
			when 3      => return 15;
			when 4      => return 63;
			when 5      => return 127;
			when 6      => return 191;
			when 7      => return 223;
			when 8      => return 239;
			when 9      => return 247;
			when 10     => return 251;
			when 11     => return 253;
			when others => return 254;
		end case;
	end function;

	-- -2^8 +1 + G_N-5 0 and then rest is 1 of the 7 characteristic bits for minimum showable
	function get_underflow_value(N : integer) return characteristic is
	begin 
		case N is
            when 2      => return -1;
            when 3      => return -16;
            when 4      => return -64;
            when 5      => return -128;
            when 6      => return -192;
            when 7      => return -224;
            when 8      => return -240;
            when 9      => return -248;
            when 10     => return -252;
            when 11     => return -254;
            when others => return -255; -- Absolutes Minimum für N >= 12
        end case;
	end function;

end package body utility_pkg;
