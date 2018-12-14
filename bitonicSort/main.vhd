library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.types.all;



entity main is
end main;

architecture Flow of main is


	constant size: integer := 12;

	component bitonicSort is
		generic(
			logN: integer := 3
		);
		port (
			unsorted: in list(2**logN - 1 downto 0);
			sorted:  out list(2**logN - 1 downto 0)
		);
	end component;
	
	signal alpha, beta: list(2 ** size - 1 downto 0);
begin
	
	setup: for I in 0 to 2 ** size - 1 generate
		alpha(I) <= to_unsigned((2 ** size - I) mod 256, 8);
	end generate setup;
	
	sort: bitonicSort generic map(logN => size)
							   port map(unsorted => alpha, sorted => beta);

end Flow;

