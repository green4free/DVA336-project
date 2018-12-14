library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

package types is
   type list is array(natural range <>) of unsigned(8 - 1 downto 0);
end package;